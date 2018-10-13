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

local UserStore = commonlib.gettable('Mod.WorldShare.store.User')
local PageStore = commonlib.gettable('Mod.WorldShare.store.Page')
local WorldStore = commonlib.gettable('Mod.WorldShare.store.World')

local Store = NPL.export()

local USER = 'user'
local PAGE = 'page'
local WORLD = 'world'

function Store:set(key, value)
    if (not key) then
        return false
    end

    local storeType = self:getStoreType(key)
    local storeKey = self:getStoreKey(key)

    if (storeType == USER) then
        UserStore[storeKey] = commonlib.copy(value)
    end

    if (storeType == WORLD) then
        WorldStore[storeKey] = commonlib.copy(value)
    end

    if (storeType == PAGE) then
        PageStore[storeKey] = value
    end
end

function Store:get(key)
    if (not key) then
        return false
    end

    local storeType = self:getStoreType(key)
    local storeKey = self:getStoreKey(key)

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

function Store:remove(key)
    self:set(key, nil)
end

function Store:getStorePath(key)
    if (type(key) ~= 'string') then
        return false
    end

    local keyTable = {}

    for item in string.gmatch(key, "[^/]+") do
        keyTable[#keyTable + 1] = item
    end

    return keyTable
end

function Store:getStoreType(key)
    local keyTable = self:getStorePath(key)

    if (keyTable[1]) then
        return keyTable[1]
    else
        return nil
    end
end

function Store:getStoreKey(key)
    local keyTable = self:getStorePath(key)

    if (keyTable[2]) then
        return keyTable[2]
    else
        return nil
    end
end