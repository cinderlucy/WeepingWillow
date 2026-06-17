--[[
Written by cinderlucy
Made for all
]]

--!strict
local CommonWarns = {
    ["LockedArray"] = "Array is locked and can not be modified until unlocked",
    ["ImmutableArray"] = "Array is immutable and can not be modified",
    ["ImmutableOrLockedArray"] = "Array is either locked or immutable. If locked, you can unlock it",
    ["InsufficientSpace"] = "Array doesn't have enough space to add a new element"
}
table.freeze(CommonWarns)
return CommonWarns