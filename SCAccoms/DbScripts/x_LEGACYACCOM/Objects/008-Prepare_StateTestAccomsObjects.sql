

--- create a transform for all test accommodations, then use it to create a distinct list of accommodations, then to map EO to Enrich accoms






select * from x_LEGACYACCOM.Transform_IepTestAccommodation


insert x_LEGACYACCOM.MAP_IepAccommodationID (AccommodationRefID, DestID)
select tta.AccommodationRefID, newID()
from x_LEGACYACCOM.Transform_TestAccommodation tta
left join x_LEGACYACCOM.MAP_IepAccommodationID ma on tta.AccommodationRefID = ma.AccommodationRefID 
where ma.DestID is null 
-- 527


select count(*) from x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW -- 527


select *
from x_LEGACYACCOM.Transform_TestAccommodation tta





-- insert IepAccommodationCategory specific to EO accoms
if not exists (select 1 from IepAccommodationCategory where ID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E')
insert dbo.IepAccommodationCategory values ('B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', 'Excent Online Assess Accom (DO NOT USE)', 0)

insert IepAccommodationDef (ID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate)
select ID = NewID(), CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', ta.Text, IsValidWithoutTest = 0, IsNonstandard = 0, ta.IsModification, DeletedDate = getdate()
from x_LEGACYACCOM.TestAccom ta
left join IepAccommodationDef ad on ta.Text = ad.Text and ta.IsModification = ad.IsModification
where ad.ID is null
group by ta.Text, ta.IsModification


-- select * from IepAccommodationDef where CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E' and IsModification = 1

--select ta.*, ad.ID
--from x_LEGACYACCOM.TestAccom ta
--join IepAccommodationDef ad on ta.Text = ad.Text and ad.CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E'

-- select * from x_LEGACYACCOM.Transform_IepTestParticipation


select top 3 ID = tp.DestID, tp.InstanceID,  from x_LEGACYACCOM.Transform_IepTestParticipation tp
select top 3 * from IepAccommodation




select ParticipationID = ttp.DestID
 	, ta.AccommodationDefID
from x_LEGACYACCOM.Transform_IepTestParticipation ttp
join x_LEGACYACCOM.TestAccom ta on ttp.TestParticipationRefID = ta.TestParticipationRefID and ttp.EOTestCode = ta.EOTestCode 
where ttp.StudentLocalID = '165714505300'
and ttp.EOTestCode = 'AC3'
and ttp.TestParticipationRefID = 3539


select * from ieptestaccom


select * from x_LEGACYACCOM.TestAccom where TestParticipationRefID = 3539


-- insert iepaccommodation


-- insert IepTestAccom (from IepAccommodation and IepTestParticipation)




-- insert IepAccommodationDef records from EO
--insert IepAccommodationDef (ID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate)
--select t.*
--from (
--select ID = NewID(), CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', Text = convert(varchar(100), aa.AccomDesc), IsValidWithoutTest = 0, IsNonstandard = 0, 
--	IsModification = case when aa.AccomCode like '%MOD%' then 1 else 0 end, -- set this correctly based on the accomcode
--	DeletedDate = getdate()
--from LEGACYSPED.MAP_IEPStudentRefID s
--join x_LEGACYACCOM.EO_IEPAccomModTbl_RAW a on s.StudentRefID = a.GStudentID
--join x_LEGACYACCOM.EO_IEPAccomModListTbl_SC_RAW aa on a.iepaccomseq = aa.iepaccomseq
--group by convert(varchar(100), aa.AccomDesc), case when aa.AccomCode like '%MOD%' then 1 else 0 end
--) t 
--left join IepAccommodationDef x on t.CategoryID = x.CategoryID and t.text = x.Text
--where x.id is null


-- select * from ieptestaccom



---- insert test accommodations
--insert IepTestAccom (ParticipationID, AccommodationID)
--select ttp.DestID
--from x_LEGACYACCOM.Transform_IepTestParticipation ttp
--join x_LEGACYACCOM.





