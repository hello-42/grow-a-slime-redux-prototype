local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")

local Overhead = setmetatable({}, BaseObject)
Overhead.__index = Overhead

function Overhead.new(character)
	local self = setmetatable(BaseObject.new(character), Overhead)

	return self
end

return Overhead
