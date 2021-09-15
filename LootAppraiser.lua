-- init ace stuff
local LootAppraiser, la = ...;
local LA = LibStub("AceAddon-3.0"):NewAddon(la, LootAppraiser, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "LibSink-2.0", "AceTimer-3.0")

local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local LibToast = LibStub("LibToast-1.0")
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

-- Lua APIs
local tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string = 
	  tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string

-- wow APIs
local _G,  GetRealZoneText, SecondsToTime, GameTooltip, GetContainerItemID, UseContainerItem, GetContainerItemLink, GetContainerNumSlots, GetMerchantItemInfo, GetMerchantNumItems, SendChatMessage, ResetInstances, IsInGroup, DeleteCursorItem, PickupContainerItem, GetRealmName, GetUnitName, GetCurrentMapAreaID, CreateFrame, UIFrameFadeIn, GetLootSlotInfo, GetLootSlotLink, PlaySoundFile, GetLootSlotType, GetNumLootItems, GetItemInfo, GetContainerItemInfo, UIParent, InterfaceOptionsFrame_OpenToCategory, IsShiftKeyDown, UIFrameFadeOut =
      _G,  GetRealZoneText, SecondsToTime, GameTooltip, GetContainerItemID, UseContainerItem, GetContainerItemLink, GetContainerNumSlots, GetMerchantItemInfo, GetMerchantNumItems, SendChatMessage, ResetInstances, IsInGroup, DeleteCursorItem, PickupContainerItem, GetRealmName, GetUnitName, GetCurrentMapAreaID, CreateFrame, UIFrameFadeIn, GetLootSlotInfo, GetLootSlotLink, PlaySoundFile, GetLootSlotType, GetNumLootItems, GetItemInfo, GetContainerItemInfo, UIParent, InterfaceOptionsFrame_OpenToCategory, IsShiftKeyDown, UIFrameFadeOut
local NUM_BAG_SLOTS, CHAT_FRAME_FADE_TIME, LE_PARTY_CATEGORY_INSTANCE, LE_PARTY_CATEGORY_HOME = 
      NUM_BAG_SLOTS, CHAT_FRAME_FADE_TIME, LE_PARTY_CATEGORY_INSTANCE, LE_PARTY_CATEGORY_HOME

LA.DEBUG = false

LA.METADATA = {
	NAME = GetAddOnMetadata(..., "Title"), 
	VERSION = GetAddOnMetadata(..., "Version")
}

-- GUI related local vars
-- frames
local START_SESSION_PROMPT, MAIN_UI, LITE_UI, LAST_NOTEWOTHYITEM_UI, TIMER_UI
local TIMER_UI_TAB, b1

-- single elements
local VALUE_TOTALCURRENCY, VALUE_LOOTEDITEMVALUE, VALUE_LOOTEDITEMCOUNTER, VALUE_NOTEWORTHYITEMCOUNTER, VALUE_ZONE, VALUE_SESSIONDURATION, dataContainer
local STATUSTEXT
local GUI_LOOTCOLLECTED, GUI_SCROLLCONTAINER
local BUTTON_STOPSESSION, BUTTON_RESETINSTANCES


local sessionIsRunning = false 			-- is currently a session running?
local startSessionPromptAlreadyAnswerd = false -- is the start session prompt already answered?
local lootAppraiserDisabled = false		-- is LootAppraiser disabled?

local currentSession = nil
local currentSessionID = nil
local sessionPause = 0
local pauseStart = nil

local totalLootedCurrency = 0   	-- the total looted currency during a session
local lootedItemCounter = 0			-- counter for looted items
local noteworthyItemCounter = 0		-- counter for noteworthy items
local totalItemLootedCounter = 0	-- counter for looted items (before filtering)

local savedLoot = {}
local lootCollectedLastEntry = nil  -- remember last element from loot collected list to add elements before this (on top of the list)

local ITEM_FILTER_VENDOR = {
	--DEFAULT ITEM IDs BELOW TO VENDORSELL PRICING
	["1205"] = true, ["3770"] = true, ["104314"] = true, ["11444"] = true, ["104314"] = true, ["11444"] = true, ["117437"] = true, ["117439"] = true, 
	["117442"] = true, ["117453"] = true, ["117568"] = true, ["1179"] = true, ["117"] = true, ["159"] = true, ["1645"] = true, ["1707"] = true, ["1708"] = true, 
	["17344"] = true, ["17404"] = true, ["17406"] = true, ["17407"] = true, ["19221"] = true, ["19222"] = true, ["19223"] = true, ["19224"] = true, ["19225"] = true, 
	["19299"] = true, ["19300"] = true, ["19304"] = true, ["19305"] = true, ["19306"] = true, ["2070"] = true, ["20857"] = true, ["21151"] = true, ["21215"] = true, 
	["2287"] = true, ["2593"] = true, ["2594"] = true, ["2595"] = true, ["2596"] = true, ["2723"] = true, ["27854"] = true, ["27855"] = true, ["27856"] = true, 
	["27857"] = true, ["27858"] = true, ["27859"] = true, ["27860"] = true, ["28284"] = true, ["28399"] = true, ["29453"] = true, ["29454"] = true, ["33443"] = true, 
	["33444"] = true, ["33445"] = true, ["33449"] = true, ["33451"] = true, ["33452"] = true, ["33454"] = true, ["35947"] = true, ["35948"] = true, ["35951"] = true, 
	["3703"] = true, ["37252"] = true, ["3771"] = true, ["3927"] = true, ["40042"] = true, ["414"] = true, ["41731"] = true, ["422"] = true, ["44570"] = true, 
	["44940"] = true, ["44941"] = true, ["4536"] = true, ["4537"] = true, ["4538"] = true, ["4539"] = true, ["4540"] = true, ["4541"] = true, ["4542"] = true, 
	["4544"] = true, ["4592"] = true, ["4593"] = true, ["4594"] = true, ["4595"] = true, ["4599"] = true, ["4600"] = true, ["4601"] = true, ["4602"] = true, 
	["4604"] = true, ["4605"] = true, ["4606"] = true, ["4607"] = true, ["4608"] = true, ["58256"] = true, ["58257"] = true, ["58258"] = true, ["58259"] = true, 
	["58260"] = true, ["58261"] = true, ["58262"] = true, ["58263"] = true, ["58264"] = true, ["58265"] = true, ["58266"] = true, ["58268"] = true, 
	["58269"] = true, ["59029"] = true, ["59230"] = true, ["61982"] = true, ["61985"] = true, ["61986"] = true, ["73260"] = true, ["74822"] = true, ["787"] = true, 
	["81400"] = true, ["81401"] = true, ["81402"] = true, ["81403"] = true, ["81404"] = true, ["81405"] = true, ["81406"] = true, ["81407"] = true, 
	["81408"] = true, ["81409"] = true, ["81410"] = true, ["81411"] = true, ["81412"] = true, ["81413"] = true, ["81414"] = true, ["81415"] = true, 
	["8766"] = true, ["8932"] = true, ["8948"] = true, ["8950"] = true, ["8952"] = true, ["8953"] = true, ["9260"] = true, ["20404"] = true	
}

local ITEM_FILTER_BLACKLIST = {
	--These items are from AQ20.  All of the Idols and Scarabs are Blacklisted.
	["20858"] = true, ["20859"] = true, ["20860"] = true, ["20861"] = true, ["20862"] = true, ["20863"] = true, ["20864"] = true, ["20865"] = true, 
	["20874"] = true, ["20866"] = true, ["20868"] = true, ["20869"] = true, ["20870"] = true, ["20871"] = true, ["20872"] = true, ["20873"] = true, 
	["20867"] = true, ["20875"] = true, ["20876"] = true, ["20877"] = true,	["20878"] = true, ["20879"] = true, ["20881"] = true, ["20882"] = true, 
	["19183"] = true, ["18640"] = true, ["8623"]  = true, ["114120"] = true, ["114116"] = true, ["9243"] = true
}

LA.QUALITY_FILTER = { -- little hack to sort them in the menu
	["0"] = "|cff9d9d9dPoor|r", 
	["1"] = "|cffffffffCommon|r", 
	["2"] = "|cff1eff00Uncommon|r", 
	["3"] = "|cff0070ddRare|r", 
	["4"] = "|cffa335eeEpic|r"
};

-- TSM predefined price sources + 'Custom'
LA.PRICE_SOURCE = {
	-- TSM price sources
	["Custom"] = "Custom Price Source",
	["DBGlobalHistorical"] = "AuctionDB: Global Historical Price",
	["DBGlobalMarketAvg"] = "AuctionDB: Global Market Value Avg",
	["DBGlobalMinBuyoutAvg"] = "AuctionDB: Global Min Buyout Avg",
	["DBGlobalSaleAvg"] = "AuctionDB: Global Sale Average",
	["DBHistorical"] = "AuctionDB: Historical Price",
	["DBMarket"] = "AuctionDB: Market Value",
	["DBMinBuyout"] = "AuctionDB: Min Buyout",
	["DBRegionHistorical"] = "AuctionDB: Region Historical Price",
	["DBRegionMarketAvg"] = "AuctionDB: Region Market Value Avg",
	["DBRegionMinBuyoutAvg"] = "AuctionDB: Region Min Buyout Avg",
	["DBRegionSaleAvg"] = "AuctionDB: Region Global Sale Average",
	["VendorSell"] = "VendorSell: Sell to Vendor cost",
	["wowuctionMarket"] = "wowuction: Realm Market Value",
	["wowuctionMedian"] = "wowuction: Realm Median Price",
	["wowuctionRegionMarket"] = "wowuction: Region Market Value",
	["wowuctionRegionMedian"] = "wowuction: Region Median Price",
	-- TUJ price sources
	["globalMedian"] = "TUJ: Global Median",
	["globalMean"] = "TUJ: Global Mean",
	["globalStdDev"] = "TUJ: Global Std Dev",
	["stddev"] = "TUJ: 14-Day Std Dev",
	["market"] = "TUJ: 14-Day Price",
	["recent"] = "TUJ: 3-Day Price",
};


-- define toast template
LibToast:Register(LootAppraiser, 
	function(toast, text, iconTexture, qualityID, amountGained, itemValue)
		local _, _, _, hex = _G.GetItemQualityColor(qualityID)

		toast:SetFormattedTitle("|c%s%s|r %s", hex, text, amountGained > 1 and _G.PARENS_TEMPLATE:format(amountGained) or "")
		toast:SetText(itemValue)

		if iconTexture then
			toast:SetIconTexture(iconTexture)
		end
	end
)


--[[-------------------------------------------------------------------------------------
-- hook for add lines to item tooltip
---------------------------------------------------------------------------------------]]
local lineAdded = false
local function OnTooltipSetItem(tooltip, ...)
	if not lineAdded then
		local _, link = tooltip:GetItem()

		local itemID = LA.TSM:GetItemID(link)

		local data = LA.db.global.drops[itemID]
		if data then
			tooltip:AddLine("|cFFFFFF00" .. LA.METADATA.NAME .. " - Drop Info|r") -- headline
			for mapID, count in pairs(data) do
				local mapName =  GetRealZoneText()
				if mapName then
					-- add drop count
					tooltip:AddDoubleLine("|cFFFFFFFF  " .. mapName .. "|r", "|cFFFFFFFF" .. tostring(count) .. " drop(s)|r")
				end
			end
		end

		-- calc drop chance
		local sessions = LA.db.global.sessions
		local itemCount = 0
		local fullItemCount = 0
		for index, session in ipairs(sessions) do
			local count = session.noteworthyItems[tostring(itemID)]
			if count ~= nil then
				itemCount = itemCount + count
				fullItemCount = fullItemCount + session.totalItemsLooted
			end
		end

		if itemCount > 0 then
			local dropChance = LA:round((100 / fullItemCount * itemCount), 2)

			tooltip:AddDoubleLine("|cFFFFFF00Dropchance:|r", "|cFFFFFFFF" .. tostring(dropChance) .. "%|r")
		end

		lineAdded = true
	end
