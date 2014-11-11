IF EXISTS (SELECT 1 FROM sys.schemas s JOIN sys.objects o on s.schema_id = o.schema_id WHERE s.name = 'x_LEGACYACCOM' AND o.name = 'ImportLegacyData_RAWandLOCAL')
DROP PROC x_LEGACYACCOM.ImportLegacyData_RAWandLOCAL
GO

CREATE PROC x_LEGACYACCOM.ImportLegacyData_RAWandLOCAL
AS
BEGIN
/*
To Populate the source data in Enrich database from the EO database
*/
DECLARE @etlRoot varchar(255), @VpnConnectFile varchar(255), @VpnDisconnectFile varchar(255), @PopulateDCSpeedObj varchar(255), @q varchar(8000),@district varchar(50), @vpnYN char(1),@locfolder varchar(250) ; 

DECLARE @ro varchar(100), @et varchar(100), @deleteqa NVARCHAR(max),@deleteqasc NVARCHAR(max),@deleteqascm NVARCHAR(max), 
	@insertqa NVARCHAR(max),
	@insertqasc NVARCHAR(max), 
	@insertqascm NVARCHAR(max), 
	@insertqam NVARCHAR(max),
	@LinkedserverAddress VARCHAR(100), @DatabaseOwner VARCHAR(100), @DatabaseName VARCHAR(100), @newline varchar(5) ; set @newline = '
'

SELECT @LinkedserverAddress = LinkedServer, @DatabaseOwner = DatabaseOwner, @DatabaseName = DatabaseName -- SELECT *
FROM VC3ETL.ExtractDatabase 
WHERE ID = '9756E9BB-8B6B-44E4-9C4E-B3F8E6A6CD16'

SELECT @etlRoot = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='etlRoot'
SELECT @VpnConnectFile = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='VpnConnectFile'
SELECT @VpnDisconnectFile = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='VpnDisconnectFile'
SELECT @PopulateDCSpeedObj = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='populateDVSpeedObj'
SELECT @district = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='district'
SELECT @vpnYN = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='vpnYN'
SELECT @locfolder = ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName='locfolder'

SET @q = 'cd '+@etlRoot
SET @VpnConnectFile = '"'+@VpnConnectFile+'"';
SET @PopulateDCSpeedObj = '"'+@PopulateDCSpeedObj+'"';
SET @PopulateDCSpeedObj = @PopulateDCSpeedObj+' '+@locfolder;

PRINT @district
PRINT @q
PRINT @VpnConnectFile
PRINT @PopulateDCSpeedObj
PRINT @VpnDisconnectFile


--SELECT * FROM x_DATAVALIDATION.ParamValues where paramname not like 'check%'


IF (@vpnYN = 'Y')
BEGIN
EXEC master..xp_CMDShell @q
EXECUTE AS LOGIN = 'cmdshelluser'
EXEC master..xp_CMDShell @VpnConnectFile
REVERT
END

SET @deleteqa = 'if object_id(''x_LEGACYACCOM.EO_IEPAccomModTbl_RAW'') is not null
DROP TABLE x_LEGACYACCOM.EO_IEPAccomModTbl_RAW'
EXEC (@deleteqa)
 
SET @insertqa = 'select a.* INTO x_LEGACYACCOM.EO_IEPAccomModTbl_RAW
from '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.dbo.SpecialEdStudentsAndIEPs x
join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.[dbo].IEPAccomModTbl a on x.GStudentID = a.GStudentID  
where isnull(a.del_flag,0)=0'

SET @deleteqasc = 'if object_id(''x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW'') is not null
DROP TABLE x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW'
EXEC (@deleteqasc)

SET @insertqasc = 'select a2.* INTO x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW
from '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.dbo.SpecialEdStudentsAndIEPs x
join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.[dbo].IEPAccomModTbl a on x.GStudentID = a.GStudentID
join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.[dbo].IEPAccomModTbl_SC a2 on a.IEPAccomSeq = a2.IEPAccomSeq 
where isnull(a.del_flag,0)=0 and isnull(a2.del_flag,0)=0'
 
SET @deleteqascm = 'if object_id(''x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW'') is not null
DROP TABLE x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW'
EXEC (@deleteqascm)

