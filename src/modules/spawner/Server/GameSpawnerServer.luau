local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local require = require(script.Parent.loader :: ModuleScript).load(script)

local Assets = ReplicatedStorage.Assets

local Constants = require("Constants")
local R = Constants.Random

local GameSpawnerServer = {}

local EDIBLE_DATA_TYPES = {
	"Banana",
	"Cake",
	"Coconut",
	"Haybale",
	"Rain",
	"Shrub",
}
local DEFAULT_ROUND_DATA = {
	RoundEpochs = 3,
	RoundLength = 10,
}
local DEFAULT_SPAWN_DATA = {
	Experience = 10,
	Count = 15,
	RoundEpochs = 3,
	RoundLength = 10,
}
local SPAWNERS = CollectionService:GetTagged("Spawners")[1]
local SPAWNABLES = CollectionService:GetTagged("Spawnables")[1]
local CLOUDS = CollectionService:GetTagged("Clouds")[1]

function GameSpawnerServer:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._weatherServer = self._serviceBag:GetService(require("GameWeatherServer"))
end

function GameSpawnerServer:Start()
	local activeSpawners = table.clone(EDIBLE_DATA_TYPES)
	table.remove(activeSpawners, table.find(activeSpawners, "Rain"))

	self._weatherServer._weatherChanged:Connect(function()
		if self._weatherServer._storming == true then
			table.insert(activeSpawners, if not table.find(activeSpawners, "Rain") then "Rain" else nil)
		else
			local wasStorming = table.find(activeSpawners, "Rain")

			if wasStorming then
				table.remove(activeSpawners, wasStorming)
			end
		end
	end)

	for _, spawnable in { "Fish", table.unpack(EDIBLE_DATA_TYPES) } do
		local data = Constants[spawnable] or DEFAULT_SPAWN_DATA
		local spawners = if spawnable == "Rain" then CLOUDS else SPAWNERS[spawnable]

		for _, t in { DEFAULT_ROUND_DATA, DEFAULT_SPAWN_DATA } do
			for index, value in t do
				data[index] = data[index] or value
			end
		end

		task.spawn(function()
			while task.wait() do
				if spawnable ~= "Fish" and typeof(table.find(activeSpawners, spawnable)) ~= "number" then
					task.wait(data.RoundLength)
				else
					local elapsed = 0

					for n = 1, data.RoundEpochs do
						local elapsedEpoch = R:NextNumber((2 / 3), (7 / 6)) * data.RoundLength

						if n == data.RoundEpochs then
							elapsedEpoch = data.RoundLength - elapsed
						end

						local currentEdibles = #CollectionService:GetTagged(spawnable)
						local waitTime = math.clamp(((elapsedEpoch / (data.Count - currentEdibles)) / 2), (1 / 60), 1)
						local endClock = os.clock() + elapsedEpoch

						repeat
							task.wait(waitTime)

							if
								os.clock() >= endClock
								or (data.Count - #CollectionService:GetTagged(spawnable)) <= 0
							then
								break
							end

							local xspawners = spawners:GetChildren()
							local spawner = xspawners[R:NextInteger(1, #xspawners)]

							local radius = ((spawner.Size * (Vector3.xAxis + Vector3.zAxis)).Magnitude / 2)
							local pivot = spawner:GetPivot()
								* CFrame.new(
									R:NextNumber(-radius, radius),
									-(spawner.Size.Y / 2),
									R:NextNumber(-radius, radius)
								)

							local xedible = Assets[spawnable]:Clone()
							xedible:PivotTo(pivot * CFrame.new(0, (xedible.Size.Y / 2), 0))
							xedible.Parent = SPAWNABLES[spawnable]

							task.wait(waitTime)

							if
								os.clock() >= endClock
								or (data.Count - #CollectionService:GetTagged(spawnable)) <= 0
							then
								break
							end
						until false

						elapsed += elapsedEpoch
					end
				end
			end
		end)
	end
end

return GameSpawnerServer
