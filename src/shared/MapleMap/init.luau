--[[
Created by cinderlucy
Meant for all
]]

--!strict
local Settings = require("./MapleMap/Settings")
local CommonWarns = require("./MapleMap/CommonWarns")

export type RawMap = {[string]: any}

local MapleMap = {}
MapleMap.__index = MapleMap
MapleMap.__newindex = function(self: RawMap, key: string, value: any)
    if not MapleMap.IsMaple(self) then
        warn(`Can't add key {key} because map provided is not a MapleMap`)
        return
    end
    local map = self :: MapleMapT
    if map:ContainsKey(key) and Settings.AllowNewIndexToUseSet then
        map:Set(key, value)
        return
    end
    map:Add(key, value)
end
MapleMap.__len = function(self: RawMap)
    if not MapleMap.IsMaple(self) then
        warn(`Can't check length of map provided is not a MapleMap`)
        return -1
    end
    local map = self :: MapleMapT
    return map._Metadata.Count
end
MapleMap.__eq = function(self: RawMap, other: RawMap)
    if not MapleMap.IsMaple(self) or not MapleMap.IsMaple(other) then
        warn(`One or both maps provided are not MapleMaps`)
        return false
    end
    
    local map = self :: MapleMapT
    local otherMap = other :: MapleMapT

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
    ["IsLocked"]: boolean,
    ["IsMutable"]: boolean,
    ["MapleMap"]: true,
    [string]: any
}

export type MapleMapT = setmetatable<{
    ["_KVs"]: RawMap,
    ["_Metadata"]: MapleMapMetadata,
    [string]: any
}, typeof(MapleMap)>

local INFINITE_CAPACITY = -1

local function MapContainsTable(map: RawMap)
    for _, v in map do
        if typeof(v) == "table" then
            return true
        end
    end
    return false
end

function MapleMap.New(map: RawMap?, metadata: MapleMapMetadata?)
    local self = setmetatable({}, MapleMap) :: MapleMapT
    local mapToUse = map or {}

    if map and MapContainsTable(map) then
        mapToUse = {}
        warn(CommonWarns.TableNotAllowed)
        warn("Not using map argument for _KVs. Defaulting to empty dictionary")
    end

    rawset(self, "_KVs", mapToUse)
    rawset(self, "_Metadata", if metadata then metadata else {
            Capacity = INFINITE_CAPACITY,
            Count = 0,
            IsLocked = false,
            IsMutable = true,
            MapleMap = true
        })

    if map ~= nil then
        self:_CountKeys()
    end

    return self
end

function MapleMap.Add(self: MapleMapT, key: string, value: any)
    if self:_IsLockedOrConst() then
        warn(CommonWarns.LockedMap)
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

function MapleMap.Get(self: MapleMapT, key: string)
    return self._KVs[key]
end

function MapleMap.Set(self: MapleMapT, key: string, value: any)
    if self:_IsLockedOrConst() then
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

function MapleMap.Remove(self: MapleMapT, key: string)
    if self:_IsLockedOrConst() then
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

function MapleMap.ContainsKey(self: MapleMapT, key: string)
    return self._KVs[key] ~= nil
end

function MapleMap.Clear(self: MapleMapT)
    if self:_IsLockedOrConst() then
        warn(CommonWarns.LockedMap)
        return false
    end
    self._KVs = {}
    self._Metadata.Count = 0
    return true
end

function MapleMap.Join(self: MapleMapT, other: RawMap | MapleMapT)
    if self:_IsLockedOrConst() then
        warn(CommonWarns.LockedMap)
        return false
    end

    local elements: RawMap = {}
    if MapleMap.IsMaple(other) then
        local other2 = other :: MapleMapT
        elements = other2._KVs
    else
        local raw = other :: RawMap
        elements = raw
    end

    local elementsJoined = 0
    for k, v: any in elements do
        if self._KVs[k] then
            continue
        end
        self._KVs[k] = v
        elementsJoined += 1
    end
    self._Metadata.Count += elementsJoined

    return true
