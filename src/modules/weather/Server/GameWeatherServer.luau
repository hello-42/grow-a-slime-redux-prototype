local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Signal = require("Signal")

local Constants = require("Constants")
local R = Constants.Random

local GameWeatherService = {}

local CLOUDS = CollectionService:GetTagged("Clouds")[1]:GetChildren()

function GameWeatherService:Init()
	self._weatherChanged = Signal.new()

	Lighting.ClockTime = 17
end

function GameWeatherService:Start()
	self._weatherChanged:Connect(function()
		if self._storming then
			for _, cloud in CLOUDS do
				local cloudColor = R:NextNumber(0.25, 0.75)
				local cloudSize = cloud.Size

				cloud.Size = Vector3.zero
				cloud.Transparency = 1

				task.delay(60, function()
					cloud.Size = cloudSize
					cloud.Color = Color3.new(cloudColor, cloudColor, cloudColor)
				end)

				TweenService:Create(cloud, TweenInfo.new(5, Enum.EasingStyle.Linear), {
					Size = cloudSize,
					Transparency = 0,
					Color = Color3.new(cloudColor, cloudColor, cloudColor),
				}):Play()

				task.delay(50, function()
					TweenService:Create(cloud, TweenInfo.new(5, Enum.EasingStyle.Linear), {
						Size = Vector3.zero,
						Transparency = 1,
						Color = Color3.new(1, 1, 1),
					}):Play()

					task.wait(5)

					cloud.Size = cloudSize
				end)
			end

			workspace.Terrain.Clouds.Color = Color3.new(1, 1, 1)
			workspace.Terrain.Clouds.Cover = 0
			workspace.Terrain.Clouds.Density = 0

			task.delay(60, function()
				self._storming = false
				self._weatherChanged:Fire()
			end)

			TweenService:Create(workspace.Terrain.Clouds, TweenInfo.new(5, Enum.EasingStyle.Linear), {
				Density = 0.8,
				Cover = 0.8,
				Color = Color3.new(0.2, 0.2, 0.2),
			}):Play()

			task.delay(50, function()
				TweenService:Create(workspace.Terrain.Clouds, TweenInfo.new(5, Enum.EasingStyle.Linear), {
					Density = 0,
					Cover = 0,
					Color = Color3.new(1, 1, 1),
				}):Play()

				task.wait(5)

				workspace.Terrain.Clouds.Density = 0
				workspace.Terrain.Clouds.Cover = 0
				workspace.Terrain.Clouds.Color = Color3.new(1, 1, 1)
			end)
		end

		task.wait(60)

		self._storming = Constants.Random:NextInteger(1, 6) == 6
		self._weatherChanged:Fire()
	end)

	self._storming = true or Constants.Random:NextInteger(1, 6) == 6
	self._weatherChanged:Fire()
end

return GameWeatherService
