--[[
Title: Event Tracking Service
Author(s): big
CreateDate: 2020.11.2
ModifyDate: 2022.3.11
City: Foshan
use the lib:
------------------------------------------------------------
local EventTrackingService = NPL.load("(gl)Mod/WorldShare/service/EventTracking.lua")
------------------------------------------------------------
]]

-- libs
local ParaWorldAnalytics = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldAnalytics.lua")

-- api
local EventGatewayEventsApi = NPL.load("(gl)Mod/WorldShare/api/EventGateway/Events.lua")

-- service
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

-- database
local EventTrackingDatabase = NPL.load("(gl)Mod/WorldShare/database/EventTracking.lua")

local EventTrackingService = NPL.export()

EventTrackingService.firstInit = false
EventTrackingService.firstSave = false
EventTrackingService.timeInterval = 10000 * 6 -- 60 seconds
EventTrackingService.currentLoop = nil


function EventTrackingService:Init()
    if self.firstInit then
        return        
    end

    self.firstInit = true
    self.timeInterval = 10000 -- 10 seconds

    -- send not finish event
    self:Loop()
end

function EventTrackingService:GetServerTime()
    return Mod.WorldShare.Store:Get('world/currentServerTime')
end

function EventTrackingService:GenerateDataPacket(eventType, userId, action, started)
    if not userId or not action then
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local projectId

    if currentEnterWorld and currentEnterWorld.kpProjectId and currentEnterWorld.kpProjectId ~= 0 then
        projectId = currentEnterWorld.kpProjectId
    end

    if eventType == 1 then -- one click event
        return {
            userId = userId,
            projectId = projectId,
            currentAt = self:GetServerTime(),
            traceId = System.Encoding.guid.uuid()
        }
    elseif eventType == 2 then -- duration event
        local unitinfo =  {
            userId = userId,
            projectId = projectId
        }

        -- get previous action from local storage
        local previousUnitinfo = EventTrackingDatabase:GetPacket(userId, action)

        if not previousUnitinfo then
            unitinfo.beginAt = self:GetServerTime()
            unitinfo.endAt = 0
            unitinfo.duration = 0
            unitinfo.traceId = System.Encoding.guid.uuid()
        else
            if started then
                unitinfo.beginAt = previousUnitinfo.beginAt
                unitinfo.endAt = 0
                unitinfo.duration = self:GetServerTime() - previousUnitinfo.beginAt
                unitinfo.traceId = previousUnitinfo.traceId
            else
                unitinfo.beginAt = previousUnitinfo.beginAt
                unitinfo.endAt = self:GetServerTime()
                unitinfo.duration = unitinfo.endAt - previousUnitinfo.beginAt
                unitinfo.traceId = previousUnitinfo.traceId
            end
        end

        return unitinfo
    end
end

function EventTrackingService:SaveToDisk()
    EventTrackingDatabase:SaveToDisk()
end

-- eventType: 1 is one click event, 2 is duration event
function EventTrackingService:Send(eventType, action, extra, offlineMode)
    if not offlineMode and not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    if not eventType or
       type(eventType) ~= 'number' or
       (eventType ~= 1 and eventType ~= 2) or
       not action or
       type(action) ~= 'string' then
        return false
    end

    local userId = Mod.WorldShare.Store:Get('user/userId') or 0
    local dataPacket = self:GenerateDataPacket(eventType, userId, action, extra and extra.started or false)

    if extra and extra.useNoId == true then
        dataPacket.projectId = 0
    end    

    if not offlineMode and (not dataPacket or not dataPacket.projectId) then
        return false
    end

    if eventType == 2 then
        if not extra then
            return false
        end

        -- prevent send and remove not started event 
        if extra.ended and (dataPacket.duration == 0 or dataPacket.endAt == 0) then
            EventTrackingDatabase:RemovePacket(userId, action, dataPacket)
            return false
        end
    end

    if extra and type(extra) == 'table' then
        extra.started = nil -- remove started key in extra table because we needn't upload that
        extra.ended = nil -- remove ended key in extra table because we needn't upload that
        extra.useNoId = nil -- remove useNoId key in extra table because we needn't upload that

        for key, value in pairs(extra) do
            dataPacket[key] = value
        end
    end

    local abPath = GameLogic.GetABPath();
    if (abPath and abPath ~= "") then
        dataPacket["abPath"] = abPath;
    end

    if EventTrackingDatabase:PutPacket(userId, action, dataPacket) then
        EventGatewayEventsApi:Send(
            "behavior",
            action,
            dataPacket,
            nil,
            function(data, err)
                if err ~= 200 then
                    return false
                end

                -- remove packet
                -- we won't remove record if endAt == 0

                if dataPacket.endAt and dataPacket.endAt == 0 then
                    return
                end

                EventTrackingDatabase:RemovePacket(userId, action, dataPacket)
            end,
            function(data, err)
                -- fail
                -- do nothing...
            end
        )
    end

    return dataPacket
end

function EventTrackingService:Loop()
    EventTrackingDatabase:ClearUselessCache()

    if not self.currentLoop then
        self.currentLoop = commonlib.Timer:new(
            {
                callbackFunc = function()
                    -- send not finish event
                    local allData = EventTrackingDatabase:GetAllData()
                    local finishedCount = 0
                    local dataTatol = 0

                    for key, item in ipairs(allData) do
                        local unitinfo = item.unitinfo
                        dataTatol = dataTatol + #unitinfo
                    end

                    local function firstTimeSave()
                        if firstSave then
                            return
                        end

                        if finishedCount == dataTatol then
                            EventTrackingDatabase:SaveToDisk()
                            firstSave = true
                        end
                    end

                    for key, item in ipairs(allData) do
                        local userId = item.userId
                        local unitinfo = item.unitinfo

                        if unitinfo and type(unitinfo) == 'table' then
                            for uKey, uItem in ipairs(unitinfo) do
                                if uItem and uItem.packet then
                                    if uItem.packet.endAt and uItem.packet.endAt == 0 then
                                        if not self:GetServerTime() or not uItem.packet.beginAt then
                                            return
                                        end

                                        uItem.packet.duration = self:GetServerTime() - uItem.packet.beginAt
                                    end

                                    -- send and remove cache
                                    EventGatewayEventsApi:Send(
                                        "behavior",
                                        uItem.action,
                                        uItem.packet,
                                        nil,
                                        function(data, err)
                                            finishedCount = finishedCount + 1

                                            if err ~= 200 then
                                                firstTimeSave()
                                                return false
                                            end

                                            -- remove packet
                                            -- we won't remove record if endAt == 0
                                            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                                            if currentEnterWorld and
                                               currentEnterWorld.kpProjectId and
                                               currentEnterWorld.kpProjectId ~= 0 and
                                               tonumber(currentEnterWorld.kpProjectId) == tonumber(uItem.packet.projectId) then
                                                if uItem.packet.endAt and uItem.packet.endAt == 0 then
                                                    firstTimeSave()
                                                    return
                                                end
                                            end

                                            EventTrackingDatabase:RemovePacket(userId, uItem.action, uItem.packet)
                                            firstTimeSave()
                                        end,
                                        function(data, err)
                                            -- fail
                                            -- do nothing...
                                            firstTimeSave()
                                        end
                                    )
                                end
                            end
                        end
                    end
                end
            }
        )
    end

	self.currentLoop:Change(0, self.timeInterval)
end

