--[[
Title: World Lock API
Author(s):  big
Date:  2020.2.10
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkWorldLocksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/WorldLocks.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkWorldLocksApi = NPL.export()

-- url: /worldlock
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
function KeepworkWorldLocksApi:UpdateWorldLockRecord(pid, mode, revision, success, error)
  local params = {
    pid = pid,
    mode = mode,
    revision = revision,
  }

  KeepworkBaseApi:Post("/worldlocks", params, nil, success, error)
end

-- url: /worldlock
-- method: DELETE
-- params:
--[[
  pid	integer	necessary
]]
-- return: object
function KeepworkWorldLocksApi:RemoveWorldLockRecord(pid, success, error)
  KeepworkBaseApi:Delete("/worldlocks", { pid = pid }, nil, success, error)
end