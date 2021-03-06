--Get rid off old version
IF EXISTS (SELECT 1 FROM sys.schemas s join sys.objects o on s.schema_id = o.schema_id where s.name = 'x_DATAVALIDATION' and o.name = 'Check_SpecialFactors_Specifications')
DROP PROC x_DATAVALIDATION.Check_SpecialFactors_Specifications
GO
/*
To check the specfication of Goal file with our data specification
*/
CREATE PROC x_DATAVALIDATION.Check_SpecialFactors_Specifications
AS
BEGIN

DECLARE @sql nVARCHAR(MAX)

SET @sql = 'DELETE x_DATAVALIDATION.SpecialFactors'
EXEC sp_executesql @stmt = @sql

---Validated data
DECLARE @sqlvalidated VARCHAR(MAX)
SET @sqlvalidated = 
'INSERT  x_DATAVALIDATION.SpecialFactors  
SELECT g.Line_No '
             
DECLARE @MaxCount INTEGER
DECLARE @Count INTEGER
DECLARE @sel VARCHAR(MAX)
DECLARE @tblsel table (id int, columnname varchar(50),datatype varchar(50),datalength varchar(5))
INSERT @tblsel
SELECT ColumnOrder,columnname,DataType,datalength
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' 

SET @Count = 1
SET @sel = ''
SET @MaxCount = (SELECT MAX(id)FROM @tblsel)
WHILE @Count<=@MaxCount
    BEGIN
    IF ((SELECT datatype FROM @tblsel WHERE ID = @Count) = 'varchar')
    BEGIN
    SET @sel=@sel+', CONVERT ( VARCHAR ('+(SELECT datalength from @tblsel WHERE ID = @Count)+'), g.' +(SELECT columnname from @tblsel WHERE ID = @Count)+')'
    END
    ELSE IF ((SELECT datatype FROM @tblsel WHERE ID = @Count) = 'datetime')
    BEGIN
    SET @sel=@sel+', CONVERT ( DATETIME , g.' +(SELECT columnname from @tblsel WHERE ID = @Count)+')'
    END
    ELSE IF ((SELECT datatype FROM @tblsel WHERE ID = @Count) = 'int')
    BEGIN
    SET @sel=@sel+', CONVERT ( INT , g.' +(SELECT columnname from @tblsel WHERE ID = @Count)+')'
    END
    ELSE
    BEGIN
    SET @sel=@sel+', CONVERT ( VARCHAR ('+(SELECT datalength from @tblsel WHERE ID = @Count)+'), g.' +(SELECT columnname from @tblsel WHERE ID = @Count)+')'
    END
    SET @Count=@Count+1
    END
--print @sel
SET @sqlvalidated = @sqlvalidated + @sel+ ' FROM x_DATAVALIDATION.SpecialFactors_Local g'

DECLARE @Txtreq VARCHAR(MAX)
DECLARE @tblreq table (id int, columnname varchar(50))
INSERT @tblreq
SELECT ROW_NUMBER()over(order by columnname),columnname
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' AND IsRequired =1

SET @Count = 1
SET @Txtreq = ''
SET @MaxCount = (SELECT MAX(id)FROM @tblreq)
WHILE @Count<=@MaxCount
    BEGIN
        SET @Txtreq=@Txtreq+' AND g.'+(select columnname from @tblreq WHERE ID=@Count) + ' IS NOT NULL '
    SET @Count=@Count+1
    END
--SELECT @Txtreq AS Txt


