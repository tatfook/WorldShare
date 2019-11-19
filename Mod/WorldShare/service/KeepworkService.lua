--[[
Title: KeepworkService
Author(s):  big
Date:  2018.06.21
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
------------------------------------------------------------
]]
local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")

local HttpRequest = NPL.load("./HttpRequest.lua")
local GitService = NPL.load("./GitService.lua")
local GitGatewayService = NPL.load("./GitGatewayService.lua")
local LocalService = NPL.load("./LocalService.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")

local KeepworkService = NPL.export()

function KeepworkService:GetEnv()
    for key, item in pairs(Config.env) do
        if key == Config.defaultEnv then
            return Config.defaultEnv
        end
    end

	return Config.env.ONLINE
end

function KeepworkService:GetKeepworkUrl()
	local env = self:GetEnv()

	return Config.keepworkList[env]
end

function KeepworkService:GetCoreApi()
    local env = self:GetEnv()

    return Config.keepworkServerList[env]
end

function KeepworkService:GetLessonApi()
    local env = self:GetEnv()

    return Config.lessonList[env]
end

function KeepworkService:GetServerList()
    if (LOG.level == "debug") then
        return {
            {value = Config.env.ONLINE, name = Config.env.ONLINE, text = L"使用KEEPWORK登录", selected = true},
            {value = Config.env.STAGE, name = Config.env.STAGE, text = L"使用STAGE登录"},
            {value = Config.env.RELEASE, name = Config.env.RELEASE, text = L"使用RELEASE登录"},
            {value = Config.env.LOCAL, name = Config.env.LOCAL, text = L"使用本地服务登录"}
        }
    else
        return {
            {value = Config.env.ONLINE, name = Config.env.ONLINE, text = L"使用KEEPWORK登录", selected = true}
        }
    end
end

function KeepworkService:GetApi(url)
    if type(url) ~= "string" then
        return ""
    end

    return format("%s%s", self:GetCoreApi(), url)
end

function KeepworkService:GetHeaders(selfDefined, notTokenRequest)
    local headers = {}

    if type(selfDefined) == "table" then
        headers = selfDefined
    end

    local token = Store:Get("user/token")

    if (token and not notTokenRequest and not headers["Authorization"]) then
        headers["Authorization"] = format("Bearer %s", token)
    end

    return headers
end

function KeepworkService:Request(url, method, params, headers, callback, noTryStatus)
    local params = {
        method = method or "GET",
        url = self:GetApi(url),
        json = true,
        headers = headers or {},
        form = params or {}
    }

    HttpRequest:GetUrl(params, callback, noTryStatus)
end

function KeepworkService:LoginResponse(response, err, callback)
    if err == 400 then
        Mod.WorldShare.MsgBox:Close()
        GameLogic.AddBBS(nil, L"用户名或者密码错误", 3000, "255 0 0")
        return false
    end

    if (type(response) ~= "table") then
        Mod.WorldShare.MsgBox:Close()
        GameLogic.AddBBS(nil, L"服务器连接失败", 3000, "255 0 0")
        return false
    end

    local token = response["token"] or ""
    local userId = response["id"] or 0
    local username = response["username"] or ""
    local nickname = response["nickname"] or ""

    local SetUserinfo = Store:Action("user/SetUserinfo")
    SetUserinfo(token, username, nickname)

    Store:Set("user/userId", userId)
    Store:Set("user/username", username)

    -- new api remove verified field, set all users are verified
    Store:Set("user/isVerified", true)
    -- new api remove vip field, set all users are vip
    Store:Set("user/userType", 'vip')

    local function HandleGetDataSource(data, err)
        if (not data or not data.token) then
            GameLogic.AddBBS(nil, L"Token已过期，请重新登录", 3000, "255 0 0")
            self:Logout()
            Mod.WorldShare.MsgBox:Close()
            return false
        end

        local dataSourceType = 'gitlab'
        local env = self:GetEnv()

        local dataSourceInfo = {
            dataSourceToken = data.token, -- 数据源Token
            dataSourceUsername = data.git_username, -- 数据源用户名
            dataSourceType = dataSourceType, -- 数据源类型
            apiBaseUrl = Config.dataSourceApiList[dataSourceType][env], -- 数据源api
            rawBaseUrl = Config.dataSourceRawList[dataSourceType][env] -- 数据源raw
        }

        Store:Set("user/dataSourceInfo", dataSourceInfo)

        if (type(callback) == "function") then
            callback()
        end

        Mod.WorldShare.MsgBox:Close()
    end

    GitGatewayService:Accounts(HandleGetDataSource)
