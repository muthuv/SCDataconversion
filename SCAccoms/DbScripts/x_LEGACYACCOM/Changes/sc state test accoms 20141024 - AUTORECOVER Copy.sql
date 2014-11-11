



select * from iepassessments
select * from EnumValue where ID = 'A2B683CD-BEA7-4EC8-8BF8-41C1ACBC909E'



--insert IepAssessments (ID, ParentsAreInformedID, UseBooleanParticipation)
--select DestID, ParentsAreInformedID = cast(NULL as uniqueidentifier), UseBooleanParticipation = cast(0 as bit)
--from x_WalkIEP.Transform_PrgSection t
--left join IepAssessments x on t.DestID = x.ID 
--where t.DefID = '6B65D022-365A-42F3-979E-73F7A887C2C4'
--and x.ID is null


---- Where any student has an alternate assesseement, insert a record for each TPQ with a response of Yes
--insert IepTestPartQuestionResponse (ID, QuestionID, InstanceID, IsYes)
--select ID = newid(), QuestionID = q.ID, t.InstanceID, IsYes = 1
--from x_WalkIEP.Transform_IepTestParticipation t
--cross join IepTestParticipationQuestion q
--left join IepTestPartQuestionResponse x on q.ID = x.QuestionID and t.InstanceID = x.InstanceID 
--where ParticipationType = 'Alternate'
--and x.ID is null
--group by t.InstanceID, q.ID


---- only insert 1 AQR for the "Imported from Encore" question. Others not necessary 
--insert IepAccomQuestionResponse (ID, QuestionID, InstanceID, IsYes)
--select ID = newID(), 
--	QuestionID = '82A6C533-ADC3-49F7-8104-4660DE312385', -- Imported from Encore
--	t.InstanceID, 
--	IsYes = cast(1 as bit)
--from x_WalkIEP.Transform_IepTestParticipation t
--left join IepAccomQuestionResponse aqr on t.InstanceID = aqr.InstanceID and aqr.QuestionID = '82A6C533-ADC3-49F7-8104-4660DE312385'
--group by t.InstanceID



--insert IepTestParticipation (ID, InstanceID, TestDefID, ParticipationDefID, IsParticipating)
--select ID = newID(), inst.InstanceID, test.TestDefID, t.ParticipationDefID, IsParticipating = cast(case when t.instanceid is null then 0 else 1 end as bit)
--from (
--	select TestDefID -- distinct list of all tests from Encore matching tests in Enrich
--	from x_WalkIEP.Transform_IepTestParticipation t
--	group by TestDefID
--	) test
--	cross join 
--	(
--	select t.InstanceID -- all instances with tests
--	from x_WalkIEP.Transform_IepTestParticipation t
--	group by t.InstanceID
--	) inst
--left join x_WalkIEP.Transform_IepTestParticipation t on test.TestDefID = t.TestDefID and inst.InstanceID = t.InstanceID
--left join IepTestParticipation x on test.TestDefID = x.TestDefID and inst.InstanceID = x.InstanceID
--where x.id is null
--go




sp_helptext 'x_LEGACYACCOM.Transform_IepAccommodations'

go

alter view x_LEGACYACCOM.Transform_IepAccommodations
as
select c.IEPRefID, s.DestID, Explanation = cast (NULL as VARCHAR(max)), TrackDetails = 0, TrackForAssessments = 0, 
	NoAccommodationsRequired = case when isnull(c.Accoms, 'NA') in ('NA', 'N/A', '', 'None') then 1 else 0 end,
	NoModificationsRequired = abs(1-c.ModifyYN)
	--, c.Accoms, c.Mods -- testing only
from LEGACYSPED.MAP_PrgSectionID s 
join LEGACYSPED.MAP_PrgVersionID v on s.VersionID = v.DestID
join x_LEGACYACCOM.ClassroomAccomMod_LOCAL c on v.IepRefID = c.IEPRefID --- classroom yes, but tests like it too
where s.DefID = '43CD5045-8083-4534-AD66-A81C43A42F26'
go



--x_WalkIEP.Encore_TestAccommodations
-- equiv in SC ?

select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL -- x_WalkIEP.Encore_TestAccommodations
go

alter view x_LEGACYACCOM.EO_StateTestAccommodations
as
select 
	tp.IEPRefID, /* tp.IEPAccomSeq, */ 
	TestAccomRefID = am.RecNum, -- Must be unique. NULLs will exist if we left join
	tp.InstanceID, tp.TestDefID, 
	tp.TestGroup, tp.EnrichTestName, tp.Participation, tp.StateParticipationDefID, 
	AccommType = am.AccomType, 
	AccommodationText = am.AccomDesc,
	IsModification = case when AccomCode like '%MOD%' then 1 else 0 end
