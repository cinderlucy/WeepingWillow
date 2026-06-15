--[[
Written by cinderlucy
Made for all
]]

--!strict
local CommonWarns = {
    ["LockedMap"] = "Map can not be edited until unlocked",
    ["MutabilityDisabled"] = "Map is in a permanently read-only state due to setting the map to be immutable",
    ["TableNotAllowed"] = "Key that's value is table is not allowed to be added or set"
}
table.freeze(CommonWarns)

return CommonWarns