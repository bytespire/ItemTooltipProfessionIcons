local _, ItemProfConstants = ...

local frame = CreateFrame( "Frame" )
frame.name = "ItemTooltipIconConfig"

local profsCheck
local vendorCheck
local iconSizeSlider
local iconSizeLabel
local iconDemoTexture

local PROF_CHECK = {}

local configDefaultShowProfs = true
local configDefaultProfFlags = 0x3FF
local configDefaultIncludeVendor = true
local configDefaultIconSize = 18

local userVariables

local NUM_PROFS_TRACKED = ItemProfConstants.NUM_PROF_FLAGS




local function SaveAndQuit() 

	local profFlags = 0
	-- Ignore the profession flags if master profession checkbox is unchecked
	for i=0, NUM_PROFS_TRACKED-1 do
		local bitMask = bit.lshift( 1, i )
		local isChecked = PROF_CHECK[ bitMask ]:GetChecked()
		if isChecked then
			profFlags = profFlags + bitMask
		end
	end

	
	userVariables.showProfs = profsCheck:GetChecked()
	userVariables.profFlags = profFlags
	userVariables.includeVendor = vendorCheck:GetChecked()
	userVariables.iconSize = iconSizeSlider:GetValue()

	ItemProfConstants:ConfigChanged()
end



local function ToggleProfCheckbox() 

	local isChecked = profsCheck:GetChecked()
	for k,v in pairs( PROF_CHECK ) do
		if isChecked then
			v:Enable()
		else
			v:Disable()
		end
	end
	
end


local function RefreshWidgets()

	-- Sync the widgets state with the config variables
	profsCheck:SetChecked( userVariables.showProfs )
	vendorCheck:SetChecked( userVariables.includeVendor )
	local profFlags = userVariables.profFlags
	iconSizeSlider:SetValue( userVariables.iconSize )
	
	-- Update the profession checkboxes
	for i=0, NUM_PROFS_TRACKED-1 do
		local bitMask = bit.lshift( 1, i )
		local isSet = bit.band( profFlags, bitMask )
		PROF_CHECK[ bitMask ]:SetChecked( isSet ~= 0 )
	end

	-- Set checkboxes enabled/disabled
	ToggleProfCheckbox()
end


local function IconSizeChanged( self, value ) 

	-- Called when the icon slider widget changes value
	iconDemoTexture:SetSize( value, value )
	iconSizeLabel:SetText( value )
end


local function InitVariables()
	
	local configRealm = ItemProfConstants.configTooltipIconsRealm
	local configChar = ItemProfConstants.configTooltipIconsChar
	
	
	if not ItemTooltipIconsConfig then
		ItemTooltipIconsConfig = {}
	end
	
	if not ItemTooltipIconsConfig[ configRealm ] then
		ItemTooltipIconsConfig[ configRealm ] = {}
	end
	
	if not ItemTooltipIconsConfig[ configRealm ][ configChar ] then
		ItemTooltipIconsConfig[ configRealm ][ configChar ] = {}
	end
	
	userVariables = ItemTooltipIconsConfig[ configRealm ][ configChar ]
	
	if userVariables.showProfs == nil then
		userVariables.showProfs = configDefaultShowProfs
	end
	
	if userVariables.profFlags == nil then
		userVariables.profFlags = configDefaultProfFlags
	end
	
	if userVariables.includeVendor == nil then
		userVariables.includeVendor = configDefaultIncludeVendor
	end
	
	if userVariables.iconSize == nil then
		userVariables.iconSize = configDefaultIconSize
	end
	
	
	RefreshWidgets()
	ItemProfConstants:ConfigChanged()
end


local function CreateCheckbox( name, x, y, label, tooltip )

	local check = CreateFrame( "CheckButton", name, frame, "ChatConfigCheckButtonTemplate" ) --"OptionsCheckButtonTemplate" )
	_G[ name .. "Text" ]:SetText( label )
	check.tooltip = tooltip
	check:SetPoint( "TOPLEFT", x, y )

	return check
