-- LootAppraiser_TSM.lua --
local LA = LibStub("AceAddon-3.0"):GetAddon("LootAppraiser")

-- Lua APIs
local tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string, sort = 
	  tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string, sort


local TSM = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster")
if not TSM then return end

local TSMAPI = _G.TSMAPI;
local TSMVERSION = TSM._version;

LA.TSM = LA.TSM or {}
LA.TSM.v3 = string.startsWith("" .. TSMVERSION, "v3") or string.startsWith("" .. TSMVERSION, "3X")

--------------------------------
-- Wrapper for TSMAPI methods --
--------------------------------
function LA.TSM:isItemInGroup(itemID, group)
	if not LA.TSM.v3 then
		-- tsm 2
		local path = TSMAPI:GetGroupPath("item:" .. tostring(itemID))
		return path == group
	else
		-- tsm 3
		local path = TSMAPI.Groups:GetPath("i:" .. tostring(itemID))
		return path == group
	end
end


--[[-------------------------------------------------------------------------------------
-- this method encapsulate the spezial price source 'custom'
---------------------------------------------------------------------------------------]]
function LA.TSM:GetItemValue(itemID, priceSource)
	-- special handling for priceSource = 'Custom'
	if priceSource == "Custom" then
		LA:D("    price source (custom): " ..  LA.db.profile.pricesource.customPriceSource)
		if not LA.TSM.v3 then
			return TSMAPI:GetCustomPriceSourceValue(itemID, LA.db.profile.pricesource.customPriceSource) -- TSM2
		else 
			return TSMAPI:GetCustomPriceValue(LA.db.profile.pricesource.customPriceSource, itemID) -- TSM3
		end
	end

	-- TSM default price sources
	return TSMAPI:GetItemValue(itemID, priceSource)
end


function LA.TSM:GetItemID(itemString)
	if not LA.TSM.v3 then
		return TSMAPI:GetItemID(itemString, true) -- TSM2
	else 
		return TSMAPI.Item:ToItemID(itemString, true) -- TSM3
	end
end


function LA.TSM:FormatTextMoney(value) 
	local disabled -- ???
	if not LA.TSM.v3 then
		return TSMAPI:FormatTextMoney(value, nil, true, true, disabled) -- TSM2
	else
		return TSMAPI:MoneyToString(value, nil, true, true, disabled) -- TSM3
	end
end


function LA.TSM:ParseCustomPrice(value) 
	LA:Print("ParseCustomPrice(value=" .. tostring(value) .. ")")
	if not LA.TSM.v3 then
		return TSMAPI:ParseCustomPrice(value)
	else 
		return TSMAPI:ValidateCustomPrice(value)
	end
end


function LA.TSM:GetPriceSources()
	if not LA.TSM.v3 then
		return TSMAPI:GetPriceSources()
	else
		return select(1, TSMAPI:GetPriceSources())
	end
end


--[[-------------------------------------------------------------------------------------
-- returns a table with the filtered available price sources
---------------------------------------------------------------------------------------]]
function LA.TSM:GetAvailablePriceSources()
	local priceSources = {}
	local keys = {}

	-- filter
	local tsmPriceSources = LA.TSM:GetPriceSources()

	for k, v in pairs(tsmPriceSources) do
		if LA.PRICE_SOURCE[k] then
			table.insert(keys, k)
		end
	end

	-- add custom
	table.insert(keys, "Custom")
	sort(keys)

	for _,v in ipairs(keys) do
		priceSources[v] = LA.PRICE_SOURCE[v]
	end

	return priceSources
end