--[[
Written by cinderlucy
Made for all
]]

--[[
Some settings can result in undefined behavior. These setting will be marked with a UNDEF_ prefix
]]

--!strict
type EqualityLevels = "Shallow" | "Deep" | "True"

local Settings = {
    AllowNewIndexToUseSet = true,
    AllowNewIndexToUseRemove = true,
    DefaultEqualityCheck = "Shallow" :: EqualityLevels,
    UNDEF_FallbackToInfinityIfCapacityLessThanCount = true
}
table.freeze(Settings)
return Settings