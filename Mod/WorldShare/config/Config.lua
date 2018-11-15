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

Config.keepworkList = {
  ONLINE = "https://keepwork.com",
  STAGE = "https://stage.keepwork.com",
  RELEASE = "https://release.keepwork.com",
  LOCAL = "https://stage.keepwork.com"
}

Config.keepworkServerList = {
  ONLINE = "https://api.keepwork.com/core/v0",
  STAGE = "https://api-stage.keepwork.com/core/v0",
  RELEASE = "https://api-release.keepwork.com/core/v0",
  LOCAL = "https://api-stage.keepwork.com/core/v0",
}

Config.gitGatewayList = {
  ONLINE = "https://api.keepwork.com/git/v0",
  STAGE = "https://api-stage.keepwork.com/git/v0",
  RELEASE = "https://api-release.keepwork.com/git/v0",
  LOCAL = "https://api-stage.keepwork.com/git/v0"
}

Config.lessonList = {
  ONLINE = "https://api.keepwork.com/lesson/v0",
  STAGE = "https://api-stage.keepwork.com/lesson/v0",
  RELEASE = "https://api-release.keepwork.com/lesson/v0",
  LOCAL = "https://api-stage.keepwork.com/lesson/v0"
}

Config.dataSourceApiList = {
  gitlab = {
    ONLINE = "https://git.keepwork.com/api/v4",
    STAGE = "https://git-stage.keepwork.com/api/v4",
    RELEASE = "https://git-release.keepwork.com/api/v4",
    LOCAL = "https://git-stage.keepwork.com/api/v4"
  }
}

Config.dataSourceRawList = {
  gitlab = {
    ONLINE = "https://git.keepwork.com",
    STAGE = "https://git-stage.keepwork.com",
    RELEASE = "https://git-release.keepwork.com",
    LOCAL = "https://git-stage.keepwork.com"
  }
}

Config.RecommendedWorldList = 'https://git.keepwork.com/gitlab_rls_official/keepworkdatasource/raw/master/official/paracraft/RecommendedWorldList.md'