local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Class = require(ReplicatedStorage.common.packages.Class)
local Array = require(ReplicatedStorage.common.packages.Array)

local RateTracker = Class:create()


function RateTracker:new(cooldown, funcGetLimit)
	return self:create({
		COOLDOWN = cooldown,
		Cooldowns = Array:new(),
		GetLimit = funcGetLimit,
	})
end

-- Updates the cooldown queue
function RateTracker:Update()
	local time = os.clock()
	while self.Cooldowns:Count() > 0 and time - self.Cooldowns:Get(1) > self.COOLDOWN do
		self.Cooldowns:Remove(1)
	end
end

-- Returns whether the cooldowns are over the limit
function RateTracker:IsAvailable()
	return self.Cooldowns:Count() < self:GetLimit()
end

-- Adds a value to the cooldowns
function RateTracker:Append(value)
	return self.Cooldowns:append(value)
end


return RateTracker