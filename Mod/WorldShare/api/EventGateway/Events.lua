--[[
Title: Event Gateway Event API
Author(s):  big
Date:  2020.11.2
Place: Foshan
use the lib:
------------------------------------------------------------
local EventGatewayEventsApi = NPL.load("(gl)Mod/WorldShare/api/EventGateway/Event.lua")
------------------------------------------------------------
]]

local EventGatewayBaseApi = NPL.load('./BaseApi.lua')

local EventGatewayEventsApi = NPL.export()

-- url: /events/send
-- method: POST
-- params:
--[[
    category string necessary 事件类别，比如某一项服务的一些事件 | behavior
    action string necessary 事件动作描述，比如createUser，能够简单描述事件意图 stayWorld | editWorld
    data object	necessary 事件数据，需要符合对应的格式 备注: 事件数据，需要符合对应的格式
    extra object not necessary 一些附加信息，可能有些服务有需要 备注: 一些附加信息，可能有些服务有需要
]]
-- return: object
function EventGatewayEventsApi:Send(category, action, data, extra, success, error)
    local params = {
        category = category,
        action = action,
        data = data
    }

    EventGatewayBaseApi:Post('/events/send', params, nil, success, error)
end

-- url: /events/bulk
-- method: POST
-- params:
--[[
    events object [] not necessary item type: object
        category string	not necessary 事件类别，比如某一项服务的一些事件	
        action string not necessary 事件动作描述，比如createUser，能够简单描述事件意图	
    data object not necessary 事件数据，需要符合对应的格式 备注: 事件数据，需要符合对应的格式
    extra object not necessary 一些附加信息，可能有些服务有需要 备注: 一些附加信息，可能有些服务有需要
]]
-- return: object
function EventGatewayEventsApi:Bulk(events, data, extra, success, error)

    EventGatewayBaseApi:Post('/events/bulk', params, nil, success, error)
end
