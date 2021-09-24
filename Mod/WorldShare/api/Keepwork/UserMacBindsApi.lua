--[[
Title: User Mac Binds Api
Author(s): big
CreateDate: 2021.09.18
ModifyDate: 2021.09.18
Desc: 
use the lib:
------------------------------------------------------------
local UserMacBindsApi = NPL.load('(gl)Mod/Offline/api/UserMacBindsApi.lua')
------------------------------------------------------------
]]

-- api
local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

local UserMacBindsApi = NPL.export()

-- url: /userMacBinds
-- method: POST
-- params:
--[[
    macAddr string necessary
    uuid string necessary
]]
-- return: object
function UserMacBindsApi:BindMacAddress(macAddress, uuid, success, error)
    if not macAddress or
       type(macAddress) ~= 'string' or
       not uuid or
       type(uuid) ~= 'string' then
        return
    end

    local params = {
        macAddr = macAddress,
        uuid = uuid
    }

    KeepworkBaseApi:Post('/userMacBinds', params, nil, success, error)
end

-- url: /userMacBinds
-- method: GET
-- params:
--[[
]]
-- return: object
function UserMacBindsApi:GetBindList(success, error)
    KeepworkBaseApi:Get('/userMacBinds', nil, nil, success, error)
end

-- url: /userMacBinds/:id
-- method: DELETE
-- params:
--[[
]]
-- return: object
function UserMacBindsApi:RemoveMacAddress(id, success, error)
    if not id or type(id) ~= 'number' then
        return
    end

    KeepworkBaseApi:Delete('/userMacBinds/' .. id, nil, nil, success, error)
end