end


--[[-------------------------------------------------------------------------------------
-- hook for add lines to item tooltip (save function to add lines only once)
---------------------------------------------------------------------------------------]]
local function OnTooltipCleared(tooltip, ...)
   lineAdded = false
end


--[[-------------------------------------------------------------------------------------
-- AceAddon-3.0 standard methods
---------------------------------------------------------------------------------------]]
function LA:OnInitialize()
	self:Debug("LA:OnInitialize()")

	self:initDB()

	-- price source check --
	local priceSources = self.TSM:GetAvailablePriceSources()

	-- only 2 or less price sources -> chat msg: missing modules
	if self:tablelength(priceSources) <= 2 then
		-- chat msg
		self:Print("|cffff0000Attention!|r Missing TSM Modules for additional price sources (e.g. like TradeSkillMaster_AuctionDB for AuctionDB price sources).")
		self:Print("|cffff0000LootAppraiser disabled.|r")
		self:Disable()
		return
	else
		-- current preselected price source
		local priceSource = self:getPriceSource() -- die voreingestellte Preisquelle von LA

		-- price source 'custom'
		if priceSource == "Custom" then
			-- validate 'custom' price source 
			local isValidCustomPriceSource = self.TSM:ParseCustomPrice(self:getCustomPriceSource())
			if not isValidCustomPriceSource then
				-- invalid -> chat msg: invalid 'custom' price source
				self:Print("|cffff0000Attention!|r You have selected 'Custom' as price source but your formular ist invalid (see TSM documentation for detailed custom price source informations).")
				self:Print(self:getCustomPriceSource())
			end
		else
			-- normal price source check against prepared list
			if not priceSources[priceSource] then
				-- invalid -> chat msg: invalid price source
				self:Print("|cffff0000Attention!|r Your selected price source is not valid (maybe due to a missing TSM module). Please select another price source or install the needed TSM module for the selected price source (see TSM documentation).")
			end
	 	end
	end

	self:SetSinkStorage(self.db.profile.notification.sink)

	-- prepare minimap icon --
	self.LibDBIcon = LibStub("LibDBIcon-1.0")
	self.LibDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject(LA.METADATA.NAME, {
		type = "launcher",
		text = "Loot Appraiser", -- for what?
		icon = "Interface\\Icons\\Ability_Racial_PackHobgoblin",

		OnClick = function(self, button, down)
			if button == "LeftButton" then
				local isShiftKeyDown = IsShiftKeyDown()
				if isShiftKeyDown then

				else

				end

				if not LA:isSessionRunning() then
			        LA:StartSession(true)        
			    end

			    LA:ShowMainWindow(true)



			elseif button == "RightButton" then
				LA:Print("Open LootAppraiser Configuration")

				InterfaceOptionsFrame_OpenToCategory(LA.METADATA.NAME)
				InterfaceOptionsFrame_OpenToCategory(LA.METADATA.NAME)
			end
		end,

		OnTooltipShow = function (tooltip)
			tooltip:AddLine(LA.METADATA.NAME .. " " .. LA.METADATA.VERSION, 1 , 1, 1)
			tooltip:AddLine("|cFFFFFFCCLeft-Click|r to open the main window")
			tooltip:AddLine("|cFFFFFFCCRight-Click|r to open options window")
			tooltip:AddLine("|cFFFFFFCCDrag|r to move this button")
			tooltip:AddLine(" ") -- spacer

			if self:isSessionRunning() then
				local offset
				if pauseStart ~= nil then
					offset = pauseStart -- session is paused
				else
					offset = time() -- session is running
				end

				local delta = offset - currentSession["start"] - sessionPause

				-- don't show seconds
				local noSeconds = false
				if delta > 3600 then
					noSeconds = true
				end

				local text = "Session is "
				if pauseStart ~= nil then
					text = text .. "paused: "
				else
					text = text .. "running: "
				end

				tooltip:AddDoubleLine(text, SecondsToTime(delta, noSeconds, false))
			else
				tooltip:AddLine("Session is not running")
			end

			-- if module present we add the additional modul informations
			if self.regModules then
				for name, module in pairs(self.regModules) do
					if module.icon and module.icon.tooltip then
						-- add lines
						tooltip:AddLine(" ") -- spacer

						for _, line in pairs(module.icon.tooltip) do
							tooltip:AddLine(line)
						end
					end
				end
			end
		end
	})
	self.LibDBIcon:Register(LA.METADATA.NAME, self.LibDataBroker, self.db.profile.minimapIcon)

	-- hook into tooltip to add lines
	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
end


function LA:OnEnable()
	LA:Print("ENABLED.")

	-- register chat commands
	LA:RegisterChatCommand("la", LA.chatCmdLootAppraiser)
	LA:RegisterChatCommand("lal", LA.chatCmdLootAppraiserLite)
	LA:RegisterChatCommand("laa", LA.chatCmdGoldAlertTresholdMonitor)

	LA:RegisterChatCommand("lat", LA.test)

	-- register event for...
	-- ...looting items
	LA:RegisterEvent("LOOT_OPENED", LA.OnLootReady)
	LA:RegisterEvent("BAG_UPDATE", LA.OnBagUpdate)
	-- ...looting currency
	LA:RegisterEvent("CHAT_MSG_MONEY", LA.OnChatMsgMoney)

	-- register event for reset instance
	--LA:RegisterEvent("CHAT_MSG_SYSTEM", LA.OnResetInfoEvent)
	LA:RegisterEvent("CHAT_MSG_SYSTEM", LA.OnChatMsgSystem)

	-- set DEBUG=true if player is Netatik-Antonidas --
	local nameString = GetUnitName("player", true)
	local realm = GetRealmName()

	if (nameString == "xNetatik" or nameString == "xSailas") and realm == "Antonidas" then
		self:Debug("DEBUG enabled")
		LA.DEBUG = true
	end

	--TUJTooltip(true)
end

function LA.test()
	LA.OnChatMsgSystem("CHAT_MSG_SYSTEM", "'Hügel der Klingenhauer' wurde zurückgesetzt.")
end


--[[-------------------------------------------------------------------------------------
-- reset instance historie
---------------------------------------------------------------------------------------]]
LA.ResetInfo = {}
local resetmsg = INSTANCE_RESET_SUCCESS:gsub("%%s",".+")

function LA.OnChatMsgSystem(event, msg)
	if event == "CHAT_MSG_SYSTEM" then
		if msg:match("^" .. resetmsg .. "$") then
			LA:D("  match: " .. tostring(msg:match("^" .. resetmsg .. "$")))

			local instanceName = string.match(msg, INSTANCE_RESET_SUCCESS:gsub("%%s","(.+)"))
			LA.ResetInfo[time() + 60*60] = instanceName

			if BUTTON_RESETINSTANCES then
				BUTTON_RESETINSTANCES:SetText("Reset Instances (" .. LA:tablelength(LA.ResetInfo) .. "/10)") -- add lockouts
			end
		end
	end
end


--[[
function LA.doExplicitReset(instancemsg, failed)
	LA:D("LA.doExplicitReset: instancemsg=" .. tostring(instancemsg) .. ", failed=" .. tostring(failed))
	if HasLFGRestrictions() or IsInInstance() or (LA:InGroup() and not UnitIsGroupLeader("player")) then return end
	if not failed then
		LA:D("  ### ich war da ###")
		LA:HistoryUpdate(true)
	end

	local reportchan = LA:InGroup()
	if reportchan then
		if not failed then
			--SendAddonMessage(addonName, "GENERATION_ADVANCE", reportchan)
		end
		if true then -- vars.db.Tooltip.ReportResets
			local msg = instancemsg or RESET_INSTANCES
			msg = msg:gsub("\1241.+;.+;","") -- ticket 76, remove |1;; escapes on koKR
			SendChatMessage("<LA> "..msg, reportchan)
		end
	end
end
--hooksecurefunc("ResetInstances", LA.doExplicitReset)


local resetfails = { INSTANCE_RESET_FAILED, INSTANCE_RESET_FAILED_OFFLINE, INSTANCE_RESET_FAILED_ZONING }
for k,v in pairs(resetfails) do 
  resetfails[k] = v:gsub("%%s",".+")
end
local raiddiffmsg = ERR_RAID_DIFFICULTY_CHANGED_S:gsub("%%s",".+")
local dungdiffmsg = ERR_DUNGEON_DIFFICULTY_CHANGED_S:gsub("%%s",".+")
local delaytime = 3 -- seconds to wait on zone change for settings to stabilize

function LA.OnChatMsgSystem(f, evt, msg)
	LA:D("LA.OnChatMsgSystem: evt=" .. tostring(f) .. ", msg=" .. tostring(evt))
	if evt == "CHAT_MSG_SYSTEM" then
    	--local msg = ...
		if msg:match("^"..resetmsg.."$") then -- I performed expicit reset
			LA.doExplicitReset(msg)
		elseif msg:match("^"..INSTANCE_SAVED.."$") then -- just got saved
			LA:ScheduleTimer("HistoryUpdate", delaytime+1)
		elseif (msg:match("^"..raiddiffmsg.."$") or msg:match("^"..dungdiffmsg.."$")) and 
			not addon:histZoneKey() then -- ignore difficulty messages when creating a party while inside an instance
			LA:HistoryUpdate(true)
		elseif msg:match(TRANSFER_ABORT_TOO_MANY_INSTANCES) then
			LA:HistoryUpdate(false, true)
		else
			for _, m in pairs(resetfails) do 
				if msg:match("^"..m.."$") then
					LA.doExplicitReset(msg, true) -- send failure chat message
				end
			end
		end
    end
end


function LA:InGroup() 
	if IsInRaid() then 
		return "RAID"
	elseif GetNumGroupMembers() > 0 then 
		return "PARTY"
	else 
		return nil 
	end
end
]]


function LA:OnDisable()
	-- nothing to do
end


function LA:RegisterModule(theModule)
	LA:D("RegisterModule")

	if not self.regModules then
		self.regModules = {}
	end

	self.regModules[theModule.name] = theModule
end


function LA.OnChatMsgMoney(event, msg)
	if not LA:isSessionRunning() then return end
	
	LA:D("  OnChatMsgMoney: msg=%s", tostring(msg))

	local lootedCopper = LA:getLootedCopperFromText(msg)

	LA:D("    lootedCopper=%s", tostring(lootedCopper))
	LA:handleCurrencyLooted(lootedCopper)
end

