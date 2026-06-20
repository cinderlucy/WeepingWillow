--!strict
export type WeepingWillowBrand = {__brand: "WeepingWillow"}

local WeepingWillow = {}

function WeepingWillow.IsWeepingWillow(tab: {[any]: any})
    if tab["_Metadata"] == nil then
        return false
    end
    return tab["_Metadata"]["__brand"] == "WeepingWillow"
end

function WeepingWillow.GetMetatableAddress(tab: {[any]: any}): string?
    if tab["_Metadata"] == nil then
        return nil
    end
    if tab["_Metadata"]["__brand"] ~= "WeepingWillow" then
        return nil
    end
    return tab["_Metadata"]["Metatable"]
end

return WeepingWillow