local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")

local Slime = setmetatable({}, BaseObject)
Slime.__index = Slime

function Slime.new(player)
	local self = setmetatable(BaseObject.new(player), Slime)

	return self
end

return Slime