--[[-------------------------------------------------------------------------------------
-- init lootappraiser db
---------------------------------------------------------------------------------------]]
function LA:initDB()
	self:Debug("LA:initDB()")

	local parentWidth = UIParent:GetWidth()
	local parentHeight = UIParent:GetHeight()

	-- la defaults
	self.dbDefaults = {
		profile = {
			enableDebugOutput = false,
			-- minimap icon position and visibility
			minimapIcon = { hide = false, minimapPos = 220, radius = 80, },
			mainUI = { ["height"] = 400, ["top"] = (parentHeight-50), ["left"] = 50, ["width"] = 400, },
			timerUI = { ["height"] = 32, ["top"] = (parentHeight+55), ["left"] = 50, ["width"] = 400, },
			challengeUI = { ["height"] = 400, ["top"] = (parentHeight-50), ["left"] = 50, ["width"] = 400, },
			liteUI = { ["height"] = 32, ["top"] = (parentHeight+20), ["left"] = 50, ["width"] = 400, },
			lastNotewothyItemUI = { ["height"] = 32, ["top"] = (parentHeight-15), ["left"] = 50, ["width"] = 400, },
			startSessionPromptUI = { },
			general = { ["qualityFilter"] = "2", ["goldAlertThreshold"] = "100", ["ignoreRandomEnchants"] = true, ["surpressSessionStartDialog"] = false, },
			pricesource = { ["source"] = "DBGlobalMarketAvg", },
			notification = { ["sink"] = { ["sink20Sticky"] = false, ["sink20OutputSink"] = "Blizzard", }, ["enableToasts"] = true, ["playSoundEnabled"] = true, ["soundName"] = "Auction Window Open", },
			sellTrash = { ["tsmGroupEnabled"] = false, ["tsmGroup"] = "LootAppraiser`Trash", },
			blacklist = { ["tsmGroupEnabled"] = false, ["tsmGroup"] = "LootAppraiser`Blacklist", ["addBlacklistedItems2DestroyTrash"] = false, },
			display = { lootedItemListRowCount = 5, showZoneInfo = true, showSessionDuration = true, showLootedItemValue = true, showLootedItemValuePerHour = true, showCurrencyLooted = true, showItemsLooted = true, showNoteworthyItems = true, enableLastNoteworthyItemUI = false, enableLootAppraiserLite = false, enableLootAppraiserTimerUI = false, },
			sessionData = { groupBy = "datetime", },
			challenge = { },
		},
		global = { sessions = { }, drops = { }, },
	}
	
	-- load the saved db values
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("LootAppraiserDB", self.dbDefaults, true)
end


--[[-------------------------------------------------------------------------------------
-- open gold alert treshold monitor
---------------------------------------------------------------------------------------]]
function LA.chatCmdGoldAlertTresholdMonitor()
    if not LA:isSessionRunning() then
        LA:StartSession(true)        
    end

    LA:ShowLastNoteworthyItemWindow()
end


--[[-------------------------------------------------------------------------------------
-- open loot appraiser and start a new session
---------------------------------------------------------------------------------------]]
function LA.chatCmdLootAppraiser(input)
    if not LA:isSessionRunning() then
        LA:StartSession(true)        
    end

    LA:ShowMainWindow(true)

    -- for debug only (no official option)
    if input == "event" then			
		MAIN_UI.frame:SetScript("OnEvent", 
			function (self, event, ...) 
				-- filter events
				if string.startsWith(event, "CHAT_MSG_") and event ~= "CHAT_MSG_ADDON" then --string.startsWith(event, "LOOT_") or
					-- prepare event parameters
					local variables = ""
					for n=1,select('#',...) do
						if n > 1 then
							variables = variables .. "; "
						end
						variables = variables .. tostring(select(n,...))
					end

					LA:D("### event=" .. tostring(event) .. " with " .. tostring(variables)) 
				end
			end
		)
		MAIN_UI.frame:RegisterAllEvents()
		LA:Print("Debug: events activated")
	end

	if input == "debug" then
		LA.DEBUG = true
		LA:Debug("Debug: enabled")
	end
end


--[[-------------------------------------------------------------------------------------
-- open loot appraiser lite and start a new session
---------------------------------------------------------------------------------------]]
function LA.chatCmdLootAppraiserLite()
    if not LA:isSessionRunning() then
        LA:StartSession(false)        
    end

    LA:ShowLiteWindow()
end


--[[-------------------------------------------------------------------------------------
-- event handler
---------------------------------------------------------------------------------------]]
local currentSavedLoot = {}
local currentBagSnapshots = {}


function LA.OnBagUpdate(event, bagID)
	-- is LootAppraiser running?
	if lootAppraiserDisabled then return end
	if not LA:isSessionRunning() then return end

	if bagID > NUM_BAG_SLOTS then return end -- we only monitor our char bags

	local bagSnapshot = currentBagSnapshots[bagID]
	if bagSnapshot == nil then return end
	--LA:D("  bagSnapshot=" .. tostring(bagSnapshot))

	--LA:D("event:OnBagUpdate with bagID=%s", tostring(bagID))

	for slot = 1, GetContainerNumSlots(bagID), 1 do
		local currentItemID = GetContainerItemID(bagID, slot)
		local currentCount = select(2, GetContainerItemInfo(bagID, slot))

		-- prepare key and value
		local key = tostring(slot)
		local currentValue = "" .. tostring(currentItemID) .. ":" .. tostring(currentCount)

		local value = bagSnapshot[key]
		if value ~= currentValue then
			LA:D("  value at slot %s changed from %s to %s" , tostring(slot), tostring(value), currentValue)

			-- check against saved loot
			local data = currentSavedLoot[currentItemID]
			if data ~= nil then
				if data["multiNonStackItem"] == true then
					--LA:D("  |cffff0000non-stackable item -> not removing|r")
				else
					currentSavedLoot[currentItemID] = nil -- remove from saved loot
				end

				local itemLink = data["link"]
				local quantity = data["quantity"]
				local itemID = data["itemID"]

				LA:D("    handle item %s", data["link"])
				LA:handleItemLooted(itemLink, itemID, quantity)
			else
				LA:D("    ignore bag update of item " .. tostring(currentItemID))
			end

			-- set new value
			bagSnapshot[key] = currentValue
		end
	end
end


function LA.OnLootReady( ... )
	-- is LootAppraiser running?
	if lootAppraiserDisabled then return end

	-- is a loot appraiser session running?
	if not LA:isSessionRunning() then
		-- no session -> should we ask for session start?
		if not startSessionPromptAlreadyAnswerd and not LA:isSurpressSessionStartDialog() then
			-- save current loot
			LA:saveCurrentLoot()

			-- and open dialog
			LA:ShowStartSessionDialog()
		end
	else
		-- pause
		if pauseStart ~= nil then
			LA:restartSession()
		end

		-- clear the table
		currentSavedLoot = {}

		if GetNumLootItems() < 1 then
			LA:ScheduleTimer(LA.OnLootReady, 1)
		end
		-- save current loot
		for i = 1, GetNumLootItems() do
			local slotType = select(4, GetLootSlotInfo(i))
			LA:Debug(tostring(slotType))
			if slotType >= 1 then
				-- item looted
				local itemLink = GetLootSlotLink(i)
				local itemID = LA.TSM:GetItemID(itemLink, true) -- get item id

				local quantity = select(3, GetLootSlotInfo(i))

				local data = {}
				data["link"] = itemLink
				data["quantity"] = quantity
				data["itemID"] = itemID

				-- check for already existing itemID
				if currentSavedLoot[itemID] then
					-- add flag to signal multiple non stacking items
					data["multiNonStackItem"] = true
				end

				-- save data
				currentSavedLoot[itemID] = data

			elseif slotType == 0 then
				-- currency looted

				--local lootedCoin = select(2, GetLootSlotInfo(i))
				--local lootedCopper = LA:getLootedCopperFromText(lootedCoin)

				--LA:handleCurrencyLooted(lootedCopper)
			end
		end

		-- save current bag content
		for bagID = 0, NUM_BAG_SLOTS, 1 do
			local bagSnapshot = {}

			for slot = 1, GetContainerNumSlots(bagID), 1 do
				local itemID = GetContainerItemID(bagID, slot)
				local count = select(2, GetContainerItemInfo(bagID, slot))

				-- prepare key and value
				local key = tostring(slot)
				local value = "" .. tostring(itemID) .. ":" .. tostring(count)

				bagSnapshot[key] = value
			end

			currentBagSnapshots[bagID] = bagSnapshot
		end

		-- todo: remove
		--[[
		LA:D("event:OnLootReady")
		for key, value in pairs(currentSavedLoot) do
			local data = ""
			for k,v in pairs(value) do
				data = data .. tostring(k) .. "=" .. tostring(v) .. "; "
			end
			LA:D("  key=" .. key .. "; value=" .. data)
		end
		]]
	end
end


