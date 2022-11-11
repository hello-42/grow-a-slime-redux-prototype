local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")

local Character = setmetatable({}, BaseObject)
Character.__index = Character

function Character.new(character)
	local self = setmetatable(BaseObject.new(character), Character)

	task.defer(function()
		self._player = Players:GetPlayerFromCharacter(self._obj)
	end)

	return self
end

return Character
