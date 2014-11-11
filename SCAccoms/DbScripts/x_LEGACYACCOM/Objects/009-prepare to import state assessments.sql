

-- participation def map view
if object_id('x_LEGACYACCOM.StateDistrictParticipationDef ') is not null
drop view x_LEGACYACCOM.StateDistrictParticipationDef 
go

create view x_LEGACYACCOM.StateDistrictParticipationDef
as
/* 
	There are 2 Participation Def records with the name "Alternate", one for District and one for State tests
	Where there is an Alternate participation in the legacy data, we need to associate it with the proper participation def in Enrich
	To do so, we will create a view that identifies which is which 
	Then we will use this view in Transform_IepTestParticipation to get the correct ParticipationDef ID
	If the same participation def ID is used for both State and District test, as in the case of "Regular" no harm done
*/
select 
	ParticipationTypeCode = case pd.text
		when 'Standard' then 1 -- arbitrary values in a logical order, to avoid spelling issues in joins
		when 'Std w/ Accom' then 2
		when 'Non-Standard' then 3
		when 'Alternate' then 4
		when 'Not in group' then 5
	end,
	td.IsState,
	ParticipationType = pd.Text, 
	DistrictParticipationDefID = max(convert(varchar(36), pdd.ID)),
	StateParticipationDefID = max(convert(varchar(36), pds.ID))
from IepAllowedTestParticipation atp 
join IepTestDef td on atp.TestDefID = td.ID
join IepTestParticipationDef pd on atp.ParticipationDefID = pd.ID -- one row each
left join IepTestParticipationDef pdd on atp.ParticipationDefID = pdd.ID and td.IsState = 0
left join IepTestParticipationDef pds on atp.ParticipationDefID = pds.ID and td.IsState = 1
where pd.text in ('Not in group', 'Standard', 'Std w/ Accom', 'Alternate', 'Non-Standard')  -- these are the only ones coming from Excent Online
group by pd.Text, td.IsState
go



-- logic table and related tables
set nocount on

if object_id('x_LEGACYACCOM.TestGroupSelection') is not null
drop table x_LEGACYACCOM.TestGroupSelection
go

create table x_LEGACYACCOM.TestGroupSelection (
Num int not null primary key,
Label varchar(20) not null
)

if object_id('x_LEGACYACCOM.SCAltSelection') is not null
drop table x_LEGACYACCOM.SCAltSelection
go

create table x_LEGACYACCOM.SCAltSelection (
Num int not null primary key,
Label varchar(20) not null
)

if object_id('x_LEGACYACCOM.TakingTest') is not null
drop table x_LEGACYACCOM.TakingTest
go

create table x_LEGACYACCOM.TakingTest (
Num int not null primary key,
Label varchar(20) not null
)

if object_id('x_LEGACYACCOM.ConditionsSelection') is not null
drop table x_LEGACYACCOM.ConditionsSelection
go

create table x_LEGACYACCOM.ConditionsSelection (
Num int not null primary key,
Label varchar(20) not null
)

set nocount on;
-- test group selections (PASS, EOC, ELDA, GTTP) 
insert x_LEGACYACCOM.TestGroupSelection values (0, 'not selected')
insert x_LEGACYACCOM.TestGroupSelection values (1, 'Yes')
insert x_LEGACYACCOM.TestGroupSelection values (2, 'No')
insert x_LEGACYACCOM.TestGroupSelection values (3, 'NA')

-- SC Alternate test (as opposed to the regular test)
insert x_LEGACYACCOM.SCAltSelection values (0, 'not selected')
insert x_LEGACYACCOM.SCAltSelection values (1, 'Yes')
insert x_LEGACYACCOM.SCAltSelection values (2, 'No')
insert x_LEGACYACCOM.SCAltSelection values (3, 'NA')

-- Taking the test or not (this is a checkbox 0 is unchecked, 1 is checked, indicating Yes, taking test)
insert x_LEGACYACCOM.TakingTest values (0, 'No')
insert x_LEGACYACCOM.TakingTest values (1, 'Yes')

-- Conditions. For each test, user should select standard (with or w/o accoms) or non-standard
insert x_LEGACYACCOM.ConditionsSelection values (0, 'not selected')
insert x_LEGACYACCOM.ConditionsSelection values (1, 'Std')
insert x_LEGACYACCOM.ConditionsSelection values (2, 'Std w/ Accom')
insert x_LEGACYACCOM.ConditionsSelection values (3, 'Non-Standard')
go

set nocount off;



if object_id ('x_LEGACYACCOM.LOGIC_EOTestParticipation') is not null
drop view x_LEGACYACCOM.LOGIC_EOTestParticipation
go


create view x_LEGACYACCOM.LOGIC_EOTestParticipation
as
select t.TestGroup, 
	t.GroupYNna, t.GroupYNnaDesc, 
	t.AltYNna, t.AltYNnaDesc, 
	t.TestYN, t.TestYNDesc, 
	t.Conditions, t.ConditionsDesc, 
	Participation = p.ParticipationType
