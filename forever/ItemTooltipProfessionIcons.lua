local _, ItemProfConstants = ...

local previousItemID = -1
local itemIcons

local ITEM_PROF_FLAGS = ItemProfConstants.ITEM_PROF_FLAGS
local PROF_TEXTURES = ItemProfConstants.PROF_TEXTURES
local NUM_PROFS

local iconSize
local QUEST_TEXT
local CRATE_TEXT

-- Ordered list of { flag, texture } entries used to build the icon line,
-- rebuilt by ConfigChanged (professions, then vendor, then Waylaid Crate)
local iconFilter

local showQuests
local profFilter
local questFilter

local t = {}



local function CreateItemIcons( itemFlags )

	for i=1, #t do t[ i ] = nil end

	local profFlags = bit.band( itemFlags, profFilter )
	if profFlags ~= 0 then
		for _, entry in ipairs( iconFilter ) do
			if bit.band( profFlags, entry.flag ) ~= 0 then
				t[ #t+1 ] = entry.texture
			end
		end
	end

	if showQuests then
		local questFlags = bit.band( itemFlags, questFilter )
		if questFlags ~= 0 then
			t[ #t+1 ] = QUEST_TEXT
		end
	end

	return table.concat( t )
end


local function ModifyItemTooltip( tt ) 

	local data = tt:GetPrimaryTooltipData()
	if not data then return end
	local itemID = data.id
	if itemID == nil then
		-- Try get the ID from link/guid
		local itemLink = data.hyperlink
		local itemGuid = data.guid
		if itemLink ~= nil then
			itemID = tonumber( string.match( itemLink, "item:?(%d+):" ) )
		elseif itemGuid ~= nil then
			itemID = C_Item.GetItemIDByGUID( itemGuid )
		end
		if itemID == nil then
			return
		end
	end
	
	-- Reuse the texture state if the item hasn't changed
	if previousItemID == itemID then
		tt:AddLine( itemIcons )
		return
	end
	
	-- Check if the item is a profession reagent
	local itemFlags = ITEM_PROF_FLAGS[ itemID ]
	if itemFlags == nil then
		return
	end
	
	-- Convert the flags into texture icons
	previousItemID = itemID
	itemIcons = CreateItemIcons( itemFlags )
	
	tt:AddLine( itemIcons )
end


function ItemProfConstants:ConfigChanged( config )

	showQuests = config.showQuests
	profFilter = config.profFlags

	NUM_PROFS = #PROF_TEXTURES - 1
	-- Config stores quest flags aligned with lsb
	questFilter = bit.lshift( config.questFlags, NUM_PROFS+1 ) -- offset vendor flag

	-- Refresh the strings used in icon construction
	if iconSize ~= config.iconSize then
		iconSize = config.iconSize
		local sizeStr = config.iconSize .. "|t "
--		DMF_TEXT = "|T134481:" .. sizeStr
		QUEST_TEXT = "|T132049:" .. sizeStr
		CRATE_TEXT = "|T" .. ItemProfConstants.CRATE_ICON .. ":" .. sizeStr
		for i=1, NUM_PROFS do
			PROF_TEXTURES[ i ] = string.sub( PROF_TEXTURES[ i ], 1, 9 ) .. sizeStr
		end
		-- Vendor texture appended to profs
		PROF_TEXTURES[ NUM_PROFS + 1 ] = "|A:SpellIcon-256x256-SellJunk:"..iconSize..":"..iconSize.."|a"
	end

	-- Merge vendor check/texture logic with professions
	if config.includeVendor then
		profFilter = profFilter + ItemProfConstants.VENDOR_ITEM_FLAG
	end

	-- Merge Waylaid Crate materials with professions
	if config.includeCrate then
		profFilter = profFilter + ItemProfConstants.CRATE_ITEM_FLAG
	end

	-- Rebuild the ordered flag/texture list (bit order: profs, vendor, crate)
	iconFilter = {}
	for i=1, NUM_PROFS do
		iconFilter[ #iconFilter+1 ] = { flag = bit.lshift( 1, i-1 ), texture = PROF_TEXTURES[ i ] }
	end
	if config.includeVendor then
		iconFilter[ #iconFilter+1 ] = { flag = ItemProfConstants.VENDOR_ITEM_FLAG, texture = PROF_TEXTURES[ NUM_PROFS + 1 ] }
	end
	if config.includeCrate then
		iconFilter[ #iconFilter+1 ] = { flag = ItemProfConstants.CRATE_ITEM_FLAG, texture = CRATE_TEXT }
	end

	previousItemID = -1		-- Reset line
end


TooltipDataProcessor.AddTooltipPostCall( Enum.TooltipDataType.Item, ModifyItemTooltip )
