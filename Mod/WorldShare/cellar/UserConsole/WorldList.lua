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
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local Encoding = commonlib.gettable("commonlib.Encoding")

local UserConsole = NPL.load("./Main.lua")
local UserInfo = NPL.load("./UserInfo.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
local VersionChange = NPL.load("(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local LocalServiceWorld = NPL.load("(gl)Mod/WorldShare/service/LocalService/World.lua")
local SyncToLocal = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua")

local WorldList = NPL.export()

WorldList.zipDownloadFinished = true

function WorldList:RefreshCurrentServerList(callback)
    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

    self:SetRefreshing(true)

    Compare:RefreshWorldList(function(currentWorldList)
        self:SetRefreshing(false)

        if UserConsolePage then
            UserConsolePage:GetNode("gw_world_ds"):SetAttribute("DataSource", currentWorldList)
            WorldList:OnSwitchWorld(1)
        end
        
        if type(callback) == 'function' then
            callback()
        end
    end)
end

function WorldList.GetCurWorldInfo(infoType, worldIndex)
    local index = tonumber(worldIndex)
    local selectedWorld = WorldList:GetSelectWorld(index)

    if selectedWorld then
        if infoType == "mode" then
            local mode = selectedWorld["world_mode"]

            if mode == "edit" then
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

function WorldList:GetWorldIndexByFoldername(foldername, share, iszip)
    local currentWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

    for index, item in ipairs(currentWorldList) do
        if foldername == item.foldername and
           share == item.shared and
           iszip == item.is_zip then
            return index
        end
    end
end

function WorldList:SelectVersion(index)
    local selectedWorld = self:GetSelectWorld(index)

    if selectedWorld and selectedWorld.status == 1 then
        _guihelper.MessageBox(L"此世界仅在本地，无需切换版本")
        return false
    end

    VersionChange:Init(selectedWorld and selectedWorld.foldername)
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
    local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

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
            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

            if currentWorld.shared then
                Mod.WorldShare.MsgBox:Dialog(
                    L"此世界为多人世界，请登陆后再打开世界，或者以只读模式打开世界",
                    {
                        Title = L"多人世界",
                        Yes = L"知道了",
                        No = L"只读模式打开"
                    },
                    function(res)
                        if res and res == _guihelper.DialogResult.No then
                            InternetLoadWorld.EnterWorld()
                            UserConsole:ClosePage()
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo
                )

                return false
            end

            self:OnSwitchWorld(index)
            InternetLoadWorld.EnterWorld()
            return false
        end

        -- compare list is not the same before login
        local index = self:GetWorldIndexByFoldername(currentWorld.foldername, currentWorld.shared, currentWorld.is_zip)

        if not index then
            return false
        end

        self:OnSwitchWorld(index)

        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
        local userId = Mod.WorldShare.Store:Get("user/userId")
        local clientPassword = Mod.WorldShare.Store:Getter("user/GetClientPassword")
 
        local function LockAndEnter()
            Mod.WorldShare.MsgBox:Show(L"请稍后...")
            KeepworkServiceWorld:GetLockInfo(
                currentWorld.kpProjectId,
                function(data)
                    local canLocked = false

                    if not data then
                        canLocked = true
                    else
                        if data and data.owner and data.owner.userId == userId then
                            if tostring(data.password) == tostring(clientPassword) then
                                canLocked = true
                            else
                                local curTimestamp = Mod.WorldShare.Utils:GetCurrentTime(true)
                                local lastLockTimestamp = Mod.WorldShare.Utils:DatetimeToTimestamp(data.lastLockTime)

                                if (curTimestamp - lastLockTimestamp) > 60 then
                                    canLocked = true
                                else
                                    canLocked = false
                                    Mod.WorldShare.MsgBox:Close()
    
                                    Mod.WorldShare.MsgBox:Dialog(
                                        format(
                                            L"此账号已在其他地方占用此世界，请退出后再或者以只读模式打开世界",
                                            data.owner.username,
                                            currentWorld.foldername,
                                            data.owner.username
                                        ),
                                        {
                                            Title = L"世界被占用",
                                            Yes = L"知道了",
                                            No = L"只读模式打开"
                                        },
                                        function(res)
                                            if res and res == _guihelper.DialogResult.No then
                                                Mod.WorldShare.Store:Set("world/readonly", true)
                                                InternetLoadWorld.EnterWorld()
                                                UserConsole:ClosePage()
                                            end
                                        end,
                                        _guihelper.MessageBoxButtons.YesNo
                                    )
                                end
                            end
                        else
                            Mod.WorldShare.MsgBox:Dialog(
                                format(
                                    L"%s正在以独占模式编辑世界%s，请联系%s退出编辑或者以只读模式打开世界",
                                    data.owner.username,
                                    currentWorld.foldername,
                                    data.owner.username
                                ),
                                {
                                    Title = L"世界被占用",
                                    Yes = L"知道了",
                                    No = L"只读模式打开"
                                },
                                function(res)
                                    if res and res == _guihelper.DialogResult.No then
                                        Mod.WorldShare.Store:Set("world/readonly", true)
                                        InternetLoadWorld.EnterWorld()
                                        UserConsole:ClosePage()
                                    end
                                end,
                                _guihelper.MessageBoxButtons.YesNo
                            )
                        end
                    end

                    if canLocked then
                        KeepworkServiceWorld:UpdateLock(
                            currentWorld.kpProjectId,
                            "exclusive",
                            currentWorld.revision,
                            nil,
                            clientPassword,
                            function(data)
                                Mod.WorldShare.MsgBox:Close()

                                if data then
                                    InternetLoadWorld.EnterWorld()	
                                    UserConsole:ClosePage()
                                end
                            end
                        )
                    end
                end
            )
        end

        if currentWorld.status == 2 then
            Mod.WorldShare.MsgBox:Show(L"请稍后...")

            Compare:Init(function(result)
                if result ~= Compare.JUSTREMOTE then
                    return false
                end

                SyncToLocal:Init(function(result, msg)
                    if not result then
                        return false
                    end

                    LockAndEnter()
                    Mod.WorldShare.MsgBox:Close()
                end)
            end)
        else
            if currentWorld.status == 1 then
                InternetLoadWorld.EnterWorld()	
                UserConsole:ClosePage()
                return true
            end
    
            Mod.WorldShare.MsgBox:Show(L"请稍后...")
            Compare:Init(function(result)
                Mod.WorldShare.MsgBox:Close()

                if (currentWorld.project and currentWorld.project.memberCount or 0) > 1 then
                    if result == Compare.REMOTEBIGGER then
                        local currentRevision = Mod.WorldShare.Store:Get("world/currentRevision") or 0
                        local remoteRevision = Mod.WorldShare.Store:Get("world/remoteRevision") or 0

                        Mod.WorldShare.MsgBox:Dialog(
                            format(L"你的本地版本%d比远程版本%d旧， 是否更新为最新的远程版本？", currentRevision, remoteRevision),
                            {
                                Title = L"多人世界",
                                Yes = L"同步",
                                No = L"只读模式打开"
                            },
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    SyncMain:BackupWorld()
                                    Mod.WorldShare.MsgBox:Show(L"请稍后...")
                                    SyncToLocal:Init(function()
                                        Mod.WorldShare.MsgBox:Close()
                                        LockAndEnter()
                                    end)
                                end

                                if res and res == _guihelper.DialogResult.No then
                                    Mod.WorldShare.Store:Set("world/readonly", true)
                                    InternetLoadWorld.EnterWorld()
                                    UserConsole:ClosePage()
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )

                        return false
                    end

                    LockAndEnter()
                    return true
                end

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
            if result then
                -- refresh world list after 
                self:RefreshCurrentServerList(function()
                    Handle(result)
                end)
            else
                Handle(result)
            end
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
    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

    if not UserConsolePage then
        return false
    end

    UserConsolePage.refreshing = status and true or false
    UserConsole:Refresh()
end

function WorldList:IsRefreshing()
    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

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