DECLARE @Txtdatalength VARCHAR(MAX)
DECLARE @tbldl table (id int, columnname varchar(50),datalength varchar(10),isrequired bit)
INSERT @tbldl
SELECT ROW_NUMBER()over(order by columnname),columnname,datalength,IsRequired
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' 
SET @Count = 1
SET @Txtdatalength = ''
SET @MaxCount = (SELECT MAX(id)FROM @tbldl)
WHILE @Count<=@MaxCount
    BEGIN
    IF (@Txtdatalength = '' and (select isrequired from @tbldl WHERE ID=@Count)= 1)
    BEGIN
    SET @Txtdatalength=@Txtdatalength+' WHERE (DATALENGTH('+'g.'+(select columnname from @tbldl WHERE ID=@Count) + ')/2) <= '+(select datalength from @tbldl WHERE ID=@Count)
    END
    ELSE IF (@Txtdatalength = '' and (select isrequired from @tbldl WHERE ID=@Count)= 0)
    BEGIN
    SET @Txtdatalength=@Txtdatalength+' WHERE ((DATALENGTH('+'g.'+(select columnname from @tbldl WHERE ID=@Count) + ')/2) <= '+(select datalength from @tbldl WHERE ID=@Count) +' OR (g.'+(select columnname from @tbldl WHERE ID=@Count)+' IS NULL))'
    END
    ELSE IF (@Txtdatalength != '' and (select isrequired from @tbldl WHERE ID=@Count)= 0)
    BEGIN
    SET @Txtdatalength=@Txtdatalength+' AND ((DATALENGTH('+'g.'+(select columnname from @tbldl WHERE ID=@Count) + ')/2) <= '+(select datalength from @tbldl WHERE ID=@Count) +' OR (g.'+(select columnname from @tbldl WHERE ID=@Count)+' IS NULL))'
    END
    ELSE IF (@Txtdatalength != '' and (select isrequired from @tbldl WHERE ID=@Count)= 1)
    BEGIN
    SET @Txtdatalength=@Txtdatalength+' AND (DATALENGTH('+'g.'+(select columnname from @tbldl WHERE ID=@Count) + ')/2) <= '+(select datalength from @tbldl WHERE ID=@Count)
    END
    SET @Count=@Count+1
    END
--SELECT @Txtdatalength AS Txtdl

DECLARE @Txtflag VARCHAR(MAX)
DECLARE @tblflag table (id int,columnname varchar(50),flagrecords varchar(50),isrequired varchar(50))
INSERT @tblflag
SELECT ROW_NUMBER()over(order by columnname),columnname,FlagRecords,IsRequired
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' and IsFlagfield = 1

SET @Count = 1
SET @Txtflag = ''
SET @MaxCount = (SELECT MAX(id)FROM @tblflag)
WHILE @Count<=@MaxCount
    BEGIN
    IF ((select isrequired from @tblflag WHERE ID=@Count)= 1)
    BEGIN
    SET @Txtflag=@Txtflag+' AND g.'+(select columnname from @tblflag WHERE ID=@Count) + ' IN ('+(select flagrecords from @tblflag WHERE ID=@Count)+')'
    END
    ELSE IF ((select isrequired from @tblflag WHERE ID=@Count)= 0)
    BEGIN
    SET @Txtflag=@Txtflag+' AND (g.'+(select columnname from @tblflag WHERE ID=@Count) + ' IN ('+(select flagrecords from @tblflag WHERE ID=@Count)+') OR g.'+(select columnname from @tblflag WHERE ID=@Count)+' IS NULL)'
    END
    SET @Count=@Count+1
    END
--SELECT @Txtflag AS Txtflag

DECLARE @Txtfkrel VARCHAR(MAX)
DECLARE @tblfkrel table (id int, columnname varchar(50),parenttable varchar(50), parentcolumn varchar(50))
INSERT @tblfkrel
SELECT ROW_NUMBER()over(order by columnname),columnname,ParentTable,ParentColumn
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' AND IsFkRelation = 1
SET @Count = 1
SET @Txtfkrel = ''
SET @MaxCount = (SELECT MAX(id)FROM @tblfkrel)
WHILE @Count<=@MaxCount
    BEGIN
    SET @Txtfkrel=@Txtfkrel+' JOIN x_DATAVALIDATION.'+(SELECT parenttable FROM @tblfkrel WHERE ID= @Count)+' '+(SELECT LEFT(parenttable,3) FROM @tblfkrel WHERE ID= @Count)+' ON '+(SELECT LEFT(parenttable,3) FROM @tblfkrel WHERE ID= @Count)+'.'+(SELECT parentcolumn FROM @tblfkrel WHERE ID= @Count)+' = g.'+(SELECT columnname FROM @tblfkrel WHERE ID= @Count)
    SET @Count=@Count+1
    END
--SELECT @Txtfkrel AS Txtfk

