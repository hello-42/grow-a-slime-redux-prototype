local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")
local Signal = require("Signal")
local spr = require("spr")

local Assets = ReplicatedStorage.Assets
local Slime_Model = Assets.Slime

local Constants = require("Constants")
local R = Constants.Random

local Slime = setmetatable({}, BaseObject)
Slime.__index = Slime

local SPAWNABLES = CollectionService:GetTagged("Spawnables")[1]

function Slime.new(player)
	local self = setmetatable(BaseObject.new(Slime_Model:Clone()), Slime)

	self._player = player

	self.Experience = 0
	self.Level = 1
	self.Score = 0

	self._slimeChangedEvent = Signal.new()

	self:_setup()

	return self
end

function Slime:_setup()
	local function sizeContainerExtents()
		spr.target(self._obj, 0.8, 0.7, {
			Size = Vector3.one * math.clamp(self._obj._container:GetExtentsSize().Magnitude, 1, 5),
		})
	end

	self._maid:GiveTask(self._obj._container.ChildAdded:Connect(sizeContainerExtents))
	self._maid:GiveTask(self._obj._container.ChildRemoved:Connect(sizeContainerExtents))

	self._maid:GiveTask(self._obj.Touched:Connect(function(part)
		local edibleAttribute = part:GetAttribute("Edible")

		if edibleAttribute then
			self:_consume(part, edibleAttribute)
		end
	end))

	self._maid:GiveTask(self._player.AttributeChanged:Connect(function(attribute)
		if attribute == "DisplayColor" then
			self._obj.Color = self._player:GetAttribute("DisplayColor")
		end
	end))

	for attribute, value in
		{
			Alpha = math.clamp(self.Experience / (self.Level * 50), 0, 1),
			Experience = self.Experience,
			Level = self.Level,
			Score = self.Score,
		}
	do
		self._obj:SetAttribute(attribute, value)
	end

	self._obj:SetAttribute("UserId", self._player.UserId)

	self._maid:GiveTask(self._obj)

	self._obj.Parent = SPAWNABLES.Slime
end

function Slime:_consume(part, index)
	local data = Constants[index]

	if data then
		local limits = data.Limits
		local requires = data.Requires

		if limits then
			for idx, limit in limits do
				if self[idx] >= limit then
					return
				end
			end
		end

		if requires then
			for idx, required in requires do
				if self[idx] < required then
					return
				end
			end
		end
	end

	self.Experience += if data then (data.Experience or 10) else 10
	self.Score += if data then (data.Score or 1) else 1

	if self.Experience >= (self.Level * 50) then
		self.Experience = 0
		self.Level += 1
	end

	for attribute, value in
		{
			Alpha = math.clamp(self.Experience / (self.Level * 50), 0, 1),
			Experience = self.Experience,
			Level = self.Level,
			Score = self.Score,
		}
	do
		self._obj:SetAttribute(attribute, value)
	end

	self._slimeChangedEvent:Fire()

	self:_digest(part)
end

function Slime:_digest(part)
	for _, attribute in part:GetAttributes() do
		part:SetAttribute(attribute, nil)
	end

	if not table.find(CollectionService:GetTags(part), "Rain") then
		for _, instance in { part, table.unpack(part:GetDescendants()) } do
			if part:IsA("BasePart") then
				part.CanQuery = false
				part.CanTouch = false
				part.CanCollide = false
				part.Anchored = false
				part.Massless = true

				TweenService:Create(part, TweenInfo.new(5), { Transparency = 1 }):Play()

				continue
			end

			instance:Destroy()
		end

		task.delay(5, part.Destroy, part)
	end

	local internalPositionOffset = math.abs(part.Size.Magnitude - self._obj.Size.Magnitude) / 8
	part:PivotTo(
		self._obj:GetPivot()
			* CFrame.new(
				R:NextNumber(-internalPositionOffset, internalPositionOffset),
				R:NextNumber(-internalPositionOffset, internalPositionOffset),
				R:NextNumber(-internalPositionOffset, internalPositionOffset)
			)
	)

	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = self._obj
	weldConstraint.Part1 = part
	weldConstraint.Parent = part

	local sound = part:FindFirstChildOfClass("Sound")
	if sound then
		sound:Play()
	end

	part.Parent = self._obj._container
end

return Slime
