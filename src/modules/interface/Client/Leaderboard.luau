local StarterGui = game:GetService("StarterGui")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Interface = require("Interface")

local Fusion = require("fusion")
local Hydrate = Fusion.Hydrate
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring

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
					return player.Name .. " (@ " .. value:get() .. " )"
				end)
			end):get(),

			TextColor3 = self:_computeInstanceDisplayColor(playerClass._obj),
			Visible = true,

			[Children] = Hydrate(contentLabel.ImageLabel)({
				BackgroundColor3 = self:_computeInstanceDisplayColor(playerClass._obj),
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

	Hydrate(self._obj.Frame)({
		Position = Spring(
			Computed(function()
				return UDim2.fromOffset(if open:get() then 0 else 172, 36)
			end),
			14
		),

		[Children] = children,
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