end

function KeepworkService:IsSignedIn()
    local token = Store:Get("user/token")

    return token ~= nil
end

function KeepworkService:GetToken()
    local token = Store:Get('user/token')

    return token or ''
end

function KeepworkService:Logout()
    if (self:IsSignedIn()) then
        local SetToken = Store:Action("user/SetToken")
        SetToken(nil)
        Store:Remove('user/username')
        WorldList:RefreshCurrentServerList()
    end
end

function KeepworkService:Login(account, password, callback)
    if type(account) ~= "string" or type(password) ~= "string" then
        return false
    end

    local params = {
        username = account,
        password = password
    }

    self:Request(
        "/users/login",
        "POST",
        params,
        {},
        function(data, err)
            if (err == 503) then
                Mod.WorldShare.MsgBox:Close()
                -- _guihelper.MessageBox(L"keepwork正在维护中，我们马上回来")

                return false
            end

            if (type(callback) == "function") then
                callback(data, err)
            end
        end,
        {503, 400}
    )
end

-- This api will create a keepwork paracraft project and associated with paracraft world.
function KeepworkService:CreateProject(worldName, callback)
    if not self:IsSignedIn() or not worldName then
        return false
    end

    local headers = self:GetHeaders()

    local params = {
        name = worldName,
        siteId = 1,
        visibility = 0,
        privilege = 165,
        type = 1,
        description = "no desc",
        tags = "paracraft",
        extra = {}
    }

    self:Request("/projects", "POST", params, headers, callback)
end

function KeepworkService:UpdateProject(pid, params, callback)
    if not self:IsSignedIn() or
       not pid or
       type(pid) ~= 'number' or
       type(params) ~= 'table' then
        return false
    end

    local headers = self:GetHeaders()

    self:Request(format("/projects/%d", pid), "PUT", params, headers, callback)
end

function KeepworkService:GetProject(pid, callback, noTryStatus)
    if type(pid) ~= 'number' or pid == 0 then
        return false
    end

    local headers = self:GetHeaders()

    self:Request(
        format("/projects/%d/detail", pid),
        "GET",
        nil,
        headers,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 or not data or not data.world then
                callback()
                return false
            end

            callback(data, err)
        end,
        noTryStatus
    )
end

