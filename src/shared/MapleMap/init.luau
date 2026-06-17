--[[
Written by cinderlucy
Made for all
]]

--!strict
local Settings = require("@self/Settings")
local CommonWarns = require("@self/CommonWarns")
local LilacLINQ = require("./LilacLINQ")

export type RawMap = {[any]: any}

local MapleMap = {}
MapleMap.__index = MapleMap
MapleMap.__newindex = function(self: RawMap, key: string, value: any)
    if not MapleMap.IsMaple(self) then
        warn(`Can't add key {key} because map provided is not a MapleMap`)
        return
    end
    local map = self :: MapleMap
    if map:ContainsKey(key) and Settings.AllowNewIndexToUseSet then
        map:Set(key, value)
        return
    end

    if value == nil then
        map:Remove(key)
        return
    end

    map:Add(key, value)
end
MapleMap.__len = function(self: RawMap)
    if not MapleMap.IsMaple(self) then
        warn(`Can't check length of map provided is not a MapleMap`)
        return -1
    end
    local map = self :: MapleMap
    return map._Metadata.Count
end
MapleMap.__eq = function(self: RawMap, other: RawMap)
    if not MapleMap.IsMaple(self) or not MapleMap.IsMaple(other) then
        warn(`One or both maps provided are not MapleMaps`)
        return false
    end
    
    local map = self :: MapleMap
    local otherMap = other :: MapleMap

    if Settings.DefaultEqualityCheck == "Shallow" then
        return map:Equals(otherMap)
    elseif Settings.DefaultEqualityCheck == "Deep" then
        return map:DeepEquals(otherMap)
    else
        return map:TrueEquals(otherMap)
    end
end

export type MapleMapMetadata = {
    ["Count"]: number,
    ["Capacity"]: number,
    ["IsFixedCapacity"]: boolean,
    ["IsLocked"]: boolean,
    ["IsMutable"]: boolean,
    ["MapleMap"]: true,
    [string]: any
}

export type MapleMap = setmetatable<{
    ["_KVs"]: RawMap,
    ["_Metadata"]: MapleMapMetadata,
    [string]: any
}, typeof(MapleMap)>

local INFINITE_CAPACITY = -1

local function CountMap(map: RawMap)
    local count = 0
    for _, _ in map do
        count += 1
    end
    return count
end

local function MapContainsTable(map: RawMap)
    for _, v in map do
        if typeof(v) == "table" then
            return true
        end
    end
    return false
end

function MapleMap.New(map: RawMap?, capacity: number?, isFixedCapacity: boolean?, isLocked: boolean?, isMutable: boolean?)
    local self = setmetatable({}, MapleMap) :: MapleMap
    local mapToUse = map or {}
    local count = 0

    if map then
        if MapContainsTable(map) then
            mapToUse = {}
            warn(CommonWarns.TableNotAllowed)
            warn("Not using map argument for _KVs. Defaulting to empty dictionary")
        end

        count = CountMap(map)
        if capacity and capacity < count and Settings.UNDEF_FallbackToInfinityIfCapacityLessThanCount then
            warn(`Capacity can't be set to {capacity} because your map has {count} k/v pairs. Setting capacity to infinity instead`)
            capacity = INFINITE_CAPACITY
        end
    end

    rawset(self, "_KVs", mapToUse)
    rawset(self, "_Metadata", {
            Capacity = capacity or INFINITE_CAPACITY,
            Count = count,
            IsFixedCapacity = isFixedCapacity or false,
            IsLocked = isLocked or false,
            IsMutable = isMutable or true,
            MapleMap = true
        })

    if map ~= nil then
        self:_CountKeys()
    end

    return self
end

