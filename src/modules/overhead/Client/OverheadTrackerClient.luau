local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local require = require(script.Parent.loader :: ModuleScript).load(script)

local Player = Players.LocalPlayer

local OverheadTrackerClient = {}

function OverheadTrackerClient:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._gameBindersClient = self._serviceBag:GetService(require("GameBindersClient"))
end

function OverheadTrackerClient:Start()
	local overheads = {}

	self._gameBindersClient:PromiseBinder("Overhead"):Then(function(overheadBinder)
		local function overheadExistenceEvent(overhead)
			local found = table.find(overheads, overhead)

			if found then
				table.remove(overheads, found)
			else
				table.insert(overheads, overhead)
			end
		end

		for _, overhead in overheadBinder:GetAll() do
			overheadExistenceEvent(overhead)
		end

		overheadBinder:GetClassAddedSignal():Connect(overheadExistenceEvent)
		overheadBinder:GetClassRemovedSignal():Connect(overheadExistenceEvent)
	end)

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local character = Player.Character

		if camera and character then
			for _, overhead in overheads do
				if not (overhead._obj.Adornee and overhead._obj.Adornee:IsDescendantOf(workspace)) then
					continue
				end

				local adorneePosition = overhead._obj.Adornee:GetPivot().Position
				local _, inViewport = camera:WorldToViewportPoint(adorneePosition)

				if not inViewport then
					continue
				end

				local alpha = 1

				if overhead._obj.Adornee:IsDescendantOf(character) then
					alpha = 0.8
				else
					local distance = (adorneePosition - character:GetPivot().Position).Magnitude

					alpha = math.clamp(distance / 48, 0, 1)
				end

				overhead._groupTransparency:set(alpha)
			end
		end
	end)
end

return OverheadTrackerClient
