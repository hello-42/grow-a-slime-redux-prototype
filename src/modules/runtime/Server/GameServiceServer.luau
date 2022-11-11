local require = require(script.Parent.loader :: ModuleScript).load(script)

local GameServiceServer = {}

function GameServiceServer:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._serviceBag:GetService(require("GameBindersServer"))
	self._serviceBag:GetService(require("PlayerDisplayServer"))
	self._serviceBag:GetService(require("SlimeTrackerServer"))
	self._serviceBag:GetService(require("GameSpawnerServer"))
	self._serviceBag:GetService(require("GameWeatherServer"))
	self._serviceBag:GetService(require("GameSlimekeeperServer"))
	self._serviceBag:GetService(require("GameLeaderboardServer"))
end

return GameServiceServer
