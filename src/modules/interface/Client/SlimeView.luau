local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local require = require(script.Parent.loader :: ModuleScript).load(script)
local Interface = require("Interface")
local Signal = require("Signal")
local Maid = require("Maid")

local Fusion = require("fusion")
local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Out = Fusion.Out
local Cleanup = Fusion.Cleanup
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
local Spring = Fusion.Spring

local SPAWNABLES = CollectionService:GetTagged("Spawnables")[1]
local SLIMES = SPAWNABLES.Slime

local SlimeView = setmetatable({}, Interface)
SlimeView.__index = SlimeView

local Player = Players.LocalPlayer

local cameraCFrame = Value(workspace.CurrentCamera.CFrame)
Hydrate(workspace.CurrentCamera)({
	[Out("CFrame")] = cameraCFrame,
})

function SlimeView.new(screenGui, binders)
	local self = setmetatable(Interface.new(screenGui), SlimeView)

	self._binders = assert(binders, "No binders")

	self._identified = {}
	self._slimeIdentifiedSignal = Signal.new()

	self:_setup()

	return self
end

function SlimeView:_setup()
	local maid = Maid.new()

	maid:GivePromise(self._binders:PromiseBinder("Slime"):Then(function(slimeBinder)
		local function correlateSlimeToClass(slime)
			local function correlateUserIdToClass(userId)
				for _, slimeClass in slimeBinder:GetAll() do
					if slimeClass._obj.UserId ~= userId then
						continue
					end

					self._identified[slime] = slimeClass
					self._slimeIdentifiedSignal:Fire()

					break
				end
			end

			local userId = slime:GetAttribute("UserId")

			if typeof(userId) == "number" then
				correlateUserIdToClass(userId)
			else
				maid:GiveTask(slime:GetAttributeChangedSignal("UserId"):Connect(function(xuserId)
					if typeof(xuserId) == "number" then
						correlateUserIdToClass(xuserId)
					end
				end))
			end
		end

		for _, slime in SLIMES:GetChildren() do
			correlateSlimeToClass(slime)
		end

		maid:GiveTask(SLIMES.ChildAdded:Connect(correlateSlimeToClass))
	end))

	maid:GiveTask(self._slimeIdentifiedSignal:Connect(function()
		for slime, slimeClass in self._identified do
			if slimeClass._obj ~= Player then
				continue
			end

			self._localSlime = slime

			break
		end

		if self._localSlime then
			self:_init()

			maid:Destroy()
		end
	end))

	maid:GiveTask(self._slimeIdentifiedSignal)
end

function SlimeView:_init()
	if self._localSlime then
		local localSlimeCFrame = Value(self._localSlime:GetPivot())
		local localSlimeSize = Value(self._localSlime.Size)

		local slime, gradient, viewportFrame = self._obj.Slime, self._obj.Gradient, self._obj.ViewportFrame

		local gradientValue = Computed(function()
			local value = Value(0)

			self._maid:GiveTask(self._localSlime.AttributeChanged:Connect(function(attribute)
				if attribute == "Alpha" then
					local xvalue = self._localSlime:GetAttribute(attribute)

					if typeof(xvalue) == "number" then
						value:set(xvalue)
					end
				end
			end))

			local alpha = self._localSlime:GetAttribute("Alpha")
			if typeof(alpha) == "number" then
				value:set(alpha)
			end

			return Computed(function()
				return Vector2.new(0, 1 - (value:get() * 2))
			end)
		end):get()

		local children = Computed(function()
			local contains = {}
			local value = Value(contains)

			local function watchObject(object)
				if object:IsA("BasePart") then
					local found = table.find(contains, object)

					if found then
						table.remove(contains, found)
					else
						table.insert(contains, object)
					end

					value:set(contains)
				end
			end

			task.defer(function()
				local container = self._localSlime:WaitForChild("_container")

				Hydrate(viewportFrame.Value)({
					CurrentCamera = New("Camera")({
						Parent = viewportFrame.Value,

						CFrame = Computed(function()
							local position = localSlimeCFrame:get().Position
							local extents = localSlimeSize:get().Magnitude / 2

							return CFrame.new(position) * cameraCFrame:get().Rotation * CFrame.new(0, extents, -extents)
						end),
					}),
				})

				for _, object in container:GetChildren() do
					watchObject(object)
				end

				self._maid:GiveTask(container.ChildAdded:Connect(watchObject))
				self._maid:GiveTask(container.ChildRemoved:Connect(watchObject))
			end)

			return value
		end):get()

		Hydrate(self._localSlime)({
			[Out("CFrame")] = localSlimeCFrame,
			[Out("Size")] = localSlimeSize,
		})

		Hydrate(slime.Value)({
			Color = Spring(self._theme.Color, 20),
			Transparency = 0.5,
			CFrame = Computed(function()
				local value = localSlimeCFrame:get()
				return value * value.Rotation
			end),
			Size = localSlimeSize,
		})
		Hydrate(slime.Value._container)({
			[Children] = ForValues(children, function(value)
				local transparency = Value(value.Transparency)
				local clone = value:Clone()

				Hydrate(value)({
					[Out("Transparency")] = transparency,
					[Cleanup] = clone,
				})

				return Hydrate(clone)({
					Transparency = transparency,
					CFrame = CFrame.new(slime.Value:GetPivot().Position) * value:GetPivot().Rotation,

					[Children] = ForValues(clone:GetDescendants(), function(child)
						if child:IsA("BasePart") then
							Hydrate(child)({
								Transparency = transparency,
							})
						end

						return child
					end, Fusion.cleanup),
				})
			end, Fusion.cleanup),
		})
		Hydrate(gradient.Value)({
			Color = Computed(function()
				local hue = self._theme.Color:get():ToHSV()
				return ColorSequence.new(Color3.fromHSV(hue, 1, 1))
			end),
			Offset = Spring(gradientValue, 20),
		})
	end
end

return SlimeView
