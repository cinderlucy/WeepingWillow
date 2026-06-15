--[[
Created by cinderlucy
Meant for all
]]

--!strict
type EqualityLevels = "Shallow" | "Deep" | "True"

local Settings = {
    AllowNewIndexToUseSet = true,
    DefaultEqualityCheck = "Shallow" :: EqualityLevels
}
table.freeze(Settings)
return Settings