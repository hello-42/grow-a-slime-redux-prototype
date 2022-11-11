local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local PlayerThumbnailUtils = require("PlayerThumbnailUtils")
local BaseObject = require("BaseObject")

local Fusion = require("fusion")
local Value = Fusion.Value
local Computed = Fusion.Computed

local Constants = require("Constants")

local Interface = setmetatable({}, BaseObject)
Interface.__index = Interface

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local function getFusionThumbnailFromUserId(userId)
	return Computed(function()
		local value = Value("")

		PlayerThumbnailUtils.promiseUserThumbnail(userId):Then(function(thumbnailURL)
			value:set(thumbnailURL)
		end)

		return value
	end):get()
end

local function getInstanceDisplayColor(instance)
	return Computed(function()
		local value = Value(Color3.fromHSV(Constants.Random:NextNumber(), 0.6, 0.9))

		instance.AttributeChanged:Connect(function(attribute)
			if attribute == "DisplayColor" then
				local xvalue = Player:GetAttribute("DisplayColor")

				if typeof(xvalue) == "Color3" then
					value:set(xvalue)
				end
			end
		end)

		local displayColor = instance:GetAttribute("DisplayColor")

		if typeof(displayColor) == "Color3" then
			value:set(displayColor)
		end

		return Computed(function()
			return Color3.fromHSV(value:get():ToHSV(), 0.6, 0.9)
		end)
	end):get()
end

local Thumbnail = getFusionThumbnailFromUserId(Player.UserId)

local Color = getInstanceDisplayColor(Player)

function Interface.new(screenGui)
	local self = setmetatable(BaseObject.new(screenGui), Interface)

	self._player = Player
	self._playerGui = PlayerGui

	self._theme = {
		Color = Color,
		Thumbnail = Thumbnail,
	}

	self:_setup()

	return self
end

function Interface:_setup()
	self._theme = {
		Color = Computed(function()
			return Color:get()
		end),
		Thumbnail = Computed(function()
			return Thumbnail:get()
		end),
	}

	self._obj.Parent = self._playerGui
end

function Interface:_computeThumbnailFromUserId(...)
	return getFusionThumbnailFromUserId(...)
end

function Interface:_computeInstanceDisplayColor(...)
	return getInstanceDisplayColor(...)
end

return Interface
