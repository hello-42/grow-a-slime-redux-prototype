local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")
local Signal = require("Signal")

local Constants = require("Constants")

local Character = setmetatable({}, BaseObject)
Character.__index = Character

local CHARACTER_ATTRIBUTE_EXPECTS = {
	DisplayName = "string",
	DisplayColor = "Color3",
}

function Character.new(character, binders)
	local self = setmetatable(BaseObject.new(character), Character)

	self._binders = assert(binders, "No binders")
	self._player = Players:GetPlayerFromCharacter(self._obj)

	self._displayAttributes = {
		DisplayName = self._obj.Name,
		DisplayColor = Color3.fromHSV(Constants.Random:NextNumber(), 0.6, 0.9),
	}
	self._displayAttributesChanged = Signal.new()

	self:_setup()

	return self
end

function Character:_setup()
	self._maid:GiveTask(self._displayAttributesChanged)

	self._maid:GiveTask(self._displayAttributesChanged:Connect(function()
		for attribute, expects in CHARACTER_ATTRIBUTE_EXPECTS do
			local value = self._displayAttributes[attribute]

			if typeof(value) == expects then
				self._obj:SetAttribute(attribute, value)
			end
		end
	end))

	if self._player then
		self._player.AttributeChanged:Connect(function(attribute)
			local value = self._player:GetAttribute(attribute)
			local expects = CHARACTER_ATTRIBUTE_EXPECTS[attribute]

			if expects and typeof(value) == expects then
				self._displayAttributes[attribute] = value
				self._displayAttributesChanged:Fire()
			end
		end)

		for attribute, value in self._player:GetAttributes() do
			local expects = CHARACTER_ATTRIBUTE_EXPECTS[attribute]

			if expects and typeof(value) == expects then
				self._displayAttributes[attribute] = value
				self._displayAttributesChanged:Fire()
			end
		end
	end

	for _, instance in self._obj:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.CollisionGroup = "Characters"
		end
	end

	self._displayAttributesChanged:Fire()
end

return Character
