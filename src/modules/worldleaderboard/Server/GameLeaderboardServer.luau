local CollectionService = game:GetService("CollectionService")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Signal = require("Signal")

local GameLeaderboardServer = {}

local CHANGE_SCOPE_TIMER = 10
local LEADERBOARD = CollectionService:GetTagged("WORLD_LEADERBOARD")[1]

function GameLeaderboardServer:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._gameBindersServer = self._serviceBag:GetService(require("GameBindersServer"))

	self._scope = LEADERBOARD:GetAttribute("Scope")
	self._leaderboardEvent = Signal.new()
end

function GameLeaderboardServer:Start()
	local slimes = {}

	self._leaderboardEvent:Connect(function()
		local rankedSlimes = {}

		for slime in slimes do
			table.insert(rankedSlimes, {
				slime,
				slime._obj:GetAttribute(self._scope),
			})
		end

		table.sort(rankedSlimes, function(a, b)
			return a[2] > b[2]
		end)

		for i = 1, 3 do
			local dummy = LEADERBOARD.Parent[tostring(i)].Dummy
			local dummyHumanoid = dummy.Humanoid
			local dummyHumanoidDescription = dummyHumanoid:FindFirstChildOfClass("HumanoidDescription")

			if dummyHumanoidDescription then
				dummyHumanoidDescription:Destroy()
			end

			local player = if rankedSlimes[i] then rankedSlimes[i][1]["_player"] else nil
			local character = if player then player.Character else nil

			if player then
				for attribute in dummy:GetAttributes() do
					local playerValue = player:GetAttribute(attribute)

					if playerValue then
						dummy:SetAttribute(attribute, playerValue)
					end
				end

				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")

					if humanoid then
						local humanoidDescription = humanoid:FindFirstChildOfClass("HumanoidDescription")

						if humanoidDescription then
							task.spawn(pcall, dummyHumanoid.ApplyDescription, dummyHumanoid, humanoidDescription)
						end
					end
				end
			end
		end
	end)

	self._gameBindersServer:PromiseBinder("Slime"):Then(function(slimeBinder)
		local function slimeExistenceEvent(slimeClass)
			local found = slimes[slimeClass]

			if found then
				found:Disconnect()

				slimes[slimeClass] = nil
			else
				slimes[slimeClass] = slimeClass._slimeChangedEvent:Connect(function()
					self._leaderboardEvent:Fire()
				end)
			end
		end

		for _, slimeClass in slimeBinder:GetAll() do
			slimeExistenceEvent(slimeClass)
		end

		slimeBinder:GetClassAddedSignal():Connect(slimeExistenceEvent)
		slimeBinder:GetClassRemovedSignal():Connect(slimeExistenceEvent)
	end)

	task.defer(function()
		while task.wait(CHANGE_SCOPE_TIMER) do
			local scope = LEADERBOARD:GetAttribute("Scope") or "Score"

			LEADERBOARD:SetAttribute(
				"Scope",
				if scope == "Score" then "Experience" elseif scope == "Experience" then "Level" else "Score"
			)

			self._leaderboardEvent:Fire()
		end
	end)
end

return GameLeaderboardServer