function MapleMap.Add(self: MapleMap, key: string, value: any)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    local extraSpaceNeeded = 1
    if not self:_HasSufficientSpace(extraSpaceNeeded) then
        warn(`Capacity reached. Can't add any more keys`)
        return false
    end

    if typeof(value) == "table" then
        warn(CommonWarns.TableNotAllowed)
        return false
    end

    if self:ContainsKey(key) then
        warn(`Key {key} already exists. If you meant to set it's value, use Set instead`)
        return false
    end
    self._KVs[key] = value
    self._Metadata.Count += 1
    return true
end

function MapleMap.Get(self: MapleMap, key: string)
    return self._KVs[key]
end

function MapleMap.Set(self: MapleMap, key: string, value: any)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    if typeof(value) == "table" then
        warn(CommonWarns.TableNotAllowed)
        return false
    end

    if not self:ContainsKey(key) then
        warn(`Key {key} does not exist and can't be set to a value`)
        return false
    end
    self._KVs[key] = value
    return true
end

function MapleMap.Remove(self: MapleMap, key: string)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    if not self:ContainsKey(key) then
        warn(`Can't remove key {key} because it doesn't exist`)
        return false
    end

    self._KVs[key] = nil
    self._Metadata.Count -= 1
    return true
end

function MapleMap.Expand(self: MapleMap, by: number)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't expand because map has a fixed capacity`)
        return
    end
    self._Metadata.Capacity += by
end

function MapleMap.Shrink(self: MapleMap, by: number)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't shrink because map has a fixed capacity`)
        return
    end
    local difference = self._Metadata.Capacity - by
    if difference < self._Metadata.Count then
        warn(`Can't shrink map by {by} because map contains {self._Metadata.Count} element(s)`)
        return
    end
    self._Metadata.Capacity = difference
end

function MapleMap.TrimExcess(self: MapleMap)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't trim because map has a fixed capacity`)
        return
    end
    self._Metadata.Capacity = self._Metadata.Count
end

function MapleMap.Resize(self: MapleMap, newSize: number)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't resize because map has a fixed capacity`)
        return
    end

    if self._Metadata.Count > newSize then
        warn(`New capacity can not be less than current count of elements`)
        return
    end

    self._Metadata.Capacity = newSize
end

function MapleMap.Clear(self: MapleMap)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end
    self._KVs = {}
    self._Metadata.Count = 0
    return true
end

--[[ Add keys from other into self. Preserves values if self and other have a same key ]]
function MapleMap.Join(self: MapleMap, other: RawMap | MapleMap)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    local elements: RawMap = {}
    if MapleMap.IsMaple(other) then
        local other2 = other :: MapleMap
        elements = other2._KVs
    else
        local raw = other :: RawMap
        elements = raw
    end

    local elementsToAdd, count = LilacLINQ.Where(elements, function(k: string, v: any)
        return self._KVs[k] == nil
    end)

    if not self:_HasSufficientSpace(count) then
        warn(`Can not join maps together. Insufficient space`)
        return false
    end

    for k, v: any in elementsToAdd do
        self._KVs[k] = v
    end
    self._Metadata.Count += count

    return true
end

--[[ Returns a referenced copy of self(includes _KVs and _Metadata) ]]
function MapleMap.Copy(self: MapleMap)
    return table.clone(self)
end

--[[ Returns a non-referenced copy of self ]]
function MapleMap.DeepCopy(self: MapleMap): MapleMap
    local deepCopy = {} :: MapleMap
    deepCopy._KVs = {}
    deepCopy._Metadata = {} :: MapleMapMetadata

    for k, v in self._KVs do
        deepCopy._KVs[k] = v
    end
    for k, v in self._Metadata do
        deepCopy._Metadata[k] = v
    end

    return MapleMap.New(deepCopy._KVs, deepCopy._Metadata.Capacity, deepCopy._Metadata.IsFixedCapacity, deepCopy._Metadata.IsLocked, deepCopy._Metadata.IsMutable)
end

function MapleMap.For(self: MapleMap, loop: (k: string, v: any) -> ())
    for k, v: any in self._KVs do
        loop(k, v)    
    end
