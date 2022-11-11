local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Interface = require("Interface")

local Fusion = require("fusion")
local Hydrate = Fusion.Hydrate
local Cleanup = Fusion.Cleanup
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring

local Chat = setmetatable({}, Interface)
Chat.__index = Chat

local RBXGeneral

local function sendChatMessage(message)
	if not RBXGeneral then
		for _, descendant in TextChatService:GetDescendants() do
			if not (descendant:IsA("TextChannel") and descendant.Name == "RBXGeneral") then
				continue
			end

			RBXGeneral = descendant

			break
		end
	end

	if RBXGeneral then
		RBXGeneral:SendAsync(message)
	end
end

function Chat.new(screenGui)
	local self = setmetatable(Interface.new(screenGui), Chat)

	self:_setup()

	return self
end

function Chat:_setup()
	local highlightColor = Value(Color3.fromRGB(230, 230, 230))

	Hydrate(self._obj.TextBox)({
		ClearTextOnFocus = false,
		TextColor3 = self._theme.Color,

		[OnEvent("Focused")] = function()
			local h, s, v = self._theme.Color:get():ToHSV()

			highlightColor:set(Color3.fromHSV(h, s, (v * 1.6)))
		end,

		[OnEvent("FocusLost")] = function(enterPressed)
			local text = self._obj.TextBox.Text
			local length = string.len(text)

			if enterPressed then
				self._obj.TextBox.Text = ""

				if length > 0 then
					sendChatMessage(text)
				end
			end

			highlightColor:set(Color3.fromRGB(230, 230, 230))
		end,

		[Children] = Hydrate(self._obj.TextBox.ImageLabel)({
			BackgroundColor3 = Spring(
				Computed(function()
					return Color3.fromHSV(self._theme.Color:get():ToHSV(), 1, 1)
				end),
				20
			),
			Image = self._theme.Thumbnail,
		}),

		[Cleanup] = UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
			if not gameProcessedEvent then
				return
			end

			if inputObject.KeyCode == Enum.KeyCode.Slash then
				self._obj.TextBox:CaptureFocus()
			end
		end),
	})

	for _, descendant in self._obj:GetDescendants() do
		if descendant:IsA("UIStroke") then
			Hydrate(descendant)({
				Color = Spring(highlightColor, 20),
			})
		end
	end

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end

return Chat
