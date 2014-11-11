IF EXISTS (SELECT 1 FROM sys.schemas s JOIN sys.objects o on s.schema_id = o.schema_id WHERE s.name = 'x_LEGACYACCOM' AND o.name = 'SCAccoms_ImportFormletData')
DROP PROC x_LEGACYACCOM.SCAccoms_ImportFormletData
GO

CREATE PROC x_LEGACYACCOM.SCAccoms_ImportFormletData
AS
BEGIN 
-- rollback 
--begin tran

-- select * from x_LEGACYACCOM.MAP_FormInstanceID
-- ########################################################################################################################################################## --- 55125 -inserting a row for all sections.
insert x_LEGACYACCOM.MAP_FormInstanceID (Item, ItemRefID, SectionDefID, FormInstanceID, FormInstanceIntervalID, HeaderFormInstanceID, HeaderFormInstanceIntervalID)
select t.Item, t.IEPRefID, t.SectionDefID, 
	FormInstanceID = case when t.FormTemplate is not null then newid() else NULL end, 
	FormInstanceIntervalID = case when t.FormTemplate is not null then newid() else NULL end, 
	HeaderFormInstanceID = case when t.HeaderFormTemplate is not null then newid() else NULL end, 
	HeaderFormInstanceIntervalID = case when t.HeaderFormTemplate is not null then newid() else NULL end
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join x_LEGACYACCOM.MAP_FormInstanceID m on t.IEPRefID = m.ItemRefID and t.SectionDefID = m.SectionDefID
where 1=1
--and t.IEPRefID = 19761 and t.SectionDefID = 'B1903FFA-D274-4009-8441-21D6F05BF1C4'
and isnull(m.FormInstanceID, m.HeaderFormInstanceID) is null




-- ##########################################################################################################################################################
-- Footer
insert FormInstance (ID, TemplateId)
select t.FormInstanceID, t.FormTemplateID -- footer
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join FormInstance x on t.FormInstanceID = x.id 
where t.FormTemplateID is not null
and x.id is null
---- 42875


---- Header
insert FormInstance (ID, TemplateId)
select t.HeaderFormInstanceID, t.HeaderFormTemplateID -- Header
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join FormInstance x on t.HeaderFormInstanceID = x.id
where t.HeaderFormTemplateID is not null
and x.id is null


-- ##########################################################################################################################################################
-- footer
insert FormInstanceInterval (ID, InstanceId, IntervalId, CompletedBy, CompletedDate)
select t.FormInstanceIntervalID, t.FormInstanceID, t.IntervalID, t.CompletedBy, t.CompletedDate
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join FormInstanceInterval x on t.FormInstanceIntervalID = x.ID
where t.FormInstanceIntervalID is not null
and x.ID is null

-- header
insert FormInstanceInterval (ID, InstanceId, IntervalId, CompletedBy, CompletedDate)
select t.HeaderFormInstanceIntervalID, t.HeaderFormInstanceID, t.IntervalID, t.CompletedBy, t.CompletedDate
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join FormInstanceInterval x on t.HeaderFormInstanceIntervalID = x.ID
where t.HeaderFormInstanceIntervalID is not null
and x.ID is null

--------------- moved this 20140625 -- begin tran
insert x_LEGACYACCOM.MAP_FormInputValueID (Item, IntervalID, InputFieldID, Sequence, DestID)
select t.Item, t.IntervalID, t.InputFieldID, t.Sequence, newid()
from x_LEGACYACCOM.Transform_FormInputValue t 
where DestID is null

-- ##########################################################################################################################################################
insert FormInputValue (ID, IntervalId, InputFieldId, Sequence)
select t.DestID, t.IntervalID, t.InputFieldID, t.Sequence
from x_LEGACYACCOM.Transform_FormInputValue t 
left join FormInputValue x on t.DestID = x.ID
where x.ID is null

-- ##########################################################################################################################################################
insert FormInputTextValue 
select t.DestID, t.Value
from x_LEGACYACCOM.Transform_FormInputTextValue t
left join FormInputTextValue x on t.DestID = x.id
where x.id is null

-- ##########################################################################################################################################################
insert FormInputFlagValue 
select t.DestID, t.Value
from x_LEGACYACCOM.Transform_FormInputFlagValue t
left join FormInputFlagValue x on t.DestID = x.id
where x.id is null

-- ##########################################################################################################################################################
--insert FormInputDateValue 
--select t.DestID, t.Value
--from x_LEGACYACCOM.Transform_FormInputDateValue t
--left join FormInputDateValue x on t.DestID = x.id
--where x.id is null

