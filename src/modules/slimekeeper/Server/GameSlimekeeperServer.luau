local require = require(script.Parent.loader :: ModuleScript).load(script)
local GetRemoteEvent = require("GetRemoteEvent")

local GameSlimekeeperServer = {}

local EVENT_DB = 0.2

function GameSlimekeeperServer:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._gameBindersServer = self._serviceBag:GetService(require("GameBindersServer"))

	self._gameResetRequestEvent = GetRemoteEvent("GameResetRequestEvent")
end

function GameSlimekeeperServer:Start()
	self._gameBindersServer:PromiseBinder("Slime"):Then(function(slimeBinder)
		local eventSignalData = {}

		self._gameResetRequestEvent.OnServerEvent:Connect(function(player)
			local entry = {
				last = os.clock(),
				step = 0,
			}

			entry = eventSignalData[player.UserId] or entry
			eventSignalData[player.UserId] = entry

			if (entry.last == os.clock()) or ((entry.last - EVENT_DB) <= os.clock()) then
				if entry.step == 1 then
					local slimeClass

					for _, xslimeClass in slimeBinder:GetAll() do
						if xslimeClass._player ~= player then
							continue
						end

						slimeClass = xslimeClass

						break
					end

					if slimeClass then
						slimeClass.Experience = 0
						slimeClass.Level = 1
						slimeClass.Score = 0

						for _, attribute in { "Experience", "Level", "Score" } do
							slimeClass._obj:SetAttribute(attribute, slimeClass[attribute])
						end
						slimeClass._obj:SetAttribute("Alpha", 0)

						entry.last = os.clock() + 60
					end
				else
					entry.step += 1
				end
			end
		end)
	end)
end

return GameSlimekeeperServer