DECLARE @Txtlookup VARCHAR(MAX)
DECLARE @tbllookup table (id int, columnname varchar(50),lookuptable varchar(50),lookupcolumn varchar(50),lookuptype varchar(50), isrequired bit)
INSERT @tbllookup
SELECT ROW_NUMBER()over(order by columnname),columnname,LookupTable,LookupColumn,LookUpType,IsRequired
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' AND IsLookupColumn = 1
SET @Count = 1
SET @Txtlookup = ''
SET @MaxCount = (SELECT MAX(id)FROM @tbllookup)
WHILE @Count<=@MaxCount
    BEGIN
    IF ((select isrequired from @tbllookup WHERE ID=@Count)= 1 and (select lookuptable from @tbllookup WHERE ID=@Count) != 'SelectLists')
    BEGIN
    SET @Txtlookup=@Txtlookup+' AND g.'+(SELECT columnname FROM @tbllookup WHERE ID= @Count)+' IN ( SELECT '+(SELECT lookupcolumn FROM @tbllookup WHERE ID= @Count)+' FROM x_DATAVALIDATION.'+(SELECT lookuptable FROM @tbllookup WHERE ID= @Count)+')'
    END
    ELSE IF ((select isrequired from @tbllookup WHERE ID=@Count)= 1 and (select lookuptable from @tbllookup WHERE ID=@Count) = 'SelectLists')
    BEGIN
    SET @Txtlookup=@Txtlookup+' AND g.'+(SELECT columnname FROM @tbllookup WHERE ID= @Count)+' IN ( SELECT '+(SELECT lookupcolumn FROM @tbllookup WHERE ID= @Count)+' FROM x_DATAVALIDATION.'+(SELECT lookuptable FROM @tbllookup WHERE ID= @Count)+' WHERE Type = '''+ (SELECT lookuptype FROM @tbllookup WHERE ID= @Count)+''')'
    END
    ELSE IF ((select isrequired from @tbllookup WHERE ID=@Count)= 0 and (select lookuptable from @tbllookup WHERE ID=@Count) != 'SelectLists')
    BEGIN
    SET @Txtlookup=@Txtlookup+' AND (g.'+(SELECT columnname FROM @tbllookup WHERE ID= @Count)+' IN ( SELECT '+(SELECT lookupcolumn FROM @tbllookup WHERE ID= @Count)+' FROM x_DATAVALIDATION.'+(SELECT lookuptable FROM @tbllookup WHERE ID= @Count)+') OR g.'+(SELECT columnname FROM @tbllookup WHERE ID= @Count)+' IS NULL)'
    END
    ELSE IF ((select isrequired from @tbllookup WHERE ID=@Count)= 0 and (select lookuptable from @tbllookup WHERE ID=@Count) = 'SelectLists')
    BEGIN
      SET @Txtlookup=@Txtlookup+' AND ( g.'+(SELECT columnname FROM @tbllookup WHERE ID= @Count)+' IN (SELECT '+(SELECT lookupcolumn FROM @tbllookup WHERE ID= @Count)+' FROM x_DATAVALIDATION.'+(SELECT lookuptable FROM @tbllookup WHERE ID= @Count)+' WHERE Type = '''+ (SELECT lookuptype FROM @tbllookup WHERE ID= @Count)+''') OR g.'+(SELECT columnname FROM @tbllookup WHERE ID= @Count)+' IS NULL)'
    END
    SET @Count=@Count+1
    END
--SELECT @Txtlookup AS Txtl

DECLARE @Txtdatatype VARCHAR(MAX)
DECLARE @tbldttype table (id int, columnname varchar(50),datatype varchar(50),isrequired bit)
INSERT @tbldttype
SELECT ROW_NUMBER()over(order by columnname),columnname,DataType,IsRequired
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors' 

SET @Count = 1
SET @Txtdatatype = ''
SET @MaxCount = (SELECT MAX(id)FROM @tbldttype)
WHILE @Count<=@MaxCount
    BEGIN
    IF ((SELECT datatype FROM @tbldttype WHERE ID = @Count) = 'INT' and (SELECT isrequired FROM @tbldttype WHERE ID = @Count) = 1)
    BEGIN
    SET @Txtdatatype=@Txtdatatype+' AND x_DATAVALIDATION.udf_IsInteger( g.'+(SELECT columnname FROM @tbldttype WHERE ID = @Count)+') = 1'
    END
    ELSE IF ((SELECT datatype FROM @tbldttype WHERE ID = @Count) = 'INT' and (SELECT isrequired FROM @tbldttype WHERE ID = @Count) = 0)
    BEGIN
    SET @Txtdatatype=@Txtdatatype+' AND (x_DATAVALIDATION.udf_IsInteger( g.'+(SELECT columnname FROM @tbldttype WHERE ID = @Count)+') = 1 OR g.'+(SELECT columnname FROM @tbldttype WHERE ID = @Count)+' IS NULL)'
    END
    ELSE IF ((SELECT datatype FROM @tbldttype WHERE ID = @Count) = 'Datetime' and (SELECT isrequired FROM @tbldttype WHERE ID = @Count) = 1)
    BEGIN
    SET @Txtdatatype=@Txtdatatype+' AND ISDATE(g.'+(SELECT columnname FROM @tbldttype WHERE ID = @Count)+') = 1'
    END
    ELSE IF ((SELECT datatype FROM @tbldttype WHERE ID = @Count) = 'Datetime' and (SELECT isrequired FROM @tbldttype WHERE ID = @Count) = 0)
    BEGIN
    SET @Txtdatatype=@Txtdatatype+' AND ( ISDATE( g.'+(SELECT columnname FROM @tbldttype WHERE ID = @Count)+') = 1 OR g.'+(SELECT columnname FROM @tbldttype WHERE ID = @Count)+' IS NULL)'
    END
    SET @Count=@Count+1
    END
--SELECT @Txtdatatype AS Txt

DECLARE @Txtunique VARCHAR(MAX)
DECLARE @tbluq table (id int, columnname varchar(50))
INSERT @tbluq
SELECT ROW_NUMBER()over(order by columnname),columnname
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors'  AND IsUniqueField = 1
SET @Count = 1
SET @Txtunique = ''
SET @MaxCount = (SELECT MAX(id)FROM @tbluq)
WHILE @Count<=@MaxCount
    BEGIN
    SET @Txtunique=@Txtunique + ' JOIN (SELECT ' +(select columnname from @tbluq WHERE ID=@Count)+ ' FROM x_DATAVALIDATION.SpecialFactors_LOCAL GROUP BY '+(select columnname from @tbluq WHERE ID=@Count)+' HAVING COUNT(*)=1) '+(select 'u'+left(columnname,3) from @tbluq WHERE ID=@Count)+' ON ' +(select 'u'+left(columnname,3) from @tbluq WHERE ID=@Count)+'.' +(select columnname from @tbluq WHERE ID=@Count) +' = g.'+(select columnname from @tbluq WHERE ID=@Count)        
        
        SET @Count=@Count+1
    END
--SELECT @Txtunique AS Txtq

SET @sqlvalidated = @sqlvalidated +@Txtunique+@Txtfkrel+@Txtreq+@Txtflag+@Txtdatatype+@Txtlookup
--SET @sqlvalidated = @sqlvalidated +@Txtunique+@Txtfkrel+@Txtdatalength+@Txtreq+@Txtflag+@Txtdatatype+@Txtlookup
print @sqlvalidated

EXEC (@sqlvalidated)

--================================================================================		  
--Log the count of successful records
--================================================================================    
INSERT x_DATAVALIDATION.ValidationSummaryReport(TableName,ErrorMessage,NumberOfRecords)
SELECT 'SpecialFactors','SuccessfulRecords',COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors


--=========================================================================
--Log the Validation Results (If any issues we encounter)
--=========================================================================
--To check the Datalength of the fields
IF (SELECT CURSOR_STATUS('global','chkSpecifications')) >=0 
BEGIN
DEALLOCATE chkSpecifications
END

DECLARE @tableschema VARCHAR(50),@tablename VARCHAR(50),@columnname VARCHAR(50),@datatype VARCHAR(50),@datalength VARCHAR(50),@isrequired bit,@isuniquefield bit,@isFkRelation bit, @parenttable VARCHAR(50),@parentcolumn VARCHAR(50),@islookupcolumn bit, @lookuptable VARCHAR(50),@lookupcolumn VARCHAR(50),@lookuptype VARCHAR(50),@isFlagfield bit,@flagrecords VARCHAR(50)

DECLARE chkSpecifications CURSOR FOR 
SELECT TableSchema, TableName,ColumnName,DataType,DataLength,IsRequired,IsUniqueField,IsFkRelation,ParentTable,ParentColumn,IsLookupColumn,LookupTable,LookupColumn,LookupType,IsFlagfield,FlagRecords
FROM x_DATAVALIDATION.ValidationRules WHERE TableName = 'SpecialFactors'

OPEN chkSpecifications

FETCH NEXT FROM chkSpecifications INTO @tableschema,@tablename,@columnname,@datatype,@datalength,@isrequired,@isuniquefield,@isFkRelation,@parenttable,@parentcolumn,@islookupcolumn,@lookuptable,@lookupcolumn,@lookuptype,@isFlagfield,@flagrecords
DECLARE @vsql nVARCHAR(MAX)
DECLARE @sumsql nVARCHAR(MAX)
DECLARE @query nVARCHAR(MAX)
DECLARE @uncol nVARCHAR(MAX)
DECLARE @uniqoncol nVARCHAR(MAX)

WHILE @@FETCH_STATUS = 0
BEGIN
------------------------------------------------
--Check the required fields
------------------------------------------------
IF (@isrequired=1)
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''The field '+@columnname+' is required but not found.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	WHERE 1 = 1'

SET @query  = ' AND (spfct.'+@columnname+' IS NULL)'
SET @vsql = @vsql + @query
--PRINT @vsql
EXEC sp_executesql @stmt=@vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''The field '+@columnname+' is required but not found.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local WHERE 1 = 1 '

SET @query  = ' AND ('+@columnname+' IS NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql
END
----------------------------------------------------------------
--Check the datalength of Every Fields in the file
----------------------------------------------------------------
IF (1=1)
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'','''+@columnname+' field will be truncated at '+@datalength+' characters.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	WHERE 1 = 1'

