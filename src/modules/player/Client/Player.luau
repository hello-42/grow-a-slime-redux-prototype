local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")
local Signal = require("Signal")

local Player = setmetatable({}, BaseObject)
Player.__index = Player

function Player.new(player)
	local self = setmetatable(BaseObject.new(player), Player)

	self._editDisplayEventSignal = Signal.new()

	return self
end

return Player
