--[[
Title: store
Author(s): big
CreateDate: 2018.6.20
ModifyDate: 2022.1.4
City: Foshan 
use the lib:
------------------------------------------------------------
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')
------------------------------------------------------------
]]

NPL.load('./UserStore.lua')
NPL.load('./PageStore.lua')
NPL.load('./WorldStore.lua')
NPL.load('./LessonStore.lua')

local UserStore = commonlib.gettable('Mod.WorldShare.store.User')
local PageStore = commonlib.gettable('Mod.WorldShare.store.Page')
local WorldStore = commonlib.gettable('Mod.WorldShare.store.World')
local LessonStore = commonlib.gettable('Mod.WorldShare.store.Lesson')

local Store = NPL.export()

Store.storeList = {
    user = UserStore,
    page = PageStore,
    world = WorldStore,
    lesson = LessonStore,
}

function Store:Subscribe(key, callback)
    if not key or type(key) ~= 'string' then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    self.storeList[storeType]:Connect('on' .. storeKey, nil, callback, 'UniqueConnection')
end

function Store:Unsubscribe(key)
    if not key or type(key) ~= 'string' then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    self.storeList[storeType]:Disconnect('on' .. storeKey)
end

function Store:Set(key, value)
    if not key or type(key) ~= 'string' then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if self.storeList[storeType] then
        self.storeList[storeType][storeKey] = value
    end
end

function Store:Get(key)
    if not key or type(key) ~= 'string' then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if self.storeList[storeType] then
        return self.storeList[storeType][storeKey]
    end

    return nil
end

function Store:Action(key)
    if not key or type(key) ~= 'string' then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if self.storeList[storeType] then
        local CurStore = self.storeList[storeType]
        local CurFun = CurStore:Action()[storeKey]

        if CurFun and type(CurFun) == 'function' then
            return CurFun
        end
    end
end

function Store:Getter(key)
    if not key or type(key) ~= 'string' then
        return false
    end

    local storeType = self:GetStoreType(key)
    local storeKey = self:GetStoreKey(key)

    if self.storeList[storeType] then
        local CurStore = self.storeList[storeType]
        local CurFun = CurStore:Getter()[storeKey]

        if type(CurFun) == 'function' then
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