SET @query  = ' AND ((DATALENGTH (REPLACE(spfct.'+@columnname+','''''''',''''))/2) > '+@datalength+' AND spfct.'+@columnname+' IS NOT NULL)'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'','''+@columnname+' field will be truncated at '+@datalength+' characters.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local WHERE 1 = 1 '

SET @query  = ' AND ((DATALENGTH (REPLACE('+@columnname+','''''''',''''))/2) > '+@datalength+' AND '+@columnname+' IS NOT NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql

END
-------------------------------------------------------------------
--Check the Referntial Integrity Issues
-------------------------------------------------------------------
/*
IF (@isFkRelation = 1)
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''No '+@parenttable+' record found for '+@tablename+'.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	 '

SET @query  = ' LEFT JOIN x_DATAVALIDATION.'+@parenttable+' dt ON spfct.'+@columnname+' = dt.'+@parentcolumn+' WHERE dt.'+@parentcolumn+' IS NULL'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''No '+@parenttable+' record found for '+@tablename+'.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local goal '

SET @query  = ' LEFT JOIN x_DATAVALIDATION.'+@parenttable+' dt ON spfct.'+@columnname+' = dt.'+@parentcolumn+' WHERE dt.'+@parentcolumn+' IS NULL'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql
END
*/
-------------------------------------------------------------------
--Check the flag fields
-------------------------------------------------------------------
IF (@isFlagfield = 1)
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''Invalid value in '+@columnname+' it must be Y or N.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	 '

SET @query  = '  WHERE (spfct.'+@columnname+' NOT IN  ('+@flagrecords+') AND spfct.'+@columnname+' IS NOT NULL)'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql


SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''Invalid value in '+@columnname+' it must be Y or N.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local spfct '

SET @query  = '  WHERE (spfct.'+@columnname+' NOT IN  ('+@flagrecords+') AND spfct.'+@columnname+' IS NOT NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql
END
-------------------------------------------------------------------
--Check the unique fields
-------------------------------------------------------------------

IF (@isuniquefield = 1)
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'','''+@columnname+' is duplicated.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	'