SET @insertqascm = 'select aa.* INTO x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW
from '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.dbo.SpecialEdStudentsAndIEPs x
join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.[dbo].IEPAccomModTbl a on x.GStudentID = a.GStudentID
join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.[dbo].ICIEPAccomModTbl_SC a2 on a.IEPAccomSeq = a2.IEPAccomSeq and x.IEPSeqNum = a2.IEPComplSeqNum 
join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.[dbo].ICIEPAccomModListTbl_SC aa on a.IEPAccomSeq = aa.IEPAccomSeq and x.IEPSeqNum = aa.IEPComplSeqNum
where isnull(a.del_flag,0)=0 and isnull(a2.del_flag,0)=0 and isnull(aa.del_flag,0)=0'
 
SET @deleteqascm = 'if object_id(''x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW'') is not null
DROP TABLE x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW'
EXEC (@deleteqascm)
 
set @insertqam = 'select IEPComplSeqNum = x.IEPSeqNum, m.IEPModSeq, m.SupplementAids, ProgramModify = isnull(m.ProgramModify,0), m.Modifications into x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW 
from '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.dbo.SpecialEdStudentsAndIEPs x
left join '+isnull(@LinkedserverAddress,'linkservhere')+'.'+isnull(@DatabaseName,'dbnamehere')+'.dbo.ICIEPModTbl_SC m on x.IEPSeqNum = m.IEPComplSeqNum and isnull(m.del_flag,0)=0'
 
 EXEC (@insertqa)
 EXEC (@insertqasc)
 EXEC (@insertqascm)
 EXEC (@insertqam)

------------------------------------------------------------ populate local table for district test accoms import
DELETE x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL 

insert x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL 
select m.IEPRefID, SubRefID = a.IEPAccomSeq,
	DistAssessTitle = case isnull(a2.DistAssess,0) when 2 then cast(a2.AltAssess as varchar(100)) when 1 then a2.DistAssessTitle end,
	Participation = 
		case isnull(a2.DistAssess,0) when 3 then NULL -- District Assessment Not Applicable
			when 2 then '1A5FC3E2-4C97-4323-976A-D9D129D92414' --1A5FC3E2-4C97-4323-976A-D9D129D92414	Non-standard with modifications
			when 1 then 
				case 
					when acc.Accommodations is null then '024F58CF-A177-426B-AE43-7F758962752F' --024F58CF-A177-426B-AE43-7F758962752F	Standard, no accommodations
					else '5D3D44BA-3348-4E5A-A321-5253F76DFEC8' --5D3D44BA-3348-4E5A-A321-5253F76DFEC8	Standard, with accommodations
				end
		end,
	Accommodations = 
		case isnull(a2.DistAssess,0) when 3 then NULL -- N/A in the EO UI
			when 0 then NULL
			else '<ul>'+acc.Accommodations+'</ul>' -- 1 Accommodations, 2 Modifications (non-standard means Alternate district assessment, with modifications, per Enrich UI drop-down)
		end,
	Sequence = (
		select count(*) 
		from x_LEGACYACCOM.EO_IEPAccomModTbl_RAW c 
		where a.GStudentID = c.GStudentID 
		and a.IEPAccomSeq > c.IEPAccomSeq
		) -- cannot cheat anymore we were getting more than one result per IEP at Oconee.
from LEGACYSPED.MAP_IEPStudentRefID m
join x_LEGACYACCOM.EO_IEPAccomModTbl_RAW a on m.StudentRefID = a.GStudentID
join x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW a2 on a.IEPAccomSeq = a2.IEPAccomSeq and isnull(a2.del_flag,0)=0 and isnull(a.del_flag,0)=0
join (
	select a1.IEPAccomSeq,
		Accommodations = (
			select li = t1.AccomDesc -- column name will be used as a tag 
			from x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW t1
			where a1.IEPAccomSeq = t1.IEPAccomSeq 
			and t1.AccomType = 'AC12' 
			and isnull(a1.del_flag,0)=0 and isnull(t1.del_flag,0)=0
			for xml path('')
			)
	from x_LEGACYACCOM.EO_IEPAccomModTbl_RAW a1 
) acc on a.IEPAccomSeq = acc.IEPAccomSeq


insert  x_LEGACYACCOM.ClassroomAccomMod_LOCAL
-- using this for performance when we union all of the forminputfields together
select IEPRefID = r.IEPComplSeqNum, SubRefID = r.IEPModSeq, ModifyYN = ProgramModify, Accoms = SupplementAids, Mods = Modifications
from x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW r join
(Select IEPComplSeqNum,MAX(IEPModSeq) IEPModSeq 
 from x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW Group by IEPComplSeqNum )rmax 
on rmax.IEPComplSeqNum = r.IEPComplSeqNum and r.IEPModSeq = rmax.IEPModSeq
-- where IEPModSeq is not null -- we should not use a left join for this view. handle missing later.

 
END
GO
