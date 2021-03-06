IF EXISTS (SELECT 1 FROM sys.schemas s join sys.objects o on s.schema_id = o.schema_id where s.name = 'x_DATAVALIDATION' and o.name = 'usp_GenerateValidationReport')
DROP PROC x_DATAVALIDATION.usp_GenerateValidationReport
GO

CREATE PROC x_DATAVALIDATION.usp_GenerateValidationReport
AS
DECLARE @jobID uniqueidentifier, @cmd varchar(1000) ,@startdate int, @starttime int,@job_name varchar(50),@district varchar(50)
,@vpndisconnect varchar(500),@locfolder varchar(250),@enrichdbname varchar(250),@validationreportcmd varchar(1000);

SET @startdate = CONVERT(INT,REPLACE(CONVERT(VARCHAR(10),GETDATE(),102),'.',''));
SET @starttime = CONVERT(INT,REPLACE(CONVERT(VARCHAR(8),DATEADD(mi,2,GETDATE()),108),':',''));

select @cmd = '"'+ParamValue+'"' from x_DATAVALIDATION.ParamValues where ParamName='ValidationreportFile'
select @district = ParamValue from x_DATAVALIDATION.ParamValues where ParamName='district'
select @locfolder = ParamValue from x_DATAVALIDATION.ParamValues where ParamName='locfolder'
SELECT @enrichdbname=ParamValue FROM x_DATAVALIDATION.ParamValues WHERE ParamName = 'EnrichDbname'
select @vpndisconnect=ParamValue from x_DATAVALIDATION.ParamValues where ParamName='VPNDisconnectFile'

set @vpndisconnect = '"'+@vpndisconnect+'"';
set @cmd=@cmd+' '+@locfolder;
set @job_name='_runValidationReport_Prod'+@district;
set @validationreportcmd = N'EXECUTE AS LOGIN = ''cmdshelluser''
EXEC master..xp_CMDShell '''+@cmd+'''
REVERT';


IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = @job_name)
BEGIN
     EXEC msdb.dbo.sp_delete_job @job_name = @job_name
END


EXEC msdb.dbo.sp_add_job @job_name = @job_name, @enabled  = 1, @start_step_id = 1, @owner_login_name='sa', @job_id = @jobID OUTPUT 

EXEC msdb.dbo.sp_add_jobstep @job_id = @jobID, @step_name = 'Dissconnect VPN',@subsystem=N'TSQL', 
		@command=N'EXECUTE AS LOGIN = ''cmdshelluser''
exec master..xp_CMDShell ''rasdial "SC Excentonline"  /DISCONNECT''
REVERT', 
		@database_name=@enrichdbname
, @step_id = 1,@on_success_action=4,@on_success_step_id=2

EXEC msdb.dbo.sp_add_jobstep @job_id = @jobID, @step_name = 'Run validation step', @step_id = 2
,@subsystem=N'TSQL', @command = @validationreportcmd,@database_name=@enrichdbname

EXEC msdb.dbo.sp_add_jobserver @job_id = @jobID
--SET @job_name = '_runValidationReport'

EXEC msdb.dbo.sp_add_jobschedule @job_name = @job_name,
@name = 'ValidationReportSchedule',
@freq_type=1,
@active_start_date = @startdate,
@active_start_time = @starttime

GO

/*
IF EXISTS (SELECT 1 FROM sys.schemas s join sys.objects o on s.schema_id = o.schema_id where s.name = 'x_DATAVALIDATION' and o.name = 'usp_GenerateValidationReport')
DROP PROC x_DATAVALIDATION.usp_GenerateValidationReport
GO

CREATE PROC x_DATAVALIDATION.usp_GenerateValidationReport
AS

EXEC master..xp_CMDShell 'C:\ValidationReport_SSIS\ValidationReport_Upload_FTP\validationreport.bat'

GO



exec msdb.dbo.sp_help_job '_runValidationReport'


EXEC msdb.dbo.sp_start_job @job_id = @jobID, @output_flag = 0 

WAITFOR DELAY '000:02:00' -- Give the job a chance to complete
*/