--#include ..\..\..\Objects\Check_SelectLists_Specifications.sql
--#include ..\..\..\Objects\Check_District_Specifications.sql
--#include ..\..\..\Objects\Check_School_Specifications.sql
--#include ..\..\..\Objects\Check_Student_Specifications.sql
--#include ..\..\..\Objects\Check_IEP_Specifications.sql
--#include ..\..\..\Objects\Check_SpedStaffMember_Specifications.sql
--#include ..\..\..\Objects\Check_Service_Specifications.sql
--#include Check_Goal_Specifications.sql
--#include Check_Objective_Specifications.sql
--#include ..\..\..\Objects\Check_TeamMember_Specifications.sql
--#include ..\..\..\Objects\Check_StaffSchool_Specifications.sql
--#include ..\..\..\Objects\usp_DatavalidatoinCleanUp_Flatfile.sql
--#include ..\..\..\Objects\usp_DatavalidatoinCleanUp_EO.sql
--#include ..\..\..\Objects\usp_ImportDataFileStaging.sql
--#include ..\..\..\Objects\usp_CheckColumnNameAndOrder.sql
--#include ..\..\..\Objects\usp_ExtractDatafile_From_Csv.sql
--#include ..\..\..\Objects\usp_ReportFilePreaprtion.sql
--#include ..\..\..\Objects\usp_DataValidationReport_History.sql
--#include ..\..\..\Objects\usp_ExtractDatafile_EO.sql
--#include ..\..\..\Objects\usp_ExtractFlatfile.sql

-- let's reset the counts for imported data so we know this script ran when we run dc from the ui
--update et set LastSuccessfulCount = 0, CurrentCount = 0 from VC3ETL.ExtractTable et where ExtractDatabase = '9756E9BB-8B6B-44E4-9C4E-B3F8E6A6CD16' 
--go