from x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL tp
join x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW am on tp.IEPAccomSeq = am.IEPAccomSeq and tp.EOTestCode = am.AccomType
--order by IepRefID, TestGroup, EnrichTestName -- am.AccomType, convert(varchar(max), AccomDesc)
go

--select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL tp where Eo
--select * from x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW am where am.RecNum = 37045 --- 1 record
--select * from x_LEGACYACCOM.EO_StateTestAccommodations a where TestAccomRefID = 37045 

--select * from x_LEGACYACCOM.EO_IEPAccomModTbl_RAW a where a.IepAccomSeq = 3539
--select * from x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW a where a.IepAccomSeq = 3539
--select * from x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW a where a.IepAccomSeq = 3539

-- is IsModification column available?

select * from x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW where AccomCode like '%MOD%'


select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL




--select * from IepTestDef 

-- Encore_TestAccommodations
-- IEPRefID, TestAccomRefID, AccommType, AccommodationText -- AccomType = Standard


select top 1 * from IepAccommodation 
go


-- drop table x_LEGACYACCOM.MAP_IepAccommodationID 

create table x_LEGACYACCOM.MAP_IepAccommodationID (
TestAccomRefID int not null,
DestID uniqueidentifier not null
)

alter table x_LEGACYACCOM.MAP_IepAccommodationID 
	add constraint PK_x_LEGACYACCOM_MAP_IepAccommodationID primary key (TestAccomRefID)
go



alter view x_LEGACYACCOM.Transform_IepAccommodation
as
select 
	ias.IEPRefID,
	t.TestAccomRefID,
	t.TestGroup,
	t.EnrichTestName,
	ad.Text,
-- IepAccommodation values
	DestID = m.DestID,
	InstanceID = ias.DestID,
	ad.CategoryID,
	DefID = ad.ID,
	CustomText = case when t.AccommType = 'Custom' then t.AccommodationText else NULL end,
	StartDate = i.IEPStartDate,
	EndDate = dateadd(dd, -1, dateadd(yy, 1, i.IEPEndDate))
-- select t.*, ad.*
from x_LEGACYACCOM.Transform_IepAccommodations ias
join LEGACYSPED.IEP i on ias.IEPRefID = i.IEPRefID
join x_LEGACYACCOM.EO_StateTestAccommodations t on i.IepRefID = t.IepRefID 
join dbo.IepAccommodationDef ad on 
	convert(varchar(100), t.AccommodationText) = convert(varchar(max), ad.Text) and 
	ad.CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E' and
	t.IsModification = ad.IsModification
left join x_LEGACYACCOM.MAP_IepAccommodationID m on t.TestAccomRefID = m.TestAccomRefID

--where 1=1
--and ad.ID is null
go

select * from x_LEGACYACCOM.EO_StateTestAccommodations




insert x_LEGACYACCOM.MAP_IepAccommodationID (TestAccomRefID, DestID)
select a.TestAccomRefID, newid()
from x_LEGACYACCOM.Transform_IepAccommodation a
left join x_LEGACYACCOM.MAP_IepAccommodationID m on a.TestAccomRefID = m.TestAccomRefID
where m.DestID is null
-- 441

insert IepAccommodation (ID, InstanceID, CategoryID, DefID, CustomText, StartDate, EndDate)
select a.DestID, a.InstanceID, a.CategoryID, a.DefID, a.CustomText, a.StartDate, a.EndDate
from x_LEGACYACCOM.Transform_IepAccommodation a
left join IepAccommodation x on a.DestID = x.ID
where x.id is null
-- 441

select * from x_LEGACYACCOM.Transform_IepAccommodation




--and ias.IEPRefID = 16244
--order by 2, 3, 4

select * from x_LEGACYACCOM.EO_StateTestAccommodations where IEPRefID = 16244 order by 2, 5, 6

select * from IepAccommodationDef where Id in ('576C6470-31F1-4BFB-B6AF-3895F5220331', '99B38529-4541-4C18-B2EC-9906676382CE')

-- does this have IsModifications?
select * from x_LEGACYACCOM.EO_StateTestAccommodations t 



-- and t.AccommType = 'Standard' -- testing, not looking at custom
--and ad.ID is null

select * from IepAccommodationDef where CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E'

select * from IepAccommodationCategory -- not inserted yet
select * from IepAccommodationDef

select * from IepTestParticipation

select * from x_LEGACYACCOM.EO_StateTestAccommodations t where t.Participation is null

select * from x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW m 
select * from x_legacyaccom.EO_StateAccomParticipation_LOCAL where Participation is null and IEPAccomSeq = 5010

select * from [x_LEGACYACCOM].[EO_IEPAccomModTbl_SC_RAW] where IEPAccomSeq = 5010


select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL sap where sap.StudentLocalID = '154379921400'

18210	3963
select * from x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW where IEPAccomSeq = 3963



--- find the missing objects by running the insert

--- we are getting a new ID here, so there is no map reference to the source data

