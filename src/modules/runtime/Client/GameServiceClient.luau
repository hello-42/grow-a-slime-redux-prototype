local require = require(script.Parent.loader :: ModuleScript).load(script)

local GameServiceClient = {}

function GameServiceClient:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._serviceBag:GetService(require("GameBindersClient"))
	self._serviceBag:GetService(require("PlayerDisplayClient"))
	self._serviceBag:GetService(require("GameFishClient"))
	self._serviceBag:GetService(require("GameSlimekeeperClient"))
	self._serviceBag:GetService(require("OverheadTrackerClient"))
end

return GameServiceClient
