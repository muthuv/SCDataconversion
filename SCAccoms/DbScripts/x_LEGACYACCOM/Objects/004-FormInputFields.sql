if object_id('x_LEGACYACCOM.FormInputFields', 'V') is not null
DROP VIEW x_LEGACYACCOM.FormInputFields
GO

CREATE view x_LEGACYACCOM.FormInputFields
as
with controlCTE 
as
(
select TemplateName = t.name, 
	tl.TemplateID, 
	ControlCode = tc.Code, tl.ControlID, LayoutID = tl.ID, LayoutParentID = tl.ParentID, ControlTypeID = tc.TypeId,
	ControlIsRepeatable = tc.IsRepeatable,
	ControlLevel = 0, 
	LayoutSequence = tl.Sequence
from FormTemplate t
join FormTemplateLayout tl on t.id = tl.TemplateId
join FormTemplateControl tc on tl.ControlId = tc.Id and tl.ParentId is null
union all
select t.name, 
	tl.TemplateID, 
	ControlCode = tc.Code, tl.ControlID, LayoutID = tl.ID, LayoutParentID = tl.ParentID, ControlTypeID = tc.TypeId,
	ControlIsRepeatable = tc.IsRepeatable,
	c.ControlLevel+1, 
	LayoutSequence = tl.Sequence
from FormTemplate t
join FormTemplateLayout tl on t.id = tl.TemplateId
join FormTemplateControl tc on tl.ControlId = tc.Id
join controlCTE c on tl.ParentId = c.LayoutID
)
select Distinct c.TemplateName, ControlType = ct.Name, ControlProperty = coalesce(cpl.Value, cpt.Value, cpn.Value),
	c.ControlCode,
	FooterSection = fst.name+ isnull(' / '+fsd.Title,''), FooterSectionDefID = fsd.ID,
	HeaderSection = hst.name+ isnull(' / '+hsd.Title,''), HeaderSectionDefID = hsd.ID, 
	InputItemCode = ii.Code, InputItemLabel = ii.Label, InputItemType = iit.Name, 
	c.ControlIsRepeatable, c.ControlLevel, c.LayoutSequence, 
	InputItemSequence = ii.Sequence, 
	c.TemplateID, c.ControlId, c.LayoutID, c.LayoutParentID, InputFieldID = ii.ID, ii.IsRequired, InputItemControl = ii.Control
from controlCTE c -- 120
join FormTemplateControlType ct on c.ControlTypeID = ct.Id
left join PrgSectionDef fsd on c.TemplateId = fsd.FormTemplateID -- footer
	left join PrgSectionType fst on fsd.TypeID = fst.ID
left join PrgSectionDef hsd on c.TemplateId = hsd.HeaderFormTemplateID -- header
	left join PrgSectionType hst on hsd.TypeID = hst.ID
left join FormTemplateControlProperty cpl on c.ControlId = cpl.ControlId and cpl.Name = 'Label'
left join FormTemplateControlProperty cpt on c.ControlId = cpt.ControlId and cpt.Name = 'Text'
left join FormTemplateControlProperty cpn on c.ControlId = cpn.ControlId and cpn.Name = 'LayoutName'
left join FormTemplateInputItem ii on c.ControlId = ii.InputAreaId
left join FormTemplateInputItemType iit on ii.TypeId = iit.Id
go
