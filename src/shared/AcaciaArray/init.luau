--!strict
local AcaciaArray = {}
AcaciaArray.__index = AcaciaArray

export type RawArray = {[number]: any}
type AcaciaArrayMetadata = {
    ["IsLocked"]: boolean,
    ["IsMutable"]: boolean
}
export type AcaciaArray = setmetatable<{
    ["_Array"]: RawArray,
    ["_Metadata"]: AcaciaArrayMetadata
}, typeof(AcaciaArray)>

function AcaciaArray.New()
    
end

return AcaciaArray