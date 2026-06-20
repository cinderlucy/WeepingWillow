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
    MaxEqualityNestingCheck = 2, -- Set to -1 for the truest level of equality at the cost of performance on larger maps,
    NestedTablesAreReferences = true, -- Setting to false will deep copy the contents of nested tables before adding them, resulting in a performance hit
    UNDEF_FallbackToInfinityIfCapacityLessThanCount = true
}
table.freeze(Settings)
return Settings