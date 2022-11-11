local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")
local PlayerUtils = require("PlayerUtils")

local Player = setmetatable({}, BaseObject)
Player.__index = Player

function Player.new(player, binders)
	local self = setmetatable(BaseObject.new(player), Player)

	self._binders = assert(binders, "No binders")

	self._editDisplayEvent = Instance.new("RemoteEvent")
	self._editDisplayEvent.Name = "EditDisplayEvent"
	self._editDisplayEvent.Parent = player

	self:_setup()

	return self
end

function Player:_setup()
	self._maid:GiveTask(self._binders:PromiseBinder("Slime"):Then(function(slimeBinder)
		for _, slime in slimeBinder:GetAll() do
			if self._obj.Character then
				slime:PivotTo(self._obj.Character:GetPivot())
			end
		end

		self._maid:GiveTask(slimeBinder:GetClassAddedSignal():Connect(function(slimeClass)
			if slimeClass._player == self._obj then
				self._maid:GiveTask(self._obj.CharacterAdded:Connect(function(character)
					slimeClass._obj:PivotTo(character:GetPivot())

					local characterRemoved
					characterRemoved = character.AncestryChanged:Connect(function()
						if character:IsDescendantOf(game) then
							return
						end

						character:Destroy()
						characterRemoved:Disconnect()
					end)
				end))
			end
		end))
	end))

	self._obj:SetAttribute("DisplayName", self._obj.DisplayName)
	self._obj:SetAttribute("DisplayColor", PlayerUtils.getDefaultNameColor(self._obj.Name))
end

return Player
