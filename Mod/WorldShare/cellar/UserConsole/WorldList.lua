--[[
Title: WorldList
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
------------------------------------------------------------
]]
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local Encoding = commonlib.gettable("commonlib.Encoding")

local UserConsole = NPL.load("./Main.lua")
local UserInfo = NPL.load("./UserInfo.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
local VersionChange = NPL.load("(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local SyncCompare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")

local WorldList = NPL.export()

function WorldList.GetCurWorldInfo(info_type, world_index)
    local index = tonumber(world_index)
    local compareWorldList = Store:Get("world/compareWorldList")
    local selected_world = compareWorldList[world_index]

    if (selected_world) then
        if (info_type == "mode") then
            local mode = selected_world["world_mode"]

            if (mode == "edit") then
                return L"创作"
            else
                return L"参观"
            end
        else
            return selected_world[info_type]
        end
    end
end

function WorldList:UpdateWorldList()
    local compareWorldList = Store:Get("world/compareWorldList") or {}

    self:GetInternetWorldList(
        function(InternetWorldList)
            for CKey, CItem in ipairs(compareWorldList) do
                for IKey, IItem in ipairs(InternetWorldList) do
                    if (IItem.foldername == CItem.foldername) then
                        for key, value in pairs(IItem) do
                            if(key ~= "revision") then
                                CItem[key] = value
                            end
                        end
                    end
                end
            end

            InternetLoadWorld.cur_ds = compareWorldList
        end
    )

    local UserConsolePage = Store:Get('page/UserConsole')

    if (UserConsolePage) then
        UserConsolePage:GetNode("gw_world_ds"):SetAttribute("DataSource", compareWorldList)
        WorldList:OnSwitchWorld(1)
    end
end

function WorldList:GetInternetWorldList(callback)
    local ServerPage = InternetLoadWorld.GetCurrentServerPage()

    RemoteServerList:new():Init(
        "local",
        "localworld",
        function(bSucceed, serverlist)
            if (not serverlist:IsValid()) then
                BroadcastHelper.PushLabel(
                    {
                        id = "userworlddownload",
                        label = L"无法下载服务器列表, 请检查网络连接",
                        max_duration = 10000,
                        color = "255 0 0",
                        scaling = 1.1,
                        bold = true,
                        shadow = true
                    }
                )
            end

            ServerPage.ds = serverlist.worlds or {}
            InternetLoadWorld.OnChangeServerPage()

            if type(callback) == 'function' then
                callback(ServerPage.ds)
            end
        end
    )
end

function WorldList:RefreshCurrentServerList(callback, isForce)
    local UserConsolePage = Store:Get('page/UserConsole')

    if not UserConsolePage and not isForce then
        if type(callback) == 'function' then
            callback()
        end

        return false
    end

    self:SetRefreshing(true)

    if (not KeepworkService:IsSignedIn()) then
        self:GetLocalWorldList(
            function()
                self:ChangeRevision(
                    function()
                        self:SetRefreshing(false)
                        self:UpdateWorldList()

                        if (type(callback) == "function") then
                            callback()
                        end
                    end
                )
            end
        )
    end

    if (KeepworkService:IsSignedIn()) then
        self:GetLocalWorldList(
            function()
                self:ChangeRevision(
                    function()
                        self:SyncWorldsList(
                            function()
                                self:SetRefreshing(false)
                                self:UpdateWorldList()

                                if type(callback) == "function" then
                                    callback()
                                end
                            end
                        )
                    end
                )
            end
        )
    end
end

function WorldList:GetLocalWorldList(callback)
    local localWorldList = LocalLoadWorld.BuildLocalWorldList(true)
    Store:Set("user/localWorlds", localWorldList)

    if type(callback) == 'function' then
        callback()
    end
end

function WorldList:ChangeRevision(callback)
    local localWorlds = Store:Get("user/localWorlds")

    if (not localWorlds) then
        return false
    end

    for key, value in ipairs(localWorlds) do
        if (value.IsFolder) then
            local foldername = {}
            foldername.utf8 = value.foldername
            foldername.default = Encoding.Utf8ToDefault(value.foldername)

            local WorldRevisionCheckOut = WorldRevision:new():init(SyncMain.GetWorldFolderFullPath() .. "/" .. foldername.default .. "/")
            value.revision = WorldRevisionCheckOut:GetDiskRevision()

            local tag = LocalService:GetTag(foldername.default)

            if (tag.size) then
                value.size = tag.size
            else
                value.size = 0
            end
        else
            value.revision = LocalService:GetZipRevision(value.worldpath)
            value.size = LocalService:GetZipWorldSize(value.worldpath)
            value.foldername = value.Title
            value.text = value.Title
            value.is_zip = true
            value.remotefile = format("local://%s", value.worldpath)
        end

        value.modifyTime = self:UnifiedTimestampFormat(value.writedate)
    end

    Store:Set("world/localWorlds", localWorlds)
    Store:Set("world/compareWorldList", localWorlds)
    
    UserConsole:Refresh()

    if (callback) then
        callback()
    end
end

function WorldList:SelectVersion()
    local selectWorld = Store:Get('world/selectWorld')

    if(selectWorld.status == 1) then
        _guihelper.MessageBox(L"此世界仅在本地，无法切换版本")
        return false
    end

    VersionChange:Init()
end

--[[
status代码含义:
1:仅本地
2:仅网络
3:本地网络一致
4:网络更新
5:本地更新
]]
function WorldList:SyncWorldsList(callback)
    local function HandleWorldList(data, err)
        if (type(data) ~= "table") then
            _guihelper.MessageBox(L"获取服务器世界列表错误")
            self:SetRefreshing(false)
            UserConsole:Refresh()
            return false
        end

        local localWorlds = Store:Get("world/localWorlds") or {}
        local remoteWorldsList = data
        local compareWorldList = commonlib.vector:new()

        -- 处理 本地网络同时存在/本地不存在/网络存在 的世界
        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local worldpath = ""
            local status
            local revision

            for LKey, LItem in ipairs(localWorlds) do
                if (DItem["worldName"] == LItem["foldername"]) then
                    if (tonumber(LItem["revision"]) == tonumber(DItem["revision"])) then
                        status = 3 --本地网络一致
                        revision = LItem['revision']
                    elseif (tonumber(LItem["revision"]) > tonumber(DItem["revision"])) then
                        status = 4 --网络更新
                        revision = LItem['revision']
                    elseif (tonumber(LItem["revision"]) < tonumber(DItem["revision"])) then
                        status = 5 --本地更新
                        revision = LItem['revision']
                    end

                    isExist = true
                    worldpath = LItem["worldpath"]
                    break
                end
            end

            if (not isExist) then
                --仅网络
                status = 2
                revision = DItem['revision']
            end

            local currentWorld = {
                text = DItem["worldName"],
                foldername = DItem["worldName"],
                revision = revision,
                size = DItem["fileSize"],
                modifyTime = self:UnifiedTimestampFormat(DItem["updatedAt"]),
                lastCommitId = DItem["commitId"], 
                worldpath = worldpath,
                status = status,
                kpProjectId = DItem["projectId"]
            }

            compareWorldList:push_back(currentWorld)
        end

        -- 处理 本地存在/网络不存在 的世界
        for LKey, LItem in ipairs(localWorlds) do
            local isExist = false

            for DKey, DItem in ipairs(remoteWorldsList) do
                if (LItem["foldername"] == DItem["worldName"]) then
                    isExist = true
                    break
                end
            end

            if (not isExist) then
                currentWorld = LItem
                currentWorld.modifyTime = self:UnifiedTimestampFormat(currentWorld.writedate)
                currentWorld.text = currentWorld.foldername
                currentWorld.status = 1 --仅本地
                compareWorldList:push_back(currentWorld)
            end
        end

        -- 排序
        if (#compareWorldList > 0) then
            local tmp = 0

            for i = 1, #compareWorldList - 1 do
                for j = 1, #compareWorldList - i do
                    local curItemModifyTime = 0
                    local nextItemModifyTime = 0

                    if (compareWorldList[j] and compareWorldList[j].modifyTime) then
                        curItemModifyTime = compareWorldList[j].modifyTime
                    end

                    if (compareWorldList[j + 1] and compareWorldList[j + 1].modifyTime) then
                        nextItemModifyTime = compareWorldList[j + 1].modifyTime
                    end

                    if curItemModifyTime < nextItemModifyTime then
                        tmp = compareWorldList[j]
                        compareWorldList[j] = compareWorldList[j + 1]
                        compareWorldList[j + 1] = tmp
                    end
                end
            end
        end

        Store:Set("world/localWorlds", localWorlds)
        Store:Set("world/remoteWorldsList", remoteWorldsList)
        Store:Set("world/compareWorldList", compareWorldList)

        UserConsole:Refresh()

        if (type(callback) == "function") then
            callback()
        end
    end

    KeepworkService:GetWorldsList(HandleWorldList)
end

function WorldList:UnifiedTimestampFormat(data)
    if (not data) then
        return 0
    end

    local years = 0
    local months = 0
    local days = 0
    local hours = 0
    local minutes = 0

    if string.find(data, "T") then
        local date = string.match(data or "", "^%d+-%d+-%d+")
        local time = string.match(data or "", "%d+:%d+")

        years = string.match(date or "", "^(%d+)-")
        months = string.match(date or "", "-(%d+)-")
        days = string.match(date or "", "-(%d+)$")

        hours = string.match(time or "", "^(%d+):")
        minutes = string.match(time or "", ":(%d+)")
    else
        local date = string.match(data or "", "^%d+-%d+-%d+")
        local time = string.match(data or "", "%d+-%d+$")

        years = string.match(date or "", "^(%d+)-")
        months = string.match(date or "", "-(%d+)-")
        days = string.match(date or "", "-(%d+)$")

        hours = string.match(time or "", "^(%d+)-")
        minutes = string.match(time or "", "-(%d+)$")
    end

    local timestamp = os.time{year = years, month = months, day = days, hour = hours, min = minutes}

    return timestamp or 0
end

function WorldList:Sync(index)
    SyncCompare:Init()
end

function WorldList.DeleteWorld(index)
    DeleteWorld:DeleteWorld(index)
end

function WorldList.GetWorldType()
    return InternetLoadWorld.type_ds
end

function WorldList:OnSwitchWorld(index)
    if not index then
        return false
    end

    InternetLoadWorld.OnSwitchWorld(index)
    self:UpdateWorldInfo(index)
end

function WorldList.GetSelectWorldIndex()
    return Store:Get("world/worldIndex")
end

function WorldList:UpdateWorldInfo(worldIndex, callback)
    local compareWorldList = Store:Get("world/compareWorldList")

    if (not compareWorldList) then
        return false
    end

    local currentWorld = compareWorldList[worldIndex]

    if (currentWorld and currentWorld.status ~= 2) then
        local filesize = LocalService:GetWorldSize(currentWorld.worldpath)
        local worldTag = LocalService:GetTag(Encoding.Utf8ToDefault(currentWorld.foldername))

        worldTag.size = filesize
        LocalService:SetTag(currentWorld.worldpath, worldTag)

        Store:Set("world/worldTag", worldTag)

        compareWorldList[worldIndex].size = filesize
    end

    local selectWorld = compareWorldList[worldIndex]

    if(selectWorld) then
        Store:Set("world/selectWorld", selectWorld)
        Store:Set("world/worldIndex", worldIndex)

        local foldername = {}

        foldername.utf8 = selectWorld.foldername
        foldername.default = Encoding.Utf8ToDefault(foldername.utf8)
        foldername.base32 = GitEncoding.Base32(foldername.utf8)
    
        local worldDir = {}

        worldDir.utf8 = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.utf8)
        worldDir.default = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)

        Store:Set("world/foldername", foldername)
        Store:Set("world/worldDir", worldDir)
    end

    if (type(callback) == "function") then
        callback()
    end

    UserConsole:Refresh()