--[[-------------------------------------------------------------------------------------
-- the main logic for item processing
---------------------------------------------------------------------------------------]]
local mapIDItemCount = {}
function LA:handleItemLooted(itemLink, itemID, quantity)
	self:Debug("handleItemLooted itemID=%s", itemID)
	LA:D("  " .. tostring(itemID) .. ": handle item: " .. itemLink .. " x" .. tostring(quantity))

    local quality = select(3, GetItemInfo(itemID)) or 0

    if quantity ~= nil then
    	totalItemLootedCounter = totalItemLootedCounter + quantity
    end

    -- overwrite link if we only want base items					
	if LA:getIgnoreRandomEnchants() then
		itemLink = select(2, GetItemInfo(itemID)) -- we use the link from GetItemInfo(...) because GetLootSlotLink(...) returns not the base item
	end

	LA:D("  " .. tostring(itemID) .. ": price source (before checks): " .. tostring(LA:getPriceSource()))
    local singleItemValue = LA.TSM:GetItemValue(itemID, LA:getPriceSource()) or 0 -- single item

    --[[
    if TUJMarketInfo then
    	local o = {}
    	TUJMarketInfo(itemID, o)

    	LA:print_r(o)
    end
    ]]
		
	LA:D("  " .. tostring(itemID) .. ": single item value (before checks): " .. tostring(singleItemValue))

    -- blacklisted items
    if LA:isItemBlacklisted(itemID) then
    --if ITEM_FILTER_BLACKLIST[tostring(itemID)] then

		self:Debug("  item filter blacklist -> ignored")
		LA:D("  " .. tostring(itemID) .. ": blacklisted -> ignore")
		return

    elseif quality >= LA:getQualityFilter() then
		LA:D("  " .. tostring(itemID) .. ": item quality (" .. tostring(quality) .. ") >= filter (" .. LA:getQualityFilter() .. ")")

    	-- special handling for poor quality items
    	if quality == 0 then
    		self:Debug("  poor quality -> VendorSell")
			LA:D("  " .. tostring(itemID) .. ": poor quality -> price source 'VendorSell'")

			singleItemValue = LA.TSM:GetItemValue(itemID, "VendorSell") or 0
		end

		-- special handling for item filter vendor sell
		if ITEM_FILTER_VENDOR[tostring(itemID)] then
			self:Debug("  item filter vendor -> VendorSell")
			LA:D("  " .. tostring(itemID) .. ": item filtered by vendor list -> price source 'VendorSell'")

			singleItemValue = LA.TSM:GetItemValue(itemID, "VendorSell") or 0
		end

		-- special handling for soulbound items
		if singleItemValue == 0 and quality >= 1 then
			self:Debug("  item value = 0 -> soulbound item")
			LA:D("  " .. tostring(itemID) .. ": soulbound item -> price source 'VendorSell'")

			singleItemValue = LA.TSM:GetItemValue(itemID, "VendorSell") or 0
		end
		
		LA:D("  " .. tostring(itemID) .. ": single item value (after checks): " .. tostring(singleItemValue))

    	local itemValue = singleItemValue * quantity

		LA:D("  " .. tostring(itemID) .. ": total item(s) value: " .. tostring(itemValue))

		LA:incLootedItemCounter(quantity)											-- increase looted item counter
		LA:addItemValue2LootedItemValue(itemValue) 									-- add item value
		LA:addItem2LootCollectedList(itemID, itemLink, quantity, itemValue, false)	-- add item

		-- gold alert treshold
		local goldValue = floor(singleItemValue/10000)	
		if goldValue >= LA:getGoldAlertThreshold() then
			LA:D("  " .. tostring(itemID) .. ": gold value (" .. tostring(goldValue) .. ") >= gold alert threshold (" .. LA:getGoldAlertThreshold() .. ")")

			-- inc noteworthy items counter
			LA:incNoteworthyItemCounter(quantity)

			-- print to configured output 'channel'
			local formattedValue = LA.TSM:FormatTextMoney(singleItemValue) or 0
			LA:Pour(itemLink .. " x" .. quantity .. ": " .. formattedValue)

			-- last noteworthy item ui
			if LAST_NOTEWOTHYITEM_UI then
				LAST_NOTEWOTHYITEM_UI:SetTitle(itemLink .. "|cffffffff x" .. quantity .. ": " .. formattedValue .. "|r")
			end

			-- toast
			if LA:isToastsEnabled() then
				local name, _, _, _, _, _, _, _, _, texturePath = _G.GetItemInfo(itemID)
				LibToast:Spawn(LootAppraiser, name, texturePath, quality, quantity, formattedValue)
			end

			-- add item to current session
			local itemCountCurrentSession = currentSession.noteworthyItems[tostring(itemID)]
			if itemCountCurrentSession == nil then
				currentSession.noteworthyItems[tostring(itemID)] = quantity
			else
				currentSession.noteworthyItems[tostring(itemID)] = itemCountCurrentSession + quantity
			end

			-- add item to drops
			local drops = self.db.global.drops
			local itemDrops = drops[itemID]
			if itemDrops == nil then
				itemDrops = {}
				drops[itemID] = itemDrops
			end

			local mapCounter = itemDrops[GetCurrentMapAreaID()]
			if mapCounter == nil then
				mapCounter = quantity
			else
				mapCounter = mapCounter + quantity
			end
			itemDrops[GetCurrentMapAreaID()] = mapCounter

			-- play sound (if enabled)
			if LA:isPlaySoundEnabled() then
				--PlaySound("AuctionWindowOpen", "master");
				local soundName = self.db.profile.notification.soundName or "None"
				PlaySoundFile(LSM:Fetch("sound", soundName), "master")
			end

			-- check current mapID with session mapID
			if currentSession["mapID"] ~= GetCurrentMapAreaID() then
				self:Debug("  current vs. session mapID: %s vs. %s" , GetCurrentMapAreaID(), currentSession["mapID"])

				-- quick fix: if we loot a noteworthy item we change the map id
				currentSession["mapID"] = GetCurrentMapAreaID()
			end
		else
			LA:D("  " .. tostring(itemID) .. ": gold value (" .. tostring(goldValue) .. ") < gold alert threshold (" .. LA:getGoldAlertThreshold() .. ") -> no ding")
		end

		LA:refreshUIs()

		-- modules callback
		if self.regModules then
			for name, data in pairs(self.regModules) do
				if data and data.callback and data.callback.itemDrop then
					local callback = data.callback.itemDrop

					callback(itemID, singleItemValue)
				end
			end
		end
	else
		self:Debug("  item quality to low -> ignored")
		LA:D("  " .. tostring(itemID) .. ": item quality (" .. tostring(quality) .. ") < filter (" .. LA:getQualityFilter() .. ") -> ignore item")
    end
end

--[[-------------------------------------------------------------------------------------
-- handle looted currency
---------------------------------------------------------------------------------------]]
function LA:handleCurrencyLooted(lootedCopper)
	-- add to total looted currency 
	totalLootedCurrency = totalLootedCurrency + lootedCopper 
	LA:D("  handle currency: add " .. tostring(lootedCopper) .. " copper -> new total: " .. tostring(totalLootedCurrency))

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if LA:isDisplayEnabled("showCurrencyLooted") then
			-- format the total looted currency and add to main ui
			local formattedValue = LA.TSM:FormatTextMoney(totalLootedCurrency) or 0
			VALUE_TOTALCURRENCY:SetText(formattedValue)
		end
	end
end

--[[-------------------------------------------------------------------------------------
-- save the current loot during 'start session?' dialog so we miss no loot if we start
-- a new session
---------------------------------------------------------------------------------------]]
function LA:saveCurrentLoot()
	if not LA:tablelength(savedLoot) == 0 then self:Debug("savedLoot is not empty...") end

	savedLoot = {}

	for i = 1, GetNumLootItems() do
		local slotType =  select(4, GetLootSlotInfo(i))

		if slotType >= 1 then
			-- item looted
			self:Debug("item looted (save)")
				
			-- Get Information about Item Looted --
			local itemLink = GetLootSlotLink(i)
			local itemID = LA.TSM:GetItemID(itemLink, true) -- get item id

			local quantity = select(3, GetLootSlotInfo(i))

			self:Debug("  item=%s", tostring(itemID))

			local data = {}
			data["link"] = itemLink
			data["quantity"] = quantity
			data["itemID"] = itemID

			savedLoot[tostring(i)] = data

		elseif slotType == 0 then
			-- currency looted
			self:Debug("currency looted (save)")

			local lootedCoin = select(2, GetLootSlotInfo(i))
			local lootedCopper = LA:getLootedCopperFromText(lootedCoin)

			self:Debug("  lootedCopper=%s", tostring(lootedCopper))

			local data = {}
			data["currency"] = lootedCopper

			savedLoot[tostring(i)] = data
		end

		self:Debug("  savedLoot=%s", tostring(LA:tablelength(savedLoot)))
	end
end

--[[-------------------------------------------------------------------------------------
-- GUIs
---------------------------------------------------------------------------------------]]


--[[-------------------------------------------------------------------------------------
-- the last noteworthy item ui
---------------------------------------------------------------------------------------]]
function LA:ShowLastNoteworthyItemWindow()
	self:Debug("ShowLastNoteworthyItemWindow")

	if LAST_NOTEWOTHYITEM_UI then
		LAST_NOTEWOTHYITEM_UI:Show()
		return 
	end

	LAST_NOTEWOTHYITEM_UI = AceGUI:Create("LALiteWindow")
	LAST_NOTEWOTHYITEM_UI:Hide()
	LAST_NOTEWOTHYITEM_UI:SetStatusTable(self.db.profile.lastNotewothyItemUI)
	LAST_NOTEWOTHYITEM_UI:SetWidth(350)
	LAST_NOTEWOTHYITEM_UI:SetHeight(30)

	LAST_NOTEWOTHYITEM_UI:SetTitle("Gold Alert Threshold")

	LAST_NOTEWOTHYITEM_UI:Show()
end


--[[-------------------------------------------------------------------------------------
-- the lite ui
---------------------------------------------------------------------------------------]]
function LA:ShowLiteWindow()
	self:Debug("ShowLiteWindow")

	if LITE_UI then
		LITE_UI:Show()
		return 
	end

	LITE_UI = AceGUI:Create("LALiteWindow")
	LITE_UI:Hide()
	LITE_UI:SetStatusTable(self.db.profile.liteUI)
	LITE_UI:SetWidth(150)
	LITE_UI:SetHeight(30)
	--LITE_UI:EnableResize(false)

	local totalItemValue = currentSession["liv"] or 0
	LITE_UI:SetTitle("|cffffffff" .. LA.TSM:FormatTextMoney(totalItemValue) .. "|r")

	LITE_UI:Show()
end


--[[-------------------------------------------------------------------------------------
-- the timer ui
---------------------------------------------------------------------------------------]]
local timerUItotal = 0
function LA:ShowTimerWindow()
	self:Debug("ShowTimerWindow")

	if TIMER_UI then
		TIMER_UI:Show()
		return 
	end

	TIMER_UI = AceGUI:Create("LALiteWindow")
	TIMER_UI:Hide()

	TIMER_UI:SetTitle("|cffffffff" .. date("!%X", 0) .. "|r")
	TIMER_UI:SetStatusTable(self.db.profile.timerUI)
	TIMER_UI:SetWidth(110)
	TIMER_UI:SetHeight(30)
	TIMER_UI.frame:SetScript("OnUpdate", 
		function(event, elapsed)
			timerUItotal = timerUItotal + elapsed
    		if timerUItotal >= 1 then
    			LA:refreshUIs()
		        timerUItotal = 0
		    end	
		end
	)

	-- tab --
	TIMER_UI_TAB = CreateFrame("Frame", nil, TIMER_UI.frame)
	TIMER_UI_TAB.prevMouseIsOver = false
	TIMER_UI_TAB:SetSize(104, 47)
	TIMER_UI_TAB:SetPoint("BOTTOMLEFT", TIMER_UI.frame, "BOTTOMLEFT", 3, 3)
	TIMER_UI_TAB:SetScript("OnUpdate", 
		function(self)
			if ( self.prevMouseIsOver ) then
				if ( not self:IsMouseOver() ) then
					UIFrameFadeOut(TIMER_UI_TAB, CHAT_FRAME_FADE_TIME)
					self.prevMouseIsOver = false
				end
			else
				if ( self:IsMouseOver() ) then
					UIFrameFadeIn(TIMER_UI_TAB, CHAT_FRAME_FADE_TIME)
					self.prevMouseIsOver = true
				end
			end
		end
	)
	UIFrameFadeOut(TIMER_UI_TAB, CHAT_FRAME_FADE_TIME);

	local l1 = TIMER_UI_TAB:CreateTexture(nil, "BACKGROUND")
	l1:SetTexture([[Interface\ChatFrame\ChatFrameTab]])
	l1:SetSize(7, 24)
	l1:SetPoint("TOPLEFT", TIMER_UI_TAB, "TOPLEFT", 26, 0)
	l1:SetTexCoord(0.03125, 0.140625, 0.28125, 1.0)

	local l2 = TIMER_UI_TAB:CreateTexture(nil, "BACKGROUND")
	l2:SetTexture([[Interface\ChatFrame\ChatFrameTab]])
	l2:SetSize(31, 24)
	l2:SetPoint("LEFT", l1, "RIGHT")
	l2:SetTexCoord(0.140625, 0.859375, 0.28125, 1.0)

	local l3 = TIMER_UI_TAB:CreateTexture(nil, "BACKGROUND")
	l3:SetTexture([[Interface\ChatFrame\ChatFrameTab]])
	l3:SetSize(7, 24)
	l3:SetPoint("LEFT", l2, "RIGHT")
	l3:SetTexCoord(0.859375, 0.96875, 0.28125, 1.0)

	b1 = CreateFrame("Button", nil, TIMER_UI_TAB)
	b1:SetSize(20, 20)
	if pauseStart ~= nil then
		b1:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
	else
		b1:SetNormalTexture([[Interface\TimeManager\PauseButton]])
	end
	b1:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]], "ADD")
	b1:SetPoint("BOTTOMLEFT", l1, "BOTTOMLEFT", 4, 1)
	b1:SetScript("OnClick",
		function (self)
			--LA:D("  b1")
			if pauseStart ~= nil then
				b1:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
				LA:onBtnStartSessionClick()
			else
				b1:SetNormalTexture([[Interface\TimeManager\PauseButton]])
				LA:onBtnStopSessionClick()
			end
		end
	)

	local b2 = CreateFrame("Button", nil, TIMER_UI_TAB)
	b2:SetSize(20, 20)
	b2:SetNormalTexture([[Interface\TimeManager\ResetButton]])
	b2:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]], "ADD")
	b2:SetPoint("LEFT", b1, "RIGHT", -2, 0)
	b2:SetScript("OnClick",
		function (self)
			--LA:D("  b2")
			LA:onBtnNewSessionClick()
		end
	)

	TIMER_UI:Show()	
