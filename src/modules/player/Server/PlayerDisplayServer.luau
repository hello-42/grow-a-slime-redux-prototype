local require = require(script.Parent.loader :: ModuleScript).load(script)
local Color = require("Color")
local Maid = require("Maid")
local TextFilterUtils = require("TextFilterUtils")

local PlayerDisplayServer = {}

local EDIT_DISPLAY_DEBOUNCE = 0.25
local EDIT_DISPLAY_EXPECTS = {
	DisplayName = "string",
	DisplayColor = "string",
}

local function handleDisplayEditRequest(playerClass)
	local lastSignal = os.clock()
	local editRequestMaid = Maid.new()

	editRequestMaid:GiveTask(playerClass._editDisplayEvent.OnServerEvent:Connect(function(player, payload)
		if (os.clock() - lastSignal) <= EDIT_DISPLAY_DEBOUNCE or player ~= playerClass._obj then
			return
		end

		lastSignal = os.clock()

		if typeof(payload) == "table" then
			local safePayload = {}

			for attribute, expects in EDIT_DISPLAY_EXPECTS do
				if typeof(payload[attribute]) ~= expects then
					continue
				end

				safePayload[attribute] = payload[attribute]
			end

			if next(safePayload) then
				if safePayload.DisplayColor then
                    local _, color = pcall(function()
                        return Color.Color.named(safePayload.DisplayColor):toColor3()
                    end)

                    if typeof(color) == "Color3" then
                        player:SetAttribute("DisplayColor", Color3.fromHSV(color:ToHSV(), 0.6, 0.9))
                    end
				end
				if safePayload.DisplayName then
					editRequestMaid:GivePromise(
						TextFilterUtils.promiseNonChatStringForBroadcast(
							safePayload.DisplayName,
							player.UserId,
							Enum.TextFilterContext.PublicChat
						)
							:Then(function(filteredDisplayName)
								local textWasFiltered = string.find(filteredDisplayName, "#") ~= nil

								if textWasFiltered == false then
									player:SetAttribute("DisplayName", filteredDisplayName)
								end
							end)
					)
				end
			end
		end
	end))

	return editRequestMaid
end

function PlayerDisplayServer:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._maid = Maid.new()
	self._gameBindersServer = self._serviceBag:GetService(require("GameBindersServer"))
end

function PlayerDisplayServer:Start()
	local playerBinder = self._gameBindersServer:Get("Player")
	local playerClasses = {}

	for _, playerClass in playerBinder:GetAll() do
		playerClasses[playerClass] = handleDisplayEditRequest(playerClass)
	end

	for _, event in { "Added", "Removed" } do
		playerBinder["GetClass" .. event .. "Signal"](playerBinder):Connect(function(...)
			local initialized = playerClasses[...]

			if initialized then
				initialized:Destroy()
				playerClasses[...] = nil

				return
			end

			playerClasses[...] = handleDisplayEditRequest(...)
		end)
	end
end

return PlayerDisplayServer
