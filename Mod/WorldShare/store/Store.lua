--[[
Title: Store
Author(s):  big
Date:  2018.6.20
City: Foshan 
use the lib:
------------------------------------------------------------
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
------------------------------------------------------------
]]
NPL.load("./UserStore.lua")
NPL.load("./PageStore.lua")
NPL.load("./WorldStore.lua")

local UserStore = commonlib.gettable("Mod.WorldShare.store.User")
local PageStore = commonlib.gettable("Mod.WorldShare.store.Page")
local WorldStore = commonlib.gettable("Mod.WorldShare.store.World")

local Store = NPL.export()

local USER = "user"
local PAGE = "page"
local WORLD = "world"

function Store:Set(key, value)
    if (not key) then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if (storeType == USER) then
        UserStore[storeKey] = commonlib.copy(value)
        if (storeKey == "token") then
            commonlib.setfield("System.User.keepworktoken", value)
        end
    end

    if (storeType == WORLD) then
        WorldStore[storeKey] = commonlib.copy(value)
    end

    if (storeType == PAGE) then
        PageStore[storeKey] = value
    end
end

function Store:Get(key)
    if (not key) then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if (storeType == USER and UserStore[storeKey]) then
        return commonlib.copy(UserStore[storeKey])
    end

    if (storeType == WORLD) then
        return commonlib.copy(WorldStore[storeKey])
    end

    if (storeType == PAGE and PageStore[storeKey]) then
        return PageStore[storeKey]
    end

    return nil
end

function Store:Remove(key)
    self:Set(key, nil)
end

function Store:GetStorePath(key)
    if (type(key) ~= "string") then
        return false
    end

    local keyTable = {}

    for item in string.gmatch(key, "[^/]+") do
        keyTable[#keyTable + 1] = item
    end

    return keyTable
end

function Store:GetStoreType(key)
    local keyTable = self:GetStorePath(key)

    if (keyTable[1]) then
        return keyTable[1]
    else
        return nil
    end
end

function Store:GetStoreKey(key)
    local keyTable = self:GetStorePath(key)

    if (keyTable[2]) then
        return keyTable[2]
    else
        return nil
    end
end
