--[[
Title: World Lock API
Author(s): big
CreateDate: 2020.2.10
ModifyDate: 2022.8.4
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkWorldLocksApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkWorldLocksApi.lua')
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkWorldLocksApi = NPL.export()

-- url: /worldlocks
-- method: GET
--[[
  pid inter necessary project id
]]
-- return: object
function KeepworkWorldLocksApi:GetWorldLockInfo(pid, success, error)
    if not pid or type(pid) ~= 'number' then
        return
    end

    KeepworkBaseApi:Get('/worldlocks?pid=' .. tostring(pid), nil, nil, success, error)
end

-- url: /worldlocks
-- method: POST
-- params:
--[[
  pid	integer	necessary project id	
  mode string necessary edit mode(share,exclusive)
  revision integer necessary revision number when server opened
  server string not necessary server address
  password string not necessary server password
]]
-- return: object
function KeepworkWorldLocksApi:UpdateWorldLockRecord(pid, mode, revision, server, password, success, error)
    local params = {
        pid = pid,
        mode = mode,
        revision = revision,
        server = server,
        password = password,
    }

    KeepworkBaseApi:Post('/worldlocks', params, nil, success, error)
end

-- url: /worldlocks
-- method: DELETE
-- params:
--[[
  pid	integer	necessary
]]
-- return: object
function KeepworkWorldLocksApi:RemoveWorldLockRecord(pid, success, error)
    KeepworkBaseApi:Delete('/worldlocks', { pid = pid }, nil, success, error)
end