SET @query  = ' JOIN (SELECT '+@columnname+' FROM x_DATAVALIDATION.SpecialFactors_Local GROUP BY '+@columnname+' HAVING COUNT(*)>1) ucspfct ON ucspfct.'+@columnname+' = spfct.'+@columnname+' '
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'','''+@columnname+' is duplicated.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN  '

SET @query  = ' (SELECT '+@columnname+' FROM x_DATAVALIDATION.SpecialFactors_Local GROUP BY '+@columnname+' HAVING COUNT(*)>1) ucspfct ON ucspfct.'+@columnname+' = spfct.'+@columnname+' '
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql

END
-------------------------------------------------------------------
--Check the Lookup columns and Referntial issues
-------------------------------------------------------------------
IF (@islookupcolumn = 1 AND @lookuptable = 'SelectLists')
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''No lookup value found for '+@columnname+'.  Contact ExcentDataTeam@excent.com .'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	'

SET @query  = ' WHERE (spfct.'+@columnname+' NOT IN ( SELECT '+@lookupcolumn+' FROM x_DATAVALIDATION.'+@lookuptable+' WHERE Type = '''+@lookuptype+''') AND spfct.'+@columnname+' IS NOT NULL)'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''No lookup value found for '+@columnname+'.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local spfct  '

SET @query  = ' WHERE (spfct.'+@columnname+' NOT IN ( SELECT '+@lookupcolumn+' FROM x_DATAVALIDATION.'+@lookuptable+' WHERE Type = '''+@lookuptype+''') AND spfct.'+@columnname+' IS NOT NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql

END

IF (@islookupcolumn =1 AND @lookuptable != 'SelectLists')
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''No lookup value found for '+@columnname+'.  Contact ExcentDataTeam@excent.com .'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	'

SET @query  = ' WHERE (spfct.'+@columnname+' NOT IN ( SELECT '+@lookupcolumn+' FROM x_DATAVALIDATION.'+@lookuptable+') AND spfct.'+@columnname+' IS NOT NULL)'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''No lookup value found for '+@columnname+'.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local spfct  '

SET @query  = ' WHERE (spfct.'+@columnname+' NOT IN ( SELECT '+@lookupcolumn+' FROM x_DATAVALIDATION.'+@lookuptable+') AND spfct.'+@columnname+' IS NOT NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql

END


IF (@datatype = 'datetime')
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''Expected date value in '+@columnname+'.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	WHERE 1 = 1 '

SET @query  = ' AND (ISDATE(''spfct.'+@columnname+''') = 0 AND spfct.'+@columnname+' IS NOT NULL)'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''Expected date value in '+@columnname+'.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local WHERE 1 = 1 '

