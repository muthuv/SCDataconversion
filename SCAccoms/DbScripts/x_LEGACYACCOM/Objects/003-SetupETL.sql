BEGIN TRAN

-- Declare a temporary table to hold the data to be synchronized
DECLARE @VC3ETL_ExtractDatabase TABLE (ID uniqueidentifier, Type uniqueidentifier, DatabaseType uniqueidentifier, Server varchar(64), DatabaseOwner varchar(64), DatabaseName varchar(128), Username varchar(32), Password varchar(32), LinkedServer varchar(100), IsLinkedServerManaged bit, LastExtractDate datetime, LastLoadDate datetime, SucceededEmail varchar(500), SucceededSubject text, SucceededMessage text, FailedEmail varchar(500), FailedSubject text, FailedMessage text, RetainSnapshot bit, DestTableTempSuffix varchar(30), DestTableFinalSuffix varchar(30), FileGroup varchar(64), Schedule uniqueidentifier, Name varchar(100), Enabled bit)

-- Insert the data to be synchronized into the temporary table
INSERT INTO @VC3ETL_ExtractDatabase VALUES ( 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B', 'ACBEF25A-A8EB-465B-97D8-9738F07C3023', 'CBE6E716-95F0-44BC-837C-BBC4FD59506C','EOServer', 'dbo', 'SouthCarolinaEODB', 'DBUser', 'Password', NULL, 0, '1/1/1970', '1/1/1970', NULL, '[{BrandName}] {SisDatabase} import completed', 'Successfully imported {SisDatabase} data into {BrandName}.  {SisDatabase} data in {BrandName} is now current as of {SnapshotDate}.', NULL, '[{BrandName}] {SisDatabase} import failed', 'There was a problem importing {SisDatabase} data into {BrandName}:  {ErrorMessage}', 1, '_NEW', '_LOCAL', NULL, NULL, 'EO Accomdation Data Import', 1)

-- Declare a temporary table to hold the data to be synchronized
DECLARE @VC3ETL_ExtractTable TABLE (ID uniqueidentifier, ExtractDatabase uniqueidentifier, SourceTable varchar(100), DestSchema varchar(50), DestTable varchar(50), PrimaryKey varchar(100), Indexes varchar(200), LastSuccessfulCount int, CurrentCount int, Filter varchar(1000), Enabled bit, IgnoreMissing bit, Columns varchar(4000), Comments varchar(1000))

-- Insert the data to be synchronized into the temporary table
--INSERT INTO @VC3ETL_ExtractTable VALUES ('642BB649-FF50-418E-9866-FE605880F8A1', 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B', 'AllDocs', 'x_LEGACYDOC', 'AllDocs', 'DocumentRefID, DocumentType', NULL, 0, 0, NULL, 1, 0, NULL, NULL)

-- Declare a temporary table to hold the data to be synchronized
DECLARE @VC3ETL_LoadTable TABLE (ID uniqueidentifier, ExtractDatabase uniqueidentifier, Sequence int, SourceTable varchar(100), DestTable varchar(100), HasMapTable bit, MapTable varchar(100), KeyField varchar(250), DeleteKey varchar(50), ImportType int, DeleteTrans bit, UpdateTrans bit, InsertTrans bit, Enabled bit, SourceTableFilter varchar(1000), DestTableFilter varchar(1000), PurgeCondition varchar(1000), KeepMappingAfterDelete bit, StartNewTransaction bit, LastLoadDate datetime, MapTableMapID varchar(250), Comments varchar(1000))

-- Insert the data to be synchronized into the temporary table
INSERT INTO @VC3ETL_LoadTable VALUES ('5C8F8B6B-973B-4C8B-ACD1-1853C441E277', 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B', 0, 'x_LEGACYACCOM.ImportLegacyData_RAWandLOCAL', NULL, 0, NULL, NULL, NULL, 4, 0, 0, 0, 1, NULL, NULL, NULL, 0, 0, '12/17/2012 10:13:21 AM', NULL, NULL)
INSERT INTO @VC3ETL_LoadTable VALUES ('75353434-5301-409C-8F61-993DAF274135', 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B', 1,  'x_LEGACYACCOM.SCAccoms_ImportFormletData', NULL, 0, NULL, NULL, NULL, 4, 0, 0, 0, 1, NULL, NULL, NULL, 0, 0, '12/17/2012 10:13:21 AM', NULL, NULL)
-- INSERT INTO @VC3ETL_LoadTable VALUES ('85834387-84C1-4570-A48C-5F17DE3A3F10', 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B', 2,  'x_LEGACYACCOM.SCAccoms_ImportFormletData', NULL, 0, NULL, NULL, NULL, 4, 0, 0, 0, 1, NULL, NULL, NULL, 0, 0, '12/17/2012 10:13:21 AM', NULL, NULL)

-- Declare a temporary table to hold the data to be synchronized    
DECLARE @VC3ETL_LoadColumn TABLE (ID uniqueidentifier, LoadTable uniqueidentifier, SourceColumn varchar(500), DestColumn varchar(500), ColumnType char(1), UpdateOnDelete bit, DeletedValue varchar(500), NullValue varchar(500), Comments varchar(1000))

--select * from VC3ETL.LoadTable Destination where ExtractDatabase = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B'
--select * from VC3ETL.ExtractTable Destination where ExtractDatabase = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B'


-- refactor 
delete Destination 
from VC3ETL.ExtractTable Destination left join 
@VC3ETL_ExtractTable Source on Destination.ID = Source.ID
where Destination.ExtractDatabase = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B' and
Source.ID is null


delete Destination 
from VC3ETL.LoadTable Destination left join 
@VC3ETL_LoadTable Source on Destination.ID = Source.ID
where Destination.ExtractDatabase = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B' and
Source.ID is null

--Delete the records from the VC3ETL.LoadColumn table by matching the constraints LoadColumn ID == null.  
delete Destination
from VC3ETL.LoadTable lt join
VC3ETL.LoadColumn Destination on lt.ID = Destination.LoadTable left join
@VC3ETL_LoadColumn Source on Destination.ID = Source.ID
where lt.ExtractDatabase = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B' and
Source.ID is null


-- Insert records in the destination tables that do not already exist
INSERT INTO VC3ETL.ExtractDatabase SELECT Source.* FROM @VC3ETL_ExtractDatabase Source LEFT JOIN VC3ETL.ExtractDatabase Destination ON Source.ID = Destination.ID WHERE Destination.ID IS NULL
INSERT INTO VC3ETL.ExtractTable SELECT Source.* FROM @VC3ETL_ExtractTable Source LEFT JOIN VC3ETL.ExtractTable Destination ON Source.ID = Destination.ID WHERE Destination.ID IS NULL
INSERT INTO VC3ETL.LoadTable SELECT Source.* FROM @VC3ETL_LoadTable Source LEFT JOIN VC3ETL.LoadTable Destination ON Source.ID = Destination.ID WHERE Destination.ID IS NULL
INSERT INTO VC3ETL.LoadColumn SELECT Source.*, 1 FROM @VC3ETL_LoadColumn Source LEFT JOIN VC3ETL.LoadColumn Destination ON Source.ID = Destination.ID WHERE Destination.ID IS NULL

-- Update records in the destination table that already exist
UPDATE Destination SET Destination.Type = Source.Type, Destination.DatabaseType = Source.DatabaseType, Destination.Server = Source.Server, Destination.DatabaseOwner = Source.DatabaseOwner, Destination.DatabaseName = Source.DatabaseName, Destination.Username = Source.Username, Destination.Password = Source.Password, Destination.LinkedServer = Source.LinkedServer, Destination.IsLinkedServerManaged = Source.IsLinkedServerManaged, Destination.LastExtractDate = Source.LastExtractDate, Destination.LastLoadDate = Source.LastLoadDate, Destination.SucceededEmail = Source.SucceededEmail, Destination.SucceededSubject = Source.SucceededSubject, Destination.SucceededMessage = Source.SucceededMessage, Destination.FailedEmail = Source.FailedEmail, Destination.FailedSubject = Source.FailedSubject, Destination.FailedMessage = Source.FailedMessage, Destination.RetainSnapshot = Source.RetainSnapshot, Destination.DestTableTempSuffix = Source.DestTableTempSuffix, Destination.DestTableFinalSuffix = Source.DestTableFinalSuffix, Destination.FileGroup = Source.FileGroup, Destination.Schedule = Source.Schedule, Destination.Name = Source.Name, Destination.Enabled = Source.Enabled FROM @VC3ETL_ExtractDatabase Source JOIN VC3ETL.ExtractDatabase Destination ON Source.ID = Destination.ID
UPDATE Destination SET Destination.ExtractDatabase = Source.ExtractDatabase, Destination.SourceTable = Source.SourceTable, Destination.DestSchema = Source.DestSchema, Destination.DestTable = Source.DestTable, Destination.PrimaryKey = Source.PrimaryKey, Destination.Indexes = Source.Indexes, Destination.LastSuccessfulCount = Source.LastSuccessfulCount, Destination.CurrentCount = Source.CurrentCount, Destination.Filter = Source.Filter, Destination.Enabled = Source.Enabled, Destination.IgnoreMissing = Source.IgnoreMissing, Destination.Columns = Source.Columns, Destination.Comments = Source.Comments FROM @VC3ETL_ExtractTable Source JOIN VC3ETL.ExtractTable Destination ON Source.ID = Destination.ID
UPDATE Destination SET Destination.ExtractDatabase = Source.ExtractDatabase, Destination.Sequence = Source.Sequence, Destination.SourceTable = Source.SourceTable, Destination.DestTable = Source.DestTable, Destination.HasMapTable = Source.HasMapTable, Destination.MapTable = Source.MapTable, Destination.KeyField = Source.KeyField, Destination.DeleteKey = Source.DeleteKey, Destination.ImportType = Source.ImportType, Destination.DeleteTrans = Source.DeleteTrans, Destination.UpdateTrans = Source.UpdateTrans, Destination.InsertTrans = Source.InsertTrans, Destination.Enabled = Source.Enabled, Destination.SourceTableFilter = Source.SourceTableFilter, Destination.DestTableFilter = Source.DestTableFilter, Destination.PurgeCondition = Source.PurgeCondition, Destination.KeepMappingAfterDelete = Source.KeepMappingAfterDelete, Destination.StartNewTransaction = Source.StartNewTransaction, Destination.LastLoadDate = Source.LastLoadDate, Destination.MapTableMapID = Source.MapTableMapID, Destination.Comments = Source.Comments FROM @VC3ETL_LoadTable Source JOIN VC3ETL.LoadTable Destination ON Source.ID = Destination.ID
UPDATE Destination SET Destination.LoadTable = Source.LoadTable, Destination.SourceColumn = Source.SourceColumn, Destination.DestColumn = Source.DestColumn, Destination.ColumnType = Source.ColumnType, Destination.UpdateOnDelete = Source.UpdateOnDelete, Destination.DeletedValue = Source.DeletedValue, Destination.NullValue = Source.NullValue, Destination.Comments = Source.Comments FROM @VC3ETL_LoadColumn Source JOIN VC3ETL.LoadColumn Destination ON Source.ID = Destination.ID


UPDATE VC3ETL.ExtractDatabase
SET Server = (select ParamValue from x_DATAVALIDATION.ParamValues where ParamName = 'linkedServerAddress'),
DatabaseOwner = (select ParamValue from x_DATAVALIDATION.ParamValues where ParamName = 'databaseOwner'),
DatabaseName = (select ParamValue from x_DATAVALIDATION.ParamValues where ParamName = 'databaseName'),
UserName = (select ParamValue from x_DATAVALIDATION.ParamValues where ParamName = 'EOdatabaseUserName'),
Password = (select ParamValue from x_DATAVALIDATION.ParamValues where ParamName = 'EOdatabasepwd'),
LinkedServer = (select '['+ParamValue+']' from x_DATAVALIDATION.ParamValues where ParamName = 'linkedServerAlias')
WHERE ID = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B'


delete m
-- select *
from LEGACYSPED.MAP_IEPStudentRefID m
where m.DestID not in (select s.ID from PrgItem s)

delete m
-- select *
from LEGACYSPED.MAP_PrgSectionID_NonVersioned m
where m.ItemID not in (select s.ID from PrgItem s)
-- deleted 1200+ records that were 

delete i
-- select * 
from LEGACYSPED.IEP_LOCAL i
where IepRefID not in (select IepRefID from LEGACYSPED.MAP_IEPStudentRefID)

--Rollback TRAN
set nocount off;

COMMIT TRAN

exec sp_refreshview 'LEGACYSPED.StudentView'


--select * from VC3ETL.LoadTable where ExtractDatabase = 'ECC83BE4-9CB9-4AC4-B7C3-2E4ACBECC26B'
--select * from VC3Deployment.Version where Module = 'x_LEGACYDOC'

--delete VC3Deployment.Version where Module = 'x_LEGACYDOC' and ID in (2718, 2719)
--select * from x_LEGACYDOC.IEPDoc

--17857 (active and referred).  16000+ active