end


--[[-------------------------------------------------------------------------------------
-- the main ui
---------------------------------------------------------------------------------------]]
local PaneBackdrop  = {
	bgFile = "Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 32, edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local additionalButtonHeight = 0
local mainUItotal = 0
function LA:ShowMainWindow(showMainUI) 
	self:Debug("ShowMainWindow")

	if MAIN_UI and showMainUI then 
		MAIN_UI:Show()

		if LA:isLootAppraiserLiteEnabled() then
			LA:ShowLiteWindow()
		end

		if LA:isLastNoteworthyItemUIEnabled() then
			LA:ShowLastNoteworthyItemWindow()
		end

		if LA:isLootAppraiserTimerUIEnabled() then
			LA:ShowTimerWindow()
		end

		return
	end 

	MAIN_UI = AceGUI:Create("Window")
	MAIN_UI:Hide()
	MAIN_UI:SetStatusTable(self.db.profile.mainUI)
	MAIN_UI:SetTitle(LA.METADATA.NAME .. " " .. LA.METADATA.VERSION)
	MAIN_UI:SetLayout("Flow")
	MAIN_UI:SetWidth(410)
	MAIN_UI:EnableResize(false)
	MAIN_UI.frame:SetScript("OnUpdate", 
		function(event, elapsed)
			mainUItotal = mainUItotal + elapsed
    		if mainUItotal >= 1 then
    			LA:refreshUIs()
		        mainUItotal = 0

				-- set text
				if BUTTON_RESETINSTANCES then
					BUTTON_RESETINSTANCES:SetText("Reset Instances (" .. LA:tablelength(LA.ResetInfo) .. "/10)")
				end
		    end	
		end
	)
	MAIN_UI:SetCallback("OnClose",
		function(widget, event)
			--self:Debug("Session ended")
		end
	)

	-- START: statustext
	local statusbg = CreateFrame("Button", nil, MAIN_UI.frame)
	statusbg:SetPoint("BOTTOMLEFT", MAIN_UI.frame, "BOTTOMLEFT", 5, 3)
	statusbg:SetPoint("BOTTOMRIGHT", MAIN_UI.frame, "BOTTOMRIGHT", -2, 3)
	statusbg:SetHeight(24)
	statusbg:SetBackdrop(PaneBackdrop)

	STATUSTEXT = statusbg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	STATUSTEXT:SetPoint("TOPLEFT", 7, -2)
	STATUSTEXT:SetPoint("BOTTOMRIGHT", -7, 2)
	STATUSTEXT:SetHeight(20)
	STATUSTEXT:SetJustifyH("LEFT")
	STATUSTEXT:SetText("")

 	LA:refreshStatusText()
 	-- START: statustext

	-- loot collected list --
	local backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 2,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	}

	GUI_SCROLLCONTAINER = AceGUI:Create("SimpleGroup")
	GUI_SCROLLCONTAINER:SetFullWidth(true)
	GUI_SCROLLCONTAINER:SetHeight(150)
	GUI_SCROLLCONTAINER:SetLayout("Fill")
	GUI_SCROLLCONTAINER.frame:SetBackdrop(backdrop)
	GUI_SCROLLCONTAINER.frame:SetBackdropColor(0, 0, 0)
	GUI_SCROLLCONTAINER.frame:SetBackdropBorderColor(0.4, 0.4, 0.4)

	GUI_LOOTCOLLECTED = AceGUI:Create("ScrollFrame")
	GUI_LOOTCOLLECTED:SetLayout("Flow")
	GUI_SCROLLCONTAINER:AddChild(GUI_LOOTCOLLECTED)	
	MAIN_UI:AddChild(GUI_SCROLLCONTAINER)

	--addSpacer(MAIN_UI)

	dataContainer = AceGUI:Create("SimpleGroup")
	dataContainer:SetLayout("flow")
	dataContainer:SetFullWidth(true)
	MAIN_UI:AddChild(dataContainer)

	-- data rows
	LA:prepareDataContainer()
	LA:addSpacer(MAIN_UI)

	-- button sell trash --
	local BUTTON_SELLTRASH = AceGUI:Create("Button")
	BUTTON_SELLTRASH:SetAutoWidth(true)
	BUTTON_SELLTRASH:SetText("Sell Trash")
	BUTTON_SELLTRASH:SetCallback("OnClick", 
		function()
			LA:onBtnSellTrashClick()
		end
	)
	MAIN_UI:AddChild(BUTTON_SELLTRASH)

	-- button trash grays --
	local BUTTON_DESTROYTRASH = AceGUI:Create("Button")
	BUTTON_DESTROYTRASH:SetAutoWidth(true)
	BUTTON_DESTROYTRASH:SetText("Destroy Trash")
	BUTTON_DESTROYTRASH:SetCallback("OnClick", function()
		LA:onBtnDestroyTrashClick()
	end)
	MAIN_UI:AddChild(BUTTON_DESTROYTRASH)

	-- button new session --
	local BUTTON_NEWSESSION = AceGUI:Create("Button")
	BUTTON_NEWSESSION:SetAutoWidth(true)
	BUTTON_NEWSESSION:SetText("New Session")
	BUTTON_NEWSESSION:SetCallback("OnClick", function()
		LA:onBtnNewSessionClick()
	end)
	MAIN_UI:AddChild(BUTTON_NEWSESSION)

	-- button stop session --
	BUTTON_STOPSESSION = AceGUI:Create("Button")
	BUTTON_STOPSESSION:SetAutoWidth(true)
	if LA:isSessionRunning() then
		BUTTON_STOPSESSION:SetText("Stop")
		BUTTON_STOPSESSION:SetCallback("OnClick", function()
			LA:onBtnStopSessionClick()
		end)
	else 
		BUTTON_STOPSESSION:SetText("(Re)Start")
		BUTTON_STOPSESSION:SetCallback("OnClick", function()
			LA:onBtnStartSessionClick()
		end)
	end
	MAIN_UI:AddChild(BUTTON_STOPSESSION)

	-- button reset instances --
	if LA:isDisplayEnabled("showResetInstanceButton") then
		BUTTON_RESETINSTANCES = AceGUI:Create("Button")
		BUTTON_RESETINSTANCES:SetAutoWidth(true)
		BUTTON_RESETINSTANCES:SetText("Reset Instances (" .. LA:tablelength(LA.ResetInfo) .. "/10)") -- add lockouts
		BUTTON_RESETINSTANCES:SetCallback("OnClick", 
			function()
				LA:onBtnResetInstancesClick()
			end
		)
		BUTTON_RESETINSTANCES:SetCallback("OnEnter", 
			function()
				-- clear list
				for endTime, instanceName in pairs(LA.ResetInfo) do
					if endTime < time() then
						LA.ResetInfo[endTime] = nil
					end
				end

				-- prepare tooltip
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(MAIN_UI.frame, "ANCHOR_CURSOR")  -- LootAppraiser.GUI is the AceGUI-Frame but we need the real frame
				
				GameTooltip:AddLine("Instance lockouts")
				if LA:tablelength(LA.ResetInfo) > 0 then
					for endTime, instanceName in pairs(LA.ResetInfo) do
						GameTooltip:AddDoubleLine("|cffffffff" .. instanceName .. "|r", "|cffffffff" .. date("!%X", endTime - time()) .. "|r")
					end
				else
					GameTooltip:AddLine("|cffffffffNone|r")
				end

				GameTooltip:Show()
			end
		)
		BUTTON_RESETINSTANCES:SetCallback("OnLeave", 
			function()
				GameTooltip:Hide()
			end
		)
		MAIN_UI:AddChild(BUTTON_RESETINSTANCES)

		additionalButtonHeight = 25
	end

	-- adjust height
	local baseHeight = 112

	local rowCount = self.db.profile.display.lootedItemListRowCount or 10
	local listHeight = rowCount * 15

	local dataContainerHeight = dataContainer.frame:GetHeight()

	MAIN_UI:SetHeight(baseHeight + listHeight + additionalButtonHeight + dataContainerHeight)

	if showMainUI then
		MAIN_UI:Show()

		if LA:isLootAppraiserLiteEnabled() then
			LA:ShowLiteWindow()
		end

		if LA:isLastNoteworthyItemUIEnabled() then
			LA:ShowLastNoteworthyItemWindow()
		end

		if LA:isLootAppraiserTimerUIEnabled() then
			LA:ShowTimerWindow()
		end
	end
end


--[[-------------------------------------------------------------------------------------
-- prepare the data container with the current configuration
---------------------------------------------------------------------------------------]]
function LA:prepareDataContainer()
	self:Debug("prepareDataContainer")

	if currentSession == nil then return end

	-- release data container widgets
	if dataContainer ~= nil then
		dataContainer:ReleaseChildren()
	end

	-- resize 
	local listHeight
	if GUI_SCROLLCONTAINER ~= nil then
		local rowCount = self.db.profile.display.lootedItemListRowCount or 10
		listHeight = rowCount * 15
		GUI_SCROLLCONTAINER:SetHeight(listHeight)
	end

	-- prepare data container with current rows

	-- zone and session duration
	local labelWidth = 209
	local valueWidth = 166

	local grp = AceGUI:Create("SimpleGroup")
	grp:SetLayout("flow")
	grp:SetFullWidth(true)
	dataContainer:AddChild(grp)

	-- add zone...
	local currentMapID = GetCurrentMapAreaID()
	local zoneInfo = GetRealZoneText()
	
	VALUE_ZONE = AceGUI:Create("LALabel")
	VALUE_ZONE:SetWordWrap(false)
	VALUE_ZONE:SetText(zoneInfo)
	VALUE_ZONE:SetWidth(labelWidth) -- TODO
	VALUE_ZONE:SetJustifyH("LEFT")
	grp:AddChild(VALUE_ZONE)

	-- ...and session duration
    VALUE_SESSIONDURATION = AceGUI:Create("LALabel")
	VALUE_SESSIONDURATION:SetText("not running")
	VALUE_SESSIONDURATION:SetWidth(valueWidth) -- TODO
	VALUE_SESSIONDURATION:SetJustifyH("RIGHT")
	grp:AddChild(VALUE_SESSIONDURATION)

	-- ...looted item value (with liv/h)
	local totalItemValue = currentSession["liv"] or 0
	local livValue = LA.TSM:FormatTextMoney(totalItemValue)
	if LA:isDisplayEnabled("showLootedItemValuePerHour") then
		livValue = livValue .. " (0|cffffd100g|r/h)"
	end

	VALUE_LOOTEDITEMVALUE = LA:defineRowForFrame(dataContainer, "showLootedItemValue", "Looted Item Value:", livValue)

	-- ...looted currency
	local formattedTotalLootedCurrency = LA.TSM:FormatTextMoney(totalLootedCurrency) or 0
	VALUE_TOTALCURRENCY = LA:defineRowForFrame(dataContainer, "showCurrencyLooted", "Currency Looted:", formattedTotalLootedCurrency)

	-- ...looted item counter
	VALUE_LOOTEDITEMCOUNTER = LA:defineRowForFrame(dataContainer, "showItemsLooted", "Items Looted:", lootedItemCounter)

	-- ...noteworthy item counter
	VALUE_NOTEWORTHYITEMCOUNTER = LA:defineRowForFrame(dataContainer, "showNoteworthyItems", "Noteworthy Items:", noteworthyItemCounter)

	-- and re-layout
	MAIN_UI:DoLayout()

	-- adjust height
	local baseHeight = 112

	local rowCount = self.db.profile.display.lootedItemListRowCount or 10
	local listHeight = rowCount * 15

	local dataContainerHeight = dataContainer.frame:GetHeight()

	MAIN_UI:SetHeight(baseHeight + listHeight + additionalButtonHeight + dataContainerHeight)
