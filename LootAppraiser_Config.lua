-- LootAppraiser_Config.lua --
local LootAppraiser, LA = ...;

local Config = LA:NewModule("Config", "AceEvent-3.0", "AceConsole-3.0")

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

-- Lua APIs
local tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string, sort = 
	  tostring, pairs, ipairs, table, tonumber, select, time, math, floor, date, print, type, string, sort

-- wow APIs
local InterfaceOptions_AddCategory, SecondsToTime, GameFontHighlightSmall, GetItemInfo = 
      InterfaceOptions_AddCategory, SecondsToTime, GameFontHighlightSmall, GetItemInfo
local DEFAULT_CHAT_FRAME = 
      DEFAULT_CHAT_FRAME

Config.SESSIONDATA_GROUPBY = {
	["datetime"] = "Date", 
	["liv"] = "Looted Item Value", 
	["livPerHour"] = "LIV per hour", 
}


local options = {
	type = "group",
	args = {
		general = { type = "group", name = LootAppraiser .. " " .. LA.METADATA.VERSION, childGroups = "tab",
			get = function(info) return LA.db.profile[info[#info]] end,
			set = function(info, value) 
				LA.db.profile[info[#info]] = value;
				LA:refreshStatusText()
			end,
			args = {
				generalOptionsGrp = {
					type = "group",
					order = 25,
					name = "General",
					get = function(info) 
						return LA.db.profile.general[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.general[info[#info]] = value;
					end,
					args = {
						qualityFilter = {
							type = "select",
							order = 20,
							name = "Quality Filter",
							desc = "Items below the selected quality will not show in the loot collected list",
							values = LA.QUALITY_FILTER,
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Quality Filter set to: " .. LA.QUALITY_FILTER[value] .. " and above.")
								end
								LA.db.profile.general[info[#info]] = value;
								LA:refreshStatusText()
							end,
							disabled = function(info)
								return not Config:SettingsChangeAllowed(info[#info])
							end,
						},
						spacer = {
							type = "description", 
							order = 25, 
							name = " ", 
							width = "half", 
						},
						goldAlertThreshold = {
							type = "input",
							order = 30,
							name = "Gold Alert Threshold (GAT)",
							desc = "Threshold for gold alert",
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Gold alert threshold set: " .. value .. "|cffffd100g|r or higher.")
								end
								LA.db.profile.general[info[#info]] = value;
								LA:refreshStatusText()
							end,
						},
						ignoreRandomEnchants = {
							type = "toggle",
							order = 40,
							name = "Ignore random enchants on items",
							desc = "Ignore random enchants on items (like ...of the Bear) and show only the base item",
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Ignore random enchants: " .. Config:formatBoolean(value) .. ".")
								end
								LA.db.profile.general[info[#info]] = value;
							end,
						},
						surpressSessionStartDialog = {
							type = "toggle",
							order = 50,
							name = "Suppress 'Start Session' dialogue during first loot.",
							desc = "Attention! If the dialog is suppressed, the session must be started by hand (left-click on the minimap icon)",
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Suppress 'Start Session' dialogue: " .. Config:formatBoolean(value) .. ".")
								end
								LA.db.profile.general[info[#info]] = value;
							end,
						},
					},
				},
				priceSourceGrp = {
					type = "group",
					order = 50,
					name = "Price Source",
					get = function(info) 
						return LA.db.profile.pricesource[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.pricesource[info[#info]] = value;
					end,
					args = {
						source = {
							type = "select",
							order = 20,
							name = "Price Source",
							desc = "TSM predefined price sources for item value calculation.",
							values = function() return LA.TSM:GetAvailablePriceSources() end,
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.pricesource[info[#info]]
								if oldValue ~= value then
									LA:Print("Price source changed to: " .. value)
								end
								LA.db.profile.pricesource[info[#info]] = value;
								LA:refreshStatusText()
							end,
							disabled = function(info)
								return not Config:SettingsChangeAllowed(info[#info])
							end,
						},
						customPriceSource = {
							type = "input",
							order = 30,
							name = "Custom Price Source",
							desc = "TSM Custom Price Source. See TSM documentation for detailed description.",
							width = "full",
							disabled = function()
								return not (LA.db.profile.pricesource.source == "Custom")
							end,
							set = function(info, value) 
								LA:Print("Custom price source changed to: " .. value)
								LA.db.profile.pricesource[info[#info]] = value;
							end,
							validate = function(info, value)
								local isValidPriceSource = LA.TSM:ParseCustomPrice(value)
								if not isValidPriceSource then
									-- error message
									DEFAULT_CHAT_FRAME:AddMessage("Invalid custom price source. See TSM documentation for detailed description.")
									return false
								end
								return true
							end,
						},
					},
				},
				sellTrashGrp = {
					type = "group",
					order = 60,
					name = "Sell Trash",
					get = function(info) 
						return LA.db.profile.sellTrash[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.sellTrash[info[#info]] = value;
					end,
					args = {
						description = {
							type = "description", 
							order = 5, 
							fontSize = "medium",
							name = "The button sell trash always sells gray items. Here you can add a TSM group to the sell trash function and all items in this group will also sold. Be careful. If your TSM group containts items with value and you click sell trash... all items are gone with the wind... you be warned. Note: TSM uses ` as group seperator.\n", 
							width = "full", 
						}, 
						tsmGroupEnabled = {
							type = "toggle",
							order = 10,
							name = " Sell trash via TSM group",
							desc = "Use a TSM group to define additional none gray items to sell at the vendor with the sell trash button",
							--width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.sellTrash[info[#info]]
								if oldValue ~= value then
									LA:Print("Sell trash via TSM group: " .. Config:formatBoolean(value) .. ".")
								end
								LA.db.profile.sellTrash[info[#info]] = value;
							end,
						},
						tsmGroup = {
							type = "input",
							order = 20,
							name = "TSM Group",
							desc = "The TSM Group with all the none gray items to sell at the vendor.",
							width = "double",
							disabled = function()
								return not (LA.db.profile.sellTrash.tsmGroupEnabled == true)
							end,
							set = function(info, value) 
								LA:Print("Sell trash TSM group set to: " .. value)
								LA.db.profile.sellTrash[info[#info]] = value;
							end,
							-- TODO validation
							validate = function(info, value)
								-- validate the tsn group
								if value == nil or value == "" then
									-- error message
									DEFAULT_CHAT_FRAME:AddMessage("Invalid TSM group.")
									return false
								end
								return true
							end,
						},
					},
				},
				blacklist = {
					type = "group",
					order = 70,
					name = "Blacklist",
					get = function(info) 
						return LA.db.profile.blacklist[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.blacklist[info[#info]] = value;
					end,
					args = {
						description = {
							type = "description",
							order = 10,
							fontSize = "medium",
							name = "The black list is intended for all worthless items. They can not be sold to the vendor and the auction value is only theoretical (like the idols and scarabs from AQ20). Therefore, these objects are ignored in the calculation of the looted itemvalue.\nNote: TSM uses ` as group seperator.",
							width = "full"
						},
						emptyLine1 = {
							type = "description",
							order = 13,
							name = " ",
							width = "full"
						},
						addBlacklistedItems2DestroyTrash = {
							type = "toggle",
							order = 15,
							name = " Add blacklisted items to the destroy trash button.",
							desc = "Adds all blacklisted items from the TSM group to the destroyabel items list.",
							width = "full",
							--[[
							disabled = function()
								return not (LA.db.profile.blacklist.tsmGroupEnabled == true)
							end,
							]]
							set = function(info, value) 
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Add blacklisted items to destroy trash: " .. Config:formatBoolean(value) .. ".")
								end
								LA.db.profile.blacklist[info[#info]] = value;
							end,
						},
						tsmGroupEnabled = {
							type = "toggle",
							order = 20,
							name = " Blacklist via TSM group",
							desc = "Use a TSM group to define blacklisted items. If deactivated LootAppraiser uses the old unmaintained list.",
							--width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.blacklist[info[#info]]
								if oldValue ~= value then LA:Print("Blacklist items via TSM group: " .. Config:formatBoolean(value) .. ".") end
								LA.db.profile.blacklist[info[#info]] = value;
							end,
							disabled = function(info)
								return not Config:SettingsChangeAllowed(info[#info])
							end,
						},
						tsmGroup = {
							type = "input",
							order = 30,
							name = "TSM Group",
							desc = "The TSM Group with all the blacklistes items.",
							width = "double",
							disabled = function()
								return not (LA.db.profile.blacklist.tsmGroupEnabled == true)
							end,
							set = function(info, value) 
								LA:Print("Blacklisted items TSM group set to: " .. value)
								LA.db.profile.blacklist[info[#info]] = value;
							end,
							validate = function(info, value)
								-- validate the tsn group
								if value == nil or value == "" then
									-- error message
									DEFAULT_CHAT_FRAME:AddMessage("Invalid TSM group.")
									return false
								end
								return true
							end,
						},
						emptyLine2 = { type = "description", order = 40, name = " ", width = "full" },
					},
				},
				notificationOptionsGrp = { type = "group", order = 75, name = "Notifications",
					get = function(info) return LA.db.profile.notification[info[#info]] end,
					set = function(info, value) LA.db.profile.notification[info[#info]] = value end,
					args = {
						noteworthyItemOutputHeader = { order = 100, type = "header", name = "Noteworthy Item Output Channel", },
						notificationLibSink = LA:GetSinkAce3OptionsDataTable(),
						enableToasts = { type = "toggle", order = 300, name = "Enable Toasts", desc = "Enable Toasts", width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.notification[info[#info]]
								if oldValue ~= value then LA:Print("Enable Toasts set: " .. Config:formatBoolean(value) .. ".") end
								LA.db.profile.notification[info[#info]] = value;
							end,
						},
						noteworthyItemSoundHeader = { order = 400, type = "header", name = "Noteworthy Item Sound", },
						playSoundEnabled = { order = 425, type = "toggle", name = "Play Sound", desc = "Play Sound", },
						soundName = { order = 450, type = "select", name = "Sound", desc = "Sound", width = "double", dialogControl = "LSM30_Sound", values = LSM:HashTable("sound"),
							disabled = function() return not LA.db.profile.notification.playSoundEnabled end,
						},
					},
				},
				displayOptions = { type = "group", order = 90, name = "Display", hidden = false,
					get = function(info) return LA.db.profile.display[info[#info]] end,
					set = function(info, value) 
						LA.db.profile.display[info[#info]] = value 
						LA:prepareDataContainer() 
					end,
					args = {
						displayMainUiOptions = { type = "group", order = 10, name = "Main UI", hidden = false, inline = true,
							args = {
								lootedItemListRowCount = { type = "range", order = 5, name = "Looted Item List: number of rows", desc = "Number of rows in the looted item list", min = 3, max = 10, step = 1, width = "double", },
								showLootedItemValue = { type = "toggle", order = 30, name = "Show 'Looted Item Value'", desc = "Show 'Looted Item Value'", width = "double", },
								showLootedItemValuePerHour = { type = "toggle", order = 40, name = "Show 'Looted Item Value' Per Hour", desc = "Show 'Looted Item Value' Per Hour (in parentes behind the Looted Item Value)", width = "double", },
								showCurrencyLooted = { type = "toggle", order = 50, name = "Show 'Currency Looted'", desc = "Show 'Currency Looted'", width = "double", },
								showItemsLooted = { type = "toggle", order = 60, name = "Show 'Items Looted'", desc = "Show 'Items Looted'", width = "double", },
								showNoteworthyItems = { type = "toggle", order = 70, name = "Show 'Noteworthy Items'", desc = "Show 'Noteworthy Items'", width = "double", },
								showResetInstanceButton = { type = "toggle", order = 80, name = "Show 'Reset Instance' Button (/reload necessary)", desc = "Show 'Reset Instance' Button", width = "double", set = function(info, value) LA.db.profile.display[info[#info]] = value end, },
								descResetInstanceButton = { type = "description", order = 85, fontSize = "medium", name = "The displayed instance lockout should only help to optimize the 10 instance resets per hour. Not more and not less. No lockout magic, cross char tracking or such stuff. Those who want more should install the addon SavedInstances from Curse.", width = "full", },
							},
							plugins = {},
						},
						displayLastNoteworthyItemOptions = { type = "group", order = 20, name = "Additional Loot Appraiser 'Lite' windows", hidden = false, inline = true,
							args = { 
								enableLastNoteworthyItemUI = { type = "toggle", order = 10, name = "Enable 'Last Noteworthy Item' UI", desc = "Enables the 'Last Noteworthy Item' UI", width = "double", }, 
								enableLootAppraiserLite = { type = "toggle", order = 10, name = "Enable 'Loot Appraiser Lite' UI", desc = "Enables the 'Loot Appraiser Lite' UI which shows the looted item value.", width = "double", },
								enableLootAppraiserTimerUI = { type = "toggle", order = 10, name = "Enable 'Timer' UI", desc = "Enables the 'Timer' UI.", width = "double", set = function(info, value) LA.db.profile.display[info[#info]] = value end, },
							},
							plugins = {},
						},
						displayTooltipOptions = { type = "group", order = 40, name = "Tooltip", hidden = true, inline = true,
							args = {},
							plugins = {},
						},
					},
					plugins = {},
				},
				aboutGroup = { type = "group", order = 100, name = "About",
					args = {
						generalText = { type = "description", order = 10, fontSize = "medium",name = "LootAppraiser is an addon which determines an item's value when looted based upon a pricing source you select. It keeps track of all gold asset value of the items in total including a quality item filter. Perfect for farming and determining gold asset value or potential gold-per-hour.\n\nThe reason Profitz developed this addon was because while proving out some gold earnings via farming, he was using spreadsheets for post-run calculations on item values and pricing models. Now, we all can just run this addon, select the price source we want and let it calculate it for us!\n\nPlease understand, this addon does NOT determine liquid gold you are guaranteed to make but rather, potential ‘asset’ values of items looted where you will have to do the work and sell it on the Auction House, trade chat, etc.\n",width = "full", }, 
						generalText15 = { type = "description", order = 15, fontSize = "medium",name = "EMail:",width = "half", }, 
						generalText16 = { type = "description", order = 16, fontSize = "medium",name = "lootappraiser@gmail.com",width = "double", }, 
						generalText20 = { type = "description", order = 20, fontSize = "medium", name = "\nAuthor/Designer/Developer: Profitz", width = "full", }, 
						blank26 = { type = "description", order = 26, fontSize = "small", name = "", width = "full", }, 
						generalText30 = { type = "description", order = 30, fontSize = "medium", name = "Twitter:", width = "half", }, 
						generalText35 = { type = "description", order = 35, fontSize = "medium", name = "@WowProfitz (https://twitter.com/WowProfitz)", width = "double", }, 
						blank36 = { type = "description", order = 36, fontSize = "small", name = "", width = "full", }, 
						generalText40 = { type = "description", order = 40, fontSize = "medium", name = "Twitch:", width = "half", }, 
						generalText45 = { type = "description", order = 45, fontSize = "medium", name = "ProfitzTV (http://www.twitch.tv/profitztv)", width = "double", }, 
						blank46 = { type = "description", order = 46, fontSize = "small", name = "", width = "full", }, 
						generalText50 = { type = "description", order = 50, fontSize = "medium", name = "EMail:", width = "half", }, 
						generalText55 = { type = "description", order = 55, fontSize = "medium", name = "WowProfitz@Gmail.com", width = "double", }, 
						generalText60 = { type = "description", order = 60, fontSize = "medium", name = "\nCo-Author/Lead Developer/Designer:  Testerle", width = "full", }, 
						blank66 = { type = "description", order = 66, fontSize = "small",name = "",width = "full", }, 
						generalText70 = { type = "description", order = 70, fontSize = "medium", name = "Twitter:", width = "half", }, 
						generalText75 = { type = "description", order = 75, fontSize = "medium", name = "@Testerle (https://twitter.com/Testerle)", width = "double", }, 
						blank76 = { type = "description", order = 76, fontSize = "small", name = "", width = "full", }, 
						generalText77 = { type = "description", order = 77, fontSize = "medium", name = "Twitch:", width = "half", }, 
						generalText78 = { type = "description", order = 78, fontSize = "medium", name = "Testerle (http://www.twitch.tv/testerle)", width = "double", }, 
						generalText80 = { type = "description", order = 80, fontSize = "medium", name = "\nContributor(s)/Developer: Munglunch\n\nEarly Adopters/Beta Testers:", width = "full", }, 
						blank86 = { type = "description", order = 86, fontSize = "small", name = "", width = "full", }, 
						generalText100 = { type = "description", order = 100, fontSize = "medium", name = "ACubed10\nBrozerian\nConzec89\nDecepticon2012\nDozerBob\nFatherfajita\nGoblinRaset\nJuniorDeBoss\nMorricade\nPhatLewts\nSelltacular", width = "full", }, 
						blank110 = { type = "description", order = 110, fontSize = "small",name = "",width = "full", }, 
						enableDebugOutput = { type = "toggle",order = 120,name = "Enable debug output",desc = "Enable debug output",width = "full", },
						blank130 = { type = "description", order = 130, fontSize = "small",name = "",width = "full", }, 
					}, 
				},
			}, 
		},	
		statistic = { type = "group", name = LootAppraiser .. " Statistic", get = function(info) return LA.db.profile[info[#info]] end, set = function(info, value) LA.db.profile[info[#info]] = value; end, childGroups = "select", inline = true,
			args = {},
		},
	}, 
}


--[[-------------------------------------------------------------------------------------
-- AceAddon-3.0 - module standard methods
---------------------------------------------------------------------------------------]]
local statisticFrame

function Config:OnInitialize()
	LA:Debug("Config:OnInitialize()")

	-- register sounds
	LSM:Register("sound", "Auction Window Open", "Sound/Interface/AuctionWindowOpen.ogg")
	LSM:Register("sound", "Auction Window Close", "Sound/Interface/AuctionWindowClose.ogg")
	LSM:Register("sound", "Auto Quest Complete", "Sound/Interface/AutoQuestComplete.ogg")
	LSM:Register("sound", "Level Up", "Sound/Interface/LevelUp.ogg")
	LSM:Register("sound", "Player Invite", "Sound/Interface/iPlayerInviteA.ogg")
	LSM:Register("sound", "Raid Warning", "Sound/Interface/RaidWarning.ogg")
	LSM:Register("sound", "Ready Check", "Sound/Interface/ReadyCheck.ogg")

	-- general LootAppraiser configuration
	AceConfigRegistry:RegisterOptionsTable(LootAppraiser, options.args.general)
	AceConfigRegistry:RegisterOptionsTable(LootAppraiser .. " Statistic", options.args.statistic, LootAppraiser)

	local lootAppraiserConfig = AceConfigDialog:AddToBlizOptions(LootAppraiser)
	lootAppraiserConfig.default = Config.resetDB -- add reset function

	statisticFrame = AceConfigDialog:AddToBlizOptions(LootAppraiser .. " Statistic", "Statistic", LootAppraiser)
	LA:prepareStatisticGroups() -- prepare statistic groups

	--testFrame = AceConfigDialog:AddToBlizOptions(LootAppraiser .. " Test", "Test", LootAppraiser) -- test
	--test()

	-- Fix sink config options
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.order = 200
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.inline = true
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.name = ""
end


function Config:OnEnable()
end


function Config:OnDisable()
end


--[[-------------------------------------------------------------------------------------
-- reset loot appraiser db
---------------------------------------------------------------------------------------]]
function Config.resetDB()
	LA:Debug("Config.resetDB")

	LA.db:ResetProfile(false, true)

	AceConfigRegistry:NotifyChange(LootAppraiser)
end


function LA:prepareStatisticGroups()
	options.args.statistic.args = Config:getStatisticGroups()
end


local groups = {}
function Config:test()
	local appName = LootAppraiser .. " Statistic"
	local name = "Statistic 2"
	local parent = LootAppraiser

	-- blizz options group
	local blizzOptionsGrp = AceGUI:Create("BlizOptionsGroup")
	blizzOptionsGrp:SetName(name or appName, parent)
	blizzOptionsGrp:SetTitle(name or appName)
	blizzOptionsGrp:SetUserData("appName", appName)
	blizzOptionsGrp:SetLayout("fill")
	InterfaceOptions_AddCategory(blizzOptionsGrp.frame)

	-- scroll frame
	--[[
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	blizzOptionsGrp:AddChild(scrollFrame)
	]]

	-- dropdown group
	local select = AceGUI:Create("DropdownGroup")
	select:SetLayout("fill")
	select:SetTitle("")

	-- prepare select entries
	local grouplist = {}
	local key

	local sessions = LA:getSessions()
	for _, session in ipairs(sessions) do
		local sessionEnd = session["end"]

		if sessionEnd ~= nil then
			local sessionMapID = session["mapID"]
			local sessionStart = session["start"]
			local sessionEnd = session["end"]
			local liv = session["liv"]

			-- group name
			local grpID
			local groupName
			if sessionMapID ~= nil then
				grpID = "grp" .. tostring(sessionMapID)
				groupName = GetRealZoneText()
			else
				grpID = "grgUndefined"
				groupName = "-Undefined-"
			end

			-- get group or create new if no group exists
			local grp = groups[grpID]
			if grp == nil then
				--grp = prepareMapGroup(groupName, #groups+1)
				grp = AceGUI:Create("ScrollFrame")
				grp:SetLayout("flow")

				groups[grpID] = grp
			end

			--local scrollFrame = AceGUI:Create("ScrollFrame")
			--scrollFrame:SetLayout("flow")

			--local container = AceGUI:Create("InlineGroup")
			--container:SetTitle(groupName)
			--container:SetLayout("fill")
			--scrollFrame:AddChild(container)

			-- row group (with name-server - datetime)
			local t = date("*t", sessionStart)
			local player = session["player"] or ""
			local rowTitle = player .. " - " .. date("%m/%d/%Y %I:%M %p", session["start"])

			local rowGrp = AceGUI:Create("InlineGroup")
			rowGrp:SetTitle(rowTitle)
			rowGrp:SetLayout("flow")
			rowGrp:SetFullWidth(true)
			grp:AddChild(rowGrp)

			-- duration
			local sessionDuration = sessionEnd - sessionStart

			local labelDuration = AceGUI:Create("Label")
			labelDuration:SetText(SecondsToTime(sessionDuration))
			labelDuration:SetWidth(170)
			labelDuration:SetFontObject(GameFontHighlightSmall)
			rowGrp:AddChild(labelDuration)
			
			-- looted item value
			local formattedLiv = LA.TSM:FormatTextMoney(liv) or 0

			local labelLiv = AceGUI:Create("Label")
			labelLiv:SetText(formattedLiv)
			labelLiv:SetWidth(170)
			labelLiv:SetFontObject(GameFontHighlightSmall)
			labelLiv.label:SetJustifyH("RIGHT")
			rowGrp:AddChild(labelLiv)

			-- liv / hour
			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end

			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)

			local labelLivPerHour = AceGUI:Create("Label")
			labelLivPerHour:SetText(livGoldPerHour .. "|cffffd100g|r/h")
			labelLivPerHour:SetWidth(170)
			labelLivPerHour:SetFontObject(GameFontHighlightSmall)
			labelLivPerHour.label:SetJustifyH("RIGHT")
			rowGrp:AddChild(labelLivPerHour)


			--local label = AceGUI:Create("Label")
			--label:SetText("Label " .. tostring(i))
			--label:SetFontObject(GameFontHighlightSmall)
			--label:SetFullWidth(true)
			--container:AddChild(label)

			--groups[grpID] = scrollFrame

			grouplist[grpID] = groupName
			if not key then
				key = grpID
			end
		end
	end
	
	select:SetGroupList(grouplist)
	select:SetCallback("OnGroupSelected", Config.onGroupSelected)
	--select:SetGroup(key)
	blizzOptionsGrp:AddChild(select)

end


function Config.onGroupSelected(widget, event, value)
	LA:Debug("    value=" .. value)

	widget:ReleaseChildren()

	local group = groups[value]
	if group ~= nil then
		widget:AddChild(groups[value])
	end
end


function Config:getOrCreateZoneGrp(groups, session, order)
	-- group name and ID
	local sessionMapID = session["mapID"]

	local grpID
	local groupName
	if sessionMapID ~= nil then
		grpID = "zone" .. tostring(sessionMapID)
		groupName =  GetRealZoneText()
	else
		grpID = "grgUndefined"
		groupName = "-Undefined-"
	end

	local zoneGrp = groups[grpID]
	if zoneGrp == nil then
		zoneGrp = {
			type = "group",
			--order = order,
			name = groupName,
			args = {
				-- group by dropdown
				groupBy = {
					type = "select",
					order = order,
					name = "Group by",
					desc = "TBD",
					values = Config.SESSIONDATA_GROUPBY,
					inline = true,
					get = function(info) 
						if LA.db.profile.sessionData[info[#info]] == nil then
							LA.db.profile.sessionData[info[#info]] = "datetime"
						end
						return LA.db.profile.sessionData[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.sessionData[info[#info]] = value

						options.args.statistic.args = Config:getStatisticGroups()
					end,
				},
				-- empty line
				newline = {
					type = "description",
					order = order+1,
					name = " ",
					width = "full",
				},
			},
			plugins = {
			},
		}

		groups[grpID] = zoneGrp
	end

	return zoneGrp
end


function Config:createSessionGrp(session, order)
	-- get group by information
	local groupBy = LA.db.profile.sessionData.groupBy
	if groupBy == nil then
		groupBy = "datetime"
	end

	-- prepare name
	local name
	if groupBy == "datetime" then
		name = date("%m/%d/%Y %I:%M %p", session["start"])
	elseif groupBy == "liv" then
		local liv = session["liv"]

		name = LA.TSM:FormatTextMoney(liv) or 0
	elseif groupBy == "livPerHour" then
		local liv = session["liv"] or 0
		local sessionStart = session["start"]
		local sessionEnd = session["end"]
		local sessionDuration = sessionEnd - sessionStart

		local factor = 3600
		if sessionDuration < factor then
			factor = sessionDuration
		end

		local livGold = floor(liv/10000)
		local livGoldPerHour = floor(livGold/sessionDuration*factor)

		name = livGoldPerHour .. "|cffffd100g|r/h"
	end

	local sessionGrp = {
		type = "group",
		--order = order,
		name = name,
		args = {
		},
		plugins = {
		},
	}

	return sessionGrp
end


function Config:addSessionData(group, key, label, value, order)
	-- label
	group.args["label_" .. key .. "_" .. order] = {
		type = "description", 
		order = order, 
		name = label,
		width = "normal", 
	}

	-- value
	group.args["value_" .. key .. "_" .. order] = {
		type = "description", 
		order = order+1, 
		name = value,
		width = "normal", 
	}

	-- new line
	group.args["newline_" .. key .. "_" .. order] = {
		type = "description",
		order = order+2,
		name = "",
		width = "full",
	}
end


function Config:addEmptyLine(group, order)
	-- empty line
	group.args["newline_" .. order] = {
		type = "description",
		order = order,
		name = " ",
		width = "full",
	}
end

--[[-------------------------------------------------------------------------------------
-- prepare statistic groups
---------------------------------------------------------------------------------------]]
function Config:getStatisticGroups()
	LA:Debug("Config:getStatisticGroups")

	local groups = {}

	local sessions = LA:getSessions()
	for index, session in ipairs(sessions) do
		local sessionEnd = session["end"]
		
		if sessionEnd ~= nil then
			local sessionMapID = session["mapID"]
			local sessionStart = session["start"]
			local liv = session["liv"] or 0

			local zoneGrp = Config:getOrCreateZoneGrp(groups, session, index)

			-- add session to zone
			local sessionGrp = Config:createSessionGrp(session, index) -- TODO add group by
			zoneGrp.args["session" .. index] = sessionGrp

			-- date time
			Config:addSessionData(sessionGrp, "datetime", "Date:", date("%m/%d/%Y %I:%M %p", sessionStart), (index+10))

			-- player-realm
			Config:addSessionData(sessionGrp, "char", "Character:", session["player"], (index+20))

			-- duration
			local sessionDuration = sessionEnd - sessionStart
			Config:addSessionData(sessionGrp, "duration", "Duration:", SecondsToTime(sessionDuration), (index+30))

			-- empty line
			Config:addEmptyLine(sessionGrp, (index+40))

			-- looted item value
			local formattedLiv = LA.TSM:FormatTextMoney(liv) or 0
			Config:addSessionData(sessionGrp, "liv", "Looted Item Value:", formattedLiv, (index+50))

			-- ...per hour			
			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end

			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)
			Config:addSessionData(sessionGrp, "liv", "...per Hour:", livGoldPerHour .. "|cffffd100g|r/h", (index+60))

			-- empty line
			Config:addEmptyLine(sessionGrp, (index+70))

			-- noteworthy items
			local noteworthyItems = session["noteworthyItems"]
			local niCount = LA:tablelength(noteworthyItems)
			Config:addSessionData(sessionGrp, "noteworthyItemsCount", "|cffffd100Noteworthy Items:|r", tostring(niCount), (index+70))

			--if niCount > 0 then
				-- add inline group
				local noteworthyItemsGroup = {
					type = "group",
					order = (index+80),
					inline = true,
					args = {
					},
					plugins = {
					},
				}
				sessionGrp.args["noteworthyItems"] = noteworthyItemsGroup

				local i = 0
				for itemID, quantity in pairs(noteworthyItems) do
					--LA:Debug("    " .. tostring(itemID) .. " x" .. tostring(quantity))

					if itemID ~= nil then
						local itemLink = select(2, GetItemInfo(itemID))

						noteworthyItemsGroup.args["item_" .. tostring(itemID)] = {
							type = "description",
							order = i,
							name = tostring(itemLink) .. " x" .. tostring(quantity),
							width = "full",
						}

						i = i+10
					end
				end
			--end

		end
	end
	
	return groups
end


function Config:formatBoolean(flag)
	if flag then
		return "|cff00ff00" .. "activated" .. "|r"
	else
		return "|cffff0000" .. "deactivated" .. "|r"
	end
end


function Config:getIconDelete()
	return "Interface\\AddOns\\" .. LA.METADATA.NAME .. "\\Media\\delete2", 16, 16
end


function Config:deleteStatisticEntry(entryID)
	--LA:Debug("  deleteStatisticEntry: entryID=" .. tostring(entryID))
end


function Config:SettingsChangeAllowed(setting)
	LA:D("SettingsChangeAllowed: name=" .. tostring(setting))
	if LA.regModules then
		for name, data in pairs(LA.regModules) do
			if data and data.callback and data.callback.settingsChangeAllowed then
				local callback = data.callback.settingsChangeAllowed

				return callback(setting)
			end
		end
	end
	return true -- default
end