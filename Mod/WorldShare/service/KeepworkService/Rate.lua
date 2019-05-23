--[[
Title: KeepworkService Rate
Author(s):  big
Date:  2019.05.22
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceRate = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Rate.lua")
------------------------------------------------------------
]]
local KeepworkService = NPL.load("../KeepworkService.lua")

local KeepworkServiceRate = NPL.export()

-- get project rate
function KeepworkServiceRate:GetRatedProject(kpProjectId, callback)
  if not kpProjectId then
      return false
  end

  if not KeepworkService:IsSignedIn() then
      return false
  end

  local url = format("/projectRates?projectId=%d", kpProjectId)
  local headers = KeepworkService:GetHeaders()

  KeepworkService:Request(url, "GET", {}, headers, callback)
end

-- set project rate
function KeepworkServiceRate:SetRatedProject(kpProjectId, rate, callback)
  if not kpProjectId then
      return false
  end

  if not KeepworkService:IsSignedIn() then
      return false
  end

  local headers = KeepworkService:GetHeaders()

  local params = {
      projectId = kpProjectId,
      rate = rate
  }

  self:GetRatedProject(
      kpProjectId,
      function(data, err)
          if err ~= 200 or #data == 0 then
            KeepworkService:Request("/projectRates", "POST", params, headers, callback)
          end

          if err == 200 and type(data) == 'table' and #data == 1 and type(data[1].projectId) == 'number' then
            KeepworkService:Request(format("/projectRates/%d", data[1].projectId), "PUT", params, headers, callback)
          end
      end
  )
end