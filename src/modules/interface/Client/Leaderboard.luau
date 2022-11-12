local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Interface = require("Interface")

local Fusion = require("fusion")
local Hydrate = Fusion.Hydrate
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Out = Fusion.Out
local Cleanup = Fusion.Cleanup

local Leaderboard = setmetatable({}, Interface)
Leaderboard.__index = Leaderboard

function Leaderboard.new(screenGui, binders)
	local self = setmetatable(Interface.new(screenGui), Leaderboard)

	self._binders = assert(binders, "No binders")

	self:_setup()

	return self
end

function Leaderboard:_setup()
	local function getPlayerClassContentLabel(playerClass)
		local contentLabel = self._obj.ContentLabel:Clone()

		local playerColor = Computed(function()
			local player = playerClass._obj
			local value = Value(player:GetAttribute("DisplayColor") or Color3.new(1, 1, 1))

			local playerDisplayColorChanged = player.AttributeChanged:Connect(function(attribute)
				if attribute == "DisplayColor" then
					local displayColor = player:GetAttribute("DisplayColor")

					if typeof(displayColor) == "Color3" then
						value:set(displayColor)
					end
				end
			end)

			local playerLeft
			playerLeft = player.AncestryChanged:Connect(function()
				if player:IsDescendantOf(game) then
					return
				end

				playerDisplayColorChanged:Disconnect()
				playerLeft:Disconnect()
			end)

			local displayColor = player:GetAttribute("DisplayColor")
			if typeof(displayColor) == "Color3" then
				value:set(displayColor)
			end

			return Computed(function()
				return value:get()
			end)
		end):get()
		
		return Hydrate(contentLabel)({
			Text = Computed(function()
				local player = playerClass._obj
				local value = Value(player.Name)

				local playerDisplayNameChanged = player
					:GetAttributeChangedSignal("DisplayName")
					:Connect(function(displayName)
						if typeof(displayName) == "string" then
							value:set(displayName)
						end
					end)
				local playerLeft
				playerLeft = player.AncestryChanged:Connect(function()
					if player:IsDescendantOf(game) then
						return
					end

					playerDisplayNameChanged:Disconnect()
					playerLeft:Disconnect()
				end)

				local displayName = player:GetAttribute("DisplayName")
				if typeof(displayName) == "string" then
					value:set(displayName)
				end

				return Computed(function()
					return player.Name .. " (" .. value:get() .. ")"
				end)
			end):get(),

			TextColor3 = playerColor,
			Visible = true,

			[Children] = Hydrate(contentLabel.ImageLabel)({
				BackgroundColor3 = playerColor,
				Image = self:_computeThumbnailFromUserId(playerClass._obj.UserId),
			}),
		})
	end

	local children = Computed(function()
		local value = Value({})

		self._binders:PromiseBinder("Player"):Then(function(playerBinder)
			local playerClasses = {}

			for _, playerClass in playerBinder:GetAll() do
				playerClasses[playerClass] = getPlayerClassContentLabel(playerClass)

				value:set(playerClasses)
			end

			value:set(playerClasses)

			for _, event in { "Added", "Removed" } do
				playerBinder["GetClass" .. event .. "Signal"](playerBinder):Connect(function(...)
					local initialized = playerClasses[...]

					if initialized then
						initialized:Destroy()

						playerClasses[...] = nil

						value:set(playerClasses)

						return
					end

					playerClasses[...] = getPlayerClassContentLabel(...)

					value:set(playerClasses)
				end)
			end

			value:set(playerClasses)
		end)

		return value
	end):get()

	local open = Value(false)
	local containerSize = Value(self._obj.Frame.AbsoluteSize)

	Hydrate(self._obj.Frame)({
		[Out "AbsoluteSize"] = containerSize,
		
		Position = Spring(
			Computed(function()
				return UDim2.fromOffset(if open:get() then 0 else (containerSize:get().X + 18), 36)
			end),
			21
		),

		[Children] = children,
		[Cleanup] = UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
			if gameProcessedEvent then
				return
			end

			if inputObject.KeyCode == Enum.KeyCode.Tab then
				open:set(not open:get())
			end
		end),
	})
	Hydrate(self._obj)({
		[Children] = Hydrate(self._obj.TextButton)({
			[OnEvent("MouseButton1Click")] = function()
				open:set(not open:get())
			end,
		}),
	})

	task.delay(5, function()
		if not open:get() then
			open:set(true)
		end
	end)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end

return Leaderboard
