--[[
Title: LoginWorldList
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")
------------------------------------------------------------
]]
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local Encoding = commonlib.gettable("commonlib.Encoding")

local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local SyncCompare = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncCompare.lua")
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
local VersionChange = NPL.load("(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")

local LoginWorldList = NPL.export()

function LoginWorldList.CreateNewWorld()
    local LoginMainPage = Store:get('page/LoginMain')

    LoginMainPage:CloseWindow()
    CreateNewWorld.ShowPage()
end

function LoginWorldList.GetCurWorldInfo(info_type, world_index)
    local index = tonumber(world_index)
    local compareWorldList = Store:get("world/compareWorldList")
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

function LoginWorldList.UpdateWorldList()
    local compareWorldList = Store:get("world/compareWorldList") or {}

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

    local LoginMainPage = Store:get('page/LoginMain')

    if (LoginMainPage) then
        LoginMainPage:GetNode("gw_world_ds"):SetAttribute("DataSource", compareWorldList)
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

            if (callback) then
                callback(ServerPage.ds)
            end
        end
    )
end

function LoginWorldList.RefreshCurrentServerList(callback)
    LoginMain.setLoginMainPageRefreshing(true)

    if (not LoginUserInfo.IsSignedIn()) then
        LoginWorldList.getLocalWorldList(
            function()
                LoginWorldList.changeRevision(
                    function()
                        LoginMain.setLoginMainPageRefreshing(false)
                        LoginWorldList.UpdateWorldList()

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
                                LoginMain.setLoginMainPageRefreshing(false)
                                LoginWorldList.UpdateWorldList()

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
    Store:set("user/localWorlds", localWorldList)

    if (callback) then
        callback()
    end
end

function LoginWorldList.changeRevision(callback)
    local localWorlds = Store:get("user/localWorlds")

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

        value.modifyTime = value.writedate
    end

    Store:set("world/localWorlds", localWorlds)
    Store:set("world/compareWorldList", localWorlds)
    
    LoginMain.refreshLoginMainPage()

    if (callback) then
        callback()
    end
end

function LoginWorldList.selectVersion()
    local selectWorld = Store:get('world/selectWorld')

    if(selectWorld.status == 1) then
        _guihelper.MessageBox(L"此世界仅在本地，无法切换版本")
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
        local localWorlds = Store:get("world/localWorlds") or {}

        local remoteWorldsList = response.data
        local compareWorldList = commonlib.vector:new()

        -- 处理本地网络同时存在 本地不存在 网络存在 的世界
        if (type(remoteWorldsList) ~= "table") then
            _guihelper.MessageBox(L"获取服务器世界列表错误")
            return false
        end

        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local worldpath = ""
            local status
            local revision

            for LKey, LItem in ipairs(localWorlds) do
                if (DItem["worldsName"] == LItem["foldername"]) then
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
                text = DItem["worldsName"],
                foldername = DItem["worldsName"],
                revision = revision,
                size = DItem["filesTotals"],
                modifyTime = DItem["modDate"],
                lastCommitId = DItem["commitId"], 
                worldpath = worldpath,
                status = status
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
                    local curItemModifyTime = 0
                    local nextItemModifyTime = 0

                    if (compareWorldList[j] and compareWorldList[j].modifyTime) then
                        curItemModifyTime = LoginWorldList:formatDate(compareWorldList[j].modifyTime)
                    end

                    if (compareWorldList[j + 1] and compareWorldList[j + 1].modifyTime) then
                        nextItemModifyTime = LoginWorldList:formatDate(compareWorldList[j + 1].modifyTime)
                    end

                    if curItemModifyTime < nextItemModifyTime then
                        tmp = compareWorldList[j]
                        compareWorldList[j] = compareWorldList[j + 1]
                        compareWorldList[j + 1] = tmp
                    end
                end
            end
        end

        Store:set("world/localWorlds", localWorlds)
        Store:set("world/remoteWorldsList", remoteWorldsList)
        Store:set("world/compareWorldList", compareWorldList)

        LoginMain.refreshLoginMainPage()

        if (type(callback) == "function") then
            callback()
        end
    end

    KeepworkService.getWorldsList(handleWorldList)
end

function LoginWorldList:formatDate(modDate)
    if (not modDate) then
        return 0
    end

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

    return tonumber(newModDate == '' and 0 or newModDate)
end

function LoginWorldList.syncNow(index)
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
    LoginWorldList.updateWorldInfo(index)
end

function LoginWorldList.GetSelectWorldIndex()
    return Store:get("world/worldIndex")
end

function LoginWorldList.updateWorldInfo(worldIndex, callback)
    local compareWorldList = Store:get("world/compareWorldList")

    if (not compareWorldList) then
        return false
    end

    local currentWorld = compareWorldList[worldIndex]

    if (currentWorld and currentWorld.status ~= 2) then
        local filesize = LocalService:GetWorldSize(currentWorld.worldpath)
        local worldTag = LocalService:GetTag(Encoding.Utf8ToDefault(currentWorld.foldername))

        worldTag.size = filesize
        LocalService:SetTag(currentWorld.worldpath, worldTag)

        Store:set("world/worldTag", worldTag)

        compareWorldList[worldIndex].size = filesize
    end

    local selectWorld = compareWorldList[worldIndex]
    
    if(selectWorld) then
        
        Store:set("world/selectWorld", selectWorld)
        Store:set("world/worldIndex", worldIndex)
        
        local foldername = {}

        foldername.utf8 = selectWorld.foldername
        foldername.default = Encoding.Utf8ToDefault(foldername.utf8)
        foldername.base32 = GitEncoding.base32(foldername.utf8)
    
        local worldDir = {}

        worldDir.utf8 = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.utf8)
        worldDir.default = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)

        Store:set("world/foldername", foldername)
        Store:set("world/worldDir", worldDir)
    end

    if (type(callback) == "function") then
        callback()
    end

    LoginMain.refreshLoginMainPage()
end

function LoginWorldList.GetDesForWorld()
    local str = ""
    return str
end

function LoginWorldList.enterWorld(index)
    LoginWorldList.OnSwitchWorld(index)

    local enterWorld = Store:get("world/selectWorld")
    local enterWorldDir = Store:get("world/worldDir")
    local enterFoldername = Store:get("world/foldername")
    local compareWorldList = Store:get("world/compareWorldList")

    Store:set("world/enterWorld", enterWorld)
    Store:set("world/enterWorldDir", enterWorldDir)
    Store:set("world/enterFoldername", enterFoldername)

    if (not LoginUserInfo.IsSignedIn()) then
        InternetLoadWorld.EnterWorld()
        return
    end

    if (enterWorld.status == 2) then
        Store:set("world/willEnterWorld", InternetLoadWorld.EnterWorld)

        SyncCompare:syncCompare()
    else
        InternetLoadWorld.EnterWorld()
    end

    LoginMain.closeLoginMainPage()
end

function LoginWorldList.sharePersonPage()
    local url = LoginMain.personPageUrl
    ParaGlobal.ShellExecute("open", url, "", "", 1)
end

function LoginWorldList.formatStatus(status)
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