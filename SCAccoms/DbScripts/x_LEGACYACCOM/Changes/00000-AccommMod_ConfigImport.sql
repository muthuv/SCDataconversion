BEGIN TRAN

-- RelaxConstraints: disable specific foreign key constraints
ALTER TABLE FormInputSingleSelectValue NOCHECK CONSTRAINT FK_FormInputSingleSelectValue#SelectedOption# -- FK_FormInputSingleSelectValue#SelectedOption#
ALTER TABLE FormTemplateInputItem NOCHECK CONSTRAINT FK_FormTemplateInputItem#ShowIfOption# -- FK_FormTemplateInputItem#ShowIfOption#
ALTER TABLE FormTemplate NOCHECK CONSTRAINT FK_FormTemplate#LastModifiedUser# -- FK_FormTemplate#LastModifiedUser#

		set nocount on

		IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[PrgItemDef]') AND name = N'UN_PrgItemDef_Name')
		ALTER TABLE [dbo].[PrgItemDef] DROP CONSTRAINT [UN_PrgItemDef_Name]

		IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[ProgramDocTranslatedText]') AND name = N'UN_ProgramDocTranslatedText_Text')
		ALTER TABLE [dbo].[ProgramDocTranslatedText] DROP CONSTRAINT [UN_ProgramDocTranslatedText_Text]

	


-- Declare a temporary table to hold the data to be synchronized
DECLARE @FormTemplate TABLE (Id uniqueidentifier, Name varchar(50), TypeId uniqueidentifier, IntervalSeriesId uniqueidentifier, PageLength float, ProgramID uniqueidentifier, Code varchar(50), LastModifiedDate datetime, LastModifiedUserID uniqueidentifier)

-- Insert the data to be synchronized into the temporary table
INSERT INTO @FormTemplate VALUES ('876cf1e1-2e04-4f96-b15c-cb4b9d305ff9', N'Accommodations/Modifications', 'f4e41948-74c0-4bb5-b218-f2437c7b040b', '6e839019-46cc-4246-bb42-5ca42ed4ae6b', 11, 'f98a8ef2-98e2-4cac-95af-d7d89ef7f80c', N'AccomsMods', '9/12/2014 8:55:37 AM', 'eee133bd-c557-47e1-ab67-ee413dd3d1ab')

-- Declare a temporary table to hold the data to be synchronized
DECLARE @PrgSectionDef TABLE (ID uniqueidentifier, TypeID uniqueidentifier, ItemDefID uniqueidentifier, Sequence int, IsVersioned bit, Code varchar(50), Title varchar(50), VideoUrl varchar(200), HelpTextLegal text, HelpTextInfo text, FormTemplateID uniqueidentifier, DisplayPrevious bit, CanCopy bit, HeaderFormTemplateID uniqueidentifier, HelpTextState text)

-- Insert the data to be synchronized into the temporary table
INSERT INTO @PrgSectionDef VALUES ('43cd5045-8083-4534-ad66-a81c43a42f26', '265ac4ec-2325-4ca8-a428-5361dc7f83f0', '1984f017-51cb-4e3c-9b3a-338a9d409ec6', 4, 1, NULL, NULL, NULL, NULL, NULL, '876cf1e1-2e04-4f96-b15c-cb4b9d305ff9', 0, 0, NULL, NULL)

-- Declare a temporary table to hold the data to be synchronized
DECLARE @IepAccommodationsSectionDef TABLE (ID uniqueidentifier, TrackDetails bit, TrackForAssessments bit, UseDetails bit)

-- Insert the data to be synchronized into the temporary table
INSERT INTO @IepAccommodationsSectionDef VALUES ('43CD5045-8083-4534-AD66-A81C43A42F26', 0, 0, 0)

-- Insert records in the destination tables that do not already exist
INSERT INTO FormTemplate (Id, Name, TypeId, IntervalSeriesId, PageLength, ProgramID, Code, LastModifiedDate, LastModifiedUserID) SELECT Source.* FROM @FormTemplate Source LEFT JOIN FormTemplate Destination ON Source.Id = Destination.Id WHERE Destination.Id IS NULL
INSERT INTO PrgSectionDef (ID, TypeID, ItemDefID, Sequence, IsVersioned, Code, Title, VideoUrl, HelpTextLegal, HelpTextInfo, FormTemplateID, DisplayPrevious, CanCopy, HeaderFormTemplateID, HelpTextState) SELECT Source.* FROM @PrgSectionDef Source LEFT JOIN PrgSectionDef Destination ON Source.ID = Destination.ID WHERE Destination.ID IS NULL
INSERT INTO IepAccommodationsSectionDef (ID, TrackDetails, TrackForAssessments, UseDetails) SELECT Source.* FROM @IepAccommodationsSectionDef Source LEFT JOIN IepAccommodationsSectionDef Destination ON Source.ID = Destination.ID WHERE Destination.ID IS NULL

