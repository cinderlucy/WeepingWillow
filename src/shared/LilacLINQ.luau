--[[
Written by cinderlucy
Made for all
]]

--!strict
local LilacLINQ = {}

type Table = {[any]: any}
export type ConditionFunc = (k: any, v: any) -> boolean
export type AnyFunc = (k: any, v: any) -> any

--[[ Returns true if all k/vs meet the condition ]]
function LilacLINQ.All(tab: Table, condition: ConditionFunc)
    for k, v in tab do
        if not condition(k, v) then
            return false
        end
    end
    return true
end

--[[ Returns true if any k/vs meet the condition ]]
function LilacLINQ.Any(tab: Table, condition: ConditionFunc)
    for k, v in tab do
        if condition(k, v) then
            return true
        end
    end
    return false
end

--[[ Returns a new table that has k/vs where k/vs under _KVs meet the condition ]]
function LilacLINQ.Where(tab: Table, condition: ConditionFunc, isDictionary: boolean?): (Table, number)
    local dictionary: Table = {}
    local count = 0
    for key, value in tab do
        if not condition(key, value) then
            continue
        end
        if not isDictionary then
            table.insert(dictionary, value)
        else
            dictionary[key] = value
        end
        count += 1
    end
    return dictionary, count
end

--[[ Returns a modified table that's k/vs are modified based on the method provided ]]
function LilacLINQ.Select(tab: Table, method: AnyFunc, isDictionary: boolean?): (Table, number)
    local dictionary: Table = {}
    local count = 0
    for key, value: any in tab do
        local result = method(key, value)
        if not isDictionary then
            table.insert(dictionary, result)
        else
            dictionary[key] = result
        end
        count += 1
    end
    return dictionary, count
end

function LilacLINQ.GroupBy(tab: Table, method: AnyFunc): (Table, number)
    local dictionary: Table = {}
    local count = 0
    for k, v in tab do
        local category = method(k, v)
        if dictionary[category] == nil then
            dictionary[category] = {}
        end
        dictionary[category][k] = v
        count += 1
    end
    return dictionary, count
end

function LilacLINQ.Contains(tab: Table, value: any)
    return LilacLINQ.Any(tab, function(_, v): boolean
        return v == value
    end)
end

return LilacLINQ