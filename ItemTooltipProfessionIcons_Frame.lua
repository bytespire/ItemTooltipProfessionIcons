local _, ItemProfConstants = ...

local MAX_ICONS_VISIBLE = 6	-- textures visible
local COLUMN_WIDTH = 18
local FRAME_HEIGHT = 13

local frame = CreateFrame( "Frame" )
frame:SetPoint( "LEFT", 4, 0 )
frame:SetSize( MAX_ICONS_VISIBLE * COLUMN_WIDTH, FRAME_HEIGHT )

local frameTextures = {}
-- Create & align the frame's textures 
for i=1, MAX_ICONS_VISIBLE do
	local xOffset = ( i-1 ) * COLUMN_WIDTH
	frameTextures[ i ] = frame:CreateTexture( nil, "OVERLAY" )
	frameTextures[ i ]:SetPoint( "LEFT", frame, "LEFT", xOffset, -2 )
	frameTextures[ i ]:SetSize( 16, 16 )
end


local previousItemID = -1

local ITEM_PROF_FLAGS = ItemProfConstants.ITEM_PROF_FLAGS
local NUM_PROFS_TRACKED = ItemProfConstants.NUM_PROF_FLAGS
local PROF_TEXTURES = ItemProfConstants.PROF_TEXTURES


local function ModifyItemTooltip( tt ) 
	
	local itemName = select( 1, tt:GetItem() )
	local itemID = select( 1, GetItemInfoInstant( itemName ) )
	
	-- Reuse the frame state if the item hasn't changed
	if previousItemID == itemID then
		GameTooltip_InsertFrame( tt, frame )
		return
	end
	
	-- Check if the item is a profession reagent
	local itemFlags = ITEM_PROF_FLAGS[ itemID ];
	if itemFlags == nil then
		-- Don't modify the tooltip
		return
	end
	
	previousItemID = itemID
	
	-- Clear the frame's previous texture state
	for i=1, #frameTextures do
		frameTextures[ i ]:SetTexture( nil )
	end
	
	--print( "item flags: " .. itemFlags )
	local columnIndex = 1
	for i=0, NUM_PROFS_TRACKED do
	
		local bitMask = bit.lshift( 1, i )
		local isSet = bit.band( itemFlags, bitMask )
		if isSet ~= 0 then
		--	print( "bit " .. i .. " is set " .. isSet )
			frameTextures[ columnIndex ]:SetTexture( PROF_TEXTURES[ bitMask ] )
			columnIndex = columnIndex + 1
		end
	end
	
	
	GameTooltip_InsertFrame( tt, frame )
end



local function InitFrame()

	GameTooltip:HookScript("OnTooltipSetItem", ModifyItemTooltip )
	--ItemRefTooltip:HookScript( "OnTooltipSetItem", ModifyItemTooltip )
end


InitFrame()