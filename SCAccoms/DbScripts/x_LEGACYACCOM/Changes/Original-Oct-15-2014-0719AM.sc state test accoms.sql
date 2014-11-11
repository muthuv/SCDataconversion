





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

alter view x_LEGACYACCOM.EO_StateTestAccommodations -- what is this used for?  why does it have transform IDs?????/
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

select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL

select * from x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW -- this is real raw data




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

if object_id('x_LEGACYACCOM.Transform_IepTestParticipation') is not null
drop view x_LEGACYACCOM.Transform_IepTestParticipation
go

create view x_LEGACYACCOM.Transform_IepTestParticipation
as
select DestID = isnull(itp.ID, newid()),  -- need a map table after all to be able to use this view when 
	sap.IEPRefID, sap.InstanceID, sap.TestDefID, ParticipationDefID = sap.StateParticipationDefID, IsParticipating = case isnull(sap.Participation,'Not in group') when 'Not in group' then 0 else 1 end, sap.EnrichTestName
from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL sap
left join IepTestParticipation itp on sap.InstanceID = itp.InstanceID and sap.TestDefID = itp.TestDefID
-- where itp.ID is null
go

select * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL sap
-- we are here.....







if not exists (select 1 from IepAccommodationCategory where ID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E')
insert dbo.IepAccommodationCategory values ('B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', 'Excent Online Accommodations (DO NOT USE)', 0)
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





insert IepAccommodation (ID, InstanceID, CategoryID, DefID, CustomText, StartDate, EndDate)
select ID = newid(), t.InstanceID, t.CategoryID, t.DefID, t.CustomText, t.StartDate, t.EndDate
from x_LEGACYACCOM.Transform_IepAccommodation t
left join IepAccommodation x on 
	t.InstanceID = x.InstanceID and
	t.CategoryID = x.CategoryID and 
	t.DefID = x.DefID
where x.ID is null


select * from IepTestAccom

select * from x_LEGACYACCOM.Transform_IepAccommodationDef


select * from IepTestParticipation -- 1117
select * from IepAccommodation -- 445
select * from IepTestAccom -- 0


-- this makes no sense
insert IepTestAccom (ParticipationID, AccommodationID)
select ParticipationID = tp.ID, AccommodationID = a.ID 
from IepTestParticipation tp
cross join IepAccommodation a 
left join IepTestAccom ita on 
	tp.ID = ita.ParticipationID and
	a.ID = ita.AccommodationID and
	tp.InstanceID = a.InstanceID
where tp.ParticipationDefID is not null
and ita.AccommodationID is null

select *
from (
select top 100 IEPRefID, count(*) tot
from x_LEGACYACCOM.Transform_IepTestParticipation
group by IEPRefID
) t
join (
select top 100 IEPRefID, count(*) tot 
from x_LEGACYACCOM.Transform_IepAccommodation
group by IEPRefID
) a on t.IEPRefID = a.IEPRefID





insert IepTestAccom
select p.ID, a.ID
from dbo.IepAccommodation a 
cross join dbo.IepTestParticipation p 
left join IepTestAccom x on p.id = x.ParticipationID and a.id = x.AccommodationID
where a.InstanceID = '0AC9BC4C-5AA0-44D9-99F6-801A7FB8156F'
and p.InstanceID = '0AC9BC4C-5AA0-44D9-99F6-801A7FB8156F'
and p.ParticipationDefID is not null
and x.AccommodationID is null


go

declare @s uniqueidentifier ; select @s = ID from Student where Number = '192519539000'
select s.Number, s.Firstname, s.Lastname, td.Name, tpd.Text, tp.IsParticipating, tp.InstanceID, TestParticipationID = tp.ID
from Student s 
join PrgItem i on s.ID = i.StudentID
join PrgSection sec on i.ID = sec.ItemID 
join IepTestParticipation tp on sec.ID = tp.InstanceID
join IepTestDef td on tp.TestDefID = td.ID
left join IepTestParticipationDef tpd on tp.ParticipationDefID = tpd.ID
where s.ID = @s

select i.*
from LEGACYSPED.Student s
join LEGACYSPED.IEP i on s.StudentRefID = i.StudentRefID
where StudentLocalID = '192519539000'



select * 
from x_LEGACYACCOM.EO_StateTestAccommodations
where IEPRefID = 18161



select top 1 * from x_LEGACYACCOM.Transform_IepAccommodation where IEPRefID = 18161

select top 1 * from IepTestAccom


select * from IepTestParticipation






-- insert IepTestAccom (ParticipationID, AccommodationID)
select ParticipationID = tp.ID, AccommodationID = a.ID 
from IepTestParticipation tp
cross join IepAccommodation a 
left join IepTestAccom ita on 
	tp.ID = ita.ParticipationID and
	a.ID = ita.AccommodationID and
	tp.InstanceID = a.InstanceID
where 1=1 
and a.InstanceID = 'B571CA97-F343-45BF-9282-3CBC4067485A'
and tp.InstanceID = 'FE53EF24-4A99-4A40-97BF-AD28090B69D0'
and tp.ParticipationDefID is not null
and ita.AccommodationID is null



select ParticipationID = tp.ID, AccommodationID = a.ID 
from IepTestParticipation tp
cross join IepAccommodation a 
left join IepTestAccom ita on 
	tp.ID = ita.ParticipationID and
	a.ID = ita.AccommodationID and
	tp.InstanceID = a.InstanceID
where 1=1 
and a.InstanceID = 'B571CA97-F343-45BF-9282-3CBC4067485A'
and tp.InstanceID = 'FE53EF24-4A99-4A40-97BF-AD28090B69D0'
and tp.ParticipationDefID is not null
and ita.AccommodationID is null

go


declare @s uniqueidentifier ; select @s = ID from Student where Number = '192519539000'
select s.Number, s.Firstname, s.Lastname, td.Name, tpd.Text, tp.IsParticipating, tp.InstanceID, TestParticipationID = tp.ID
from Student s 
join PrgItem i on s.ID = i.StudentID
join PrgSection sec on i.ID = sec.ItemID 
join IepTestParticipation tp on sec.ID = tp.InstanceID
join IepTestDef td on tp.TestDefID = td.ID
left join IepTestParticipationDef tpd on tp.ParticipationDefID = tpd.ID
where s.ID = @s


select * 
from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL p --- should be named state assess participation
join x_LEGACYACCOM.EO_StateTestAccommodations a on p.InstanceID = a.InstanceId and p.EnrichTestName = a.EnrichTestName
where p.IEPRefID = 18161




select * 
from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL p --- should be named state assess participation
join x_LEGACYACCOM.EO_StateTestAccommodations a on p.IepRefID = a.IepRefID and p.EOTestCode = a.AccommType

where p.IEPRefID = 18161





select top 1 * from x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL where IEPRefID = 18161
select top 1 * from x_LEGACYACCOM.EO_StateTestAccommodations  where IEPRefID = 18161


delete x
--insert IepTestAccom
--select p.ID, a.ID
--select x.*
from dbo.IepAccommodation a 
cross join dbo.IepTestParticipation p 
left join IepTestAccom x on p.id = x.ParticipationID and a.id = x.AccommodationID
where 1=1
and a.InstanceID = 'B571CA97-F343-45BF-9282-3CBC4067485A'
and p.InstanceID = 'FE53EF24-4A99-4A40-97BF-AD28090B69D0'
and p.ParticipationDefID is not null
and x.AccommodationID is null



insert IepTestAccom 
select p.DestID, a.DestID
from x_LEGACYACCOM.Transform_IepTestParticipation p --- should be named state assess participation
join x_LEGACYACCOM.Transform_IepAccommodation a on p.IepRefID = a.IEPRefID and p.EnrichTestName = a.EnrichTestName
-- left join IepAccommodation ta 
where p.IEPRefID = 18161


select * from IepTestParticipation where ID = '517A3640-DABF-4AAA-89AB-06933ED3B733'


go
-- sp_helptext x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL

create view x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL----------------------------------------------------------------------- rename this to StateAssessParticipation ????????
as
/*
	DO NOT USE

	USE x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL

	or 

	the Transform based on it.

*/


with participationCTE
as (
select m.IEPRefID, a2.IEPAccomSeq,
	PACT = isnull(a2.PACT,0), -- PACT = PASS
	PACTAlt = isnull(a2.PACTAlt,0),
		a2.PACTEnglish, PACTEnglishCond = isnull(a2.PACTEnglishCond,0),
		a2.PACTMath, PACTMathCond = isnull(a2.PACTMathCond,0),
		a2.PACTSocStudies, PACTSocialCond = isnull(a2.PACTSocialCond,0),
		a2.PACTScience, PACTScienceCond = isnull(a2.PACTScienceCond,0),
		a2.PASSWriting, PASSWritingCond = isnull(a2.PASSWritingCond,0),
	--
	ELDA = isnull(a2.ELDA,0), ELDAStandard = isnull(a2.ELDAStandard,0),
	GTTP = isnull(a2.GTTP,0), 
		-- here we will derive a value for Std or Std w/ Accom 
		GTTPCond = case when isnull(convert(varchar(max), a2.GTTPAccom),'') in ('', 'NA', 'N/A', 'None', 'No') -- check for either no text or text that indicates no accoms
			then 1 -- standard
			else 2 -- standard w/ accoms, because there is text in the accoms text box
		end,
		GTTPAccom = convert(varchar(max), a2.GTTPAccom), 
	--
	a2.DistAssess, a2.DistAssessTitle, a2.AltAssess,
	--
	EOCTest = isnull(a2.EOCTest,0),
		a2.EOCAlgMath, EOCMathCond = isnull(a2.EOCMathCond,0),
		a2.EOCEnglish, EOCEnglishCond = isnull(a2.EOCEnglishCond,0),
		a2.EOCPhysicalSci, EOCPhysicalSciCond = isnull(a2.EOCPhysicalSciCond,0),
		a2.EOCBiology, EOCBiologyCond = isnull(a2.EOCBiologyCond,0),
		a2.EOCUSHistory, EOCUSHistoryCond = isnull(a2.EOCUSHistoryCond,0)
from LEGACYSPED.MAP_IEPStudentRefID m 
join x_LEGACYACCOM.EO_IEPAccomModTbl_RAW a on m.StudentRefID = a.GStudentID
join x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW a2 on a.IEPAccomSeq = a2.IEPAccomSeq 
)

select 
	s.StudentLocalID, s.Firstname, s.Lastname, s.GradeLevelCode,
	stp.IepRefID, stp.IEPAccomSeq,
	InstanceID = isnull(a.DestID, av.DestID), 
	stp.TestGroup, 
	stp.EOTestCode, td.EnrichTestName, td.TestDefID,
	GroupSelection = logic.GroupYNnaDesc, 
	AltSelection = logic.AltYNnaDesc, 
	TestYN = logic.TestYNDesc,
	Conditions = logic.ConditionsDesc,
	Logic.Participation, p.StateParticipationDefID
	--, stp.GroupYNna, stp.AltYNna, stp.TestYN, stp.Conditions
from (

-- PASS
----- English language arts (ELA)
-- Note: Alternate pass applies to ELA, Math, Social Studies and Science, but not writing. If they take one Alt, they take all 4.
select c.IepRefID, c.IEPAccomSeq, TestGroup = 'PASS', EOTestCode = 'AC3', GroupYNna = c.PACT, AltYNna = c.PActAlt, TestYN = c.PACTEnglish,  Conditions = c.PACTEnglishCond
from participationCTE c

union all

------- Mathematics
select c.IepRefID, c.IEPAccomSeq, 'PASS', 'AC4', c.PACT, c.PActAlt, c.PACTMath, c.PACTMathCond 
from participationCTE c

union all

----- Social studies
select c.IepRefID, c.IEPAccomSeq, 'PASS', 'AC5', c.PACT, c.PActAlt, c.PACTSocStudies, c.PACTSocialCond
from participationCTE c

union all

----- Science
select c.IepRefID, c.IEPAccomSeq, 'PASS', 'AC6', c.PACT, c.PActAlt, c.PACTScience, c.PACTScienceCond
from participationCTE c

union all

--- Writing --------------------------------------------- DOES NOT APPLY TO ALTERNATE. Alternate is for students that use pictures and objects, so they can't write at all.
select c.IepRefID, c.IEPAccomSeq, 'PASS', 'AC7', c.PACT, c.PActAlt, c.PASSWriting, c.PASSWritingCond
from participationCTE c

union all

--------------------------------------------------------------------------------------------
--                                          Page 2
--------------------------------------------------------------------------------------------

-- ELDA
select c.IepRefID, c.IEPAccomSeq, 'ELDA', 'AC14', 
	GroupYNna = isnull(c.ELDA, 0), -- simulate the EOC radio buttons
	AltYNna = 0,
	TestYN = case isnull(c.ELDA, 0) when 1 then 1 when 2 then 1 else 0 end, -- simulate the EOC checkbox. 1 is checked, 2 is checked, else not checked.
	Condition = case isnull(c.ELDA, 0) when 2 then 3 else isnull(c.ELDAStandard,0) end -- simulate non-standard radio button. Assuming ELDA 2 means non-standard? Enrich has non-std for ELDA
from participationCTE c

union all

-- Grade 2 Gifted
select c.IepRefID, c.IEPAccomSeq, 'GTTP', 'GTTP', -- we made up the EO test code. accoms are in a text box.  We'll put 'See PDF' in the Enrich UI
	GroupYNna = case isnull(c.GTTP, 0) when 1 then 1 when 2 then 1 else 0 end,
	AltYNna = 0,
	TestYN = c.GTTP, 
	Condition = c.GTTPCond
from participationCTE c

union all

------- algebra
select c.IepRefID, c.IEPAccomSeq, 'EOC', 'AC8', c.EOCTest, AltYNna = 0, c.EOCAlgMath, c.EOCMathCond
from participationCTE c

union all

---- english
select c.IepRefID, c.IEPAccomSeq, 'EOC', 'AC10', c.EOCTest, AltYNna = 0, c.EOCEnglish, EOCEnglishCond
from participationCTE c

union all

---- biology
select c.IepRefID, c.IEPAccomSeq, 'EOC', 'AC9', c.EOCTest, AltYNna = 0, c.EOCBiology, EOCBiologyCond
from participationCTE c

union all

---- history
select c.IepRefID, c.IEPAccomSeq, 'EOC', 'AC13', c.EOCTest, AltYNna = 0, c.EOCUSHistory, EOCUSHistoryCond
from participationCTE c

) stp
join LEGACYSPED.MAP_IepStudentRefID ms on stp.IEPRefID = ms.IEPRefID
join LEGACYSPED.Student s on ms.StudentRefID = s.StudentRefID
left join x_LEGACYACCOM.MAP_TestDefID td on stp.EOTestCode = td.EOTestCode
left join x_LEGACYACCOM.LOGIC_EOTestParticipation logic on 
	stp.TestGroup = logic.TestGroup and
	stp.GroupYNna = logic.GroupYNna and 
	stp.AltYNna = logic.AltYNna and 
	stp.TestYN = logic.TestYN and 
	stp.Conditions = logic.Conditions
left join x_LEGACYACCOM.StateDistrictParticipationDef p on logic.Participation = p.ParticipationType
left join LEGACYSPED.MAP_PrgSectionID_NonVersioned a on ms.DestID = a.ItemID and a.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC' -- need to handle the case where someone made this a versioned section
left join LEGACYSPED.MAP_PrgVersionID v on ms.IEPRefID = v.IEPRefID 
left join LEGACYSPED.MAP_PrgSectionID av on v.DestID = av.VersionID and av.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC' 

GO





