local addonName, ItemProfConstants = ...

local frame = CreateFrame( "Frame" )
frame.name = addonName

local questCheck
local vendorCheck
local crateCheck
local dmfCheck
local iconSizeSlider

local PROF_CHECK = table.create( 9 ) -- preallocating?
local QUEST_CHECK = table.create( 2 )

local userVariables


local function SaveAndQuit() 
	
	local profFlags = 0
	for i=1, #PROF_CHECK do
		if PROF_CHECK[ i ]:GetChecked() then
			profFlags = profFlags + PROF_CHECK[ i ]:GetID()
		end
	end

	local questFlags = 1		-- Always track quest flag 'Q'
	for i=1, #QUEST_CHECK do
		if QUEST_CHECK[ i ]:GetChecked() then
			questFlags = questFlags + QUEST_CHECK[ i ]:GetID()
		end
	end

	userVariables.showQuests = questCheck:GetChecked()
	userVariables.profFlags = profFlags
	userVariables.questFlags = questFlags
	userVariables.includeVendor = vendorCheck:GetChecked()
	userVariables.includeCrate = crateCheck:GetChecked()
	userVariables.iconSize = iconSizeSlider:GetValue()
	userVariables.showDMF = dmfCheck:GetChecked()
	ItemProfConstants:ConfigChanged( userVariables )
end


local function ToggleQuestCheckbox() 
	-- Enable/disable quest tracking
	local isChecked = questCheck:GetChecked()
	for i=1, #QUEST_CHECK do
		QUEST_CHECK[ i ]:SetEnabled( isChecked )
	end
end


local function RefreshWidgets()
	-- Sync the widgets with the config variables
	questCheck:SetChecked( userVariables.showQuests )
	vendorCheck:SetChecked( userVariables.includeVendor )
	crateCheck:SetChecked( userVariables.includeCrate )
	dmfCheck:SetChecked( userVariables.showDMF )
	local profFlags = userVariables.profFlags
	local questFlags = userVariables.questFlags
	iconSizeSlider:SetValue( userVariables.iconSize )
		
	-- Update the profession checkboxes
	for i=1, #PROF_CHECK do
		local isSet = bit.band( profFlags, PROF_CHECK[ i ]:GetID() )
		PROF_CHECK[ i ]:SetChecked( isSet ~= 0 )
	end
	-- Update the quest checkboxes
	for i=1, #QUEST_CHECK do 
		local isSet = bit.band( questFlags, QUEST_CHECK[ i ]:GetID() )
		QUEST_CHECK[ i ]:SetChecked( isSet ~= 0 )
	end

	-- Set checkboxes enabled/disabled
	ToggleQuestCheckbox()
end


local function IconSizeChanged( self, value ) 
	-- Called when the icon slider widget changes value
	self.ValueText:SetText( value )
	self.IconPreview:SetSize( value, value )
end


local function InitVariables( self, event, loadedName )
	
	if loadedName ~= self.name then
		return
	end

	self:UnregisterEvent( "ADDON_LOADED" )
	
	if not ItemTooltipIconsConfig then
		-- Enable only the character faction by default
		local qFaction = 2
		if select( 1, UnitFactionGroup( "player" ) ) == "Horde" then
			qFaction = 4
		end

		ItemTooltipIconsConfig = {
			showQuests = true,
			profFlags = 0xFFF,
			questFlags = 1 + qFaction,
			includeVendor = false,
			includeCrate = true,
			iconSize = 18,
			showDMF = true
		}
	end
	userVariables = ItemTooltipIconsConfig

	RefreshWidgets()
	ItemProfConstants:ConfigChanged( userVariables )
end


local function CreateCheckbox( name, label, parent, texture )

	local check = CreateFrame( "CheckButton", name, parent, "ChatConfigCheckButtonTemplate" )
	check.Text:SetText( label )
	check.Text:SetPointsOffset( 6, 1 )
	if texture ~= nil then
		check.Icon = check:CreateTexture( "Icon", "OVERLAY" )
		check.Icon:SetTexture( texture )
		check.Icon:SetSize( 24, 24 )
		check.Icon:SetPoint( "LEFT", -44, 0 ) -- should prob define offset
	end
	return check
