local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")

local Fusion = require("fusion")
local Hydrate = Fusion.Hydrate
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring

local Assets = ReplicatedStorage.Assets
local Overhead_Gui = Assets.Overhead

local Constants = require("Constants")

local Overhead = setmetatable({}, BaseObject)
Overhead.__index = Overhead

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local OverheadContainer = Instance.new("Folder")

OverheadContainer.Name = "OverheadContainer"
OverheadContainer.Parent = PlayerGui

local OVERHEAD_ATTRIBUTE_EXPECTS = {
	DisplayName = "string",
	DisplayColor = "Color3",
}

function Overhead.new(character)
	local self = setmetatable(BaseObject.new(Overhead_Gui:Clone()), Overhead)

	self._model = character
	self._text = Value(self._model.Name)
	self._color = Value(Color3.fromHSV(Constants.Random:NextNumber(), 0.6, 0.9))
	self._groupTransparency = Value(0)

	self:_setup()

	return self
end

function Overhead:_setup()
	self._maid:GiveTask(self._model.AttributeChanged:Connect(function(attribute)
		local value = self._model:GetAttribute(attribute)
		local expects = OVERHEAD_ATTRIBUTE_EXPECTS[attribute]

		if expects and typeof(value) == expects then
			if typeof(value) == "string" then
				self._text:set(value)
			elseif typeof(value) == "Color3" then
				self._color:set(value)
			end
		end
	end))

	local humanoid = self._model:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	for attribute, value in self._model:GetAttributes() do
		local expects = OVERHEAD_ATTRIBUTE_EXPECTS[attribute]

		if expects and typeof(value) == expects then
			if typeof(value) == "string" then
				self._text:set(value)
			elseif typeof(value) == "Color3" then
				self._color:set(value)
			end
		end
	end

	Hydrate(self._obj.CanvasGroup)({
		GroupTransparency = Spring(self._groupTransparency, 20),
	})

	for _, descendant in self._obj:GetDescendants() do
		if descendant:IsA("TextLabel") then
			Hydrate(descendant)({
				TextColor3 = Spring(Computed(function()
					return Color3.fromHSV(self._color:get():ToHSV(), 0.6, 0.9)
				end)),

				Text = self._text,
			})
		end
	end

	task.defer(function()
		self._obj.Adornee = if self._model:IsA("Model") then (self._model.PrimaryPart or self._model) else self._model
		self._obj.Enabled = (self._obj.Adornee and self._obj.Adornee:IsDescendantOf(workspace))
	end)

	self._obj.Name = self._model.Name
	self._obj.Parent = OverheadContainer

	self._maid:GiveTask(self._obj)
end

return Overhead
