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

status代码含义:
1:仅本地
2:仅网络
3:本地网络一致
4:网络更新
5:本地更新

]]
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local Encoding = commonlib.gettable("commonlib.Encoding")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")

local UserConsole = NPL.load("./Main.lua")
local UserInfo = NPL.load("./UserInfo.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
local VersionChange = NPL.load("(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

local WorldList = NPL.export()

WorldList.zipDownloadFinished = true

function WorldList.GetCurWorldInfo(infoType, worldIndex)
    local index = tonumber(worldIndex)
    local selectedWorld = WorldList:GetSelectWorld(index)

    if (selectedWorld) then
        if (infoType == "mode") then
            local mode = selectedWorld["world_mode"]

            if (mode == "edit") then
                return L"创作"
            else
                return L"参观"
            end
        else
            return selectedWorld[infoType]
        end
    end
end

function WorldList:GetSelectWorld(index)
    local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

    if compareWorldList then
        return compareWorldList[index]
    else
        return nil
    end
end

function WorldList:GetWorldIndexByFoldername(foldername, is_zip)
    local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

    for index, item in ipairs(compareWorldList) do
        if foldername == item.foldername and is_zip == item.is_zip then
            return index
        end
    end
end

function WorldList:UpdateWorldListFromInternetLoadWorld(callbackFunc)
    local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList") or {}

    self:GetInternetWorldList(
        function(InternetWorldList)
            for CKey, CItem in ipairs(compareWorldList) do
                for IKey, IItem in ipairs(InternetWorldList) do
                    if IItem.foldername == CItem.foldername then
                        if IItem.is_zip == CItem.is_zip then 
                            for key, value in pairs(IItem) do
                                if(key ~= "revision") then
                                    CItem[key] = value
                                end
                            end
                            break
                        end
                    end
                end
            end

            InternetLoadWorld.cur_ds = compareWorldList
            Store:Set("world/compareWorldList", compareWorldList)

            local UserConsolePage = Store:Get('page/UserConsole')

            if UserConsolePage then
                UserConsolePage:GetNode("gw_world_ds"):SetAttribute("DataSource", compareWorldList)
                WorldList:OnSwitchWorld(1)
            end

            if(callbackFunc) then
                callbackFunc();
            end
        end
    )
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
    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

    if not UserConsolePage and not isForce then
        if type(callback) == 'function' then
            callback()
        end

        return false
    end

    self:SetRefreshing(true)

    if not KeepworkService:IsSignedIn() then
        self:GetLocalWorldList(
            function()
                self:UpdateRevision(
                    function()
                        local localWorlds = Mod.WorldShare.Store:Get("world/localWorlds")
                        Mod.WorldShare.Store:Set("world/compareWorldList", localWorlds)

                        self:SetRefreshing(false)
                        self:UpdateWorldListFromInternetLoadWorld(callback)
                    end
                )
            end
        )
    end

    if KeepworkService:IsSignedIn() then
        self:GetLocalWorldList(
            function()
                self:UpdateRevision(
                    function()
                        self:SyncWorldsList(
                            function()
                                self:SetRefreshing(false)
                                self:UpdateWorldListFromInternetLoadWorld(callback)
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
    Mod.WorldShare.Store:Set("world/localWorlds", localWorldList)

    if type(callback) == 'function' then
        callback()
    end
end

function WorldList:UpdateRevision(callback)
    local localWorlds = Mod.WorldShare.Store:Get("world/localWorlds")

    if not localWorlds then
        return false
    end

    for key, value in ipairs(localWorlds) do
        if value.IsFolder then
            value.worldpath = value.worldpath .. '/'

            local worldRevision = WorldRevision:new():init(value.worldpath)
            value.revision = worldRevision:GetDiskRevision()

            local tag = SaveWorldHandler:new():Init(value.worldpath):LoadWorldInfo()

            if type(tag) ~= 'table' then
                return false
            end

            if tag.kpProjectId then
                value.kpProjectId = tag.kpProjectId
            end

            if tag.size then
                value.size = tag.size
            else
                value.size = 0
            end

            value.local_tagname = tag.name
            value.is_zip = false
        else
            value.foldername = value.Title
            value.text = value.Title
            value.is_zip = true
            value.remotefile = format("local://%s", value.worldpath)
        end

        value.modifyTime = self:UnifiedTimestampFormat(value.writedate)
    end

    Mod.WorldShare.Store:Set("world/localWorlds", localWorlds)
    
    UserConsole:Refresh()

    if type(callback) == 'function' then
        callback()
    end
end

function WorldList:SelectVersion(index)
    local selectedWorld = self:GetSelectWorld(index)

    if(selectedWorld and selectedWorld.status == 1) then
        _guihelper.MessageBox(L"此世界仅在本地，无需切换版本")
        return false
    end

    VersionChange:Init(selectedWorld and selectedWorld.foldername)
end

function WorldList:SyncWorldsList(callback)
    local function HandleWorldList(data, err)
        if type(data) ~= "table" then
            _guihelper.MessageBox(L"获取服务器世界列表错误")
            self:SetRefreshing(false)
            UserConsole:Refresh()
            return false
        end

        local localWorlds = Mod.WorldShare.Store:Get("world/localWorlds") or {}
        local remoteWorldsList = data
        local compareWorldList = commonlib.vector:new()
        local currentWorld

        -- 处理 本地网络同时存在/本地不存在/网络存在 的世界
        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local worldpath = ""
            local localTagname = ""
            local remoteTagname = ""
            local revision = 0
            local commitId = ""
            local status

            for LKey, LItem in ipairs(localWorlds) do
                if DItem["worldName"] == LItem["foldername"] and not LItem.is_zip then
                    if tonumber(LItem["revision"] or 0) == tonumber(DItem["revision"] or 0) then
                        status = 3 --本地网络一致
                        revision = LItem['revision']
                    elseif tonumber(LItem["revision"] or 0) > tonumber(DItem["revision"] or 0) then
                        status = 4 --网络更新
                        revision = DItem['revision'] -- use remote revision beacause remote is newest
                    elseif tonumber(LItem["revision"] or 0) < tonumber(DItem["revision"] or 0) then
                        status = 5 --本地更新
                        revision = LItem['revision'] or 0
                    end

                    isExist = true
                    worldpath = LItem["worldpath"]

                    localTagname = LItem["local_tagname"] or LItem["foldername"]
                    remoteTagname = DItem["extra"] and DItem["extra"]["worldTagName"] or DItem["worldName"]

                    if tonumber(LItem["kpProjectId"]) ~= tonumber(DItem["projectId"]) then
                        local tag = SaveWorldHandler:new():Init(worldpath):LoadWorldInfo()

                        tag.kpProjectId = DItem['projectId']
                        LocalService:SetTag(worldpath, tag)
                    end

                    break
                end
            end

            local text = DItem["worldName"] or ""

            if not isExist then
                --仅网络
                status = 2
                revision = DItem['revision']
                remoteTagname = DItem['extra'] and DItem['extra']['worldTagName'] or text

                if remoteTagname ~= "" and text ~= remoteTagname then
                    text = remoteTagname .. '(' .. text .. ')'
                end
            end

            currentWorld = {
                text = text,
                foldername = DItem["worldName"],
                revision = revision,
                size = DItem["fileSize"],
                modifyTime = self:UnifiedTimestampFormat(DItem["updatedAt"]),
                lastCommitId = DItem["commitId"], 
                worldpath = worldpath,
                status = status,
                kpProjectId = DItem["projectId"],
                local_tagname = localTagname,
                remote_tagname = remoteTagname,
                is_zip = false,
            }

            compareWorldList:push_back(currentWorld)
        end

        -- 处理 本地存在/网络不存在 的世界
        for LKey, LItem in ipairs(localWorlds) do
            local isExist = false

            for DKey, DItem in ipairs(remoteWorldsList) do
                if LItem["foldername"] == DItem["worldName"] and not LItem.is_zip then
                    isExist = true
                    break
                end
            end

            if not isExist then
                currentWorld = LItem
                currentWorld.modifyTime = self:UnifiedTimestampFormat(currentWorld.writedate)
                currentWorld.text = currentWorld.foldername
                currentWorld.local_tagname = LItem['local_tagname']
                currentWorld.status = 1 --仅本地
                currentWorld.is_zip = LItem['is_zip'] or false
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

        Mod.WorldShare.Store:Set("world/remoteWorldsList", remoteWorldsList)
        Mod.WorldShare.Store:Set("world/compareWorldList", compareWorldList)

        UserConsole:Refresh()

        if (type(callback) == "function") then
            callback()
        end
    end

    KeepworkServiceWorld:GetWorldsList(HandleWorldList)
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

        local timestamp = os.time{year = years, month = months, day = days, hour = hours, min = minutes}

        if timestamp then
            return timestamp + 8 * 3600
        else
            return 0
        end
    else
        local date = string.match(data or "", "^%d+-%d+-%d+")
        local time = string.match(data or "", "%d+-%d+$")

        years = string.match(date or "", "^(%d+)-")
        months = string.match(date or "", "-(%d+)-")
        days = string.match(date or "", "-(%d+)$")

        hours = string.match(time or "", "^(%d+)-")
        minutes = string.match(time or "", "-(%d+)$")

        local timestamp = os.time{year = years, month = months, day = days, hour = hours, min = minutes}

        return timestamp or 0
    end
end

function WorldList:Sync()
    Mod.WorldShare.MsgBox:Show(L"请稍后...")

    Compare:Init(function(result)
        if not result then
            GameLogic.AddBBS(nil, L"同步失败", 3000, "255 0 0")
            Mod.WorldShare.MsgBox:Close()
            return false
        end

        if result == Compare.JUSTLOCAL then
            SyncMain:SyncToDataSource()
        end

        if result == Compare.JUSTREMOTE then
            SyncMain:SyncToLocal()
        end

        if result == Compare.REMOTEBIGGER or result == Compare.LOCALBIGGER or result == Compare.EQUAL then
            SyncMain:ShowStartSyncPage()
        end

        Mod.WorldShare.MsgBox:Close()
    end)
end

function WorldList:DeleteWorld()
    DeleteWorld:DeleteWorld()
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

function WorldList:UpdateWorldInfo(worldIndex)
    self.worldIndex = worldIndex
    local currentWorld = self:GetSelectWorld(worldIndex)
    local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

    if currentWorld and currentWorld.status ~= 2 then

        if not currentWorld.is_zip then
            local filesize = LocalService:GetWorldSize(currentWorld.worldpath)
            local worldTag = LocalService:GetTag(currentWorld.worldpath)

            worldTag.size = filesize
            LocalService:SetTag(currentWorld.worldpath, worldTag)

            Mod.WorldShare.Store:Set("world/worldTag", worldTag)

            compareWorldList[worldIndex].size = filesize
        else
            compareWorldList[worldIndex].revision = LocalService:GetZipRevision(currentWorld.worldpath)
            compareWorldList[worldIndex].size = LocalService:GetZipWorldSize(currentWorld.worldpath)
        end
    end

    if not currentWorld then
        return false
    end

    Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
    Mod.WorldShare.Store:Set("world/compareWorldList", compareWorldList)

    UserConsole:Refresh()
end

function WorldList.GetLatestSize(index)
    local compareWorldList = Store:Get("world/compareWorldList")

    if (not compareWorldList or type(index) ~= 'number' or  not compareWorldList[index]) then
        return 0
    end

    local currentWorld = compareWorldList[index]
    return currentWorld.size or 0
end

function WorldList.GetDesForWorld()
    local str = ""
    return str
end

function WorldList:EnterWorld(index)
    self:OnSwitchWorld(index)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        return false
    end

    local function Handle(result)
        if result == 'REGISTER' or result == 'FORGET' then
            return false
        end

        if not KeepworkService:IsSignedIn() then
            self:OnSwitchWorld(index)

            InternetLoadWorld.EnterWorld()
            return false
        end

        -- compare list is not the same before login
        local index = self:GetWorldIndexByFoldername(currentWorld.foldername, currentWorld.is_zip)

        self:OnSwitchWorld(index)
        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

        if currentWorld.status == 2 then
            Mod.WorldShare.MsgBox:Show(L"请稍后...")

            Compare:Init(function(result)
                if result ~= Compare.JUSTREMOTE then
                    return false
                end

                SyncMain:SyncToLocal(function(result, msg)
                    if not result then
                        return false
                    end

                    InternetLoadWorld.EnterWorld()
                    Mod.WorldShare.MsgBox:Close()
                end)
            end)
        else
            if currentWorld.status == 1 then
                InternetLoadWorld.EnterWorld()	
                UserConsole:ClosePage()
                return true
            end
    
            Compare:Init(function(result)
                if result == Compare.REMOTEBIGGER then
                    SyncMain:ShowStartSyncPage(true)
                else
                    InternetLoadWorld.EnterWorld()	
                    UserConsole:ClosePage()	
                end	
            end)
        end

        Mod.WorldShare.Store:Set("explorer/mode", "mine")
    end

    if not KeepworkService:IsSignedIn() and currentWorld.kpProjectId then
        LoginModal:Init(function(result)
            self:RefreshCurrentServerList(function()
                Handle(result)
            end)
        end)
    else
        Handle()
    end
end

function WorldList.FormatStatus(status)
    if status == 1 then
        return L"仅本地"
    elseif status == 2 then
        return L"仅网络"
    elseif status == 3 then
        return L"本地版本与远程数据源一致"
    elseif status == 4 then
        return L"本地版本更加新"
    elseif status == 5 then
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
    UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

    if UserConsolePage and UserConsolePage.refreshing then
        return true
    else
        return false
    end
end

function WorldList:OpenProject(index)
    if type(index) ~= 'number' then
        return false
    end

    local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

    if not compareWorldList or type(compareWorldList[index]) ~= 'table' then
        return false
    end

    ParaGlobal.ShellExecute("open", format("%s/pbl/project/%d/", KeepworkService:GetKeepworkUrl(), compareWorldList[index].kpProjectId or 0), "", "", 1)
end