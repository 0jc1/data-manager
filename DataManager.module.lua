local ProfileService = require(game.ServerStorage.Modules.ProfileService)
local Badges = require(game.ServerStorage.Modules.Badges)

local Players = game:GetService("Players")

local DataManager = {}

-- Profile template
DataManager.template = {
	coins = 0,
	LogInTimes = 0,
	wins = 0,
	gamesPlayed = 0,
	banned = false,
}

local ProfileStore = ProfileService.GetProfileStore("Player", DataManager.template)
local Profiles: { [Player]: any } = {}

local function DoSomethingWithALoadedProfile(player: Player, profile: any)
	profile.Data.LogInTimes += 1

	--[[
	print(player.Name .. " has logged in " .. tostring(profile.Data.LogInTimes)
		.. " time" .. ((profile.Data.LogInTimes > 1) and "s" or ""))
	--]]

	if profile.Data.LogInTimes == 1 then
		-- Badges:awardBadge(player, 234324)
	end
end

-- Yielding function
function DataManager:GetProfile(player: Player)
	assert(player ~= nil, "assertion failed")

	for _ = 1, 6 do
		if Profiles[player] == nil then
			task.wait(1)
		end
	end

	local profile = Profiles[player]

	if profile then
		return profile
	else
		warn("DataManager: got a nil profile")
		return nil
	end
end

function DataManager:Get(player: Player)
	assert(player ~= nil, "assertion failed")

	local profile = self:GetProfile(player)
	if profile then
		return profile.Data
	end
end

function DataManager:BindProfile(player: Player)
	local profile = self:GetProfile(player)

	if profile == nil then
		for key, value in pairs(self.template) do
			player:SetAttribute(key, value)
		end
		return
	end

	local data = profile.Data

	for key, value in pairs(data) do
		player:SetAttribute(key, value)
	end

	player.AttributeChanged:Connect(function(attributeName)
		if data[attributeName] ~= nil then
			data[attributeName] = player:GetAttribute(attributeName)
		end
	end)
end

function DataManager:Init()
	Players.PlayerAdded:Connect(function(player: Player)
		local profileKey = "p_" .. player.UserId
		local profile = ProfileStore:LoadProfileAsync(profileKey)

		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()

			profile:ListenToRelease(function()
				Profiles[player] = nil
				player:Kick()
			end)

			if player:IsDescendantOf(Players) then
				Profiles[player] = profile

				DoSomethingWithALoadedProfile(player, profile)
				self:BindProfile(player)
			else
				profile:Release()
			end
		else
			warn("Player kicked for nil profile")
			player:Kick("Profile is nil")
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local profile = Profiles[player]
		if profile then
			profile:Release()
		end
	end)
end

function DataManager:Start()
	print("DataManager started")
end

return DataManager
