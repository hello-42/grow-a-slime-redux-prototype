local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local PromiseGetRemoteEvent = require("PromiseGetRemoteEvent")
local Signal = require("Signal")

local Player = Players.LocalPlayer

local SlimekeeperClient = {}

local REMOTE_SIGNAL_DB = 0.2

function SlimekeeperClient:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._gameBindersClient = self._serviceBag:GetService(require("GameBindersClient"))

	self._localPlayerAdded = Signal.new()
	self._slimekeeperSignal = Signal.new()
end

function SlimekeeperClient:Start()
	local lastSignal = os.clock()

	self._gameBindersClient:PromiseBinder("Player"):Then(function(playerBinder)
		for _, playerClass in playerBinder:GetAll() do
			if playerClass._obj ~= Player then
				continue
			end

			self._localPlayerAdded:Fire(playerClass)
		end

		playerBinder:GetClassAddedSignal():Connect(function(playerClass)
			if playerClass._obj ~= Player then
				return
			end

			self._localPlayerAdded:Fire(playerClass)
		end)
	end)

	self._localPlayerAdded:Connect(function(playerClass)
		self._slimekeeperSignal:Connect(function(action, ...)
			if lastSignal + REMOTE_SIGNAL_DB >= os.clock() then
				return
			end

			if self._gameResetRequestEvent and action == "Reset" then
				self._gameResetRequestEvent:FireServer()
			elseif action == "Change" then
				playerClass._editDisplayEventSignal:Fire(...)
			end
		end)
	end)

	PromiseGetRemoteEvent("GameResetRequestEvent"):Then(function(remoteEvent)
		self._gameResetRequestEvent = remoteEvent
	end)
end

return SlimekeeperClient
