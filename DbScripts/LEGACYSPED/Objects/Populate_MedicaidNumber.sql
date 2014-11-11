IF EXISTS (SELECT 1 FROM sys.schemas s join sys.objects o on s.schema_id = o.schema_id where s.name = 'LEGACYSPED' and o.name = 'Update_MedicaidNumber')
DROP PROC LEGACYSPED.Update_MedicaidNumber
GO

CREATE PROC LEGACYSPED.Update_MedicaidNumber
AS
BEGIN

UPDATE s 
SET MedicaidNumber = ls.MedicaidNumber
-- select ls.MedicaidNumber, s.MedicaidNumber, s.*
FROM LEGACYSPED.Student ls
JOIN dbo.Student s on ls.StudentLocalID = s.Number
WHERE ls.MedicaidNumber IS NOT NULL
AND s.MedicaidNumber IS NULL

END
