local RunService = game:GetService("RunService")
local require = require(script.Parent.loader :: ModuleScript).load(script)

local SlimeTrackerServer = {}

function SlimeTrackerServer:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._gameBindersServer = self._serviceBag:GetService(require("GameBindersServer"))
end

function SlimeTrackerServer:Start()
	self._gameBindersServer:PromiseBindersStarted():Then(function()
		local slimeBinder = self._gameBindersServer:Get("Slime")
		local characterBinder = self._gameBindersServer:Get("Character")

		if slimeBinder and characterBinder then
			local lastPositions = {}

			RunService.Stepped:Connect(function()
				for _, slime in slimeBinder:GetAll() do
					local character

					for _, xcharacter in characterBinder:GetAll() do
						if not xcharacter._player or xcharacter._obj ~= slime._player.Character then
							continue
						end

						character = xcharacter

						break
					end

					if not character then
						continue
					elseif not character._obj:IsDescendantOf(game) then
						lastPositions[character] = nil

						continue
					end

					local currentPivot = character._obj:GetPivot()
					local delta = (currentPivot.Position - slime._obj:GetPivot().Position).Magnitude

					if currentPivot.Position ~= lastPositions[character] and delta > 5 then
						lastPositions[character] = currentPivot.Position

						slime._obj.BodyPosition.Position = (currentPivot * CFrame.new(0, -2.5, 3)).Position
					end
				end
			end)
		end
	end)
end

return SlimeTrackerServer
