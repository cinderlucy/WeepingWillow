--!strict
export type WeepingWillowBrand = {__brand: "WeepingWillow"}

local WeepingWillow = {}

function WeepingWillow.IsWeepingWillow(tab: {[any]: any})
    if tab["_Metadata"] == nil then
        return false
    end
    return tab["_Metadata"]["__brand"] == "WeepingWillow"
end

return WeepingWillow