end

function WorldList.GetDesForWorld()
    local str = ""
    return str
end

function WorldList:EnterWorld(index)
    self:OnSwitchWorld(index)

    local enterWorld = Store:Get("world/selectWorld")
    local enterWorldDir = Store:Get("world/worldDir")
    local enterFoldername = Store:Get("world/foldername")
    local compareWorldList = Store:Get("world/compareWorldList")

    Store:Set("world/enterWorld", enterWorld)
    Store:Set("world/enterWorldDir", enterWorldDir)
    Store:Set("world/enterFoldername", enterFoldername)

    if (not KeepworkService:IsSignedIn()) then
        InternetLoadWorld.EnterWorld()
        return
    end

    if (enterWorld.status == 2) then
        Store:Set("world/willEnterWorld", InternetLoadWorld.EnterWorld)

        SyncCompare:Init()
    else
        InternetLoadWorld.EnterWorld()
    end

    UserConsole:ClosePage()
end

function WorldList.FormatStatus(status)
    if (status == 1) then
        return L"仅本地"
    elseif (status == 2) then
        return L"仅网络"
    elseif (status == 3) then
        return L"本地版本与远程数据源一致"
    elseif (status == 4) then
        return L"本地版本更加新"
    elseif (status == 5) then
        return L"远程版本更加新"
    else
        return L"获取状态中"
    end
end

function WorldList.FormatDatetime(datetime)
    if type(datetime) ~= 'number' then
        return ''
    end

    return os.date("%Y-%m-%d %H:%M", datetime)
end

function WorldList:SetRefreshing(status)
    UserConsolePage = Store:Get('page/UserConsole')

    if (not UserConsolePage) then
        return false
    end

    UserConsolePage.refreshing = status and true or false
    UserConsole:Refresh()
end

function WorldList:IsRefreshing()
    UserConsolePage = Store:Get('page/UserConsole')

    if (UserConsolePage and UserConsolePage.refreshing) then
        return true
    else
        return false
    end
end