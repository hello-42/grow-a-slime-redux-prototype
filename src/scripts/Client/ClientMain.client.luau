local packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")

local serviceBag = require(packages.ServiceBag :: ModuleScript).new()
serviceBag:GetService(packages.GameServiceClient)
serviceBag:Init()
serviceBag:Start()
