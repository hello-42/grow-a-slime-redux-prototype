local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Interface = require("Interface")
local Signal = require("Signal")

local Fusion = require("fusion")
local Hydrate = Fusion.Hydrate
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
local Spring = Fusion.Spring

local WorldLeaderboard = setmetatable({}, Interface)
WorldLeaderboard.__index = WorldLeaderboard

local SPAWNABLES = CollectionService:GetTagged("Spawnables")[1]
local SLIMES = SPAWNABLES.Slime

function WorldLeaderboard.new(leaderboard, binders)
	local self = setmetatable(Interface.new(leaderboard), WorldLeaderboard)

	self._binders = assert(binders, "No binders")

	self._stateChanged = Signal.new()
	self._slimes = {}
	self._scope = Value("Score")

	self._thumbnailCache = {}
	self._colorCache = {}

	self:_setup()

	return self
end

function WorldLeaderboard:_setup()
	local transparency = Value(0)
	local titleText = Value(self._scope:get() .. " Leaderboard")

	Hydrate(self._obj.Main)({
		GroupTransparency = Spring(
			Computed(function()
				local value = transparency:get()

				if value == 1 then
					titleText:set("")

					task.delay(0.3, function()
						transparency:set(0)
						titleText:set(self._scope:get() .. " Leaderboard")
					end)
				end

				return value
			end),
			20
		),
	})
	Hydrate(self._obj.Main.TitleGroup)({
		[Children] = ForValues(self._obj.Main.TitleGroup:GetChildren(), function(value)
			return Hydrate(value)({
				Text = titleText,
				TextColor3 = self._theme.Color,
			})
		end, Fusion.cleanup),
	})

	CollectionService:GetInstanceAddedSignal("WORLD_LEADERBOARD"):Connect(function(leaderboard)
		self._maid:GiveTask(leaderboard.AttributeChanged:Connect(function(attribute)
			if attribute == "Scope" then
				local value = leaderboard:GetAttribute("Scope")

				if typeof(value) == "string" then
					transparency:set(1)

					self._scope:set(value)
					self._stateChanged:Fire()
				end
			end
		end))

		self._scope:set(leaderboard:GetAttribute("Scope") or "Score")

		self._obj.Adornee = leaderboard
	end)

	self._stateChanged:Connect(function()
		local rankedSlimes = {}

		for _, attributeData in self._slimes do
			if attributeData.UserId then
				local player = Players:GetPlayerByUserId(attributeData.UserId)

				if player then
					local scope = self._scope:get()

					table.insert(rankedSlimes, {
						sprungValue = Spring(Computed(function()
							local value = Value(attributeData.last)

							task.defer(function()
								value:set(attributeData[scope])
							end)

							return Computed(function()
								return string.match((value:get() or 0), "%d+")
							end)
						end):get()),

						name = player.Name .. " (" .. player:GetAttribute("DisplayName") .. ")",
						value = attributeData[scope],
						thumbnail = self._thumbnailCache[attributeData.UserId]
							or self:_computeThumbnailFromUserId(player.UserId),
						color = self._colorCache[attributeData.UserId] or self:_computeInstanceDisplayColor(player),
					})
				end
			end
		end

		table.sort(rankedSlimes, function(a, b)
			return a.value > b.value
		end)

		for key in Players:GetPlayers() do
			local data = rankedSlimes[key]
			local entry = self._obj.Main.EntryContainer:FindFirstChild(key)

			Hydrate(entry)({
				GroupTransparency = Spring(Computed(function()
					local value = Value(entry.GroupTransparency)

					task.defer(function()
						if data then
							value:set(0)
						else
							value:set(1)
						end
					end)

					return value
				end)),

				[Children] = {
					Hydrate(entry.ImageLabel)({
						Image = if data then data.thumbnail else "",
					}),
					Hydrate(entry.CanvasGroup)({
						[Children] = ForValues(entry.CanvasGroup:GetChildren(), function(textLabel)
							return Hydrate(textLabel)({
								Text = if data then data.name else "",
							})
						end, Fusion.cleanup),
					}),
					Hydrate(entry.Value)({
						[Children] = ForValues(entry.Value:GetChildren(), function(textLabel)
							return Hydrate(textLabel)({
								Text = if data then data.sprungValue else "",
							})
						end, Fusion.cleanup),
					}),
				},
			})
		end
	end)

	local function slimeExistenceEvent(slime)
		local found = self._slimes[slime]

		if found then
			self._slimes[slime] = found.connection:Disconnect()
		else
			local attributeData = { last = slime:GetAttribute(self._scope) }

			for attribute, value in slime:GetAttributes() do
				attributeData[attribute] = value
			end

			attributeData.connection = slime.AttributeChanged:Connect(function(attribute)
				attributeData[attribute] = slime:GetAttribute(attribute)

				self._stateChanged:Fire()
			end)

			self._slimes[slime] = attributeData
		end
	end

	for _, slime in SLIMES:GetChildren() do
		slimeExistenceEvent(slime)
	end

	SLIMES.ChildAdded:Connect(slimeExistenceEvent)
	SLIMES.ChildRemoved:Connect(slimeExistenceEvent)
end

return WorldLeaderboard
