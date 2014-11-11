-- create the table that holds the 
if object_id('x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL') is not null
drop table x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL
go

create table x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL (
IEPRefID	int not null,
SubRefID	int not null,
DistAssessTitle varchar(100)  null,
Participation varchar(max) null, -- this is a GUID, but we treat as varchar for a reason (union all with values view)
Accommodations text NULL,
Sequence int not null
)

alter table x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL 
	add constraint PK_x_LEGACYACCOM_EO_DistrictTestAccomm_LOCAL primary key (SubRefID)
go

create index IX_x_LEGACYACCOM_EO_DistrictTestAccomm_LOCAL_IEPComplSeqNum on x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL (IEPRefID)
go

if object_id('x_LEGACYACCOM.ClassroomAccomMod_LOCAL') is not null
drop table x_LEGACYACCOM.ClassroomAccomMod_LOCAL
go

create table x_LEGACYACCOM.ClassroomAccomMod_LOCAL (
 IEPRefID int not null
, SubRefID  int null
, ModifyYN bit not null
, Accoms varchar(max) null
, Mods varchar(max) null
)
alter table x_LEGACYACCOM.ClassroomAccomMod_LOCAL 
	add constraint PK_x_LEGACYACCOM_ClassroomAccomMod_LOCAL primary key (IEPRefID)
go



-- create pivot views based on the above table.
-- Texts
-- Assessment
if object_id('x_LEGACYACCOM.ConvertedAssessmentsTextsPivot', 'V') is not null
DROP VIEW x_LEGACYACCOM.ConvertedAssessmentsTextsPivot
GO

create view x_LEGACYACCOM.ConvertedAssessmentsTextsPivot
as
select u.IEPRefID, u.SubRefID, u.Value, u.Sequence, u.InputFieldID, InputItemType =  iit.Name, InputItemTypeID = iit.ID 
from (

	select IepRefID, SubRefID =  x.SubRefID, Value = x.DistAssesstitle, InputFieldID = 'D2C7221B-985B-45BB-AFB5-FBE439CC3C38', Sequence =  x.Sequence  -- (1:M)  AssessName - Name
	from x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL x
	UNION ALL
	select IepRefID, SubRefID =  x.SubRefID, Value = x.Accommodations, InputFieldID = '6E19E598-E42B-45C7-99E2-7EE834B468D8', Sequence =  x.Sequence  -- (1:M)  AssessAccom - Accommodations
	from x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL x

	) u join
FormTemplateInputItem ftii on u.InputFieldID = ftii.Id join 
FormTemplateInputItemType iit on ftii.TypeId = iit.Id
go

--exec x_DATATEAM.FormletPivotViewGenerator_TextOutput 'IEP', 'x_LEGACYACCOM.ClassroolAccomMod_LOCAL', '', 'Accommodations/Modifications', 'ClassroomAccomMod'

-- Classroom
if object_id('x_LEGACYACCOM.ClassroomAccomModTextsPivot', 'V') is not null
DROP VIEW x_LEGACYACCOM.ClassroomAccomModTextsPivot
GO

create view x_LEGACYACCOM.ClassroomAccomModTextsPivot
as
select u.IEPRefID, u.SubRefID, u.Value, u.Sequence, u.InputFieldID, InputItemType =  iit.Name, InputItemTypeID = iit.ID 
from (

	select IepRefID, SubRefID = cast(-99 as int), Value = x.Accoms, InputFieldID = '21D420C8-02B0-4442-A087-781BB4695C2A', Sequence =  cast(0 as int)  -- Accomms - Accommodations
	from x_LEGACYACCOM.ClassroomAccomMod_LOCAL x
	UNION ALL
	select IepRefID, SubRefID = cast(-99 as int), Value = x.Mods, InputFieldID = '75048692-5596-47E5-8BB0-F57D920F4B4B', Sequence =  cast(0 as int)  -- Modifs - Modifications
	from x_LEGACYACCOM.ClassroomAccomMod_LOCAL x

	) u join
FormTemplateInputItem ftii on u.InputFieldID = ftii.Id join 
FormTemplateInputItemType iit on ftii.TypeId = iit.Id
go



-- Single Selects
if object_id('x_LEGACYACCOM.ConvertedAssessmentsSingleSelectsPivot', 'V') is not null
DROP VIEW x_LEGACYACCOM.ConvertedAssessmentsSingleSelectsPivot
GO

create view x_LEGACYACCOM.ConvertedAssessmentsSingleSelectsPivot
as
select u.IEPRefID, u.SubRefID, u.Value, u.Sequence, u.InputFieldID, InputItemType =  iit.Name, InputItemTypeID = iit.ID 
from (

	select IepRefID, SubRefID =  x.SubRefID, Value = x.Participation, InputFieldID = 'CA1A4A5F-FE71-4379-866A-522CFE2B2959', Sequence =  x.Sequence  -- (1:M)  thirdS3 - Participation
	from x_LEGACYACCOM.EO_DistrictTestAccomm_LOCAL x

	) u join
FormTemplateInputItem ftii on u.InputFieldID = ftii.Id join 
FormTemplateInputItemType iit on ftii.TypeId = iit.Id
go


-- Flags
if object_id('x_LEGACYACCOM.ClassroomAccomModFlagsPivot', 'V') is not null
DROP VIEW x_LEGACYACCOM.ClassroomAccomModFlagsPivot
GO

create view x_LEGACYACCOM.ClassroomAccomModFlagsPivot
as
select u.IEPRefID, u.SubRefID, u.Value, u.Sequence, u.InputFieldID, InputItemType =  iit.Name, InputItemTypeID = iit.ID 
from (

	select IepRefID, SubRefID = cast(-99 as int), Value = x.ModifyYN, InputFieldID = 'DC181B1F-F381-470D-ACFD-5DED8F245B03', Sequence =  cast(0 as int)  -- ModNec - Modifications necessary?
	from x_LEGACYACCOM.ClassroomAccomMod_LOCAL x

	) u join
