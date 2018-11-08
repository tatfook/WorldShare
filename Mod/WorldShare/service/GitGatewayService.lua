--[[
Title: GitGatewayService
Author(s):  big
Date:  2018.11.18
Place: Foshan
use the lib:
------------------------------------------------------------
local GitGatewayService = NPL.load("(gl)Mod/WorldShare/service/GitGatewayService.lua")
------------------------------------------------------------
]]
local HttpRequest = NPL.load("./HttpRequest.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")

local GitGatewayService = NPL.export()

function GitGatewayService:GetBaseApi()
  local env = Store:Get("user/env")

  if not env then
    env = Config.env.STAGE
  end

  return Config.gitGatewayList[env] or ""
end

function GitGatewayService:GetHeaders()
  local token = Store:Get("user/token")

  local headers = {
    Authorization = format("Bearer %s", token or "")
  }

  return headers
end

function GitGatewayService:Accounts(callback)
  local url = format("%s/accounts", self:GetBaseApi())
  local headers = self:GetHeaders()

  HttpRequest:Get(
    url,
    {},
    headers,
    function(data, err)
      if (type(callback) == 'function') then
        callback(data, err)
      end
    end,
    function()
      if (type(callback) == 'function') then
        callback(false)
      end
    end
  )
end
