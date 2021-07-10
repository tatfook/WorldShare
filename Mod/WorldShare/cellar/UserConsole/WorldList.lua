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
local LocalServiceWorld = NPL.load("(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua")
local SyncToLocal = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua")

local WorldList = NPL.export()

WorldList.zipDownloadFinished = true

function WorldList:RefreshCurrentServerList(callback, statusFilter)
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    self:SetRefreshing(true)

    Compare:RefreshWorldList(function(currentWorldList)
        self:SetRefreshing(false)

        if UserConsolePage then
            UserConsolePage:GetNode("gw_world_ds"):SetAttribute("DataSource", currentWorldList or {})
            WorldList:OnSwitchWorld(1)
        end
        
        if type(callback) == 'function' then
            callback()
        end
    end, statusFilter)
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

    if not currentWorldList or type(currentWorldList) ~= 'table' then
        return false
    end

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
    if not KeepworkService:IsSignedIn() then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...")

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

    -- vip world
    if currentWorld.isVipWorld or currentWorld.instituteVipEnabled then
        if not KeepworkService:IsSignedIn() then
            LoginModal:CheckSignedIn(L"此操作需要录后继续", function(bIsSuccessed)
                if bIsSuccessed then
                    local index = self:GetWorldIndexByFoldername(currentWorld.foldername, currentWorld.shared, currentWorld.is_zip)
                    self:EnterWorld(index)
                end
            end)
            return false
        end

        local canEnter = false
        
        local username = Mod.WorldShare.Store:Get("user/username")

        if currentWorld.user and currentWorld.user.username == username then
            canEnter = true
        end

        local isVip = Mod.WorldShare.Store:Get("user/isVip")

        if currentWorld.vipEnabled == "true" then
            if isVip then
                canEnter = true
            end
        end

        local userType = Mod.WorldShare.Store:Get("user/userType")

        if currentWorld.instituteVipEnabled == "true" then
            if userType.student then
                canEnter = true
            end
        end

        if not canEnter then
            _guihelper.MessageBox(L"你没有权限进入此世界")
            return false
        end
    end

    local ThirdPartyLoginPage = Mod.WorldShare.Store:Get('page/ThirdPartyLogin')

    if ThirdPartyLoginPage then
        ThirdPartyLoginPage:CloseWindow()
    end

    local function CheckWorld()
        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
        local output = commonlib.Files.Find({}, currentWorld.worldpath, 0, 500, "worldconfig.txt")

        if not output or #output == 0 then
            _guihelper.MessageBox(L"世界文件异常，请重新下载")
            return false
        else
            return true
        end
    end

    if currentWorld.status ~= 2 then
        if not CheckWorld() then
            return false
        end
    end

    local function Handle()
        if not KeepworkService:IsSignedIn() then
            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

            if currentWorld.shared then
                Mod.WorldShare.MsgBox:Dialog(
                    "MultiPlayerWorldLogin",
                    L"此世界为多人世界，请登录后再打开世界，或者以只读模式打开世界",
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
            Mod.WorldShare.MsgBox:Show(L"请稍候...")
            local function HandleLockAndEnter()
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
    
                                    canLocked = true
                                    -- if (curTimestamp - lastLockTimestamp) > 60 then
                                    --     canLocked = true
                                    -- else
                                    --     canLocked = false
                                    --     Mod.WorldShare.MsgBox:Close()
        
                                    --     Mod.WorldShare.MsgBox:Dialog(
                                    --         "MultiPlayerWorldOccupy",
                                    --         format(
                                    --             L"此账号已在其他地方占用此世界，请退出后再或者以只读模式打开世界",
                                    --             data.owner.username,
                                    --             currentWorld.foldername,
                                    --             data.owner.username
                                    --         ),
                                    --         {
                                    --             Title = L"世界被占用",
                                    --             Yes = L"知道了",
                                    --             No = L"只读模式打开"
                                    --         },
                                    --         function(res)
                                    --             if res and res == _guihelper.DialogResult.No then
                                    --                 Mod.WorldShare.Store:Set("world/readonly", true)
                                    --                 InternetLoadWorld.EnterWorld()
                                    --                 UserConsole:ClosePage()
                                    --             end
                                    --         end,
                                    --         _guihelper.MessageBoxButtons.YesNo
                                    --     )
                                    -- end
                                end
                            else
                                Mod.WorldShare.MsgBox:Dialog(
                                    "MultiPlayerWolrdOthersOccupy",
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
                                Mod.WorldShare.MsgBox:Close()
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
            
            local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

            if currentEnterWorld and (currentEnterWorld.project and currentEnterWorld.project.memberCount or 0) > 1 then
                KeepworkServiceWorld:UnlockWorld(function()
                    HandleLockAndEnter()
                end)
            else
                HandleLockAndEnter()
            end
        end

        if currentWorld.status == 2 then
            Mod.WorldShare.MsgBox:Show(L"请稍候...")

            Compare:Init(function(result)
                if result ~= Compare.JUSTREMOTE then
                    return false
                end

                SyncToLocal:Init(function(result, option)
                    if not result then
                        if type(option) == 'string' then
                            if option == 'NEWWORLD' then
                                UserConsole:ClosePage()
                                GameLogic.AddBBS(nil, L"服务器未找到世界数据，请新建", 3000, "255 255 0")
                                local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                                CreateWorld:CreateNewWorld(currentWorld.foldername)
                                Mod.WorldShare.MsgBox:Close()
                                return false
                            end
                        end

                        if type(option) == 'table' then
                            if option.method == 'UPDATE-PROGRESS-FINISH' then
                                if not CheckWorld() then
                                    return false
                                end
            
                                LockAndEnter()
                                Mod.WorldShare.MsgBox:Close()
                            end
                        end


                        return false
                    end
                end)
            end)
        else
            if currentWorld.status == 1 then
                InternetLoadWorld.EnterWorld()	
                UserConsole:ClosePage()
                return true
            end
    
            Mod.WorldShare.MsgBox:Show(L"请稍候...")
            Compare:Init(function(result)
                Mod.WorldShare.MsgBox:Close()

                if (currentWorld.project and currentWorld.project.memberCount or 0) > 1 then
                    if result == Compare.REMOTEBIGGER then
                        local currentRevision = Mod.WorldShare.Store:Get("world/currentRevision") or 0
                        local remoteRevision = Mod.WorldShare.Store:Get("world/remoteRevision") or 0

                        Mod.WorldShare.MsgBox:Dialog(
                            "MultiPlayerWorldUpdate",
                            format(L"你的本地版本%d比远程版本%d旧， 是否更新为最新的远程版本？", currentRevision, remoteRevision),
                            {
                                Title = L"多人世界",
                                Yes = L"同步",
                                No = L"只读模式打开"
                            },
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    SyncMain:BackupWorld()
                                    Mod.WorldShare.MsgBox:Show(L"请稍候...")

                                    SyncMain:SyncToLocalSingle(function(result, option)
                                        if result == true then
                                            Mod.WorldShare.MsgBox:Close()
                                            LockAndEnter()
                                        end
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

    if not KeepworkService:IsSignedIn() and currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
        LoginModal:Init(function(result)
            if result then
                if result == 'THIRD' then
                    return function()
                        self:RefreshCurrentServerList(function()
                            Handle()
                        end)
                    end
                end

                -- refresh world list after 
                self:RefreshCurrentServerList(function()
                    if result == 'REGISTER' or result == 'FORGET' then
                        return false
                    end

                    Handle()
                end)
            else
                Handle()
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
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if not UserConsolePage then
        return false
    end

    UserConsolePage.refreshing = status and true or false
    UserConsole:Refresh()
end

function WorldList:IsRefreshing()
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

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