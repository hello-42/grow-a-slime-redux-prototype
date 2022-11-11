local TweenService = game:GetService("TweenService")
local require = require(script.Parent.loader :: ModuleScript).load(script)
local BaseObject = require("BaseObject")

local Rain = setmetatable({}, BaseObject)
Rain.__index = Rain

local FADE_RAIN_TWEEN = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Rain.new(rain)
	local self = setmetatable(BaseObject.new(rain), Rain)

	self:_setup()

	return self
end

function Rain:_setup()
	local sound = self._obj:FindFirstChildOfClass("Sound")

	self._maid:GiveTask(self._obj.Touched:Connect(function()
		if sound and not sound.IsPlaying then
			sound:Play()
		end

		task.delay(FADE_RAIN_TWEEN.Time, function()
			self._obj:Destroy()
		end)

		TweenService:Create(self._obj, FADE_RAIN_TWEEN, {
			Transparency = 1,
		}):Play()
	end))
end

return Rain