end


local function CreateProfessionWidgets( profConfig ) 

	PROF_CHECK[ 1 ] = CreateCheckbox( "ToggleCook", "Cooking", profConfig, 133971 )
	PROF_CHECK[ 2 ] = CreateCheckbox( "ToggleFAid", "First Aid", profConfig, 135966 )
	PROF_CHECK[ 3 ] = CreateCheckbox( "ToggleMine", "Mining", profConfig, 136248 )
	PROF_CHECK[ 4 ] = CreateCheckbox( "ToggleAlc", "Alchemy", profConfig, 136240 )
	PROF_CHECK[ 5 ] = CreateCheckbox( "ToggleBS", "Blacksmithing", profConfig, 136241 )
	PROF_CHECK[ 6 ] = CreateCheckbox( "ToggleEnc", "Enchanting", profConfig, 136244 )
	PROF_CHECK[ 7 ] = CreateCheckbox( "ToggleEng", "Engineering", profConfig, 136243 )
	PROF_CHECK[ 8 ] = CreateCheckbox( "ToggleLW", "Leatherworking", profConfig, 133611 )
	PROF_CHECK[ 9 ] = CreateCheckbox( "ToggleTail", "Tailoring", profConfig, 136249 )

	-- Align vertically
	local len = #PROF_CHECK
	PROF_CHECK[ 1 ]:SetPoint( profConfig:GetPointByName( "TOPLEFT" ) )
	PROF_CHECK[ 1 ]:AdjustPointsOffset( 44, 0 ) -- offset the icon
	for i=2, len do
		PROF_CHECK[ i ]:SetPoint( "TOP", PROF_CHECK[ i-1 ], "BOTTOM", 0, -5 )
	end

	-- Precalculate the bit mask used to toggle flag
	for i=1, len do
		PROF_CHECK[ i ]:SetID( bit.lshift( 1, i-1 ) )
	end

	profConfig:SetPoint( "BOTTOM", PROF_CHECK[ len ] )
end


local function CreateQuestWidgets( questConfig ) 
	
	questCheck = CreateCheckbox( "ToggleAllQuests", "Enable Quest Icons", questConfig, 132049 )
	questCheck:SetPoint( questConfig:GetPointByName( "TOPLEFT" ) )
	questCheck:AdjustPointsOffset( 44, 0 ) -- offset the icon
	questCheck.tooltip = "Show a quest icon on trade items that are needed by quests"
	questCheck:SetScript( "OnClick", ToggleQuestCheckbox )

	QUEST_CHECK[ 1 ] = CreateCheckbox( "ToggleAllianceQ", "Alliance", questConfig )
	QUEST_CHECK[ 1 ]:SetPoint( "TOPLEFT", "ToggleAllQuests", "BOTTOMLEFT", 25, 5 )
	QUEST_CHECK[ 2 ] = CreateCheckbox( "ToggleHordeQ", "Horde", questConfig )
	QUEST_CHECK[ 2 ]:SetPoint( "TOPLEFT", "ToggleAllianceQ", "BOTTOMLEFT", 0, 5 )
	
	-- Precalculate the bit mask used to toggle flag
	local len = #QUEST_CHECK
	for i=1, len do
		QUEST_CHECK[ i ]:SetID( bit.lshift( 1, i ) ) -- bit 0 is Q
	end

	questConfig:SetPoint( "BOTTOM", QUEST_CHECK[ len ] )
end


