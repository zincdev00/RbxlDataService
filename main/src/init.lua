local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Class = require(ReplicatedStorage.common.packages.Class)
local Future = require(ReplicatedStorage.common.packages.Future)

local DataService = Class:create({
	RateTracker = require(script.RateTracker),
	RequestTracker = require(script.RequestTracker),
})


local RATE_COOLDOWN = 60
local REQUEST_TIMEOUT = 4
local RATE_FUNC_LARGE = function(self)
	return 60 + (10 * #Players:GetPlayers())
end
local RATE_FUNC_SMALL = function(self)
	return 5 + (2 * #Players:GetPlayers())
end
DataService.RateTrackers = {
	Get = DataService.RateTracker:new(RATE_COOLDOWN, RATE_FUNC_LARGE),
	Set = DataService.RateTracker:new(RATE_COOLDOWN, RATE_FUNC_LARGE),
	GetSorted = DataService.RateTracker:new(RATE_COOLDOWN, RATE_FUNC_SMALL),
	GetVersion = DataService.RateTracker:new(RATE_COOLDOWN, RATE_FUNC_SMALL),
	List = DataService.RateTracker:new(RATE_COOLDOWN, RATE_FUNC_SMALL),
	Remove = DataService.RateTracker:new(RATE_COOLDOWN, RATE_FUNC_SMALL),
}
DataService.RequestTrackers = {
	Get = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.Get),
	Set = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.Set),
	Increment = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.Set),
	Update = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.Get, DataService.RateTrackers.Set),
	Remove = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.Set),
	GetSorted = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.GetSorted),
	GetVersion = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.GetVersion),
	ListDataStores = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.List),
	ListKeys = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.List),
	ListVersions = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.List),
	RemoveVersion = DataService.RequestTracker:new(REQUEST_TIMEOUT, DataService.RateTrackers.Remove),
}
local function addRequestType(funcInvoke)
	return Class:create({
		Invoke = funcInvoke,
	})
end
DataService.RequestTypes = {
	Get = addRequestType(function(self)
		return self.DataStore:GetAsync(self.Key, self.Options)
	end),
	Set = addRequestType(function(self)
		return self.DataStore:SetAsync(self.Key, self.Value, self.UserIds, self.Options)
	end),
	Increment = addRequestType(function(self)
		return self.DataStore:IncrementAsync(self.Key, self.Delta, self.UserIds, self.Options)
	end),
	Update = addRequestType(function(self)
		return self.DataStore:UpdateAsync(self.Key, function(value)
			value = self.Func(value)
			self.Value = value
		end)
	end),
	Remove = addRequestType(function(self)
		return self.DataStore:RemoveAsync(self.Key)
	end),
	GetSorted = addRequestType(function(self)
		return self.DataStore:GetSortedAsync(self.Ascending, self.PageSize, self.MinValue, self.MaxValue)
	end),
	GetVersion = addRequestType(function(self)
		return self.DataStore:GetVersionAsync(self.Key, self.Version)
	end),
	ListDataStores = addRequestType(function(self)
		return self.DataStore:ListDataStoresAsync(self.Prefix, self.PageSize, self.Cursor)
	end),
	ListKeys = addRequestType(function(self)
		return self.DataStore:ListKeysAsync(self.Key)
	end),
	ListVersions = addRequestType(function(self)
		return self.DataStore:ListVersionsAsync(self.Key)
	end),
	RemoveVersion = addRequestType(function(self)
		return self.DataStore:RemoveVersionAsync(self.Key, self.Version)
	end),
}


function DataService:Init()
	RunService.Heartbeat:Connect(function()
		for _, rateTracker in pairs(self.RateTrackers) do
			rateTracker:Update()
		end
		for _, requestTracker in pairs(self.RequestTrackers) do
			requestTracker:Update()
		end
	end)
end

function DataService:Exit()
end


function DataService:Get(dataStore, key, options)
	return self.RequestTrackers.Get:Append(self.RequestTypes.Get:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
		Options = options,
	}))
end

function DataService:Set(dataStore, key, value, userIds, options)
	return self.RequestTrackers.Set:Append(self.RequestTypes.Set:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
		Value = value,
		UserIds = userIds,
		Options = options,
	}))
end

function DataService:Increment(dataStore, key, delta, userIds, options)
	return self.RequestTrackers.Increment:Append(self.RequestTypes.Increment:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
		Delta = delta,
		UserIds = userIds,
		Options = options,
	}))
end

function DataService:Update(dataStore, key, func)
	return self.RequestTrackers.Update:Append(self.RequestTypes.Update:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
		Func = func,
	}))
end

function DataService:Remove(dataStore, key)
	return self.RequestTrackers.Update:Append(self.RequestTypes.Remove:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
	}))
end

function DataService:GetSorted(dataStore, ascending, pageSize, minValue, maxValue)
	return self.RequestTrackers.GetSorted:Append(self.RequestTypes.GetSorted:new({
		Future = Future:new(),
		DataStore = dataStore,
		Ascending = ascending,
		PageSize = pageSize,
		MinValue = minValue,
		MaxValue = maxValue,
	}))
end

function DataService:GetVersion(dataStore, key, version)
	return self.RequestTrackers.GetVersion:Append(self.RequestTypes.GetVersion:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
		Version = version,
	}))
end

function DataService:ListDataStores(dataStore, prefix, pageSize, cursor)
	return self.RequestTrackers.ListDataStores:Append(self.RequestTypes.ListDataStores:new({
		Future = Future:new(),
		DataStore = dataStore,
		Prefix = prefix,
		PageSize = pageSize,
		Cursor = cursor,
	}))
end

function DataService:ListKeys(dataStore, key)
	return self.RequestTrackers.ListKeys:Append(self.ReuqestTypes.ListKeys:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
	}))
end

function DataService:ListVersions(dataStore, key)
	return self.RequestTrackers.ListVersions:Append(self.RequestTypes.ListVersions:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
	}))
end

function DataService:RemoveVersion(dataStore, key, version)
	return self.RequestTrackers.RemoveVersion:Append(self.RequestTypes.RemoveVersion:new({
		Future = Future:new(),
		DataStore = dataStore,
		Key = key,
		Version = version,
	}))
end


return DataService