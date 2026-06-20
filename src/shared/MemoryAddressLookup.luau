--!strict
--[[
Prefering memory addresses over storing metatables directly because walking the metatables would cause an infinite loop since __index
points back to itself
]]
local MemoryAddressLookup: {[string]: {[any]: any}} = {}
return MemoryAddressLookup