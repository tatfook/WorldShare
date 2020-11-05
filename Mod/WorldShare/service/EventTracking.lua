--[[
Title: Event Tracking Service
Author(s): big
Date: 2020.11.2
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
EventTrackingService.timeInterval = 10000 -- 10 seconds
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

function EventTrackingService:GenerateDataPacket(type, userId, action)
    if not userId or not action then
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local projectId

    if currentEnterWorld and currentEnterWorld.kpProjectId then
        projectId = currentEnterWorld.kpProjectId
    end

    if type == 1 then -- one click event
        return {
            userId = userId,
            projectId = projectId,
            currentAt = os.time(),
            traceId = System.Encoding.guid.uuid()
        }
    elseif type == 2 then -- duration event
        local unitinfo =  {
            userId = userId,
            projectId = projectId
        }

        -- get previous action from local storage
        local previousUnitinfo = EventTrackingDatabase:GetPacket(userId, action)

        if not previousUnitinfo then
            unitinfo.beginAt = os.time()
            unitinfo.endAt = 0
            unitinfo.duration = 0
            unitinfo.traceId = System.Encoding.guid.uuid()
        else
            unitinfo.beginAt = previousUnitinfo.beginAt
            unitinfo.endAt = os.time()
            unitinfo.duration = unitinfo.endAt - previousUnitinfo.beginAt
            unitinfo.traceId = previousUnitinfo.traceId
        end

        return unitinfo
    end
end

-- type: 1 is one click event, 2 is duration event
function EventTrackingService:Send(type, action, ...)
    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    -- ParaWorldAnalytics:Send()

    if not type or not action then
        return false
    end

    local userId = Mod.WorldShare.Store:Get('user/userId')
    local dataPacket = self:GenerateDataPacket(type, userId, action)

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

                    for key, item in ipairs(allData) do
                        local userId = item.userId
                        local unitinfo = item.unitinfo

                        if unitinfo and type(unitinfo) == 'table' then
                            for uKey, uItem in ipairs(unitinfo) do
                                if uItem and uItem.packet then
                                    -- send and remove cache
                                    EventGatewayEventsApi:Send(
                                        "behavior",
                                        uItem.action,
                                        uItem.packet,
                                        nil,
                                        function(data, err)
                                            if err ~= 200 then
                                                return false
                                            end

                                            -- remove packet
                                            -- we won't remove record if endAt == 0

                                            if uItem.packet.endAt and uItem.packet.endAt == 0 then
                                                return
                                            end

                                            EventTrackingDatabase:RemovePacket(userId, uItem.action, uItem.packet)
                                        end,
                                        function(data, err)
                                            -- fail
                                            -- do nothing...
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

