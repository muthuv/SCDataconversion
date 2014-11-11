
--if object_id('x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL') is not null
--drop view x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL
--go


create view x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL
as
/*
	View limits output to only the records to be converted, handles NULLs and default values

	Restarting this view without Enrich IDs.  Strictly EO data this time.

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
--	s.StudentRefID, s.StudentLocalID, s.Firstname, s.Lastname, s.GradeLevelCode,
	stp.IepRefID, stp.IEPAccomSeq,
	-- InstanceID = isnull(a.DestID, av.DestID), 
	stp.TestGroup, 
	stp.EOTestCode, 
		--td.EnrichTestName, td.TestDefID,
	GroupSelection = logic.GroupYNnaDesc, 
	AltSelection = logic.AltYNnaDesc, 
	TestYN = logic.TestYNDesc,
	Conditions = logic.ConditionsDesc,
	Logic.Participation
	-- InstanceID = isnull(a.DestID, av.DestID), 
		--, p.StateParticipationDefID
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
--join LEGACYSPED.MAP_IepStudentRefID ms on stp.IEPRefID = ms.IEPRefID
--join LEGACYSPED.Student s on ms.StudentRefID = s.StudentRefID
-- left join x_LEGACYACCOM.MAP_TestDefID td on stp.EOTestCode = td.EOTestCode
left join x_LEGACYACCOM.LOGIC_EOTestParticipation logic on 
	stp.TestGroup = logic.TestGroup and
	stp.GroupYNna = logic.GroupYNna and 
	stp.AltYNna = logic.AltYNna and 
	stp.TestYN = logic.TestYN and 
	stp.Conditions = logic.Conditions
--left join x_LEGACYACCOM.StateDistrictParticipationDef p on logic.Participation = p.ParticipationType
--left join LEGACYSPED.MAP_PrgSectionID_NonVersioned a on ms.DestID = a.ItemID and a.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC' -- need to handle the case where someone made this a versioned section
--left join LEGACYSPED.MAP_PrgVersionID v on ms.IEPRefID = v.IEPRefID 
--left join LEGACYSPED.MAP_PrgSectionID av on v.DestID = av.VersionID and av.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC' 

GO

-- select * from x_LEGACYACCOM.StateDistrictParticipationDef  -- has a defid



-- now create a new view with DestIDs and name it appropriately


if object_id('x_LEGACYACCOM.Transform_IepTestParticipation_20141024') is not null
drop view x_LEGACYACCOM.Transform_IepTestParticipation_20141024
go


create view x_LEGACYACCOM.Transform_IepTestParticipation_20141024
as
select
	stp.IepRefID, stp.IEPAccomSeq,
	InstanceID = isnull(a.DestID, av.DestID), 
	stp.TestGroup, 
	stp.EOTestCode, td.EnrichTestName, td.TestDefID,
	stp.GroupSelection,
	stp.AltSelection,
	stp.TestYN,
	stp.Conditions,
	stp.Participation, p.StateParticipationDefID
from LEGACYSPED.MAP_IEPStudentRefID m
join x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL stp on m.IepRefID = stp.IepRefID
left join LEGACYSPED.MAP_PrgVersionID v on m.IEPRefID = v.IEPRefID 
left join x_LEGACYACCOM.MAP_TestDefID td on stp.EOTestCode = td.EOTestCode
left join x_LEGACYACCOM.StateDistrictParticipationDef p on stp.Participation = p.ParticipationType
left join LEGACYSPED.MAP_PrgSectionID av on v.DestID = av.VersionID and av.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC' 
left join LEGACYSPED.MAP_PrgSectionID_NonVersioned a on m.DestID = a.ItemID and a.DefID = '82AFDE84-49C0-45D0-B13E-201151CE90CC' -- need to handle the case where someone made this a versioned section
go

select * from x_LEGACYACCOM.Transform_IepTestParticipation
select * from x_LEGACYACCOM.Transform_IepTestParticipation_20141024