end


local function CreateProfessionWidgets() 

	profsCheck = CreateCheckbox( "ItemTooltipIconsConfigCheck0", 20, -50, " Enable Profession Icons", "If enabled profession icons will be displayed on items that are crafting materials" )
	profsCheck:SetScript( "OnClick", ToggleProfCheckbox )

	-- Checkbox alignment offsets
	local x0 = 45
	local x1 = 245
	local y0 = -70
	local dy = -20

	-- undefined indices are error-prone:
	PROF_CHECK[ 1 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0a", x0, y0+dy, " Cooking", nil )
	PROF_CHECK[ 2 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0b", x1, y0+(2*dy), " First Aid", nil )
	PROF_CHECK[ 4 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0c", x0, y0, " Alchemy", nil )
	PROF_CHECK[ 8 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0d", x1, y0, " Blacksmithing", nil )
	PROF_CHECK[ 16 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0e", x1, y0+dy, " Enchanting", nil )
	PROF_CHECK[ 32 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0f", x0, y0+(2*dy), " Engineering", nil )
	PROF_CHECK[ 64 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0g", x0, y0+(4*dy), " Leatherworking", nil )
	PROF_CHECK[ 128 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0h", x1, y0+(4*dy), " Tailoring", nil )
	PROF_CHECK[ 256 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0i", x0, y0+(3*dy), " Inscription", nil )
	PROF_CHECK[ 512 ] = CreateCheckbox( "ItemTooltipIconsConfigCheck0j", x1, y0+(3*dy), " Jewelcrafting", nil )
	
	vendorCheck = CreateCheckbox( "ItemTooltipIconsConfigCheck2", 20, -200, " Vendor Items", "Display icons on items sold by vendors" )
end


local function CreateIconResizeWidgets()

	iconSizeSlider = CreateFrame( "Slider", "ItemTooltipIconsConfigSlider0", frame, "OptionsSliderTemplate" )
	iconSizeSlider:SetPoint( "TOPLEFT", 20, -300 )
	iconSizeSlider:SetMinMaxValues( 8, 32 )
	iconSizeSlider:SetValueStep( 1 )
	iconSizeSlider:SetStepsPerPage( 1 )
	iconSizeSlider:SetWidth( 200 )
	iconSizeSlider:SetObeyStepOnDrag( true )
	iconSizeSlider:SetScript( "OnValueChanged", IconSizeChanged )
	_G[ "ItemTooltipIconsConfigSlider0Text" ]:SetText( "Icon Size" )
	_G[ "ItemTooltipIconsConfigSlider0Low" ]:SetText( nil )
	_G[ "ItemTooltipIconsConfigSlider0High" ]:SetText( nil )

	iconSizeLabel = frame:CreateFontString( nil, "OVERLAY", "GameTooltipText" )
	iconSizeLabel:SetFont( "Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE" )
	iconSizeLabel:SetPoint( "TOPLEFT", 225, -302 )

	iconDemoTexture = frame:CreateTexture( nil, "OVERLAY" )
	iconDemoTexture:SetPoint( "TOPLEFT", 300, -300 )
	iconDemoTexture:SetTexture( GetSpellTexture( 4036 ) )
end


local dialogHeader = frame:CreateFontString( nil, "OVERLAY", "GameTooltipText" )
dialogHeader:SetFont( "Fonts\\FRIZQT__.TTF", 10, "THINOUTLINE" )
dialogHeader:SetPoint( "TOPLEFT", 20, -20 )
dialogHeader:SetText( "These options allow you control which icons are displayed on the item tooltips." )


CreateProfessionWidgets()
CreateIconResizeWidgets()




frame.okay = SaveAndQuit
frame:SetScript( "OnShow", RefreshWidgets )
frame:SetScript( "OnEvent", InitVariables )
frame:RegisterEvent( "VARIABLES_LOADED" )


InterfaceOptions_AddCategory( frame )