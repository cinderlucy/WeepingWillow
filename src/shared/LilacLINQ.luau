--[[
Written by cinderlucy
Made for all
]]

--!strict
local LilacLINQ = {}

type ConditionFunc = (k: any, v: any) -> boolean
type Table = {[any]: any}

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

--[[ Returns a new dictionary that has k/vs where k/vs under _KVs meet the condition ]]
function LilacLINQ.Where(tab: Table, condition: ConditionFunc): (Table, number)
    local dictionary: Table = {}
    local count = 0
    for key, value in tab do
        if not condition(key, value) then
            continue
        end
        dictionary[key] = value
        count += 1
    end
    return dictionary, count
end

--[[ Returns a modified dictionary that's k/vs are modified based on the method provided ]]
function LilacLINQ.Select(tab: Table, method: (k: any, v: any) -> any): ({[string]: any}, number)
    local dictionary: {[string]: any} = {}
    local count = 0
    for key, value: any in tab do
        dictionary[key] = method(key, value)
    end
    return dictionary, count
end

return LilacLINQ