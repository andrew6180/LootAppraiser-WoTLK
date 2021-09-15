-- LootAppraiser_Data.lua --
local LootAppraiser, LA = ...;

local Data = LA:NewModule("Data", "AceEvent-3.0", "AceConsole-3.0")

-- Lua APIs
local tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string, sort = 
	  tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string, sort

--local LA = LibStub("AceAddon-3.0"):GetAddon("LootAppraiser")
--local L = LibStub("AceLocale-3.0"):GetLocale("LootAppraiser", true)


-- LDB init
--[[
local ldb_object_lootAppraiser = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(ADDON_NAME.."Mission",
	{ 
		type = "data source",
		label = L["Garrison: Missions"],
		icon = "Interface\\Icons\\Inv_Garrison_Resource",
		text = L["Garrison: Missions"],
	}
)
]]


local UPDATEPERIOD, elapsed = 1, 0
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject("LootedItemValue", {type = "data source", text="0g", label = "Looted Item Value"})


local f = CreateFrame("frame")
f:SetScript("OnUpdate", 
	function(self, elap)
		elapsed = elapsed + elap
		if elapsed < UPDATEPERIOD then return end

		elapsed = 0

		local lootedItemValue
		local currentSession = LA:getCurrentSession()
		if currentSession ~= nil then
			lootedItemValue = currentSession["liv"] or 0
		else
			lootedItemValue = 0
		end

		dataobj.text = LA.TSM:FormatTextMoney(lootedItemValue)
	end
)


function dataobj:OnTooltipShow()
	self:AddLine(LA.METADATA.NAME .. " " .. LA.METADATA.VERSION)
	self:AddLine(" ") -- spacer

	local currentSession = LA:getCurrentSession()
	if currentSession ~= nil then
		local lootedItemValue = currentSession["liv"] or 0
		self:AddDoubleLine("|cFFFFFFFFLooted Item Value|r", "|cFFFFFFFF" .. tostring(LA.TSM:FormatTextMoney(lootedItemValue)) .. "|r")

		local currencyLooted = LA:getTotalLootedCurrency() or 0
		self:AddDoubleLine("|cFFFFFFFFCurrency Looted|r", "|cFFFFFFFF" ..  tostring(LA.TSM:FormatTextMoney(currencyLooted)) .. "|r")

		local itemsLooted = lootedItemCounter or 0
		self:AddDoubleLine("|cFFFFFFFFItems Looted|r", "|cFFFFFFFF" ..  tostring(itemsLooted) .. "|r")

		local noteworthyItemsLooted = LA:getNoteworthyItemCounter() or 0
		self:AddDoubleLine("|cFFFFFFFFNoteworthy Items|r", "|cFFFFFFFF" ..  tostring(noteworthyItemsLooted) .. "|r")
	else
		self:AddLine("Session not running")
	end
end


function dataobj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	dataobj.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end


function dataobj:OnLeave()
	GameTooltip:Hide()
end