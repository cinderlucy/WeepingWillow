--[[
Written by cinderlucy
Made for all
]]

--!strict
local Settings = require("@self/Settings")
local CommonWarns = require("@self/CommonWarns")
local LilacLINQ = require("./LilacLINQ")
local WeepingWillow = require("./WeepingWillow")
local MemoryAddressLookup = require("./MemoryAddressLookup")

export type RawMap = {[any]: any}
export type _KVs<K, V> = {[K]: V}

local MapleMap = {}
MapleMap.__index = MapleMap
MapleMap.__newindex = function<K, V>(self: RawMap, key: K, value: V)
    if not MapleMap.IsMaple(self) then
        warn(`Can't add key {key} because map provided is not a MapleMap`)
        return
    end
    local map = self :: MapleMap<K, V>
    if map:ContainsKey(key) then
        if value ~= nil and Settings.AllowNewIndexToUseSet then
            map:Set(key, value)
        elseif value == nil and Settings.AllowNewIndexToUseRemove then
            map:Remove(key)
        end
        return
    end

    map:Add(key, value)
end
MapleMap.__len = function<K, V>(self: RawMap)
    if not MapleMap.IsMaple(self) then
        warn(`Can't check length of map provided is not a MapleMap`)
        return -1
    end
    local map = self :: MapleMap<K, V>
    return map:Count()
end
MapleMap.__eq = function<K, V>(self: RawMap, other: RawMap)
    if not MapleMap.IsMaple(self) or not MapleMap.IsMaple(other) then
        warn(`One or both maps provided are not MapleMaps`)
        return false
    end
    
    local map = self :: MapleMap<K, V>
    local otherMap = other :: MapleMap<K, V>

    if Settings.DefaultEqualityCheck == "Shallow" then
        return map:Equals(otherMap)
    elseif Settings.DefaultEqualityCheck == "Deep" then
        return map:DeepEquals(otherMap)
    else
        return map:TrueEquals(otherMap)
    end
end
local mapleMapMemoryAddress = tostring(MapleMap)
MemoryAddressLookup[mapleMapMemoryAddress] = MapleMap

export type MapleMapMetadata = {
    ["Count"]: number,
    ["Capacity"]: number,
    ["IsFixedCapacity"]: boolean,
    ["IsLocked"]: boolean,
    ["IsMutable"]: boolean,
    ["MapleMap"]: true,
    ["Metatable"]: string,
    [string]: number | boolean
} & WeepingWillow.WeepingWillowBrand

type MapleMapMethods<K, V> = {
    ["Add"]: (self: MapleMap<K, V>, key: K, value: V) -> boolean,
    ["Get"]: (self: MapleMap<K, V>, key: K) -> V?,
    ["Set"]: (self: MapleMap<K, V>, key: K, value: V) -> boolean,
    ["Join"]: (self: MapleMap<K, V>, other: MapleMap<K, V>) -> boolean,
    ["Copy"]: (self: MapleMap<K, V>) -> MapleMap<K, V>,
    ["DeepCopy"]: (self: MapleMap<K, V>) -> MapleMap<K, V>,
    ["For"]: (self: MapleMap<K, V>, loop: (k: K, v: V) -> ()) -> (),
    ["Keys"]: (self: MapleMap<K, V>) -> {K},
    ["Values"]: (self: MapleMap<K, V>) -> {V},
    ["ContainsKey"]: (self: MapleMap<K, V>, key: K) -> boolean,
    ["Contains"]: (self: MapleMap<K, V>, value: V) -> boolean,
}

export type MapleMap<K, V> = setmetatable<{
    ["_KVs"]: _KVs<K, V>,
    ["_Metadata"]: MapleMapMetadata,
    [string]: any -- Limiting to string to not strain the type checker
} & LilacLINQ.LINQCompatible<MapleMap<K, V>> & MapleMapMethods<K, V>, typeof(MapleMap)>

local INFINITE_CAPACITY = -1

local function GetCount(map: RawMap)
    local count = 0
    for _, _ in map do
        count += 1
    end
    return count
end

local function GetTable<K, V>(kvs: _KVs<K, V>): _KVs<K, V>
    if Settings.NestedTablesAreReferences then
        return kvs
    end

    local copied: _KVs<K, V> = {}
    local loop: (RawMap) -> RawMap
    loop = function(tab: RawMap)
        local new: RawMap = {}
        for k: any, v: any in tab do
            if typeof(v) == "table" then
                new[k] = loop(v :: RawMap)
                continue
            end
            new[k] = v
        end
        if WeepingWillow.IsWeepingWillow(new) then
            local addr = WeepingWillow.GetMetatableAddress(new)
            if addr ~= nil then
                setmetatable(new, MemoryAddressLookup[addr])
            end
        end
        return new
    end
    copied = loop(kvs)
    return copied
end

