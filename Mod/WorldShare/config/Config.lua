--[[
Title: Config
Author(s):  big
Date: 2018.10.18
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")
------------------------------------------------------------
]]

local Config = NPL.export()

Config.env = {
  ONLINE = "ONLINE",
  STAGE = "STAGE",
  RELEASE = "RELEASE",
  LOCAL = "LOCAL"
}

Config.defaultEnv = Config.env.ONLINE

Config.keepworkList = {
  ONLINE = "https://keepwork.com",
  STAGE = "http://dev.kp",
  RELEASE = "http://rls.kp",
  LOCAL = "http://dev.kp"
}

Config.keepworkServerList = {
  ONLINE = "https://api.keepwork.com/core/v0",
  STAGE = "https://api.dev.kp/core/v0",
  RELEASE = "http://api.rls.kp/core/v0",
  LOCAL = "http://api.dev.kp/core/v0",
}

Config.gitGatewayList = {
  ONLINE = "https://api.keepwork.com/git/v0",
  STAGE = "http://api.dev.kp/git/v0",
  RELEASE = "http://api.rls.kp/git/v0",
  LOCAL = "http://api.dev.kp/git/v0"
}

Config.esGatewayList = {
  ONLINE = "https://api.keepwork.com/es/v0",
  STAGE = "https://api.dev.kp/es/v0",
  RELEASE = "https://api.rls.kp/es/v0",
  LOCAL = "https://api.dev.kp/es/v0"
}

Config.lessonList = {
  ONLINE = "https://api.keepwork.com/lesson/v0",
  STAGE = "https://api.dev.kp/lesson/v0",
  RELEASE = "https://api.rls.kp/lesson/v0",
  LOCAL = "https://api.dev.kp/lesson/v0"
}

Config.dataSourceApiList = {
  gitlab = {
    ONLINE = "https://git.keepwork.com/api/v4",
    STAGE = "https://git.dev.kp/api/v4",
    RELEASE = "https://git.rls.kp/api/v4",
    LOCAL = "https://git.dev.kp/api/v4"
  }
}

Config.dataSourceRawList = {
  gitlab = {
    ONLINE = "https://git.keepwork.com",
    STAGE = "https://git.dev.kp",
    RELEASE = "https://git.rls.kp",
    LOCAL = "https://git.dev.kp"
  }
}

Config.RecommendedWorldList = 'https://git.keepwork.com/gitlab_rls_official/keepworkdatasource/raw/master/official/paracraft/RecommendedWorldList.md'