end

function MapleMap.Copy(self: MapleMapT)
    return table.clone(self)
end

function MapleMap.DeepCopy(self: MapleMapT): MapleMapT
    local deepCopy = {} :: MapleMapT
    deepCopy._KVs = {}
    deepCopy._Metadata = {} :: MapleMapMetadata

    for k, v in self._KVs do
        deepCopy._KVs[k] = v
    end
    for k, v in self._Metadata do
        deepCopy._Metadata[k] = v
    end
    return MapleMap.New(deepCopy._KVs, deepCopy._Metadata)
end

function MapleMap.For(self: MapleMapT, loop: (k: string, v: any) -> ())
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

function MapleMap.Lock(self: MapleMapT)
    self._Metadata.IsLocked = true
end

function MapleMap.Unlock(self: MapleMapT)
    if self._Metadata.IsMutable == false then
        warn(CommonWarns.MutabilityDisabled)
        return
    end
    self._Metadata.IsLocked = false
end

function MapleMap.MakeImmutable(self: MapleMapT)
    self._Metadata.IsMutable = false
end

function MapleMap.Keys(self: MapleMapT): {string}
    local keys: {string} = {}
    for k, _ in self._KVs do
        table.insert(keys, k)
    end
    return keys
end

function MapleMap.Values(self: MapleMapT): {any}
    local keys: {any} = {}
    for _, v: any in self._KVs do
        table.insert(keys, v)
    end
    return keys
end

function MapleMap.Equals(self: MapleMapT, other: MapleMapT)
    for k, v: any in self._KVs do
        if other._KVs[k] ~= v then
            return false
        end
    end
    return true
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

-- LINQ style methods
function MapleMap.All(self: MapleMapT, condition: (k: string, v: any) -> boolean)
    for k, v: any in self._KVs do
        if not condition(k, v) then
            return false
        end
    end
    return true
end

function MapleMap.Any(self: MapleMapT, condition: (k: string, v: any) -> boolean)
    for k, v: any in self._KVs do
        if condition(k, v) then
            return true
        end
    end
    return false
end

function MapleMap.Where(self: MapleMapT, condition: (k: string, v: any) -> boolean)
    local dictionary: {[string]: any} = {}
    for key, value: any in self._KVs do
        if not condition(key, value) then
            continue
        end
        dictionary[key] = value
    end
    return dictionary
end

function MapleMap.Select(self: MapleMapT, method: (k: string, v: any) -> any)
    local dictionary: {[string]: any} = {}
    for key, value: any in self._KVs do
        dictionary[key] = method(key, value)
    end
    return dictionary
end

-- Accounts for deep equality within _KVs of self and other
function MapleMap.DeepEquals(self: MapleMapT, other: MapleMapT)
    return DeepEquals(self._KVs, other._KVs)
end

-- Accounts for deep equality within _KVs and _Metadata of self and other
function MapleMap.TrueEquals(self: MapleMapT, other: MapleMapT)
    return DeepEquals(self, other)
end

-- Getters
function MapleMap.Count(self: MapleMapT)
    return self._Metadata.Count
end

function MapleMap.Capacity(self: MapleMapT)
    return self._Metadata.Capacity
end

function MapleMap.IsLocked(self: MapleMapT)
    return self._Metadata.IsLocked
end

function MapleMap.IsConst(self: MapleMapT)
    return self._Metadata.IsConst
end

-- Private methods
local function CountMap(map: RawMap)
    local count = 0
    for _, _ in map do
        count += 1
    end
    return count
end

function MapleMap._CountKeys(self: MapleMapT)
    local count = CountMap(self._KVs)
    self._Metadata.Count = count
end

function MapleMap._IsLockedOrConst(self: MapleMapT)
    return self:IsLocked() or self:IsConst()
end

return MapleMap