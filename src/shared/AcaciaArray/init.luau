--[[
Written by cinderlucy
Made for all
]]

--!strict
local CommonWarns = require("@self/CommonWarns")
local Settings = require("@self/Settings")
local LilacLINQ = require("./LilacLINQ")
local WeepingWillow = require("./WeepingWillow")

export type RawArray<T> = {T}

local AcaciaArray = {}
AcaciaArray.__index = AcaciaArray
AcaciaArray.__newindex = function<T>(self: {[string]: any}, index: number, element: any?)
    if typeof(index) ~= "number" then
        warn(`Index has to be a number`)
        return
    end
    if not AcaciaArray.IsAcacia(self) then
        return
    end

    local array = self :: AcaciaArray<T>
    if array:ContainsIndex(index) then
        if element ~= nil and Settings.AllowNewIndexToUseSet then
            array:Set(index, element) 
        elseif element == nil and Settings.AllowNewIndexToUseRemove then
            array:Remove(index)
        end
        return
    end

    array:Add(element)
end
AcaciaArray.__len = function<T>(self: {[string]: any})
    if not AcaciaArray.IsAcacia(self) then
        return 0
    end
    local array = self :: AcaciaArray<T>
    return array:Count()
end

export type AcaciaArrayMetadata = {
    ["Capacity"]: number,
    ["IsFixedCapacity"]: boolean,
    ["IsAcacia"]: boolean,
    ["IsLocked"]: boolean,
    ["IsMutable"]: boolean,
    [string]: number | boolean,
} & WeepingWillow.WeepingWillowBrand

export type AcaciaArray<T> = setmetatable<{
    ["_Array"]: RawArray<T>,
    ["_Metadata"]: AcaciaArrayMetadata,
    [string | number]: any -- Union with string and number is important to allow adding new indexes like Array[1] = 1
}, typeof(AcaciaArray)>

local INFINITE_CAPACITY = -1

function AcaciaArray.New<T>(array: {T}?, capacity: number?, isFixedCapacity: boolean?, isLocked: boolean?, isMutable: boolean?): AcaciaArray<T>
    local self = setmetatable({}, AcaciaArray) :: AcaciaArray<T>

    local metadata: AcaciaArrayMetadata = {
        Capacity = capacity or INFINITE_CAPACITY,
        IsFixedCapacity = isFixedCapacity or false,
        IsAcacia = true,
        IsLocked = if isLocked ~= nil then isLocked else false,
        IsMutable = if isMutable ~= nil then isMutable else true,
        __brand = "WeepingWillow"
    }

    rawset(self, "_Array", array or {})
    rawset(self, "_Metadata", metadata)
    return self
end

function AcaciaArray.Add<T>(self: AcaciaArray<T>, element: T)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.ImmutableOrLockedArray)
        return false
    end

    if not self:_HasSufficientSpace(1) then
        warn(CommonWarns.InsufficientSpace)
        return false
    end

    table.insert(self._Array, element)
    return true
end

function AcaciaArray.Set<T>(self: AcaciaArray<T>, index: number, element: T)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.ImmutableOrLockedArray)
        return false
    end

    if not self:ContainsIndex(index) then
        warn(`Create index {index} before attempting to set it`)
        return false
    end

    self._Array[index] = element
    return true
end

function AcaciaArray.Remove<T>(self: AcaciaArray<T>, index: number?)
    if self:_IsLockedOrImmutable() then
        warn(CommonWarns.ImmutableOrLockedArray)
        return false
    end

    table.remove(self._Array, index)
    return true
end

-- LINQ Methods
function AcaciaArray.All<T>(self: AcaciaArray<T>, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.All(self._Array, condition)
end

function AcaciaArray.Any<T>(self: AcaciaArray<T>, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.Any(self._Array, condition)
end

function AcaciaArray.Where<T>(self: AcaciaArray<T>, condition: LilacLINQ.ConditionFunc)
    return LilacLINQ.Where(self._Array, condition)
end

function AcaciaArray.Select<T>(self: AcaciaArray<T>, method: LilacLINQ.AnyFunc)
    return LilacLINQ.Select(self._Array, method)
end

function AcaciaArray.GroupBy<T>(self: AcaciaArray<T>, method: LilacLINQ.AnyFunc)
    return LilacLINQ.GroupBy(self._Array, method)
end

function AcaciaArray.ContainsIndex<T>(self: AcaciaArray<T>, index: number)
    return self._Array[index] ~= nil
end

function AcaciaArray.Contains<T>(self: AcaciaArray<T>, element: T)
    return LilacLINQ.Contains(self._Array, element)
end

-- Getters
function AcaciaArray.IsLocked<T>(self: AcaciaArray<T>)
    return self._Metadata.IsLocked
end

function AcaciaArray.IsMutable<T>(self: AcaciaArray<T>)
    return self._Metadata.IsMutable
end

function AcaciaArray.IsAcacia(raw: {[string]: any})
    if raw["_Metadata"] == nil then
        return false
    end
    return raw["_Metadata"]["IsAcacia"] == true
end

function AcaciaArray.Count<T>(self: AcaciaArray<T>)
    return #self._Array
end

-- Private methods
function AcaciaArray._IsLockedOrImmutable<T>(self: AcaciaArray<T>)
    return self:IsLocked() or not self:IsMutable()
end

function AcaciaArray._HasSufficientSpace<T>(self: AcaciaArray<T>, spaceNeeded: number)
    return self._Metadata.Capacity == INFINITE_CAPACITY or self._Metadata.Capacity > self:Count() + spaceNeeded
end

return AcaciaArray