end

function MapleMap.IsMaple(map: RawMap)
    if map["_Metadata"] == nil then
        return false
    end
    return map["_Metadata"]["MapleMap"] == true
end

function MapleMap.Lock(self: MapleMap)
    self._Metadata.IsLocked = true
end

function MapleMap.Unlock(self: MapleMap)
    if self._Metadata.IsMutable == false then
        warn(CommonWarns.MutabilityDisabled)
        return
    end
    self._Metadata.IsLocked = false
end

function MapleMap.MakeImmutable(self: MapleMap)
    self._Metadata.IsMutable = false
    table.freeze(self._KVs)
    table.freeze(self._Metadata)
end

--[[ Returns an array of all keys(not a reference table) ]]
function MapleMap.Keys(self: MapleMap): {string}
    local keys: {string} = {}
    for k, _ in self._KVs do
        table.insert(keys, k)
    end
    return keys
end

--[[ Returns an array of all values(not a reference table) ]]
function MapleMap.Values(self: MapleMap): {any}
    local keys: {any} = {}
    for _, v: any in self._KVs do
        table.insert(keys, v)
    end
    return keys
end

local function DeepEquals(first: RawMap, second: RawMap)
    for k, v: any in first do
        if second[k] ~= v then
            return false
        end
        if typeof(v) == "table" and typeof(second[k]) == "table" then
            return DeepEquals(v :: RawMap, second[k] :: RawMap)
        end
    end
    return true
end

--[[ Returns true only if top level _KVs are equal ]]
function MapleMap.Equals(self: MapleMap, other: MapleMap)
    for k, v: any in self._KVs do
        if other._KVs[k] ~= v then
            return false
        end
    end
    return true
end

--[[ Returns true for deep equality(tables in tables) within _KVs of self and other ]]
function MapleMap.DeepEquals(self: MapleMap, other: MapleMap)
    return DeepEquals(self._KVs, other._KVs)
end

--[[ Returns true for deep equality within _KVs and _Metadata of self and other ]]
function MapleMap.TrueEquals(self: MapleMap, other: MapleMap)
    return DeepEquals(self, other)
end

-- LINQ methods
function MapleMap.All(self: MapleMap, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.All(self._KVs, condition)
end

function MapleMap.Any(self: MapleMap, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.Any(self._KVs, condition)
end

function MapleMap.Where(self: MapleMap, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.Where(self._KVs, condition, true)
end

function MapleMap.Select(self: MapleMap, method: LilacLINQ.AnyFunc)
    return LilacLINQ.Select(self._KVs, method, true)
end

function MapleMap.GroupBy(self: MapleMap, method: LilacLINQ.AnyFunc)
    return LilacLINQ.GroupBy(self._KVs, method)
end

function MapleMap.ContainsKey(self: MapleMap, key: string)
    return self._KVs[key] ~= nil
end

function MapleMap.Contains(self: MapleMap, value: any)
    return LilacLINQ.Contains(self._KVs, value)
end

-- Getters
function MapleMap.Count(self: MapleMap)
    return self._Metadata.Count
end

function MapleMap.Capacity(self: MapleMap)
    return self._Metadata.Capacity
end

function MapleMap.IsLocked(self: MapleMap)
    return self._Metadata.IsLocked
end

function MapleMap.IsMutable(self: MapleMap)
    return self._Metadata.IsMutable
end

-- Private methods
function MapleMap._CountKeys(self: MapleMap)
    local count = CountMap(self._KVs)
    self._Metadata.Count = count
end

function MapleMap._IsLockedOrImmutable(self: MapleMap)
    return self:IsLocked() or not self:IsMutable()
end

function MapleMap._HasSufficientSpace(self: MapleMap, space: number)
    return self._Metadata.Capacity == INFINITE_CAPACITY or self._Metadata.Count + space <= self._Metadata.Capacity
end

return MapleMap