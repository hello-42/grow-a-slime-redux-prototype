local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Promise = require("Promise")

local PlayerDisplayClient = {}

local Player = Players.LocalPlayer

local EDIT_DISPLAY_DEBOUNCE = 0.25
local EDIT_DISPLAY_EXPECTS = {
	DisplayName = "string",
	DisplayColor = "string",
}

function PlayerDisplayClient:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._gameBindersClient = self._serviceBag:GetService(require("GameBindersClient"))
end

function PlayerDisplayClient:Start()
	local playerBinderPromise = self._gameBindersClient:PromiseBinder("Player")

	playerBinderPromise:Then(function(playerBinder)
		local players = playerBinder:GetAll()

		local promiseLocalPlayerClass = Promise.new()

		promiseLocalPlayerClass:Then(function(localPlayerClass)
			local editDisplayEvent = localPlayerClass._obj:WaitForChild("EditDisplayEvent")
			local lastSignal = os.clock()

			localPlayerClass._editDisplayEventSignal:Connect(function(data)
				if (os.clock() - lastSignal) <= EDIT_DISPLAY_DEBOUNCE then
					return
				end

				if typeof(data) == "table" then
					local payload = {
						DisplayName = data.DisplayName,
						DisplayColor = data.DisplayColor,
					}

					for attribute, expected in EDIT_DISPLAY_EXPECTS do
						if typeof(payload[attribute]) ~= expected then
							payload[attribute] = nil
						end
					end

					editDisplayEvent:FireServer(payload)
				end
			end)
		end)

		for _, playerClass in players do
			if playerClass._obj ~= Player then
				continue
			end

			promiseLocalPlayerClass:Resolve(playerClass)

			break
		end

		if promiseLocalPlayerClass:IsPending() then
			local added
			added = playerBinder:GetClassAddedSignal():Connect(function(playerClass)
				if playerClass._obj ~= Player then
					return
				end

				promiseLocalPlayerClass:Resolve(playerClass)

				added:Disconnect()
			end)
		end
	end)
end

return PlayerDisplayClient