insert IepTestParticipation (ID, InstanceID, TestDefID, ParticipationDefID, IsParticipating)
select ID = newid(), sap.InstanceID, sap.TestDefID, ParticipationDefID = sap.StateParticipationDefID, IsParticipating = case isnull(sap.Participation,'Not in group') when 'Not in group' then 0 else 1 end
from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL sap
left join IepTestParticipation itp on sap.InstanceID = itp.InstanceID and sap.TestDefID = itp.TestDefID
where itp.ID is null

go

--create table x_LEGACYACCOM.MAP_IepTestParticipationID (
--TestParticipationRefID int not null,
--DestID uniqueidentifier not null
--)
--go


create view x_LEGACYACCOM.Transform_IepTestParticipation 
as
select sap.IepRefID, sap.IEPAccomSeq, ID = newid(), sap.InstanceID, sap.TestDefID, ParticipationDefID = sap.StateParticipationDefID, IsParticipating = case isnull(sap.Participation,'Not in group') when 'Not in group' then 0 else 1 end
from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL sap
left join x_LEGACYACCOM.MAP_IepTestParticipationID
-- where itp.ID is null
go


--left join IepTestParticipation itp on sap.InstanceID = itp.InstanceID and sap.TestDefID = itp.TestDefID



select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL sap
-- we are here.....







if not exists (select 1 from IepAccommodationCategory where ID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E')
insert dbo.IepAccommodationCategory values ('B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', 'Excent Online Assess Accom (DO NOT USE)', 0)
-- insert dbo.IepAccommodationDef (ID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate) values ('FE35256C-C18A-4B09-9AF6-11E1762268AF', 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', 'Extended Breaks', 0, 0, 0, getdate())


-- THIS QUERY GENERATES THE ABOVE DEF RECORDS
-- this may be built from a view of accom data on the remote server (for speed)
insert IepAccommodationDef (ID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate)
-- note that we did not build a transform view for this. we probalby should. and a MAP


select t.*
from (
select ID = NewID(), CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', Text = convert(varchar(100), aa.AccomDesc), IsValidWithoutTest = 0, IsNonstandard = 0, 
	IsModification = case when aa.AccomCode like '%MOD%' then 1 else 0 end, -- set this correctly based on the accomcode
	DeletedDate = getdate()
from LEGACYSPED.MAP_IEPStudentRefID s
join LEGACYSPED.EO_ICIEPAccomModTbl_RAW a on s.IEPRefID = a.iepcomplseqnum
join LEGACYSPED.EO_ICIEPAccomModListTbl_SC_RAW aa on a.iepcomplseqnum = aa.iepcomplseqnum and a.iepaccomseq = aa.iepaccomseq
group by convert(varchar(100), aa.AccomDesc), case when aa.AccomCode like '%MOD%' then 1 else 0 end
) t 
left join IepAccommodationDef x on t.CategoryID = x.CategoryID and t.text = x.Text
where x.id is null

go





create view x_LEGACYACCOM.Transform_IepAccommodationDef
as
/*
	This view will only return rows if the accommodations have not been inserted yet.
	To see which accommodation defs came from the legacy database, run the following query: 

	select * from IepAccommodationDef where CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E' 

*/
select DestID = newid(), CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', Text = convert(varchar(100), aa.AccomDesc), IsValidWithoutTest = 0, IsNonstandard = 0, 
	IsModification = case when aa.AccomCode like '%MOD%' then 1 else 0 end, -- set this correctly based on the accomcode
	DeletedDate = getdate()
from LEGACYSPED.MAP_IEPStudentRefID s
join LEGACYSPED.EO_ICIEPAccomModTbl_RAW a on s.IEPRefID = a.iepcomplseqnum
join LEGACYSPED.EO_ICIEPAccomModListTbl_SC_RAW aa on a.iepcomplseqnum = aa.iepcomplseqnum and a.iepaccomseq = aa.iepaccomseq
left join IepAccommodationDef iad on convert(varchar(100), aa.AccomDesc) = iad.Text and iad.CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E'
where iad.id is null
group by convert(varchar(100), aa.AccomDesc), case when aa.AccomCode like '%MOD%' then 1 else 0 end
go



insert IepAccommodationDef (ID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate)
select DestID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate
from x_LEGACYACCOM.Transform_IepAccommodationDef





--insert IepAccommodation (ID, InstanceID, CategoryID, DefID, CustomText, StartDate, EndDate)
--select ID = newid(), t.InstanceID, t.CategoryID, t.DefID, t.CustomText, t.StartDate, t.EndDate
--from x_WalkIEP.Transform_IepAccommodation t
--left join IepAccommodation x on 
--	t.InstanceID = x.InstanceID and
--	t.CategoryID = x.CategoryID and 
--	t.DefID = x.DefID
--where x.ID is null


select * from IepTestAccom

select * from x_LEGACYACCOM.Transform_IepAccommodationDef











