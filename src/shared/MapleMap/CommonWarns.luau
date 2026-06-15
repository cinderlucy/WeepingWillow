--[[
Created by cinderlucy
Meant for all
]]

--!strict
local CommonWarns = {
    ["LockedMap"] = "Map can not be edited until unlocked",
    ["ConstMap"] = "Map is in a permanently read-only state due to setting the map to be const",
    ["TableNotAllowed"] = "Key that's value is table is not allowed to be added or set"
}
table.freeze(CommonWarns)

return CommonWarns