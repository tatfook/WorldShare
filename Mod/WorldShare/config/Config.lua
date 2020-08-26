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

Config.defaultEnv = (ParaEngine.GetAppCommandLineByParam("worldshareenv", nil) or Config.env.ONLINE)
Config.defaultGit = "KEEPWORK"

Config.keepworkList = {
  ONLINE = "https://keepwork.com",
  STAGE = "http://dev.kp-para.cn",
  RELEASE = "http://rls.kp-para.cn",
  LOCAL = "http://dev.kp-para.cn"
}

Config.storageList = {
  ONLINE = "https://api.keepwork.com/ts-storage",
  STAGE = "http://api-dev.kp-para.cn/ts-storage",
  RELEASE = "http://api-rls.kp-para.cn/ts-storage",
  LOCAL = "http://api-dev.kp-para.cn/ts-storage",
}

Config.qiniuList = {
  ONLINE = "https://upload-z2.qiniup.com",
  STAGE = "https://upload-z2.qiniup.com",
  RELEASE = "https://upload-z2.qiniup.com",
  LOCAL = "https://upload-z2.qiniup.com"
}

Config.keepworkServerList = {
  ONLINE = "https://api.keepwork.com/core/v0",
  STAGE = "http://api-dev.kp-para.cn/core/v0",
  RELEASE = "http://api-rls.kp-para.cn/core/v0",
  LOCAL = "http://api-dev.kp-para.cn/core/v0",
}

Config.gitGatewayList = {
  ONLINE = "https://api.keepwork.com/git/v0",
  STAGE = "http://api-dev.kp-para.cn/git/v0",
  RELEASE = "http://api-rls.kp-para.cn/git/v0",
  LOCAL = "http://api-dev.kp-para.cn/git/v0"
}

Config.esGatewayList = {
  ONLINE = "https://api.keepwork.com/es/v0",
  STAGE = "http://api-dev.kp-para.cn/es/v0",
  RELEASE = "http://api-rls.kp-para.cn/es/v0",
  LOCAL = "http://api-dev.kp-para.cn/es/v0"
}

Config.lessonList = {
  ONLINE = "https://api.keepwork.com/lessonapi/v0",
  STAGE = "http://api-dev.kp-para.cn/lessonapi/v0",
  RELEASE = "http://api-rls.kp-para.cn/lessonapi/v0",
  LOCAL = "http://api-dev.kp-para.cn/lessonapi/v0"
}

Config.dataSourceApiList = {
  gitlab = {
    ONLINE = "https://git.keepwork.com/api/v4",
    STAGE = "http://git-dev.kp-para.cn/api/v4",
    RELEASE = "http://git-rls.kp-para.cn/api/v4",
    LOCAL = "http://git-dev.kp-para.cn/api/v4"
  }
}

Config.dataSourceRawList = {
  gitlab = {
    ONLINE = "https://git.keepwork.com",
    STAGE = "http://git-dev.kp-para.cn",
    RELEASE = "http://git-rls.kp-para.cn",
    LOCAL = "http://git-dev.kp-para.cn"
  }
}

Config.socket = {
  ONLINE = "https://socket.keepwork.com",
  STAGE = "http://socket-dev.kp-para.cn",
  RELEASE = "http://socket-rls.kp-para.cn",
  LOCAL = "http://socket-dev.kp-para.cn"
}

Config.keepworkVipList= {
  ONLINE = "https://keepwork.com/vip",
  STAGE = "http://rls.kp-para.cn/vip",
  RELEASE = "http://rls.kp-para.cn/vip",
  LOCAL = "http://dev.kp-para.cn/vip"
}

Config.RecommendedWorldList = 'https://git.keepwork.com/gitlab_rls_official/keepworkdatasource/raw/master/official/paracraft/RecommendedWorldList.md'

Config.QQ = {
  ONLINE = {
    clientId = "101403344"
  },
  STAGE = {
    clientId = "101403344"
  },
  RELEASE = {
    clientId = "101403344"
  },
  LOCAL = {
    clientId = "101403344"
  },
}

Config.WECHAT = {
  ONLINE = {
    clientId = "wxc97e44ce7c18725e"
  },
  STAGE = {
    clientId = "wxc97e44ce7c18725e"
  },
  RELEASE = {
    clientId = "wxc97e44ce7c18725e"
  },
  LOCAL = {
    clientId = "wxc97e44ce7c18725e"
  }
}