from (
select TestGroup, EOTestCode, 
	GroupYNna = tg.num, AltYNna = alt.num, TestYN = tkt.num, Conditions = cnd.num,
	GroupYNnaDesc = tg.label, AltYNnaDesc = alt.label, TestYNDesc = tkt.label, ConditionsDesc = cnd.label,
	Participation = 
		case TestGroup --- TEST GROUP
		when 'PASS' then
			case tg.num -- PASS ANSWER
				when 2 then -- PASS N
					case alt.num 
						when 1 then -- SC ALT Y
							4 -- Alternate
						else 5 -- PASS N & SC Alt N or NA, so Not in group
					end -- SC ALT Y
				when 1 then -- PASS Y
				case tkt.num -- Taking the test Y/N (math, ela, etc.)
					when 0 then -- student not taking the subject (math, ela, etc.)
						NULL -- reflecting what's in EO
					else cnd.num -- 
				end
			when 0 then NULL -- this reflects EO data
			else 5 -- case 3 
			end -- -- TEST GROUP ANSWER
		when 'EOC' then 
			case tg.num -- EOC ANSWER
				when 1 then -- EOC Y
				case tkt.num
					when 0 then
						NULL
					else cnd.num -- 1 Std, 2 Std w/accom, 3 Non-std
				end
				when 0 then -- EOC N
					NULL -- this reflects EO data
			else 5 -- 0 (nothing selected), 2 No and 3 NA
			end -- -- EOC ANSWER
		else -- ELDA or GTTP
		case tg.num -- 8
			when 0 
				then NULL
			else
				case EOTestCode -- 6
				when 'AC14' then -- ELDA
					case tkt.num -- case 7
					when 1 then -- ELDA Y
						cnd.num -- 1 Std, 2 Std w/Accom
					when 2 then -- ELDA N
						3 -- non-std
					when 0 then
						NULL
					else -- -- ELDA NA
						5 -- Not in group
					end -- case 7
				when 'GTTP' then -- This is the same as ELDA, but we must derive some data for this logic, so we separated it here to be able to comment the code
					case tkt.num -- case 8
					when 1 then -- GTTP Y
						cnd.num -- for GTTP, this will have to be derived from the contents of the text boxes
					when 2 then -- GTTP N
						3 -- non-standard
					else -- GTTP NA
						5
					end
				end -- 6
			end
		end --- TEST GROUP
from (
	select TestGroup = case when EnrichTestName like 'SC PASS %' then 'PASS' when EnrichTestName like 'EOC %' then 'EOC' when EnrichTestName = 'ELDA' then 'ELDA' when EOTestCode = 'GTTP' then 'GTTP' end, m.EOTestCode
	from x_LEGACYACCOM.MAP_TestDefID m
	where 1=1
	) t 
cross join x_LEGACYACCOM.TestGroupSelection tg
cross join x_LEGACYACCOM.SCAltSelection alt
cross join x_LEGACYACCOM.TakingTest tkt
cross join x_LEGACYACCOM.ConditionsSelection cnd
-- there is a cleaner way to assure logical combinations, but for sake of time we'll just exclude some invalid or unimportant ones
where 1=1
and not (alt.num = 1 and TestGroup <> 'PASS') -- Alt only applicable to PASS
and not (alt.Num = 1 and t.EOTestCode = 'AC7') -- there is no Writing for the SC Alt
) t
left join x_LEGACYACCOM.StateDistrictParticipationDef p on t.Participation = p.ParticipationTypeCode
where 1=1
group by t.TestGroup, 
	t.GroupYNna, t.GroupYNnaDesc, 
	t.AltYNna, t.AltYNnaDesc, 
	t.TestYN, t.TestYNDesc, 
	t.Conditions, t.ConditionsDesc, 
	p.ParticipationType
-- order by 6, 2, 3, 4
go





-- create and populate a table with the EO codes and Enrich names of the state assessments
if object_id('x_LEGACYACCOM.MAP_EO_Enrich_TestNames') is not null
drop table x_LEGACYACCOM.MAP_EO_Enrich_TestNames
go

create table x_LEGACYACCOM.MAP_EO_Enrich_TestNames (Sequence int not null identity(1,1), EOTestCode	varchar(5) not null, EnrichTestName	varchar(100) not null)

set nocount on;
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC3', 'SC PASS ELA') -- 
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC4', 'SC PASS Math') -- 
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC5', 'SC PASS SS') -- Social Studies
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC6', 'SC PASS Science') -- 
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC7', 'SC PASS Writing') -- 

insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC14', 'ELDA') -- English Language Development Assessment (ELDA)
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('GTTP', '2nd Grade GT') -- No accommodations stored in IEPAccomModListTbl_SC

insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC8', 'EOC Algebra') -- Algebra 1/Mathematics for the Technologies 2
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC9', 'EOC Biology') -- 
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC10', 'EOC English') -- 
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC11', 'Physical Science') -- not used in Enrich?
insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC13', 'EOC History') -- US History and Constitution

insert x_LEGACYACCOM.MAP_EO_Enrich_TestNames (EOTestCode, EnrichTestName) values ('AC12', 'District Assessments') -- separate in Enrich, and no accoms in IEPAccomModListTbl_SC

set nocount off;

alter table x_LEGACYACCOM.MAP_EO_Enrich_TestNames 
	add constraint PK_x_LEGACYACCOM_MAP_EO_Enrich_TestNames primary key (EOTestCode)
go


--create a pre-transform view of the EO test data

if object_id('x_LEGACYACCOM.Transform_IepTestParticipation') is not null
drop view x_LEGACYACCOM.Transform_IepTestParticipation
go

--create view x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL -- drop view x_LEGACYACCOM.EO_StateAccomParticipation_LOCAL
create view x_LEGACYACCOM.Transform_IepTestParticipation
as
/*


				THIS CODE REPLACES x_LEGACYACCOM.EO_StateAssessParticipation_LOCAL


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
	stp.IepRefID, 
	TestParticipationRefID = stp.IEPAccomSeq,
	mtp.DestID,
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
left join x_LEGACYACCOM.MAP_IepTestParticipationID mtp on stp.IEPAccomSeq = mtp.ParticipationRefID and td.EOTestCode = mtp.EOTestCode -- chgd mtp.TestParticipationRefID to mtp.ParticipationRefID and 2nd join from TestDefID to EOTestCode
go


--select * from x_LEGACYACCOM.MAP_IepTestParticipationID
