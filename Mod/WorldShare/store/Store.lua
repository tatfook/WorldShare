--[[
Title: store
Author(s): big
CreateDate: 2018.6.20
ModifyDate: 2022.6.28
City: Foshan 
use the lib:
------------------------------------------------------------
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')
------------------------------------------------------------
]]

local UserStore = NPL.load('./UserStore.lua')
local PageStore = NPL.load('./PageStore.lua')
local WorldStore = NPL.load('./WorldStore.lua')
local LessonStore = NPL.load('./LessonStore.lua')

local Store = NPL.export()

-- private table
local storeList = {
    user = {
        store = UserStore,
        data = {},
    },
    page = {
        store = PageStore,
        data = {},
    },
    world = {
        store = WorldStore,
        data = {},
    },
    lesson = {
        store = LessonStore,
        data = {},
    },
}

function Store:Subscribe(key, callback)
    if not key or type(key) ~= 'string' then
        return
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    storeList[storeType].store:Connect('on' .. storeKey, nil, callback, 'UniqueConnection')
end

function Store:Unsubscribe(key)
    if not key or type(key) ~= 'string' then
        return
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    storeList[storeType].store:Disconnect('on' .. storeKey)
end

function Store:Set(key, value)
    if not key or type(key) ~= 'string' then
        return
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if storeList[storeType] then
        storeList[storeType].data[storeKey] = value
    end
end

function Store:Get(key)
    if not key or type(key) ~= 'string' then
        return
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if storeList[storeType] then
        return storeList[storeType].data[storeKey]
    end
end

function Store:Action(key)
    if not key or type(key) ~= 'string' then
        return
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if storeList[storeType] then
        local curStore = storeList[storeType]
        local CurFun = curStore.store:Action(curStore.data)[storeKey]

        if CurFun and type(CurFun) == 'function' then
            return CurFun
        end
    end
end

function Store:Getter(key)
    if not key or type(key) ~= 'string' then
        return
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if storeList[storeType] then
        local curStore = storeList[storeType]
        local CurFun = curStore.store:Getter(curStore.data)[storeKey]

        if CurFun and type(CurFun) == 'function' then
            return CurFun()
        end
    end
end

function Store:Remove(key)
    self:Set(key, nil)
end

function Store:GetStorePath(key)
    if not key or type(key) ~= 'string' then
        return false
    end

    local keyTable = {}

    for item in string.gmatch(key, '[^/]+') do
        keyTable[#keyTable + 1] = item
    end

    return keyTable
end

function Store:GetStoreType(key)
    local keyTable = self:GetStorePath(key)

    if keyTable and keyTable[1] then
        return keyTable[1]
    else
        return nil
    end
end

function Store:GetStoreKey(key)
    local keyTable = self:GetStorePath(key)

    if keyTable and keyTable[2] then
        return keyTable[2]
    else
        return nil
    end
end