SET @query  = ' AND (ISDATE('''+@columnname+''') = 0 AND '+@columnname+' IS NOT NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql

END

IF (@datatype = 'int')
BEGIN

SET @vsql = 'INSERT x_DATAVALIDATION.ValidationReport (TableName,ErrorMessage,LineNumber,Line)
SELECT ''SpecialFactors'',''Expected integer value in '+@columnname+'.'',spfct.Line_No,ISNULL(CONVERT(VARCHAR(max),st.studentLocalID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.FirstName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),st.LastName),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.IepRefID),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.Behaviour),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafBlind),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.DeafHH),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.BlindVI),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.HealthCarePlan),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.LEP),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.AssistiveTech),'''')+''|''+ISNULL(CONVERT(VARCHAR(max),spfct.SpecialTrans),'''') FROM x_DATAVALIDATION.SpecialFactors_Local spfct JOIN x_DATAVALIDATION.Iep_local iep ON iep.IepRefID = spfct.IepRefID JOIN x_DATAVALIDATION.Student_local st on st.StudentrefID = iep.StudentrefID	WHERE 1 = 1 '

SET @query  = ' AND (x_DATAVALIDATION.udf_IsInteger(spfct.'+@columnname+') = 0 AND spfct.'+@columnname+' IS NOT NULL)'
SET @vsql = @vsql + @query
EXEC sp_executesql @stmt=@vsql
--PRINT @vsql

SET @sumsql = 'INSERT x_DATAVALIDATION.ValidationSummaryReport (TableName,ErrorMessage,NumberOfRecords)
SELECT ''SpecialFactors'',''Expected integer value in '+@columnname+'.'', COUNT(*)
FROM x_DATAVALIDATION.SpecialFactors_Local WHERE 1 = 1 '

SET @query  = ' AND (x_DATAVALIDATION.udf_IsInteger('+@columnname+') = 0 AND '+@columnname+' IS NOT NULL)'
SET @sumsql = @sumsql + @query
--PRINT @sumsql
EXEC sp_executesql @stmt=@sumsql

END

FETCH NEXT FROM chkSpecifications INTO  @tableschema,@tablename,@columnname,@datatype,@datalength,@isrequired,@isuniquefield,@isFkRelation,@parenttable,@parentcolumn,@islookupcolumn,@lookuptable,@lookupcolumn,@lookuptype,@isFlagfield,@flagrecords
END
CLOSE chkSpecifications
DEALLOCATE chkSpecifications
/*
---------------------------------------------------------------------------------
---Required Fields
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------- 
--To Check Duplicate Records
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--To Check the Referential Integrity
----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--Checking the flags columns whether is having "Y"/"N" (as per our dataspecification)
-----------------------------------------------------------------------------------------
*/
END
