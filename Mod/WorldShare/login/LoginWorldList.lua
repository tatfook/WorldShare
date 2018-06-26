--[[
Title: LoginWorldList
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua")
NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")
NPL.load("(gl)Mod/WorldShare/login/DeleteWorld.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)Mod/WorldShare/login/VersionChange.lua")

local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local KeepworkService = commonlib.gettable("Mod.WorldShare.service.KeepworkService")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
local DeleteWorld = commonlib.gettable("Mod.WorldShare.login.DeleteWorld")
local Encoding = commonlib.gettable("commonlib.Encoding")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local VersionChange = commonlib.gettable("Mod.WorldShare.login.VersionChange")

local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")

function LoginWorldList.CreateNewWorld()
    LoginMain.LoginPage:CloseWindow()
    CreateNewWorld.ShowPage()
end

function LoginWorldList.GetCurWorldInfo(info_type, world_index)
    local index = tonumber(world_index)
    local compareWorldList = GlobalStore.get("compareWorldList")
    local selected_world = compareWorldList[world_index]

    if (selected_world) then
        if (info_type == "mode") then
            local mode = selected_world["world_mode"]

            if (mode == "edit") then
                return L "创作"
            else
                return L "参观"
            end
        else
            return selected_world[info_type]
        end
    end
end

function LoginWorldList.UpdateWorldList()
    local compareWorldList = GlobalStore.get("compareWorldList") or {}

    LoginWorldList.GetInternetWorldList(
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

    if (LoginMain.LoginPage) then
        LoginMain.LoginPage:GetNode("gw_world_ds"):SetAttribute("DataSource", compareWorldList)
        LoginWorldList.OnSwitchWorld(1)
    end
end

function LoginWorldList.GetInternetWorldList(callback)
    local ServerPage = InternetLoadWorld.GetCurrentServerPage()

    RemoteServerList:new():Init(
        "local",
        "localworld",
        function(bSucceed, serverlist)
            if (not serverlist:IsValid()) then
                BroadcastHelper.PushLabel(
                    {
                        id = "userworlddownload",
                        label = L "无法下载服务器列表, 请检查网络连接",
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

            if (callback) then
                callback(ServerPage.ds)
            end
        end
    )
end

function LoginWorldList.RefreshCurrentServerList(callback)
    LoginMain.setPageRefreshing(true)

    if (not LoginUserInfo.IsSignedIn()) then
        LoginWorldList.getLocalWorldList(
            function()
                LoginWorldList.changeRevision(
                    function()
                        LoginWorldList.UpdateWorldList()
                        LoginMain.setPageRefreshing(false)

                        if (type(callback) == "function") then
                            callback()
                        end
                    end
                )
            end
        )
    end

    if (LoginUserInfo.IsSignedIn()) then
        LoginWorldList.getLocalWorldList(
            function()
                LoginWorldList.changeRevision(
                    function()
                        LoginWorldList.syncWorldsList(
                            function()
                                LoginWorldList.UpdateWorldList()
                                LoginMain.setPageRefreshing(false)

                                if (type(callback) == "function") then
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

function LoginWorldList.getLocalWorldList(callback)
    local localWorldList = LocalLoadWorld.BuildLocalWorldList(true)

    GlobalStore.set("localWorlds", localWorldList)

    if (callback) then
        callback()
    end
end

function LoginWorldList.changeRevision(callback)
    local localWorlds = GlobalStore.get("localWorlds")

    for key, value in ipairs(localWorlds) do
        if (not value.is_zip) then
            local foldername = {}
            foldername.utf8 = value.foldername
            foldername.default = Encoding.Utf8ToDefault(value.foldername)

            local WorldRevisionCheckOut =
                WorldRevision:new():init(SyncMain.GetWorldFolderFullPath() .. "/" .. foldername.default .. "/")
            value.revision = WorldRevisionCheckOut:GetDiskRevision()

            local tag = LocalService:GetTag(foldername.default)

            if (tag.size) then
                value.size = tag.size
            else
                value.size = 0
            end
        else
            local zipWorldDir = {}
            zipWorldDir.default = value.remotefile:gsub("local://", "")
            zipWorldDir.utf8 = Encoding.Utf8ToDefault(zipWorldDir.default)

            local zipFoldername = {}
            zipFoldername.default = zipWorldDir.default:match("([^/\\]+)/[^/]*$")
            zipFoldername.utf8 = Encoding.Utf8ToDefault(zipFoldername.default)

            value.revision = LocalService:GetZipRevision(zipWorldDir.default)
            value.size = LocalService:GetZipWorldSize(zipWorldDir.default)
        end

        value.modifyTime = value.writedate
    end

    GlobalStore.set("localWorlds", localWorlds)
    GlobalStore.set("compareWorldList", localWorlds)
    LoginMain.refreshPage()

    if (callback) then
        callback()
    end
end

function LoginWorldList.selectVersion()
    local selectWorld = GlobalStore.get('selectWorld')

    if(selectWorld.status == 1) then
        _guihelper.MessageBox(L "此世界仅在本地，无法切换版本")
        return false
    end

    VersionChange:init()
end

--[[
status代码含义:
1:仅本地
2:仅网络
3:本地网络一致
4:网络更新
5:本地更新
]]
function LoginWorldList.syncWorldsList(callback)
    local function handleWorldList(response, err)
        local localWorlds = GlobalStore.get("localWorlds") or {}

        local remoteWorldsList = response.data
        local compareWorldList = commonlib.vector:new()

        -- 处理本地网络同时存在 本地不存在 网络存在 的世界
        if (type(remoteWorldsList) ~= "table") then
            _guihelper.MessageBox(L "获取服务器世界列表错误")
            return false
        end

        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local worldpath = ""
            local status

            for LKey, LItem in ipairs(localWorlds) do
                if (DItem["worldsName"] == LItem["foldername"]) then
                    if (tonumber(LItem["revision"]) == tonumber(DItem["revision"])) then
                        status = 3 --本地网络一致
                    elseif (tonumber(LItem["revision"]) > tonumber(DItem["revision"])) then
                        status = 4 --网络更新
                    elseif (tonumber(LItem["revision"]) < tonumber(DItem["revision"])) then
                        status = 5 --本地更新
                    end

                    isExist = true
                    worldpath = LItem["worldpath"]
                    break
                end
            end

            if (not isExist) then
                status = 2
            end

            local currentWorld = {
                text = DItem["worldsName"],
                foldername = DItem["worldsName"],
                revision = DItem["revision"],
                size = DItem["filesTotals"],
                modifyTime = DItem["modDate"],
                worldpath = worldpath,
                status = status --仅网络
            }

            compareWorldList:push_back(currentWorld)
        end

        -- 处理 本地存在 网络不存在 的世界
        for LKey, LItem in ipairs(localWorlds) do
            local isExist = false

            for DKey, DItem in ipairs(remoteWorldsList) do
                if (LItem["foldername"] == DItem["worldsName"]) then
                    isExist = true
                    break
                end
            end

            if (not isExist) then
                currentWorld = LItem
                currentWorld.modifyTime = currentWorld.writedate
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
                    if
                        LoginWorldList:formatDate(compareWorldList[j].modifyTime) <
                            LoginWorldList:formatDate(compareWorldList[j + 1].modifyTime)
                     then
                        tmp = compareWorldList[j]
                        compareWorldList[j] = compareWorldList[j + 1]
                        compareWorldList[j + 1] = tmp
                    end
                end
            end
        end

        GlobalStore.set("localWorlds", localWorlds)
        GlobalStore.set("remoteWorldsList", remoteWorldsList)
        GlobalStore.set("compareWorldList", compareWorldList)

        LoginMain.refreshPage()

        if (type(callback) == "function") then
            callback()
        end
    end

    KeepworkService.getWorldsList(handleWorldList)
end

function LoginWorldList:formatDate(modDate)
    local function strRepeat(num, str)
        local strRepeat = ""

        for i = 1, num do
            strRepeat = strRepeat .. str
        end

        return strRepeat
    end

    local modDateTable = {}

    for modDateEle in string.gmatch(modDate, "[^%-]+") do
        modDateTable[#modDateTable + 1] = modDateEle
    end

    local newModDate = ""

    if (modDateTable[1] and #modDateTable[1] ~= 4) then
        local num = 4 - #modDateTable[1]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[1]
    elseif (modDateTable[1] and #modDateTable[1] == 4) then
        newModDate = newModDate .. modDateTable[1]
    end

    if (modDateTable[2] and #modDateTable[2] ~= 2) then
        local num = 2 - #modDateTable[2]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[2]
    elseif (modDateTable[2] and #modDateTable[2] == 2) then
        newModDate = newModDate .. modDateTable[2]
    end

    if (modDateTable[3] and #modDateTable[3] ~= 2) then
        local num = 2 - #modDateTable[3]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[3]
    elseif (modDateTable[3] and #modDateTable[3] == 2) then
        newModDate = newModDate .. modDateTable[3]
    end

    if (modDateTable[4] and #modDateTable[4] ~= 2) then
        local num = 2 - #modDateTable[4]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[4]
    elseif (modDateTable[4] and #modDateTable[4] == 2) then
        newModDate = newModDate .. modDateTable[4]
    end

    if (modDateTable[5] and #modDateTable[5] ~= 2) then
        local num = 2 - #modDateTable[5]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[5]
    elseif (modDateTable[5] and modDateTable[5] and #modDateTable[5] == 2) then
        newModDate = newModDate .. modDateTable[5]
    end

    return tonumber(newModDate)
end

function LoginWorldList.syncNow(index)
    if (not LoginUserInfo.IsSignedIn() or not LoginUserInfo.CheckoutVerified()) then
        return false
    end

    SyncCompare:syncCompare()
end

function LoginWorldList.deleteWorld(index)
    DeleteWorld.DeleteWorld(index)
end

function LoginWorldList.GetWorldType()
    return InternetLoadWorld.type_ds
end

function LoginWorldList.OnSwitchWorld(index)
    index = index and index or Eval("index")
    InternetLoadWorld.OnSwitchWorld(index)
    LoginWorldList.updateWorldInfo(index, LoginMain.refreshPage)
end

function LoginWorldList.GetSelectWorldIndex()
    return GlobalStore.get("worldIndex")
end

function LoginWorldList.updateWorldInfo(worldIndex, callback)
    local compareWorldList = GlobalStore.get("compareWorldList")

    if (not compareWorldList) then
        return false
    end

    local currentWorld = compareWorldList[worldIndex]

    if (currentWorld and currentWorld.status ~= 2) then
        local filesize = LocalService:GetWorldSize(currentWorld.worldpath)
        local worldTag = LocalService:GetTag(Encoding.Utf8ToDefault(currentWorld.foldername))

        worldTag.size = filesize
        LocalService:SetTag(currentWorld.worldpath, worldTag)

        GlobalStore.set("worldTag", worldTag)

        compareWorldList[worldIndex].size = filesize
    end

    local selectWorld = compareWorldList[worldIndex]
    GlobalStore.set("selectWorld", selectWorld)
    GlobalStore.set("worldIndex", worldIndex)

    local foldername = {}

    foldername.utf8 = selectWorld.foldername
    foldername.default = Encoding.Utf8ToDefault(foldername.utf8)
    foldername.base32 = GitEncoding.base32(foldername.utf8)

    local worldDir = {}

    worldDir.utf8 = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.utf8)
    worldDir.default = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)

    GlobalStore.set("foldername", foldername)
    GlobalStore.set("worldDir", worldDir)

    if (type(callback) == "function") then
        callback()
    end

    LoginMain.refreshPage()
end

function LoginWorldList.GetDesForWorld()
    local str = ""
    return str
end

function LoginWorldList.enterWorld()
    local enterWorld = GlobalStore.get("selectWorld")
    local enterWorldDir = GlobalStore.get("worldDir")
    local enterFoldername = GlobalStore.get("foldername")
    local compareWorldList = GlobalStore.get("compareWorldList")

    GlobalStore.set("enterWorld", enterWorld)
    GlobalStore.set("enterWorldDir", enterWorldDir)
    GlobalStore.set("enterFoldername", enterFoldername)

    if (not LoginUserInfo.IsSignedIn()) then
        InternetLoadWorld.EnterWorld()
        return
    end

    if (LoginWorldList.status == 2) then
        GlobalStore.set("willEnterWorld", InternetLoadWorld.EnterWorld)

        SyncCompare:syncCompare()
    else
        InternetLoadWorld.EnterWorld()
    end

    LoginMain.ClosePage()
end

function LoginWorldList.sharePersonPage()
    local url = LoginMain.personPageUrl --LoginMain.site .. "/wiki/mod/worldshare/share/#?type=person&userid=" .. login.userid;
    ParaGlobal.ShellExecute("open", url, "", "", 1)
end

function LoginWorldList.formatStatus(_status)
    --LOG.std(nil, "debug", "_status", _status);
    if (_status == 1) then
        return L "仅本地"
    elseif (_status == 2) then
        return L "仅网络"
    elseif (_status == 3) then
        return L "本地版本与远程数据源一致"
    elseif (_status == 4) then
        return L "本地版本更加新"
    elseif (_status == 5) then
        return L "远程版本更加新"
    else
        return L "获取状态中"
    end
end

function LoginWorldList.formatDatetime(datetime)
    if (datetime) then
        local n = 1
        local formatDatetime = ""
        for value in string.gmatch(datetime, "[^%-]+") do
            if (n == 3) then
                formatDatetime = formatDatetime .. value .. " "
            elseif (n < 3) then
                formatDatetime = formatDatetime .. value .. "-"
            elseif (n == 5) then
                formatDatetime = formatDatetime .. value
            elseif (n < 5) then
                formatDatetime = formatDatetime .. value .. ":"
            end

            n = n + 1
        end
        return formatDatetime
    end

    return datetime
end

--[[ TODO: this makes paracraft NOT able to run when network is down.
local OnClickCreateWorld = CreateNewWorld.OnClickCreateWorld;

CreateNewWorld.OnClickCreateWorld = function()
    LoginMain:sensitiveCheck(function(hasSensitive)
        if(hasSensitive) then
            _guihelper.MessageBox(L"世界名字中含有敏感词汇，请重新输入");
        else
            OnClickCreateWorld();
        end
    end)
end
]]
function LoginWorldList:sensitiveCheck(callback)
    local new_world_name = CreateNewWorld.page:GetValue("new_world_name")

    if (new_world_name) then
        HttpRequest:GetUrl(
            {
                url = format("%s/api/wiki/models/sensitive_words/query", LoginMain.site),
                form = {
                    query = {
                        name = new_world_name
                    }
                },
                json = true
            },
            function(data, err)
                if (data and type(data) == "table") then
                    if (data.data.total ~= 0) then
                        if (callback and type(callback) == "function") then
                            callback(true)
                        end
                    else
                        if (callback and type(callback) == "function") then
                            callback(false)
                        end
                    end
                end
            end
        )
    end
end