function MapleMap.New<K, V>(_kvs: _KVs<K, V>?, capacity: number?, isFixedCapacity: boolean?, isLocked: boolean?, isMutable: boolean?): MapleMap<K, V>
    local self = setmetatable({}, MapleMap) :: MapleMap<K, V>
    local mapToUse = _kvs or ({} :: {[K]: V})
    local count = 0

    if _kvs then
        count = GetCount(_kvs)
        if capacity and capacity < count and Settings.UNDEF_FallbackToInfinityIfCapacityLessThanCount then
            warn(`Capacity can't be set to {capacity} because your map has {count} k/v pairs. Setting capacity to infinity instead`)
            capacity = INFINITE_CAPACITY
        end
    end

    local metadata: MapleMapMetadata = {
        Capacity = capacity or INFINITE_CAPACITY,
        Count = count,
        IsFixedCapacity = isFixedCapacity or false,
        IsLocked = if isLocked ~= nil then isLocked else false,
        IsMutable = if isMutable ~= nil then isMutable else true,
        Metatable = mapleMapMemoryAddress,
        MapleMap = true,
        __brand = "WeepingWillow"
    }

    rawset(self, "_KVs", mapToUse)
    rawset(self, "_Metadata", metadata)

    return self
end

function MapleMap.Add<K, V>(self: MapleMap<K, V>, key: K, value: V)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    local spaceNeeded = 1
    if not self:_HasSufficientSpace(spaceNeeded) then
        warn(`Capacity reached. Can't add any more keys`)
        return false
    end

    if typeof(value) == "table" then
        value = GetTable(value)
    end

    if self:ContainsKey(key) then
        warn(`Key {key} already exists. If you meant to set it's value, use Set instead`)
        return false
    end
    self._KVs[key] = value
    self._Metadata.Count += 1
    return true
end

function MapleMap.Get<K, V>(self: MapleMap<K, V>, key: K)
    return self._KVs[key]
end

function MapleMap.Set<K, V>(self: MapleMap<K, V>, key: K, value: V)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    if typeof(value) == "table" then
        value = GetTable(value)
    end

    if not self:ContainsKey(key) then
        warn(`Key {key} does not exist and can't be set to a value`)
        return false
    end
    self._KVs[key] = value
    return true
end

function MapleMap.Remove<K, V>(self: MapleMap<K, V>, key: K)
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

function MapleMap.Expand<K, V>(self: MapleMap<K, V>, by: number)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't expand because map has a fixed capacity`)
        return false
    end
    self._Metadata.Capacity += by
    return true
end

function MapleMap.Shrink<K, V>(self: MapleMap<K, V>, by: number)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't shrink because map has a fixed capacity`)
        return false
    end
    local difference = self._Metadata.Capacity - by
    if difference < self._Metadata.Count then
        warn(`Can't shrink map by {by} because map contains {self._Metadata.Count} element(s)`)
        return false
    end
    self._Metadata.Capacity = difference
    return true
end

function MapleMap.TrimExcess<K, V>(self: MapleMap<K, V>)
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

function MapleMap.Resize<K, V>(self: MapleMap<K, V>, newSize: number)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    if self._Metadata.IsFixedCapacity then
        warn(`Can't resize because map has a fixed capacity`)
        return false
    end

    if self._Metadata.Count > newSize then
        warn(`New capacity can not be less than current count of elements`)
        return false
    end

    self._Metadata.Capacity = newSize
    return true
end

function MapleMap.Clear<K, V>(self: MapleMap<K, V>)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end
    self._KVs = {}
    self._Metadata.Count = 0
    return true
end

--[[ Add keys from other into self. Preserves values if self and other have a same key ]]
function MapleMap.Join<K, V>(self: MapleMap<K, V>, other: MapleMap<K, V>)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.LockedMap)
        return false
    end

    local elements: RawMap = {}
    if MapleMap.IsMaple(other) then
        local other2 = other :: MapleMap<K, V>
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
function MapleMap.Copy<K, V>(self: MapleMap<K, V>)
    return table.clone(self)
end

--[[ Returns a non-referenced copy of self ]]
function MapleMap.DeepCopy<K, V>(self: MapleMap<K, V>)
    -- TODO: Deep copy tables themeselves
    local deepCopy = {} :: MapleMap<K, V>
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

function MapleMap.For<K, V>(self: MapleMap<K, V>, loop: (k: K, v: V) -> ())
    for k, v in self._KVs do
        loop(k, v)
    end
end

function MapleMap.IsMaple(map: RawMap)
    if not map["_Metadata"] then
        return false
    end
    return map["_Metadata"]["MapleMap"] == true
end

function MapleMap.Lock<K, V>(self: MapleMap<K, V>)
    if not self._Metadata.IsMutable then
        warn(CommonWarns.MutabilityDisabled)
        return
    end
    self._Metadata.IsLocked = true
end

function MapleMap.Unlock<K, V>(self: MapleMap<K, V>)
    if not self._Metadata.IsMutable then
        warn(CommonWarns.MutabilityDisabled)
        return
    end
    self._Metadata.IsLocked = false
end

function MapleMap.MakeImmutable<K, V>(self: MapleMap<K, V>)
    self._Metadata.IsMutable = false
    table.freeze(self._KVs)
    table.freeze(self._Metadata)
