/*
select tp.*, td.Sequence, td.Name, a.*
from student s
join PrgItem i on s.ID = i.StudentID
join PrgSection sec on i.ID = sec.ItemID
join IepAssessments a on sec.ID = a.ID
join ieptestparticipation tp on a.ID = tp.InstanceID
join IepTestDef td on tp.TestDefID = td.ID
order by s.ID, td.Sequence

select * from x_LEGACYACCOM.MAP_FormInstanceID

select t.name, d.* from PrgSectionDef d join PrgSectionType t on d.TypeID = t.ID where d.ID = '82AFDE84-49C0-45D0-B13E-201151CE90CC'

select * 
from FormTemplate 
where ID = '9C0BA64E-C848-42F4-9A16-B9B6D37CA85C'

select * from forminstance where templateID = '9C0BA64E-C848-42F4-9A16-B9B6D37CA85C'

x_datateam.findguid '53F25EAD-7CE1-4035-ABE6-02F7183B3F74'
select * from dbo.FormInstance where Id = '53F25EAD-7CE1-4035-ABE6-02F7183B3F74'
select * from dbo.FormInstanceInterval where InstanceId = '53F25EAD-7CE1-4035-ABE6-02F7183B3F74'
select * from LEGACYSPED.MAP_FormInstanceID where HeaderFormInstanceID = '53F25EAD-7CE1-4035-ABE6-02F7183B3F74'
select * from dbo.PrgItemForm where ID = '53F25EAD-7CE1-4035-ABE6-02F7183B3F74'
select * from dbo.PrgSection where HeaderFormInstanceID = '53F25EAD-7CE1-4035-ABE6-02F7183B3F74'

select * from dbo.FormInputValue where IntervalID = '4EC5CC46-F2B7-49B1-9F3F-715C291F1135'

x_datateam.findguid '4EC5CC46-F2B7-49B1-9F3F-715C291F1135'

select tv.* 
from FormInputValue v
join FormInputTextValue tv on v.ID = tv.ID
where v.IntervalID = '4EC5CC46-F2B7-49B1-9F3F-715C291F1135'


select ssv.* 
from FormInputValue v
join FormInputSingleSelectValue ssv on v.ID = ssv.ID
where v.IntervalID = '4EC5CC46-F2B7-49B1-9F3F-715C291F1135'

x_datateam.findguid '024F58CF-A177-426B-AE43-7F758962752F'
select * from dbo.FormTemplateInputSelectFieldOption where ID = '024F58CF-A177-426B-AE43-7F758962752F'





-- select * from ieptestdef order by Sequence



exec x_datateam.findguid '3AA56188-00C0-4E30-B074-EDCF6651B20B'
select * from LEGACYSPED.MAP_FormInputValueID where IntervalID = '3AA56188-00C0-4E30-B074-EDCF6651B20B'
select * from LEGACYSPED.MAP_FormInstanceID where HeaderFormInstanceIntervalID = '3AA56188-00C0-4E30-B074-EDCF6651B20B'

-- one dest id of a value record
exec x_datateam.findguid 'A02CBF95-74AE-4E57-9604-598B8D8F1933'

-- begin tran 
-- should use the other schema


*/

begin tran

update sec set HeaderFormInstanceID = NULL
-- select *
from x_LEGACYACCOM.MAP_FormInstanceID m
join PrgSection sec on m.HeaderFormInstanceID = Sec.HeaderFormInstanceID

delete fi
-- select *
from x_LEGACYACCOM.MAP_FormInstanceID m
join FormInstance fi on m.HeaderFormInstanceID = fi.ID

delete m
-- select * 
from x_LEGACYACCOM.MAP_FormInputValueID m -- where IntervalID = '3AA56188-00C0-4E30-B074-EDCF6651B20B'

delete m
-- select * 
from x_LEGACYACCOM.MAP_FormInstanceID m -- where HeaderFormInstanceIntervalID = '3AA56188-00C0-4E30-B074-EDCF6651B20B'

-- assessments
delete a
-- select * 
from LEGACYSPED.MAP_PrgSectionID_NonVersioned m
join PrgSection s on m.DestID = s.ID
join IepAssessments a on s.ID = a.ID

delete s
-- select * 
from LEGACYSPED.MAP_PrgSectionID_NonVersioned m
join PrgSection s on m.DestID = s.ID
where s.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC'

delete m
-- select * 
from LEGACYSPED.MAP_PrgSectionID_NonVersioned m
where m.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC'

--- accommodations
delete a
-- select * 
from LEGACYSPED.MAP_PrgSectionID m
join PrgSection s on m.DestID = s.ID
join IepAccommodations a on s.ID = a.ID

delete s
-- select * 
from LEGACYSPED.MAP_PrgSectionID m
join PrgSection s on m.DestID = s.ID
where s.DefID = '43CD5045-8083-4534-AD66-A81C43A42F26'

delete m
-- select * 
from LEGACYSPED.MAP_PrgSectionID m
where m.DefID = '43CD5045-8083-4534-AD66-A81C43A42F26'

delete m
-- select m.*
from LEGACYSPED.ImportPrgSections m 
where m.SectionDefID in ('43CD5045-8083-4534-AD66-A81C43A42F26', '82AFDE84-49C0-45D0-B13E-201151CE90CC')




commit


-- drop all x_legacyaccom objects to start over
declare @q varchar(max)

declare O cursor for
select 'drop '+case o.Type when 'P' then 'proc' when 'U' then 'table' when 'V' then 'view' end+ ' x_LEGACYACCOM.'+o.name
from sys.schemas s
join sys.objects o on s.schema_id = o.schema_id 
where s.name = 'x_LEGACYACCOM'
and o.Type <> 'PK'
order by case o.type when 'P' then 0 when 'V' then 1 when 'U' then 2 end, o.name

open O
fetch O into @q

while @@FETCH_STATUS = 0
begin

exec (@q)

fetch O into @q
end
close O
deallocate O
