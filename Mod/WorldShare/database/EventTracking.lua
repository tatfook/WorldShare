--[[
Title: Event Tracking Database
Author(s): big
Date: 2020.11.3
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local EventTrackingDatabase = NPL.load("(gl)Mod/WorldShare/database/EventTracking.lua")
------------------------------------------------------------
]]

local EventTrackingDatabase = NPL.export()

-- event tracking struct
--[[
{
    {
        userId = 1,
        unitinfo = {
            {
                action = "testEvent",
                packet = {
                    localId = '123-ddd-111', -- uuid
                    userId = 1,
                    projectId = 1,
                    beginAt = 12345678,
                    endAt = 0,
                    duration = 0,
                    traceId = 123,
                }
            },
            {
                action = "testEvent",
                packet = {
                    localId = '123-ddd-111', -- uuid
                    userId = 1,
                    projectId = 1,
                    beginAt = 12345678,
                    endAt = 12345678,
                    duration = 30000,
                    traceId = 123,
                }
            },
            {
                action = "testEvent",
                packet = {
                    localId = 'uuu-999-8888', -- uuid
                    userId = 1,
                    currentAt = 1234567,
                    traceId = 888
                }
            }
        }
    },
    {
        userId = 2,
        unitinfo = {
            {
                action = "testEvent",
                packet = {
                    localId = 'ppp-0000-7777', -- uuid
                    action = 'createUser',
                    userId = 1,
                    currentAt = 1234567,
                    traceId = 888
                }
            }
        }
    }
}
]]
function EventTrackingDatabase:GetAllData()
    local playerController = GameLogic.GetPlayerController()

    return playerController:LoadLocalData("event_tracking", {}, true)
end

function EventTrackingDatabase:SaveAllData(allData)
    local playerController = GameLogic.GetPlayerController()

    return playerController:SaveLocalData("event_tracking", allData, true)
end

function EventTrackingDatabase:PutPacket(userId, action, packet)
    if not userId or not action or not packet then
        return false
    end

    local allData = self:GetAllData()

    local beUserExisted = false
    local currentUser

    for key, item in ipairs(allData) do
        if item and item.userId and tonumber(item.userId) == tonumber(userId) then
            beUserExisted = true
            currentUser = item
            break
        end
    end

    if not beUserExisted then
        currentUser = {
            userId = tonumber(userId),
            unitinfo = {}
        }

        allData[#allData + 1] = currentUser
    end

    -- check packet action exist
    local beActionExisted = false
    local currentUnitinfo

    for key, item in ipairs(currentUser.unitinfo) do
        if item and item.action and item.action == action then
            beActionExisted = true
            currentUnitinfo = item
            break
        end
    end

    if not beActionExisted then
        currentUser.unitinfo[#currentUser.unitinfo + 1] = {
            action = action,
            packet = packet
        }
    else
        -- update record
        for key, value in pairs(packet) do
            for cKey, cValue in pairs(currentUnitinfo.packet) do
                if key == cKey then
                    if cKey ~= 'traceId' then
                        currentUnitinfo.packet[cKey] = value
                    end
                end
            end
        end
    end

    return self:SaveAllData(allData)
end

function EventTrackingDatabase:RemovePacket(userId, action, packet)
    if not userId or not action or not packet then
        return false
    end

    local allData = self:GetAllData()
    local beRemoveSuccessed = false

    for aKey, aItem in ipairs(allData) do
        if aItem and tonumber(aItem.userId) == tonumber(userId) then
            local currentUnitinfo = commonlib.Array:new(aItem.unitinfo)

            for uKey, uItem in ipairs(currentUnitinfo) do
                if uItem and uItem.action == action then
                    currentUnitinfo:remove(uKey)
                    break
                end
            end

            aItem.unitinfo = currentUnitinfo
            beRemoveSuccessed = true
            break
        end
    end

    if beRemoveSuccessed then
        return self:SaveAllData(allData)
    else
        return false
    end
end

function EventTrackingDatabase:GetPacket(userId, action)
    if not userId or not action then
        return false
    end

    local allData = self:GetAllData()

    for aKey, aItem in ipairs(allData) do
        if aItem.userId == userId then
            if aItem.unitinfo and type(aItem.unitinfo) == 'table' then
                for uKey, uItem in ipairs(aItem.unitinfo) do
                    if uItem.action == action then
                        return uItem.packet
                    end
                end
            end
        end
    end

    return nil
end

function EventTrackingDatabase:ClearUselessCache()
    local allData = self:GetAllData()

    for aKey, aItem in ipairs(allData) do
        local currentUnitinfo = commonlib.Array:new(aItem.unitinfo)

        for cKey, cItem in ipairs(currentUnitinfo) do
            if cItem and cItem.packet then
                if cItem.packet.endAt and cItem.packet.endAt == 0 then
                    currentUnitinfo:remove(cKey)
                end
            end
        end
        
        aItem.unitinfo = currentUnitinfo
    end

    return self:SaveAllData(allData)
end