-- @param usertoken: keepwork user token
function KeepworkService:Profile(callback, token)
    local headers = self:GetHeaders()

    if (type(token) == "string" and #token > 0) then
        headers =
            self:GetHeaders(
            {
                Authorization = format("Bearer %s", token)
            }
        )
    end

    self:Request("/users/profile", "GET", nil, headers, callback)
end

function KeepworkService:GetWorldsList(callback)
    if (not self:IsSignedIn()) then
        return false
    end

    local headers = self:GetHeaders()

    self:Request("/worlds", 'GET', {}, headers, callback)
end

function KeepworkService:GetProjectIdByWorldName(worldName, callback)
    if not self:IsSignedIn() then
        return false
    end

    local headers = self:GetHeaders()

    self:Request(
        format("/worlds?worldName=%s", Encoding.url_encode(worldName or '')),
        'GET',
        nil,
        headers,
        function(data)
            if not data or #data ~= 1 or type(data[1]) ~= 'table' or not data[1].projectId then
                if type(callback) == 'function' then
                    callback()
                end

                return false
            end

            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
            currentWorld.kpProjectId = data[1].projectId
            Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

            if type(callback) == 'function' then
                callback(data[1].projectId)
            end
        end
    )
end

function KeepworkService:GetWorldByProjectId(pid, callback)
    if type(pid) ~= 'number' or pid == 0 then
        return false
    end

    local headers = self:GetHeaders()

    self:Request(
        format("/projects/%d/detail", pid),
        "GET",
        nil,
        headers,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 or not data or not data.world then
                callback(nil, err)
                return false
            end

            callback(data.world, err)
        end
    )
end

function KeepworkService:GetWorld(worldName, callback)
    if (type(worldName) ~= 'string' or not self:IsSignedIn()) then
        return false
    end

    local headers = self:GetHeaders()

    self:Request(
        format("/worlds?worldName=%s", worldName or ''),
        "GET",
        nil,
        headers,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 or #data == 0 then
                return false
            end

            callback(data[1])
        end
    )
end

function KeepworkService:PushWorld(params, callback)
    if type(params) ~= 'table' or not self:IsSignedIn() then
        return false
    end

    local headers = self:GetHeaders()

    self:GetWorld(
        Encoding.url_encode(params.worldName or ''),
        function(world)
            local worldId = world and world.id or false

            if not worldId then
                return false
            end

            self:Request(
                format("/worlds/%s", worldId),
                "PUT",
                params,
                headers,
                callback
            )
        end
    )
end

function KeepworkService:DeleteWorld(kpProjectId, callback)
    if not kpProjectId then
        return false
    end

    if not self:IsSignedIn() then
        return false
    end

    local url = format("/projects/%d", kpProjectId)
    local headers = self:GetHeaders()

    self:Request(url, "DELETE", {}, headers, callback)
end

-- get keepwork project url
function KeepworkService:GetShareUrl()
    local env = self:GetEnv()
    local currentWorld = Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId then
        return ''
    end

    local baseUrl = Config.keepworkList[env]
    local foldername = Store:Get("world/foldername")
    local username = Store:Get("user/username")

    return format("%s/pbl/project/%d/", baseUrl, currentWorld.kpProjectId)
end

-- @return nil if not found or {account, password, loginServer, autoLogin}
function KeepworkService:LoadSigninInfo()
    local sessionsData = SessionsData:GetSessions()

    if sessionsData and sessionsData.selectedUser then
        for key, item in ipairs(sessionsData.allUsers) do
            if item.value == sessionsData.selectedUser then
                return item.session
            end
        end
    else
        return nil
    end
end

-- @param info: if nil, we will delete the login info.
function KeepworkService:SaveSigninInfo(info)
    if not info then
        return false
    end

    if not info.rememberMe then
        info.password = nil
    end

    SessionsData:SaveSession(info)
end

-- return nil or user token in url protocol
function KeepworkService:GetUserTokenFromUrlProtocol()
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$")
    urlProtocol = Encoding.url_decode(urlProtocol or "")

    -- local env = urlProtocol:match('env="([%S]+)"')
    local usertoken = urlProtocol:match('usertoken="([%S]+)"')

    -- if env then
    --     Store:Set("user/env", env)
    -- end
    
    if usertoken then
        local SetToken = Store:Action("user/SetToken")
        SetToken(usertoken)
    end
end

function KeepworkService:GetCurrentUserToken()
    return System.User and System.User.keepworktoken
end

local tryTimes = 0
function KeepworkService:LoginWithTokenApi(callback)
    local usertoken = Store:Get("user/token") or self:GetCurrentUserToken()

    if type(usertoken) == "string" and #usertoken > 0 and tryTimes <= 3 then
        Mod.WorldShare.MsgBox:Show(L"正在登陆，请稍后...")

        self:Profile(
            function(data)
                if type(data) == 'table' then
                    data.token = usertoken

                    self:LoginResponse(data, err, callback)
                else
                    System.User.keepworktoken = nil
                    Mod.WorldShare.MsgBox:Close()

                    UserConsole:ClosePage()
                    UserConsole:ShowPage()

                    tryTimes = tryTimes + 1
                end
            end,
            usertoken
        )

        return true
    else
        return false
    end
end

-- update world info
function KeepworkService:UpdateRecord(callback)
    local username = Store:Get("user/username")
    local foldername = Store:Get("world/foldername")
    local currentWorld = Store:Get('world/currentWorld')

    if not currentWorld then
        return false
    end

    local function Handle(data, err)
        if type(data) ~= "table" or #data == 0 then
            _guihelper.MessageBox(L"获取Commit列表失败")
            return false
        end

        local lastCommits = data[1]
        local lastCommitFile = lastCommits.title:gsub("paracraft commit: ", "")
        local lastCommitSha = lastCommits.id

        if (string.lower(lastCommitFile) ~= "revision.xml") then
            _guihelper.MessageBox(L"上一次同步到数据源同步失败，请重新同步世界到数据源")
            return false
        end

        local dataSourceInfo = Store:Get("user/dataSourceInfo")
        local localFiles = LocalService:LoadFiles(currentWorld.worldpath)

        self:SetCurrentCommidId(lastCommitSha)

        Store:Set("world/localFiles", localFiles)

        local filesTotals = currentWorld.size or 0

        local function HandleGetWorld(data)
            local oldWorldInfo = data or false

            if not oldWorldInfo then
                return false
            end

            local commitIds = {}

            if oldWorldInfo.extra and oldWorldInfo.extra.commitIds then
                commitIds = oldWorldInfo.extra.commitIds
            end

            commitIds[#commitIds + 1] = {
                commitId = lastCommitSha,
                revision = Store:Get("world/currentRevision"),
                date = os.date("%Y%m%d", os.time())
            }

            local worldInfo = {}
    
            worldInfo.worldName = foldername.utf8
            worldInfo.revision = Store:Get("world/currentRevision")
            worldInfo.fileSize = filesTotals
            worldInfo.commitId = lastCommitSha
            worldInfo.username = username
            worldInfo.archiveUrl =
                format(
                "%s/%s/%s/repository/archive.zip?ref=%s",
                dataSourceInfo.rawBaseUrl,
                dataSourceInfo.dataSourceUsername,
                foldername.base32,
                worldInfo.commitId
            )

            local preview = format(
                "%s/%s/%s/raw/master/preview.jpg?ref=%s",
                dataSourceInfo.rawBaseUrl,
                dataSourceInfo.dataSourceUsername,
                foldername.base32,
                worldInfo.commitId
            )

            worldInfo.extra = {
                coverUrl = preview,
                commitIds = commitIds
            }

            if currentWorld.local_tagname and currentWorld.local_tagname ~= foldername.utf8 then
                worldInfo.extra.worldTagName = currentWorld.local_tagname
            end

            WorldList.SetRefreshing(true)

            self:PushWorld(
                worldInfo,
                function(data, err)
                    if (err ~= 200) then
                        _guihelper.MessageBox(L"更新服务器列表失败")
                        return false
                    end
    
                    if type(callback) == 'function' then
                        callback()
                    end
                end
            )

            self:GetProject(
                currentWorld.kpProjectId,
                function(data)
                    local extra = data and data.extra or {}

                    if Mod.WorldShare.Store:Get('world/isPreviewUpdated') and
                        currentWorld.local_tagname and
                        currentWorld.local_tagname ~= foldername.utf8 then

                        extra.imageUrl = preview
                        extra.worldTagName = currentWorld.local_tagname

                        self:UpdateProject(
                            currentWorld.kpProjectId,
                            {
                                extra = extra
                            }
                        )
                    elseif Mod.WorldShare.Store:Get('world/isPreviewUpdated') then
                        extra.imageUrl = preview

                        self:UpdateProject(
                            currentWorld.kpProjectId,
                            {
                                extra = extra
                            }
                        )
                    elseif currentWorld.local_tagname and
                           currentWorld.local_tagname ~= foldername.utf8 then
                        extra.worldTagName = currentWorld.local_tagname

                        self:UpdateProject(
                            currentWorld.kpProjectId,
                            {
                                extra = extra
                            }
                        )
                    end

                    Mod.WorldShare.Store:Remove('world/isPreviewUpdated')
                end
            )
        end

        self:GetWorld(Encoding.url_encode(foldername.utf8 or ''), HandleGetWorld)
    end

    GitService:GetCommits(foldername.base32, false, Handle)
end

function KeepworkService:SetCurrentCommidId(commitId)
    local currentWorld = Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.worldpath then
        return false
    end

    local saveUrl = currentWorld.worldpath

    WorldShare:SetWorldData("revision", {id = commitId}, saveUrl)
    ParaIO.CreateDirectory(saveUrl)
    WorldShare:SaveWorldData(saveUrl)
end