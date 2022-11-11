local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Interface = require("Interface")
local Maid = require("Maid")
local Signal = require("Signal")

local Fusion = require("fusion")
local Hydrate = Fusion.Hydrate
local Cleanup = Fusion.Cleanup
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring

local Player = Players.LocalPlayer

local SlimekeeperView = setmetatable({}, Interface)
SlimekeeperView.__index = SlimekeeperView

local SLIMEKEEPER = CollectionService:GetTagged("Slimekeeper")[1]
local MIN_CIRCLE_RADIUS = 8
local MIN_CIRCLE_TIME = 2

function SlimekeeperView.new(screenGui, binders, serviceBag)
	local self = setmetatable(Interface.new(screenGui), SlimekeeperView)

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._binders = assert(binders, "No binders")

	self:_setup()

	return self
end

function SlimekeeperView:_setup()
	local maid = Maid.new()
	local maidSignal = Signal.new()

	maid:GiveTask(maidSignal:Connect(function(...)
		self:_init(...)

		maid:Destroy()
	end))

	maid:GivePromise(self._binders:PromiseBinder("Player"):Then(function(playerBinder)
		for _, playerClass in playerBinder:GetAll() do
			if playerClass._obj ~= Player then
				continue
			end

			maidSignal:Fire(playerClass)

			break
		end

		maid:GiveTask(playerBinder:GetClassAddedSignal():Connect(function(playerClass)
			if playerClass._obj ~= Player then
				return
			end

			maidSignal:Fire(playerClass)
		end))
	end))

	self._slimekeeperClient = self._serviceBag:GetService(require("GameSlimekeeperClient"))
end

function SlimekeeperView:_init(playerClass)
	local canStep = true
	local elapsedInRadius = 0
	local showSlimekeeper = Value(false)

	local menuVisible = Value(true)
	local changeInformationVisible = Value(false)

	Hydrate(self._obj.Main)({
		Position = Spring(Computed(function()
			return UDim2.fromScale(0.5, (showSlimekeeper:get() and 0.5) or 1.5)
		end)),

		[Cleanup] = {
			UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
				if
					inputObject.UserInputType == Enum.UserInputType.MouseButton1
					and showSlimekeeper:get()
					and not gameProcessedEvent
				then
					canStep = false
					elapsedInRadius = 0
					showSlimekeeper:set(false)
				end
			end),
			RunService.RenderStepped:Connect(function(deltaTime)
				local character = playerClass._obj.Character

				if character then
					local delta = (SLIMEKEEPER:GetPivot().Position - character:GetPivot().Position).Magnitude

					if canStep and delta < MIN_CIRCLE_RADIUS then
						elapsedInRadius += deltaTime

						if elapsedInRadius >= MIN_CIRCLE_TIME and not showSlimekeeper:get() then
							showSlimekeeper:set(true)
						end

						return
					else
						canStep = delta > 8
					end

					elapsedInRadius = 0
					showSlimekeeper:set(false)
				end
			end),
			Observer(showSlimekeeper):onChange(function()
				if not showSlimekeeper:get() then
					menuVisible:set(true)
					changeInformationVisible:set(true)
				end
			end),
		},
	})

	local valuableChildren = {}
	for _, descendant in self._obj.Main:GetDescendants() do
		if descendant:IsA("GuiObject") and descendant.Name ~= descendant.ClassName then
			valuableChildren[descendant.Name] = descendant
		end
	end

	Hydrate(valuableChildren.Menu)({
        GroupTransparency = Spring(Computed(function()
            return (menuVisible:get() and 0) or 1
        end), 20),
	})
	Hydrate(valuableChildren.ChangeInformation)({
        GroupTransparency = Spring(Computed(function()
            return (changeInformationVisible:get() and 0) or 1
        end), 20),
	})
	Hydrate(valuableChildren.NameSelectorBox)({
		[OnEvent("FocusLost")] = function()
			local text = valuableChildren.NameSelectorBox.Text

			if string.len(text) > 0 then
				self._slimekeeperClient._slimekeeperSignal:Fire("Change", {
					DisplayName = text,
				})

				valuableChildren.NameSelectorBox.Text = ""
			end
		end,
	})
	Hydrate(valuableChildren.ColorSelectorBox)({
        BackgroundColor3 = Spring(self._theme.Color, 20),

		[OnEvent("FocusLost")] = function()
			local text = valuableChildren.ColorSelectorBox.Text

			if string.len(text) > 0 then
				self._slimekeeperClient._slimekeeperSignal:Fire("Change", {
					DisplayColor = text,
				})

				valuableChildren.ColorSelectorBox.Text = ""
			end
		end,
	})

	for _, name in { "Reset", "Change" } do
		local instance = valuableChildren[name]
		local color = instance.BackgroundColor3

		local text = Value(instance.Text)
		local textColor = Value(Color3.new(1, 1, 1))
		local textChangeTransparency = Value(0)

		local Hover = Value(false)

		Hydrate(instance)({
			BackgroundColor3 = Spring(Computed(function()
				if Hover:get() then
					local h, s, v = color:ToHSV()
					return Color3.fromHSV(h, s, (v * 1.6))
				else
					return color
				end
			end), 20),

			Text = text,
			TextColor3 = textColor,
			TextTransparency = Spring(textChangeTransparency, 40),
			TextStrokeTransparency = 1,
            Visible = menuVisible,

			[OnEvent("MouseButton1Click")] = function()
				if name == "Reset" then
					if text:get() ~= "Are you sure? 👀" then
						textChangeTransparency:set(1)

						task.delay(0.2, function()
							text:set("Are you sure? 👀")
							textChangeTransparency:set(0)
							textColor:set(Color3.fromRGB(238, 63, 63))
						end)
					else
						text:set("Reset your Game ⛔")
						textColor:set(Color3.new(1, 1, 1))

						canStep = false
						elapsedInRadius = 0
						showSlimekeeper:set(false)
					end

					self._slimekeeperClient._slimekeeperSignal:Fire("Reset")
				elseif name == "Change" then
					menuVisible:set(false)
					changeInformationVisible:set(true)
				end
			end,
			[OnEvent("InputBegan")] = function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					Hover:set(true)
				end
			end,
			[OnEvent("InputEnded")] = function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					Hover:set(false)
				end
			end,
		})
	end
end

return SlimekeeperView