end

--[[ Returns an array of all keys(not a reference table) ]]
function MapleMap.Keys<K, V>(self: MapleMap<K, V>): {K}
    local keys: {K} = {}
    for k, _ in self._KVs do
        table.insert(keys, k)
    end
    return keys
end

--[[ Returns an array of all values(not a reference table) ]]
function MapleMap.Values<K, V>(self: MapleMap<K, V>): {V}
    local keys: {V} = {}
    for _, v in self._KVs do
        table.insert(keys, v)
    end
    return keys
end

local function DeepEquals(first: RawMap, second: RawMap)
    local loop: (RawMap, RawMap) -> boolean
    local passes = 0
    local inifitePasses = -1
    loop = function(tab0: RawMap, tab1: RawMap)
        if Settings.MaxEqualityNestingCheck ~= inifitePasses and passes > Settings.MaxEqualityNestingCheck then
            return false -- Return false to not create any false-positives
        end

        type Tables = {
            ["First"]: RawMap,
            ["Second"]: RawMap
        }
        local tablesToRecurse: {Tables} = {}

        for k, v in tab0 do
            if typeof(v) == "table" and typeof(tab1[k]) == "table" then
                local count1 = GetCount(v)
                local count2 = GetCount(tab1[k])
                if count1 ~= count2 then
                    return false
                end

                table.insert(tablesToRecurse, {First = v, Second = tab1[k]})
                continue -- Skip because the next value check will return false if the tables don't have the same memory address
            end

            if tab1[k] ~= v then
                return false
            end
        end

        if #tablesToRecurse > 0 then
            passes += 1
        end

        for _, v in tablesToRecurse do
            local result = loop(v.First, v.Second)
            if result == false then
                return false
            end
        end

        return true
    end
    return loop(first, second)
end

--[[ Returns true only if top level _KVs are equal ]]
function MapleMap.Equals<K, V>(self: MapleMap<K, V>, other: MapleMap<unknown, unknown>)
    if typeof(other) == "nil" then
        return false
    end
    if other:Count() ~= self:Count() then
        return false
    end

    for k: K, v: V in self._KVs do
        if other._KVs[k] ~= v then
            return false
        end
    end
    return true
end

--[[ Returns true for deep equality(tables in tables) within _KVs of self and other ]]
function MapleMap.DeepEquals<K, V>(self: MapleMap<K, V>, other: MapleMap<unknown, unknown>)
    if typeof(other) == "nil" then
        return false
    end
    if other:Count() ~= self:Count() then
        return false
    end
    return DeepEquals(self._KVs, other._KVs)
end

--[[ Returns true for deep equality within _KVs and _Metadata of self and other ]]
function MapleMap.TrueEquals<K, V>(self: MapleMap<K, V>, other: MapleMap<unknown, unknown>)
    if typeof(other) == "nil" then
        return false
    end
    if other:Count() ~= self:Count() then
        return false
    end
    return DeepEquals(self, other)
end

-- LINQ methods
function MapleMap.All<K, V>(self: MapleMap<K, V>, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.All(self._KVs, condition)
end

function MapleMap.Any<K, V>(self: MapleMap<K, V>, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.Any(self._KVs, condition)
end

function MapleMap.Where<K, V>(self: MapleMap<K, V>, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.Where(self._KVs, condition, true)
end

function MapleMap.Select<K, V>(self: MapleMap<K, V>, method: LilacLINQ.AnyFunc)
    return LilacLINQ.Select(self._KVs, method, true)
end

function MapleMap.GroupBy<K, V>(self: MapleMap<K, V>, method: LilacLINQ.AnyFunc)
    return LilacLINQ.GroupBy(self._KVs, method)
end

function MapleMap.ContainsKey<K, V>(self: MapleMap<K, V>, key: K)
    return self._KVs[key] ~= nil
end

function MapleMap.Contains<K, V>(self: MapleMap<K, V>, value: V)
    return LilacLINQ.Contains(self._KVs, value)
end

-- Getters
function MapleMap.Count<K, V>(self: MapleMap<K, V>)
    return self._Metadata.Count
end

function MapleMap.Capacity<K, V>(self: MapleMap<K, V>)
    return self._Metadata.Capacity
end

function MapleMap.IsLocked<K, V>(self: MapleMap<K, V>)
    return self._Metadata.IsLocked
end

function MapleMap.IsMutable<K, V>(self: MapleMap<K, V>)
    return self._Metadata.IsMutable
end

-- Private methods
function MapleMap._CountKeys<K, V>(self: MapleMap<K, V>)
    local count = GetCount(self._KVs)
    self._Metadata.Count = count
end

function MapleMap._IsLockedOrImmutable<K, V>(self: MapleMap<K, V>)
    return self:IsLocked() or not self:IsMutable()
end

function MapleMap._HasSufficientSpace<K, V>(self: MapleMap<K, V>, space: number)
    return self._Metadata.Capacity == INFINITE_CAPACITY or self._Metadata.Count + space <= self._Metadata.Capacity
end

return MapleMap