-- Update records in the destination table that already exist
UPDATE Destination SET Destination.Name = Source.Name, Destination.TypeId = Source.TypeId, Destination.IntervalSeriesId = Source.IntervalSeriesId, Destination.PageLength = Source.PageLength, Destination.ProgramID = Source.ProgramID, Destination.Code = Source.Code, Destination.LastModifiedDate = Source.LastModifiedDate, Destination.LastModifiedUserID = Source.LastModifiedUserID FROM @FormTemplate Source JOIN FormTemplate Destination ON Source.Id = Destination.Id
UPDATE Destination SET Destination.TypeID = Source.TypeID, Destination.ItemDefID = Source.ItemDefID, Destination.Sequence = Source.Sequence, Destination.IsVersioned = Source.IsVersioned, Destination.Code = Source.Code, Destination.Title = Source.Title, Destination.VideoUrl = Source.VideoUrl, Destination.HelpTextLegal = Source.HelpTextLegal, Destination.HelpTextInfo = Source.HelpTextInfo, Destination.FormTemplateID = Source.FormTemplateID, Destination.DisplayPrevious = Source.DisplayPrevious, Destination.CanCopy = Source.CanCopy, Destination.HeaderFormTemplateID = Source.HeaderFormTemplateID, Destination.HelpTextState = Source.HelpTextState FROM @PrgSectionDef Source JOIN PrgSectionDef Destination ON Source.ID = Destination.ID

-- Delete records in the destination tables that are obsolete
DELETE FROM Destination FROM PrgSectionDef Destination JOIN (SELECT * FROM PrgSectionDef WHERE ID = '43CD5045-8083-4534-AD66-A81C43A42F26') Filtered ON Destination.ID = Filtered.ID   LEFT JOIN @PrgSectionDef Source ON Destination.ID = Source.ID   WHERE Source.ID IS NULL
DELETE FROM Destination FROM FormTemplate Destination JOIN (SELECT * FROM FormTemplate WHERE ID = '876CF1E1-2E04-4F96-B15C-CB4B9D305FF9') Filtered ON Destination.Id = Filtered.Id   LEFT JOIN @FormTemplate Source ON Destination.Id = Source.Id   WHERE Source.Id IS NULL


		set nocount off

		-- update PrgItemDef.LastModifiedUserID for users that don't exist
		UPDATE i SET LastModifiedUserID = 'EEE133BD-C557-47E1-AB67-EE413DD3D1AB'
		FROM PrgItemDef i LEFT JOIN UserProfile u ON i.LastModifiedUserID = u.ID WHERE u.ID IS NULL

		-- update FormTemplate.LastModifiedUserID for users that don't exist
		UPDATE f SET LastModifiedUserID = 'EEE133BD-C557-47E1-AB67-EE413DD3D1AB'
		FROM FormTemplate f LEFT JOIN UserProfile u ON f.LastModifiedUserID = u.ID
		WHERE u.ID IS NULL

		ALTER TABLE [dbo].[PrgItemDef] ADD  CONSTRAINT [UN_PrgItemDef_Name] UNIQUE NONCLUSTERED
		(
		[ProgramID] ASC,
		[Name] ASC,
		[DeletedDate] ASC
		) ON [PRIMARY]

		ALTER TABLE [dbo].[ProgramDocTranslatedText]
		ADD CONSTRAINT [UN_ProgramDocTranslatedText_Text] UNIQUE
		(
		[TranslationLanguageID],
		[DocTextID]
		)

		DELETE m
		FROM PrgMilestone m JOIN
		PrgMilestoneDef d on m.MilestoneDefID = d.ID
		WHERE d.DeletedDate IS NOT NULL AND m.DateMet IS NULL

		UPDATE PrgMilestoneDef
		SET IsReevaluationNeeded=1, IsExternallyModified=1
		WHERE DefinedByTemplate = 1
	
-- RelaxConstraints: perform cleanup operations
UPDATE FormInputSingleSelectValue SET SelectedOptionId = NULL WHERE SelectedOptionId IS NOT NULL AND SelectedOptionId NOT IN (SELECT ID FROM FormTemplateInputSelectFieldOption) -- FK_FormInputSingleSelectValue#SelectedOption#
-- no resolution -- FK_FormTemplateInputItem#ShowIfOption#
-- no resolution -- FK_FormTemplate#LastModifiedUser#
-- RelaxConstraints: re-enable specific foreign key constraints
ALTER TABLE FormInputSingleSelectValue WITH CHECK CHECK CONSTRAINT FK_FormInputSingleSelectValue#SelectedOption# -- FK_FormInputSingleSelectValue#SelectedOption#
ALTER TABLE FormTemplateInputItem WITH CHECK CHECK CONSTRAINT FK_FormTemplateInputItem#ShowIfOption# -- FK_FormTemplateInputItem#ShowIfOption#
ALTER TABLE FormTemplate WITH CHECK CHECK CONSTRAINT FK_FormTemplate#LastModifiedUser# -- FK_FormTemplate#LastModifiedUser#


COMMIT TRAN