local function CreateMiscWidgets( miscConfig )

	vendorCheck = CreateCheckbox( "ToggleVendor", "Vendor Items", miscConfig )
	vendorCheck.tooltip = "Display an icon on items sold by vendors"
	vendorCheck:SetPoint( miscConfig:GetPointByName( "TOPLEFT" ) )
	vendorCheck:AdjustPointsOffset( 44, 0 ) -- offset the icon
	vendorCheck.Icon = vendorCheck:CreateTexture( "Icon", "OVERLAY" )
	vendorCheck.Icon:SetSize( 24, 24 )
	vendorCheck.Icon:SetPoint( "LEFT", -44, 0 )
	vendorCheck.Icon:SetAtlas( "SpellIcon-256x256-SellJunk" )

	crateCheck = CreateCheckbox( "ToggleCrate", "Waylaid Crate Materials", miscConfig, ItemProfConstants.CRATE_ICON )
	crateCheck.tooltip = "Display an icon on materials that can fill a Waylaid Crate"
	crateCheck:SetPoint( "TOP", vendorCheck, "BOTTOM", 0, -5 )
	crateCheck:AdjustPointsOffset( 44, 0 ) -- offset the icon

	dmfCheck = CreateCheckbox( "ToggleDMF", "Darkmoon Faire Ticket Items", miscConfig, 134481 )
	dmfCheck.tooltip = "Display a ticket icon if the item can be exchanged for Darkmoon Faire tickets"
	dmfCheck:SetPoint( "TOP", crateCheck, "BOTTOM", 0, -5 )
	dmfCheck:Hide()

	iconSizeSlider = CreateFrame( "Slider", "SliderIconSize", miscConfig, "MinimalSliderTemplate" )
	iconSizeSlider:SetPoint( "TOPLEFT", dmfCheck, "BOTTOMLEFT", 0, -20 )
	iconSizeSlider:SetMinMaxValues( 8, 32 )
	iconSizeSlider:SetValueStep( 1 )
	iconSizeSlider:SetStepsPerPage( 1 )
	iconSizeSlider:SetSize( 200, 17 )
	iconSizeSlider:SetObeyStepOnDrag( true )
	iconSizeSlider:SetScript( "OnValueChanged", IconSizeChanged )

	iconSizeSlider.Name = iconSizeSlider:CreateFontString( "Name", "OVERLAY", "GameFontHighlight" ) 
	iconSizeSlider.Name:SetPoint( "BOTTOM", iconSizeSlider, "TOP" )
	iconSizeSlider.Name:SetText( "Icon Size" )

	iconSizeSlider.ValueText = iconSizeSlider:CreateFontString( "ValueText", "OVERLAY", "GameFontHighlight" )
	iconSizeSlider.ValueText:SetPoint( "LEFT", iconSizeSlider, "RIGHT", 16, 0 )

	iconSizeSlider.IconPreview = iconSizeSlider:CreateTexture( "IconPreview", "OVERLAY" )
	iconSizeSlider.IconPreview:SetPoint( "LEFT", iconSizeSlider.ValueText, "RIGHT", 24, 0 )
	iconSizeSlider.IconPreview:SetTexture( 136243 )


	miscConfig:SetPoint( "BOTTOM", iconSizeSlider )
end


frame.Header = frame:CreateFontString( "Header", "OVERLAY", "GameTooltipTextSmall" )
frame.Header:SetPoint( "TOPLEFT", 20, -20 )
frame.Header:SetText( "These options allow you control which icons are displayed on the item tooltips" )

-- Frames for each category to simplify alignment
local profConfig = CreateFrame( "Frame", "ConfigProf", frame )
profConfig:SetPoint( "TOPLEFT", frame.Header, "BOTTOMLEFT", 0, -20 )
profConfig:SetPoint( "TOPRIGHT" )

local questConfig = CreateFrame( "Frame", "ConfigQuest", frame )
questConfig:SetPoint( "TOPLEFT", profConfig, "BOTTOMLEFT", 0, -20 )
questConfig:SetPoint( "TOPRIGHT" )

local miscConfig = CreateFrame( "Frame", "ConfigMisc", frame )
miscConfig:SetPoint( "TOPLEFT", questConfig, "BOTTOMLEFT", 0, -20 )
miscConfig:SetPoint( "TOPRIGHT" )

CreateProfessionWidgets( profConfig )
CreateQuestWidgets( questConfig )
CreateMiscWidgets( miscConfig )


frame:Hide()	-- The options menu is calling hide before 1st show
frame:SetScript( "OnEvent", InitVariables )
frame:SetScript( "OnHide", SaveAndQuit )
frame:RegisterEvent( "ADDON_LOADED" )


if Settings then
	local category = Settings.RegisterCanvasLayoutCategory( frame, frame.name )
	Settings.RegisterAddOnCategory( category )
end
