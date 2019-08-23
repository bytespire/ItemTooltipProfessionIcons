local _, ItemProfConstants = ...

local frame = CreateFrame( "Frame" )

local previousItemID = -1
local ICON_SIZE = 16
local itemIcons = ""

local ITEM_PROF_FLAGS = ItemProfConstants.ITEM_PROF_FLAGS
local NUM_PROFS_TRACKED = ItemProfConstants.NUM_PROF_FLAGS
local PROF_TEXTURES = ItemProfConstants.PROF_TEXTURES


local function CreateItemIcons( itemFlags )

	local t = {}
	for i=0, NUM_PROFS_TRACKED do
	
		local bitMask = bit.lshift( 1, i )
		local isSet = bit.band( itemFlags, bitMask )
		if isSet ~= 0 then
			t[ #t+1 ] = "|T"
			t[ #t+1 ] = PROF_TEXTURES[ bitMask ]
			t[ #t+1 ] = ":"
			t[ #t+1 ] = ICON_SIZE
			t[ #t+1 ] = "|t "
		end
	end

	return table.concat( t )
end


local function ModifyItemTooltip( tt ) 
		
	local itemName, itemLink = tt:GetItem() 
	local itemID = select( 1, GetItemInfoInstant( itemName ) )
	
	if itemID == nil then
		-- Extract ID from link: GetItemInfoInstant unreliable with AH items (uncached on client?)
		itemID = tonumber( string.match( itemLink, ":?(%d+):" ) )
	end
	
	-- Reuse the texture state if the item hasn't changed
	if previousItemID == itemID then
		tt:AddLine( itemIcons )
		return
	end
	
	-- Check if the item is a profession reagent
	local itemFlags = ITEM_PROF_FLAGS[ itemID ];
	if itemFlags == nil then
		-- Don't modify the tooltip
		return
	end
	
	-- Convert the flags into texture icons
	previousItemID = itemID
	itemIcons = CreateItemIcons( itemFlags )
	
	tt:AddLine( itemIcons )
end


local function InitFrame()

	GameTooltip:HookScript("OnTooltipSetItem", ModifyItemTooltip )
	--ItemRefTooltip:HookScript( "OnTooltipSetItem", ModifyItemTooltip )
end


InitFrame()