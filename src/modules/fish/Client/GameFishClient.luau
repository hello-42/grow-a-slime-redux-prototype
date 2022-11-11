local CollectionService = game:GetService("CollectionService")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local spr = require("spr")

local GameFishClient = {}

local function animateFishSwimming(fish)
	spr.target(fish, 0, 0.2, {
		Position = (fish.CFrame * CFrame.new(2.75, 0, 0)).Position,
	})
end

function GameFishClient:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
end

function GameFishClient:Start()
	for _, fish in CollectionService:GetTagged("Fish") do
		animateFishSwimming(fish)
	end

	CollectionService:GetInstanceAddedSignal("Fish"):Connect(animateFishSwimming)
end

return GameFishClient