-- ##########################################################################################################################################################
insert FormInputSingleSelectValue 
select t.DestID, t.Value -- not the name of the dest column - change later?
from x_LEGACYACCOM.Transform_FormInputSingleSelectValue t
left join FormInputSingleSelectValue x on t.DestID = x.id
where x.id is null


---- ##########################################################################################################################################################
-- MAP table has already been inserted
insert LEGACYSPED.MAP_PrgSectionID (defid, versionid, destid)
select t.DefID, t.VersionID, DestID = newid()
from LEGACYSPED.Transform_PrgSection t 
join PrgSectiondef secd on t.defid = secd.ID and secd.IsVersioned = 1
left join LEGACYSPED.MAP_PrgSectionID x on t.destid = x.destid and t.VersionID = x.VersionID 
where t.VersionID is not null ---- non versioned uses a different map
and x.destid is null  


-- looks like this is already inserted
insert LEGACYSPED.MAP_PrgSectionID_NonVersioned (DefID, ItemID, DestID)
select t.DefID, t.ItemID, DestID = newid()
from LEGACYSPED.Transform_PrgSection t 
join PrgSectiondef secd on t.defid = secd.ID and secd.IsVersioned = 0
left join LEGACYSPED.MAP_PrgSectionID_NonVersioned x on  t.destid = x.destid and t.ItemID = x.ItemID 
where t.ItemID is not null ---- non versioned uses a different map
and x.destid is null 

---- ##########################################################################################################################################################
-- footer
insert PrgItemForm (ID, ItemID, CreatedDate, CreatedBy, AssociationTypeID)
select t.FormInstanceID, t.ItemID, t.CreatedDate, t.CreatedBy, t.AssociationTypeID
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join PrgitemForm x on t.FormInstanceID = x.ID
where t.FormInstanceID is not null
and x.ID is null

---- header
insert PrgItemForm (ID, ItemID, CreatedDate, CreatedBy, AssociationTypeID)
select t.HeaderFormInstanceID, t.ItemID, t.CreatedDate, t.CreatedBy, t.AssociationTypeID
from x_LEGACYACCOM.Transform_PrgSectionFormInstance t
left join PrgitemForm x on t.HeaderFormInstanceID = x.ID
where t.HeaderFormInstanceID is not null
and x.ID is null
---- 12250






-- ##########################################################################################################################################################
-- versioned
insert PrgSection (ID, ItemID, DefID, VersionID, FormInstanceID, HeaderFormInstanceID, OnLatestVersion)
select t.DestID, t.ItemID, t.DefID, t.VersionID, t.FormInstanceID, t.HeaderFormInstanceID, t.OnLatestVersion
-- select t.*
from LEGACYSPED.Transform_PrgSection t
left join PrgSection x on t.DestID = x.id
where x.ID is null

-- non-versioned section insert
insert PrgSection (ID, ItemID, DefID, FormInstanceID, HeaderFormInstanceID, OnLatestVersion)
select t.DestID, t.ItemID, t.DefID, t.FormInstanceID, t.HeaderFormInstanceID, t.OnLatestVersion
-- select t.*
from LEGACYSPED.Transform_PrgSection t
left join PrgSection x on t.DestID = x.id
where t.VersionID is null 
and x.ID is null


-- Muthu: I thought this was already moved below the inserts.???? I moved it on 9/14/2014 at 10:30 pm eastern time.  GG
update s set FormInstanceID = mfi.FormInstanceID, HeaderFormInstanceID = mfi.HeaderFormInstanceID
-- select CurrentFormInstanceID = s.FormInstanceID, mfi.FormInstanceID, CurrentHeaderFormInstanceID = s.HeaderFormInstanceID, mfi.HeaderFormInstanceID
from LEGACYSPED.MAP_IEPStudentRefID m
left join dbo.PrgItem i on m.DestID = i.ID
left join dbo.PrgVersion v on i.ID = v.ItemID 
left join dbo.PrgSection s on i.ID = s.ItemID 
left join dbo.PrgSectionDef sd on s.DefID = sd.ID
join x_LEGACYACCOM.MAP_FormInstanceID mfi on m.IepRefID = mfi.ItemRefID and s.DefID = mfi.SectionDefID
where isnull(mfi.FormInstanceID, mfi.HeaderFormInstanceID) is not null
and isnull(s.FormInstanceID, s.HeaderFormInstanceID) is null


------------------------------------------------------------------------------------------------------------------------


