local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MapleMap = require(ReplicatedStorage.WeepingWillow.MapleMap)

local inventory = MapleMap.New({
    ["Sword"] = 1,
    ["Shield"] = 1,
    ["Potion"] = 5
})

inventory:Add("Arrow", 20)
inventory:Set("Potion", 3)
inventory:Remove("Shield")

print(inventory:ContainsKey("Sword")) -- true
print(inventory:ContainsKey("Shield")) -- false, was removed
print(inventory:Count()) -- 3
print(inventory:Get("Potion")) -- 3, was set
print(inventory:Get("Arrow")) -- 20
print(inventory:Any(function(k, v) return v > 10 end)) -- true
print(inventory:All(function(k, v) return v > 0 end)) -- true

local heavyItems = inventory:Where(function(k, v) return v >= 5 end)
print(heavyItems["Arrow"]) -- 20
print(heavyItems["Sword"]) -- nil, value is 1

local doubled = inventory:Select(function(k, v) return v * 2 end)
print(doubled["Sword"]) -- 2
print(doubled["Arrow"]) -- 40

inventory:For(function(k, v)
    print(k, v)
end)

local backup = inventory:Copy()
print(backup:Count()) -- 3
print(backup:Get("Sword")) -- 1
backup:Add("TestKey", 99)
print(backup:ContainsKey("TestKey")) -- true
print(inventory:ContainsKey("TestKey")) -- false, original unaffected

local loot = MapleMap.New({
    ["GoldCoin"] = 50,
    ["Gem"] = 3
})

local fresh = MapleMap.New()
fresh:Join(inventory)
fresh:Join(loot)
print(fresh:Count()) -- 5
print(fresh:ContainsKey("GoldCoin")) -- true
print(fresh:ContainsKey("Sword")) -- true

inventory:Lock()
inventory:Add("Dagger", 1) -- warns
inventory:Unlock()
inventory:Add("Dagger", 1) -- works
print(inventory:ContainsKey("Dagger")) -- true

inventory:MakeConst()
inventory:Remove("Dagger") -- warns
print(inventory:ContainsKey("Dagger")) -- true, wasn't removed