FormTemplateInputItem ftii on u.InputFieldID = ftii.Id join 
FormTemplateInputItemType iit on ftii.TypeId = iit.Id
go





if object_id('x_LEGACYACCOM.EO_IEPAccomModTbl_RAW') is not null
DROP TABLE x_LEGACYACCOM.EO_IEPAccomModTbl_RAW
GO

CREATE TABLE x_LEGACYACCOM.EO_IEPAccomModTbl_RAW (
	GStudentID uniqueidentifier NOT NULL,
	IEPComplSeqNum bigint NOT NULL,
	IEPAccomSeq bigint NOT NULL,
	Code nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccomDesc ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccomLevel nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccomType nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SubType nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Date01 datetime NULL,
	Pass bit NULL,
	PartAccom bit NULL,
	NotPart bit NULL,
	NA bit NULL,
	CreateID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreateDate datetime NULL,
	ModifyID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ModifyDate datetime NULL,
	DeleteID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Deletedate datetime NULL,
	Del_Flag bit NULL
) 
go
-- select * from  [10.0.1.8SQLServer2005DEMO].QASCConvert2005.dbo.IEPAccomModTbl_SC

if object_id('x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW') is not null
DROP TABLE x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW
GO

CREATE TABLE x_LEGACYACCOM.EO_IEPAccomModTbl_SC_RAW (
	IEPAccomSeq bigint NOT NULL,
	BSAP int NULL,
	BSAPRead bit NULL,
	BSAPMath bit NULL,
	BSAPWriting bit NULL,
	HSAP int NULL,
	HSAPEnglish bit NULL,
	HSAPAlt int NULL,
	PACT int NULL,
	PACTEnglish bit NULL,
	PACTEnglishGrade nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTMath bit NULL,
	PACTMathGrade nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTSocStudies bit NULL,
	PACTSocStudiesGrade nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTScience bit NULL,
	PACTScienceGrade nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTAlt int NULL,
	SCRA int NULL,
	SCRAAlt int NULL,
	DistAssess int NULL,
	DistAssessTitle nvarchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AltAssess ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EOCTest int NULL,
	EOCTitles ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccomMod int NULL,
	AccomModSheet ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	NormRef ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreateID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreateDate datetime NULL,
	ModifyID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ModifyDate datetime NULL,
	DeleteID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Deletedate datetime NULL,
	Del_Flag bit NOT NULL DEFAULT (0),
	HSAPMath bit NULL,
	MAP int NULL,
	Other int NULL,
	OtherDesc nvarchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	HSAPStandard int NULL,
	HSAPEnglishAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	HSAPMathAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	HSAPAltEnglish bit NULL,
	HSAPAltMath bit NULL,
	PACTStandard int NULL,
	PACTEnglishAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTMathAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTSocialAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTScienceAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PACTAltEnglish bit NULL,
	PACTAltMath bit NULL,
	PACTAltSocial bit NULL,
	PACTAltScience bit NULL,
	ELDA int NULL,
	ELDAStandard int NULL,
	ELDAAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EOCAlgMath bit NULL,
	EOCAlgMathAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EOCBiology bit NULL,
	EOCBioAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EOCEnglish bit NULL,
	EOCEnglishAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EOCPhysicalSci bit NULL,
	EOCPhysicalAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DistAssessAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EOCStandard int NULL,
	HSAPEnglishCond int NULL,
	HSAPMathCond int NULL,
	PACTEnglishCond int NULL,
	PACTMathCond int NULL,
	PACTSocialCond int NULL,
	PACTScienceCond int NULL,
	EOCMathCond int NULL,
	EOCBiologyCond int NULL,
	EOCEnglishCond int NULL,
	EOCPhysicalSciCond int NULL,
	EOCUSHistory bit NULL,
	EOCUSHistoryCond int NULL,
	SCAltReason ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	HSAPEngTestTaken int NULL,
	HSAPMathTestTaken int NULL,
	EOCUSHistTestTaken int NULL,
	PACTAltAgeQual int NULL,
	SCRAAltReason ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PASSWriting bit NULL,
	PASSWritingCond int NULL,
	PartTesting nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DuringEffDates nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SubjAreaAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	GTTP int NULL,
	GTTPAccom ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	GTTPData ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SB int NULL,
	SBELA bit NULL,
	SBELACond int NULL,
	SBMath bit NULL,
	SBMathCond int NULL
) 
GO

if object_id('x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW') is not null
DROP TABLE x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW
GO

CREATE TABLE x_LEGACYACCOM.EO_ICIEPAccomModListTbl_SC_RAW (
	IEPComplSeqNum bigint NOT NULL,
	IEPAccomSeq bigint NOT NULL,
	RecNum int NOT NULL,
	AccomCode nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccomDesc ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccomType nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreateID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreateDate datetime NULL,
	ModifyID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ModifyDate datetime NULL,
	DeleteID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DeleteDate datetime NULL,
	Del_Flag bit NULL
) 
go


if object_id('x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW') is not null
DROP TABLE x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW
GO

CREATE TABLE x_LEGACYACCOM.EO_ICIEPModTbl_SC_RAW (
	GStudentID uniqueidentifier NOT NULL,
	IEPComplSeqNum bigint NULL,
	IEPModSeq bigint NOT NULL,
	SupplementAids ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Modifications ntext COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProgramModify bit NULL,
	CreateID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreateDate datetime NULL,
	ModifyID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ModifyDate datetime NULL,
	DeleteID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DeleteDate datetime NULL,
	Del_Flag bit NOT NULL
) 
go





