end


--[[-------------------------------------------------------------------------------------
-- add a row with label and value to the frame
---------------------------------------------------------------------------------------]]
function LA:defineRowForFrame(frame, id, name, value)
	self:Debug("  defineRowForFrame: id=%s, name=%s, value=%s", id, name, value)

	if not LA:isDisplayEnabled(id) or frame == nil then 
		self:Debug("  -> not visible")
		return 
	end

	local labelWidth = 130
	local valueWidth = 245

	local grp = AceGUI:Create("SimpleGroup")
	grp:SetLayout("flow")
	grp:SetFullWidth(true)
	frame:AddChild(grp)

	-- add label...
	local label = AceGUI:Create("LALabel")
	label:SetText(name)
	label:SetWidth(labelWidth) -- TODO
	label:SetJustifyH("LEFT")
	grp:AddChild(label)

	-- ...and value
	local VALUE = AceGUI:Create("LALabel")
	VALUE:SetText(value)
	VALUE:SetWidth(valueWidth) -- TODO
	VALUE:SetJustifyH("RIGHT")
	grp:AddChild(VALUE)

	return VALUE
end


--[[-------------------------------------------------------------------------------------
-- refresh the main ui
---------------------------------------------------------------------------------------]]
function LA:refreshUIs()
	--self:Debug("refreshUIs")

	-- session duration
	if LA:isSessionRunning() then
		local offset
		if pauseStart ~= nil then
			offset = pauseStart -- session is paused
		else
			offset = time() -- session is running
		end

		local delta = offset - currentSession["start"] - sessionPause

		-- don't show seconds
		local noSeconds = false
		if delta > 3600 then
			noSeconds = true
		end

		--tooltip:AddDoubleLine("Session is running: ", SecondsToTime(delta, noSeconds, false))
		if pauseStart ~= nil then 
			if time() % 2 == 0 then
				VALUE_SESSIONDURATION:SetText(" " .. SecondsToTime(delta, noSeconds, false))
				--VALUE_SESSIONDURATION:SetText(" " .. date("!%X", delta))
			else
				VALUE_SESSIONDURATION:SetText(" ")
			end
		else
			VALUE_SESSIONDURATION:SetText(" " .. SecondsToTime(delta, noSeconds, false))
		end

		-- timer ui
		if TIMER_UI then
			if pauseStart ~= nil then 
				if time() % 2 == 0 then
					TIMER_UI:SetTitle("|cffffffff" .. date("!%X", delta) .. "|r")
				else
					TIMER_UI:SetTitle(" ")
				end
			else
				TIMER_UI:SetTitle("|cffffffff" .. date("!%X", delta) .. "|r")
			end
		end
	else
		--tooltip:AddLine("Session is not running")
		VALUE_SESSIONDURATION:SetText("not running")

		if TIMER_UI then
			TIMER_UI:SetTitle("|cffffffff" .. date("!%X", 0) .. "|r")
		end
	end

	-- zone info
	if VALUE_ZONE ~= nil then 
		local zoneInfo = ""
		-- session zone (if a session is running)
		if currentSession ~= nil and currentSession["mapID"] ~= nil then
			local sessionMapID = currentSession["mapID"]

			if sessionMapID ~= nil then
				local zoneName =  GetRealZoneText()

				zoneInfo = zoneInfo ..  zoneName
			end
		else
			-- current zone
			local currentMapID = GetCurrentMapAreaID()

			zoneInfo = GetRealZoneText()
		end

		VALUE_ZONE:SetText(zoneInfo)
	end

	-- looted item value
	if LA:isDisplayEnabled("showLootedItemValuePerHour") and LA:isSessionRunning() then
		local totalItemValue = currentSession["liv"] or 0
		if LA:isDisplayEnabled("showLootedItemValue") and VALUE_LOOTEDITEMVALUE then
			local livValue = LA.TSM:FormatTextMoney(totalItemValue)
			livValue = livValue .. " (" .. LA:calcLootedItemValuePerHour() .. "|cffffd100g|r/h)"

			-- add to main ui
			VALUE_LOOTEDITEMVALUE:SetText(livValue)
		end

		-- save session (for statistics)
		if totalItemValue > 0 then
			currentSession["liv"] = totalItemValue
			currentSession["end"] = time()
			currentSession["totalItemsLooted"] = totalItemLootedCounter
		end
	end

	-- looted item value (on lite ui)
	if LA:isLootAppraiserLiteEnabled() then
		if LITE_UI then
			local totalItemValue = currentSession["liv"] or 0
			LITE_UI:SetTitle("|cffffffff" .. LA.TSM:FormatTextMoney(totalItemValue) .. "|r")
		end
	end
end


-- 'start session' dialog --
function LA:ShowStartSessionDialog() 
	if START_SESSION_PROMPT then return end -- gui is already open

	local openLootAppraiser = true

	-- create 'start session prompt' frame
	START_SESSION_PROMPT = AceGUI:Create("Frame")	
	START_SESSION_PROMPT:SetStatusTable(self.db.profile.startSessionPromptUI)
	START_SESSION_PROMPT:SetLayout("Flow")
	START_SESSION_PROMPT:SetTitle("Would you like to start a LootAppraiser session?")
	START_SESSION_PROMPT:SetPoint("CENTER")
	START_SESSION_PROMPT:SetWidth(250)
	START_SESSION_PROMPT:SetHeight(115)
	START_SESSION_PROMPT:EnableResize(false)
	START_SESSION_PROMPT:SetCallback("OnClose",
		function(widget) 
			AceGUI:Release(widget)
			START_SESSION_PROMPT = nil
		end
	)
	
	-- Button: Yes
	local btnYes = AceGUI:Create("Button")
	btnYes:SetPoint("CENTER")
	btnYes:SetAutoWidth(true)
	btnYes:SetText("Yes" .. " ")
	btnYes:SetCallback("OnClick", 
		function()
			LA:StartSession(openLootAppraiser)

            START_SESSION_PROMPT:Release()
            START_SESSION_PROMPT = nil
		end
	)
	START_SESSION_PROMPT:AddChild(btnYes)
	
	-- Button: No
	local btnNo = AceGUI:Create("Button")
	btnNo:SetPoint("CENTER")
	btnNo:SetAutoWidth(true)
	btnNo:SetText("No" .. " ")
	btnNo:SetCallback("OnClick", 
		function()
			LA.DisableLootAppraiser()

            START_SESSION_PROMPT:Release()
            START_SESSION_PROMPT = nil
		end
	)	
	START_SESSION_PROMPT:AddChild(btnNo)

	-- Checkbox: Open LA window	
	local checkboxOpenWindow = AceGUI:Create("CheckBox")
	checkboxOpenWindow:SetValue(openLootAppraiser)
	checkboxOpenWindow:SetLabel(" " .. "Open LootAppraiser window")
	checkboxOpenWindow:SetCallback("OnValueChanged",
		function(value)
			--self:Debug("  OnValueChanged: value=%s", tostring(value))
			--LA:print_r(value)
			openLootAppraiser = value.checked
		end
	)

	START_SESSION_PROMPT:AddChild(checkboxOpenWindow)

	START_SESSION_PROMPT.statustext:Hide()
end

