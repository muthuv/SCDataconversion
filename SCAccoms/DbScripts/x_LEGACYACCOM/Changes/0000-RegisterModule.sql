-- NOTE: 0000 scripts run outside of a transaction so the schema can be created
-- so keep work here to a minimum

-- Create schema
if not exists (select 1 from sys.schemas where name = 'x_LEGACYACCOM')
exec VC3Deployment.CreateSchema 'x_LEGACYACCOM'


if not exists (select 1 from VC3Deployment.ModuleDependency where UsedBy = 'x_LEGACYACCOM')
begin
-- Register module
exec VC3Deployment.AddModule 'x_LEGACYACCOM'
exec VC3Deployment.AddModuleDependency @usedBy='x_LEGACYACCOM', @uses='dbo'
exec VC3Deployment.AddModuleDependency @usedBy='x_LEGACYACCOM', @uses='VC3ETL'
exec VC3Deployment.AddModuleDependency @usedBy='x_LEGACYACCOM', @uses='LEGACYSPED'
exec VC3Deployment.AddModuleDependency @usedBy='x_LEGACYACCOM', @uses='x_LEGACY504'
exec VC3Deployment.AddModuleDependency @usedBy='x_LEGACYACCOM', @uses='x_LEGACYGIFT'
end
--
