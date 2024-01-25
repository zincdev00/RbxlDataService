local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Class = require(ReplicatedStorage.common.packages.Class)
local Array = require(ReplicatedStorage.common.packages.Array)

local RequestTracker = Class:create()


function RequestTracker:new(maxAttempts, ...)
	return self:create({
		MaxAttempts = maxAttempts,
		RateTrackers = { ..., },
		Requests = Array:new(),
	})
end

-- Updates the request queue
function RequestTracker:Update()
	while self.Requests:count() > 0 and self:IsAvailable() do
		local request = self.Requests:remove(1)
		if not request.Cancel then
			local attempts = 0
			while attempts < self.MaxAttempts do
				attempts += 1
				local success, result = pcall(request.Invoke, request)
				if success then
					for _, tracker in pairs(self.RateTrackers) do
						tracker:Append(os.clock())
					end
					request.Future:completeValue(result)
					break
				else
					if (attempts + 1) >= self.MaxAttempts then
						request.Future:completeError(result)
					end
					task.wait(1)
				end
			end
		end
	end
end

function RequestTracker:IsAvailable()
	for _, rateTracker in pairs(self.RateTrackers) do
		if rateTracker:IsAvailable() then
			return true
		end
	end
	return false
end

-- Adds a value to the requests
function RequestTracker:Append(value)
	return self.Requests:append(value)
end


return RequestTracker