function LA:print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            LA:D(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        LA:D(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        LA:D(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        LA:D(indent.."["..pos..'] => "'..val..'"')
                    else
                        LA:D(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                LA:D(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        LA:D(tostring(t).." {")
        sub_print_r(t,"  ")
        LA:D("}")
    else
        sub_print_r(t,"  ")
    end
    LA:D("")
end

--[[-------------------------------------------------------------------------------------
-- starte a new session
---------------------------------------------------------------------------------------]]
function LA:StartSession(showMainUI)
	startSessionPromptAlreadyAnswerd = true
	lootAppraiserDisabled = false

	if LA:isSessionRunning() then
		--LA:Print("LootAppraiser is already running!")
	else
		LA:Print("Start Session")
		self:Debug("  mapID=%s (%s)", GetCurrentMapAreaID(), GetRealZoneText())

		sessionIsRunning = true

		LA:prepareNewSession()

        -- show main window
		LA:ShowMainWindow(showMainUI)

		-- process saved loot
		self:Debug("  savedLoot=%s", tostring(LA:tablelength(savedLoot)))
		self:Debug("  process saved loot")
		for _, data in pairs(savedLoot) do
			if data["currency"] ~= nil then
				-- currency
				local lootedCopper = data["currency"]

				LA:handleCurrencyLooted(lootedCopper)
			else
				-- item
				local itemID = data["itemID"]
				local itemLink = data["link"]
				local quantity = data["quantity"]

				LA:handleItemLooted(itemLink, itemID, quantity)
			end
		end

		-- reset var
		savedLoot = {}
	end
end


function LA:prepareNewSession()
	self:Debug("prepareNewSession")
		self:Debug("  savedLoot: %s items", LA:tablelength(savedLoot))

	-- start: prepare session (for statistics)
	currentSession = {}
	currentSession["start"] = time()
	currentSession["mapID"] =  GetCurrentMapAreaID()

	currentSession["settings"] = {}
	currentSession.settings["qualityFilter"] = LA:getQualityFilter()
	currentSession.settings["gat"] = LA:getGoldAlertThreshold()
	currentSession.settings["priceSource"] = LA:getPriceSource()

	currentSession["noteworthyItems"] = {} -- empty table
	currentSession["liv"] = 0

	local nameString = GetUnitName("player", true)
	local realm = GetRealmName()

	currentSession["player"] = nameString .. "-" .. realm

	local sessions = self.db.global.sessions
	currentSessionID = #sessions + 1

	sessions[currentSessionID] = currentSession

	sessionPause = 0
	pauseStart = nil

	sessionIsRunning = true
	-- end: prepare session (for statistics)
end


function LA.DisableLootAppraiser()
	LA:Print("LootAppraiser DISABLED.")

	startSessionPromptAlreadyAnswerd = true
	lootAppraiserDisabled = true

	savedLoot = {}
end


--[[------------------------------------------------------------------------
-- Event handler for button '(Re)Start'
--------------------------------------------------------------------------]]
function LA:onBtnStartSessionClick()
	self:Debug("onBtnStartSessionClick")

	LA:restartSession()
end


--[[------------------------------------------------------------------------
-- restart session
-- * add pause to sessionPause
-- * change button text
-- * refresh ui
--------------------------------------------------------------------------]]
function LA:restartSession()
	self:Debug("restartSession")
	
	-- calc pause add add to sessionPause
	sessionPause = sessionPause + (time() - pauseStart)
	pauseStart = nil

	-- change start button to stop button
	BUTTON_STOPSESSION:SetText("Stop")
	BUTTON_STOPSESSION:SetCallback("OnClick", function()
		LA:onBtnStopSessionClick()
	end)

	if b1 then
		b1:SetNormalTexture([[Interface\TimeManager\PauseButton]])
		b1:SetScript("OnClick", function()
			LA:onBtnStopSessionClick()
		end)
	end

	-- ui refresh
	LA:refreshUIs()
end


--[[------------------------------------------------------------------------
-- Event handler for button 'stop session'
--------------------------------------------------------------------------]]
function LA:onBtnStopSessionClick()
	self:Debug("onBtnStopSessionClick")

	LA:pauseSession()
end


--[[------------------------------------------------------------------------
-- pause session
-- * save session
-- * pause
-- * change button text
-- * refresh ui
--------------------------------------------------------------------------]]
function LA:pauseSession()
	self:Debug("pauseSession")

	-- save session
	if currentSession ~= nil then
		if currentSession["liv"] and currentSession["liv"] > 0 then
			self:Debug("  -> set session end")
			currentSession["end"] = time()
			currentSession["totalItemsLooted"] = totalItemLootedCounter

			LA:prepareStatisticGroups()
		else
			-- delete current session
			local sessions = self.db.global.sessions
			sessions[currentSessionID] = nil
		end
	end

	pauseStart = time()

	-- change stop button to start button
	BUTTON_STOPSESSION:SetText("(Re)Start")
	BUTTON_STOPSESSION:SetCallback("OnClick", function()
		LA:onBtnStartSessionClick()
	end)

	if b1 then
		b1:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
		b1:SetScript("OnClick", function()
			LA:onBtnStartSessionClick()
		end)
	end

	LA:refreshUIs()
end

--[[------------------------------------------------------------------------
-- Event handler for button 'new session'
--------------------------------------------------------------------------]]
function LA:onBtnNewSessionClick()
	self:Debug("onBtnNewSessionClick")

	LA:NewSession()
end


function LA:NewSession()
	self:Debug("NewSession")

	-- save session
	if currentSession ~= nil then
		if currentSession["liv"] and currentSession["liv"] > 0 then
			self:Debug("  -> set session end")
			currentSession["end"] = time()
			currentSession["totalItemsLooted"] = totalItemLootedCounter

			LA:prepareStatisticGroups()
		else
			-- delete current session
			local sessions = self.db.global.sessions
			sessions[currentSessionID] = nil
			-- TODO delete currentSession
		end
	end

	-- reset all values
	LA:prepareNewSession()

	totalLootedCurrency = 0   	-- the total looted currency during a session
	if VALUE_TOTALCURRENCY ~= nil then
		VALUE_TOTALCURRENCY:SetText(LA.TSM:FormatTextMoney(totalLootedCurrency))
	end

	lootedItemCounter = 0			-- counter for looted items
	totalItemLootedCounter = 0
	if VALUE_LOOTEDITEMCOUNTER ~= nil then
		VALUE_LOOTEDITEMCOUNTER:SetText(lootedItemCounter)
	end

	noteworthyItemCounter = 0		-- counter for noteworthy items
	if VALUE_NOTEWORTHYITEMCOUNTER ~= nil then
		VALUE_NOTEWORTHYITEMCOUNTER:SetText(noteworthyItemCounter)
	end

	if GUI_LOOTCOLLECTED ~= nil then
		GUI_LOOTCOLLECTED:ReleaseChildren()
	end
	lootCollectedLastEntry = nil

	-- set stop button
	BUTTON_STOPSESSION:SetText("Stop")
	BUTTON_STOPSESSION:SetCallback("OnClick", function()
		LA:onBtnStopSessionClick()
	end)

	if b1 then
		b1:SetNormalTexture([[Interface\TimeManager\PauseButton]])
		b1:SetScript("OnClick", function()
			LA:onBtnStopSessionClick()
		end)
	end

	LA:refreshUIs()

	if LAST_NOTEWOTHYITEM_UI then
		LAST_NOTEWOTHYITEM_UI:SetTitle("Gold Alert Threshold")
	end
end

--[[------------------------------------------------------------------------
-- Event handler for button 'destroy trash'
--------------------------------------------------------------------------]]
function LA:onBtnDestroyTrashClick()
	local destroyCounter = 0

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)

			-- grey items
			if link and link:find("ff9d9d9d") then -- Poor = ff9d9d9d	
				PickupContainerItem(bag,slot)
				DeleteCursorItem()

				destroyCounter = destroyCounter + 1
			end

			-- blacklist
			if link and LA:isDestroyBlacklistedItems() then
				local itemID = LA.TSM:GetItemID(link)
				if LA:isItemBlacklisted(itemID) then
					PickupContainerItem(bag, slot)
					DeleteCursorItem()

					destroyCounter = destroyCounter + 1
				end
			end
		end
	end

	if destroyCounter == 0 then
		LA:Print("There are currently no items to trash.")
	end

	if destroyCounter >= 1 then
		LA:Print("Destroyed " .. destroyCounter .. " item(s).")
	end
end


--[[------------------------------------------------------------------------
-- Event handler for button 'reset instances'
--------------------------------------------------------------------------]]
function LA:onBtnResetInstancesClick()
	--local destroyCounter = 0
	ResetInstances();
	-- if in a party - send party msg for awareness --
	local inInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
	local inInstanceGroupRealm = IsInGroup(LE_PARTY_CATEGORY_HOME)
	if inInstanceGroup or inInstanceGroupRealm then 
		SendChatMessage("Instances have been reset.","PARTY", nil)
	end

	LA:print_r(LA.ResetInfo)
end


--[[-------------------------------------------------------------------------------------
-- Event handler for button 'sell trash'
---------------------------------------------------------------------------------------]]
function LA:onBtnSellTrashClick()
	--Validate whether there is an NPC open and how many items sold
	local itemCounter = 0

	-- get items in group 'LootAppraiser`Trash' from TSM
	--local trashItems
	--if LA:isSellTrashTsmGroupEnabled() == true then
	-- 	trashItems = LA:GetGroupItems(LA:getSellTrashTsmGroup())
	--end

	for n = 1, GetMerchantNumItems() do	
		local merchantItemName = select(1, GetMerchantItemInfo(n))
		itemCounter = itemCounter + 1
	end
	
	--If not vendor open (unable to count vendor items) alert to go to merchant
	if itemCounter == 0 then
		LA:Print("Travel to a vendor first to sell your items.")
		return
	end

	local itemsSold = 0
	for bag=0,4 do
		for slot=1, GetContainerNumSlots(bag) do
			-- first: we sell all grays
			local link = GetContainerItemLink(bag, slot)
			if link and link:find("ff9d9d9d") then			--Poor = ff9d9d9d
				UseContainerItem(bag, slot)
				itemsSold = itemsSold + 1
			end

			--second: sell items in TSM group
			if LA:isSellTrashTsmGroupEnabled() == true then
				local id = GetContainerItemID(bag, slot)
				--if id and LA:isItemInList(id, trashItems) then
				if id and LA.TSM:isItemInGroup(id, LA:getSellTrashTsmGroup()) then
					--LA:Debug("  id=" .. id .. ", found=" .. tostring(trashItems["i:" .. id]) .. ", link=" .. link)
					UseContainerItem(bag, slot)
					itemsSold = itemsSold + 1
				end
			end
		end
	end

	if itemsSold == 0 then
		LA:Print("No items sold.")
	else
		LA:Print(tostring(itemsSold) .. " item(s) sold") --for " .. LA.TSM:FormatTextMoney(moneyEarned))
	end
end


--[[-------------------------------------------------------------------------------------
-- calculate looted item value / hour
---------------------------------------------------------------------------------------]]
function LA:calcLootedItemValuePerHour()
	-- calc lootedItemValuePerHour
	--local currentTime = time()		
	--
	--local delta = currentTime - currentSession["start"]

	local offset
	if pauseStart ~= nil then
		offset = pauseStart -- session is paused
	else
		offset = time() -- session is running
	end

	local delta = offset - currentSession["start"] - sessionPause

	local factor = 3600
	if delta < factor then
		factor = delta
	end

	local totalItemValue = currentSession["liv"] or 0
	local livGoldPerHour = nil
	if totalItemValue == 0 then
		livGoldPerHour = 0
	else
		local livPerHour = (totalItemValue/delta*factor)
		livGoldPerHour = floor(livPerHour/10000)
	end

	return tostring(livGoldPerHour)
end


--[[-------------------------------------------------------------------------------------
-- increase the noteworthy item counter
---------------------------------------------------------------------------------------]]
function LA:incNoteworthyItemCounter(quantity)
	noteworthyItemCounter = noteworthyItemCounter + quantity

	LA:D("    noteworthy items counter: add " .. tostring(quantity) .. " -> new total: " .. tostring(noteworthyItemCounter))

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if LA:isDisplayEnabled("showNoteworthyItems") then
			-- add to main ui
			VALUE_NOTEWORTHYITEMCOUNTER:SetText(noteworthyItemCounter)
		end
	end
end


--[[-------------------------------------------------------------------------------------
-- increase the looted item counter
---------------------------------------------------------------------------------------]]
function LA:incLootedItemCounter(quantity)
	lootedItemCounter = lootedItemCounter + quantity

	LA:D("    looted items counter: add " .. tostring(quantity) .. " -> new total: " .. tostring(lootedItemCounter))

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if LA:isDisplayEnabled("showItemsLooted") then
			-- add to main ui
			VALUE_LOOTEDITEMCOUNTER:SetText(lootedItemCounter)
		end
	end
end


--[[-------------------------------------------------------------------------------------
-- add item value to looted item value and refresh ui
---------------------------------------------------------------------------------------]]
function LA:addItemValue2LootedItemValue(itemValue)
	local totalItemValue = currentSession["liv"] or 0
	totalItemValue = totalItemValue + itemValue

	LA:D("    looted items value: add " .. tostring(itemValue) .. " -> new total: " .. tostring(totalItemValue))

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if LA:isDisplayEnabled("showLootedItemValue") then
			local livValue = LA.TSM:FormatTextMoney(totalItemValue)
			if LA:isDisplayEnabled("showLootedItemValuePerHour") then
				livValue = livValue .. " (" .. LA:calcLootedItemValuePerHour() .. "|cffffd100g|r/h)"
			end

			-- add to main ui
			VALUE_LOOTEDITEMVALUE:SetText(livValue)
		end
	end

	-- save current session (for statistics)
	if totalItemValue > 0 then
		currentSession["liv"] = totalItemValue
		currentSession["end"] = time() -- fallback if we found no way to identify session end
		currentSession["totalItemsLooted"] = totalItemLootedCounter
	end
end


--[[-------------------------------------------------------------------------------------
-- add a given item to the top of the loot colletced list
---------------------------------------------------------------------------------------]]
function LA:addItem2LootCollectedList(itemID, link, quantity, marketValue, noteworthyItemFound)
	--LA:Debug("addItem2LootCollectedList(itemID=" .. itemID .. ", link=" .. tostring(link) .. ", quantity=" .. quantity .. ")")

	-- prepare text
	local formattedItemValue = LA.TSM:FormatTextMoney(marketValue) or 0
	local preparedText = " " .. link .. " x" .. quantity .. ": " .. formattedItemValue
	
	-- item / link
	local LABEL = AceGUI:Create("InteractiveLabel")
	LABEL.frame:Hide()
	LABEL:SetText(preparedText)
	LABEL.label:SetJustifyH("LEFT")
	LABEL:SetWidth(350)
	LABEL:SetCallback("OnEnter", 
		function()
			GameTooltip:SetOwner(MAIN_UI.frame, "ANCHOR_CURSOR")  -- LootAppraiser.GUI is the AceGUI-Frame but we need the real frame
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end
	)
	LABEL:SetCallback("OnLeave", 
		function()
			GameTooltip:Hide()
		end
	)

	LA:D("  " .. tostring(itemID) .. ": add entry to list " .. preparedText)
	
	if lootCollectedLastEntry then
		GUI_LOOTCOLLECTED:AddChild(LABEL, lootCollectedLastEntry)
	else
		GUI_LOOTCOLLECTED:AddChild(LABEL)
	end
	
	-- rember the created entry to add the next entry before this -> reverse list with newest entry on top
	lootCollectedLastEntry = LABEL
end


--[[-------------------------------------------------------------------------------------
-- refresh the status bar with the current settings
---------------------------------------------------------------------------------------]]
function LA:refreshStatusText()
	if MAIN_UI ~= nil then
		-- prepare status text
		local preparedText = "Filter: " .. LA.QUALITY_FILTER[tostring(LA:getQualityFilter())] 								-- filter
		preparedText = preparedText .. " - GAT: |cffffffff" .. LA:getGoldAlertThreshold() .. "|cffffd100g|r"				-- gat
		preparedText = preparedText .. " - Source: |cffffffff" .. tostring(self.db.profile.pricesource.source) .. "|r" 	-- price source
		
		--MAIN_UI:SetStatusText(preparedText)
		STATUSTEXT:SetText(preparedText)
	end
end


--[[-------------------------------------------------------------------------------------
-- helper methods
---------------------------------------------------------------------------------------]]

-- add a blank line to the given frame
function LA:addSpacer(frame)
	local SPACER = AceGUI:Create("LALabel")
	SPACER:SetJustifyH("LEFT")
	SPACER:SetText("   ")
	SPACER:SetWidth(350)
	frame:AddChild(SPACER)
end


--[[------------------------------------------------------------------------
-- checks if a item is blacklisted
--   check depends on the blacklist options (see config)
--------------------------------------------------------------------------]]
function LA:isItemBlacklisted(itemID)
	--LA:Debug("isItemBlacklisted(): itemID=" .. itemID)
	--LA:Debug("  isBlacklistTsmGroupEnabled()=" .. tostring(LA:isBlacklistTsmGroupEnabled()))
	if not LA:isBlacklistTsmGroupEnabled() then
		-- only use static list
		return ITEM_FILTER_BLACKLIST[tostring(itemID)]
	end

	-- use TSM group
	-- get items in group 'LootAppraiser`Blacklist' from TSM
	--LA:Debug("  getBlacklistTsmGroup()=" .. LA:getBlacklistTsmGroup())
	--local blacklistItems = LA:GetGroupItems(LA:getBlacklistTsmGroup())

	--local result = LA:isItemInList(itemID, blacklistItems)
	local result = LA.TSM:isItemInGroup(itemID, LA:getBlacklistTsmGroup())
	--LA:Debug("  isItemInList=" .. tostring(result))
	return result
end


--[[-------------------------------------------------------------------------------------
-- access methods for loot appraiser local variables
---------------------------------------------------------------------------------------]]
function LA:getTotalLootedCurrency()
	return totalLootedCurrency
end


function LA:getNoteworthyItemCounter()
	return noteworthyItemCounter
end


--[[-------------------------------------------------------------------------------------
-- access methods for loot appraiser db values (saved variables)
---------------------------------------------------------------------------------------]]
function LA:isBlacklistTsmGroupEnabled()
	if self.db.profile.blacklist.tsmGroupEnabled == nil then
		self.db.profile.blacklist.tsmGroupEnabled = self.dbDefaults.profile.blacklist.tsmGroupEnabled
	end

	return self.db.profile.blacklist.tsmGroupEnabled
end

function LA:isDestroyBlacklistedItems()
	--if self:isBlacklistTsmGroupEnabled() and self.db.profile.addBlacklistedItems2DestroyTrash then
	if self.db.profile.blacklist.addBlacklistedItems2DestroyTrash then
		return true
	end
	return false
end

function LA:getBlacklistTsmGroup()
	if self.db.profile.blacklist.tsmGroup == nil then
		self.db.profile.blacklist.tsmGroup = self.dbDefaults.profile.blacklist.tsmGroup
	end

	return self.db.profile.blacklist.tsmGroup
end

function LA:getGoldAlertThreshold()
	if self.db.profile.general.goldAlertThreshold == nil then
		self.db.profile.general.goldAlertThreshold = self.dbDefaults.profile.general.goldAlertThreshold
	end

	return tonumber(self.db.profile.general.goldAlertThreshold)
end

function LA:getQualityFilter()
	if self.db.profile.general.qualityFilter == nil then
		self.db.profile.general.qualityFilter = self.dbDefaults.profile.general.qualityFilter
	end

	return tonumber(self.db.profile.general.qualityFilter)
end

function LA:getIgnoreRandomEnchants()
	if self.db.profile.general.ignoreRandomEnchants == nil then
		self.db.profile.general.ignoreRandomEnchants = self.dbDefaults.profile.general.ignoreRandomEnchants
	end

	return self.db.profile.general.ignoreRandomEnchants
end

function LA:getSessions()
	if self.db.global.sessions == nil then
		self.db.global.sessions = {}
	end

	return self.db.global.sessions
end

function LA:getPriceSource()
	if self.db.profile.pricesource.source == nil then
		self.db.profile.pricesource.source = self.dbDefaults.profile.pricesource.source
	end

	return self.db.profile.pricesource.source
end

function LA:getCustomPriceSource()
	if self.db.profile.pricesource.customPriceSource == nil then
		self.db.profile.pricesource.customPriceSource = self.dbDefaults.profile.pricesource.customPriceSource
	end

	return self.db.profile.pricesource.customPriceSource
end

function LA:isToastsEnabled()
	if self.db.profile.notification.enableToasts == nil then
		self.db.profile.notification.enableToasts = self.dbDefaults.profile.enableToasts
	end

	return self.db.profile.notification.enableToasts
end

function LA:isSessionRunning()
	return sessionIsRunning
end

function LA:isPlaySoundEnabled()
	if self.db.profile.notification.playSoundEnabled == nil then
		self.db.profile.notification.playSoundEnabled = self.dbDefaults.profile.notification.playSoundEnabled
	end

	return self.db.profile.notification.playSoundEnabled
end

function LA:isSellTrashTsmGroupEnabled()
	if self.db.profile.sellTrash.tsmGroupEnabled == nil then
		self.db.profile.sellTrash.tsmGroupEnabled = self.dbDefaults.profile.sellTrash.tsmGroupEnabled
	end

	return self.db.profile.sellTrash.tsmGroupEnabled
end

function LA:getSellTrashTsmGroup()
	if self.db.profile.sellTrash.tsmGroup == nil then
		self.db.profile.sellTrash.tsmGroup = self.dbDefaults.profile.sellTrash.tsmGroup
	end

	return self.db.profile.sellTrash.tsmGroup
end

function LA:isDisplayEnabled(name)
	if self.db.profile.display[name] == nil then
		self.db.profile.display[name] = self.dbDefaults.profile.display[name]
	end

	return self.db.profile.display[name]
end

function LA:isSurpressSessionStartDialog()
	if self.db.profile.general.surpressSessionStartDialog == nil then
		self.db.profile.general.surpressSessionStartDialog = self.dbDefaults.profile.general.surpressSessionStartDialog
	end

	return self.db.profile.general.surpressSessionStartDialog
end

function LA:getCurrentSession()
	return currentSession
end

function LA:isLootAppraiserLiteEnabled()
	if self.db.profile.display.enableLootAppraiserLite == nil then
		self.db.profile.display.enableLootAppraiserLite = self.dbDefaults.profile.display.enableLootAppraiserLite
	end

	return self.db.profile.display.enableLootAppraiserLite
end

function LA:isLootAppraiserTimerUIEnabled()
	if self.db.profile.display.enableLootAppraiserTimerUI == nil then
		self.db.profile.display.enableLootAppraiserTimerUI = self.dbDefaults.profile.display.enableLootAppraiserTimerUI
	end

	return self.db.profile.display.enableLootAppraiserTimerUI
end

function LA:isLastNoteworthyItemUIEnabled()
	if self.db.profile.display.enableLastNoteworthyItemUI == nil then
		self.db.profile.display.enableLastNoteworthyItemUI = self.dbDefaults.profile.display.enableLastNoteworthyItemUI
	end

	return self.db.profile.display.enableLastNoteworthyItemUI
end

function LA:isDebugOutputEnabled()
	if self.db.profile.enableDebugOutput == nil then
		self.db.profile.enableDebugOutput = self.dbDefaults.profile.enableDebugOutput
	end

	return self.db.profile.enableDebugOutput
end

--[[-------------------------------------------------------------------------------------
-- parse currency text from loot window and covert the result to copper
-- e.g. 2 silve, 2 copper
-- result: 202 copper
---------------------------------------------------------------------------------------]]
function LA:getLootedCopperFromText(lootedCurrencyAsText)
	local digits = {}
	local digitsCounter = 0;
	lootedCurrencyAsText:gsub("%d+", 
		function(i)
			table.insert(digits, i)
			digitsCounter = digitsCounter + 1
		end
	)
	local copper = 0
	if digitsCounter == 3 then
		-- gold + silber + copper
		copper = (digits[1]*10000)+(digits[2]*100)+(digits[3])
	elseif digitsCounter == 2 then
		-- silber + copper
		copper = (digits[1]*100)+(digits[2])
	else
		-- copper
		copper = digits[1]
	end
	
	return copper
end

function LA:Debug(msg, ...)
	if self.DEBUG then
		self:Printf(msg, ...)
	end
end

--function Debug(msg)
--	LA:Debug(msg)
--end

--[[
function LA:D(msg)
	if LA:isDebugOutputEnabled() then
		LA:Print(tostring(msg))
	end
end
]]


function LA:D(msg, ...)
	if self.DEBUG then
		self:Printf(msg, ...)

		local tab = -1
		for i = 1,10 do
			--self:Printf(" name=%s", tostring(GetChatWindowInfo(i)))
			if GetChatWindowInfo(i)=="LADebug" then
				tab = i
				break
			end
		end

		if(tab ~= -1) then
			--_G["ChatFrame"..tab]:AddMessage(...)
			self:Printf(_G["ChatFrame"..tab], msg, ...)
		end
	end
end


function string.startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end


function LA:tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

---============================================================
-- rounds a number to the nearest decimal places
--
function LA:round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end


function LA:split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, 
    	function(c) 
    		fields[#fields+1] = c 
    	end
    )
    return fields
end


function LA:printSessions()
	if not LA.DEBUG then return end

	local sessions = self.db.global.sessions
	for i,v in ipairs(sessions) do
		local sessionMapID = v["mapID"]
		local sessionStart = v["start"];
		local sessionEnd = v["end"];
		local liv = v["liv"]

		if sessionEnd ~= nil then
			LA:Debug("  session " .. tostring(i))
			LA:Debug("    time: " .. date("%x", sessionStart))

			local mapName
			if sessionMapID ~= nil then
				mapName = GetRealZoneText()
			end
			LA:Debug("    map: " .. tostring(sessionMapID) .. " (" .. tostring(mapName) .. ")")

			local sessionDuration = sessionEnd - sessionStart
			LA:Debug("    duration: " .. SecondsToTime(sessionDuration))

			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end

			local formattedLiv = LA.TSM:FormatTextMoney(liv) or 0
			LA:Debug("    looted item value: " .. formattedLiv)

			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)
			LA:Debug("    liv/h: " .. tostring(livGoldPerHour) .. "g/h")
		else
			-- missing end -> remove entry
			LA:Debug("  session " .. tostring(i) .. " is invalid (missing end)")
			--sessions[i] = nil
		end
	end
end