--insert IepAccommodationCategory -- hard coded
if not exists (select 1 from IepAccommodationCategory where ID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E')
insert dbo.IepAccommodationCategory values ('B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', 'Excent Online Accommodation (DO NOT USE)', 0)

--insert IepAccommodationDef
insert IepAccommodationDef (ID, CategoryID, Text, IsValidWithoutTest, IsNonStandard, IsModification, DeletedDate)
select t.*
from (
select ID = NewID(), CategoryID = 'B90D4D56-4A20-4901-BD7B-2FC99BF5D42E', Text = convert(varchar(100), aa.AccomDesc), IsValidWithoutTest = 0, IsNonstandard = 0, 
	IsModification = case when aa.AccomCode like '%MOD%' then 1 else 0 end, -- set this correctly based on the accomcode
	DeletedDate = getdate()
from LEGACYSPED.MAP_IEPStudentRefID s
join x_LEGACYACCOM.EO_IEPAccomModTbl_RAW a on s.StudentRefID = a.GStudentID
join x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW aa on a.iepaccomseq = aa.iepaccomseq
group by convert(varchar(100), aa.AccomDesc), case when aa.AccomCode like '%MOD%' then 1 else 0 end
) t 
left join IepAccommodationDef x on t.CategoryID = x.CategoryID and t.text = x.Text
where x.id is null


insert IepAccommodations (ID, Explanation, TrackDetails, TrackForAssessments, NoAccommodationsRequired, NoModificationsRequired)
select t.DestID, t.Explanation, t.TrackDetails, t.TrackForAssessments, t.NoAccommodationsRequired, t.NoModificationsRequired
from x_LEGACYACCOM.Transform_IepAccommodations t
left join IepAccommodations a on t.DestID = a.ID
where a.id is null


-- section
insert IepAssessments (ID, ParentsAreInformedID, UseBooleanParticipation)
select DestID, ParentsAreInformedID = cast('A2B683CD-BEA7-4EC8-8BF8-41C1ACBC909E' as uniqueidentifier), UseBooleanParticipation = cast(0 as bit)
from LEGACYSPED.Transform_PrgSection t
left join IepAssessments x on t.DestID = x.ID 
where t.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC'
and x.ID is null

-- accommodation
insert x_LEGACYACCOM.MAP_IepAccommodationID (AccommodationRefID, DestID)
select a.AccommodationRefID, newid()
-- select a.*
from x_LEGACYACCOM.Transform_IepAccommodation_ASSESSMENTS a
left join x_LEGACYACCOM.MAP_IepAccommodationID m on a.AccommodationRefID = m.AccommodationRefID
where m.DestID is null
and a.AccommodationRefID is not null

insert IepAccommodation (ID, InstanceID, CategoryID, DefID, CustomText, StartDate, EndDate)
select a.DestID, a.InstanceID, a.CategoryID, a.DefID, a.CustomText, a.StartDate, a.EndDate
from x_LEGACYACCOM.Transform_IepAccommodation_ASSESSMENTS a
left join IepAccommodation x on a.DestID = x.ID
where x.id is null
and a.AccommodationRefID is not null

insert x_LEGACYACCOM.MAP_IepTestParticipationID (ParticipationRefID, EOTestCode, DestID)
select t.ParticipationInstanceRefID, t.EOTestCode, DestID = newID() 
-- select t.*
from x_LEGACYACCOM.Transform_IepTestParticipation t
left join x_LEGACYACCOM.MAP_IepTestParticipationID m on t.ParticipationInstanceRefID = m.ParticipationRefID and t.EOTestCode = m.EOTestCode
where m.DestID is null

insert IepTestParticipation (ID, InstanceID, TestDefID, ParticipationDefID, IsParticipating)
select ID = sap.DestID, sap.InstanceID, sap.TestDefID, sap.ParticipationDefID, IsParticipating = case isnull(sap.Participation,'Not in group') when 'Not in group' then 0 else 1 end
from x_LEGACYACCOM.Transform_IepTestParticipation sap
left join IepTestParticipation itp on sap.InstanceID = itp.InstanceID and sap.TestDefID = itp.TestDefID
where itp.ID is null


insert IepTestAccom (ParticipationID, AccommodationID)
select a.TestParticipationID, a.DestID
from x_LEGACYACCOM.Transform_IepAccommodation_ASSESSMENTS a
left join IepTestAccom ita on a.TestParticipationID = ita.ParticipationID and a.DestID = ita.AccommodationID
where a.DestID is not null
and ita.AccommodationID is null


---- ##########################################################################################################################################################

-- rollback 

--commit tran 

END
GO
