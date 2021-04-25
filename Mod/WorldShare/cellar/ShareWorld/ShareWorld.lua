--[[
Title: share world to datasource
Author(s): big
Date: 2017.5.12
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
ShareWorld:Init()
-------------------------------------------------------
]]

-- libs
local PackageShareWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

-- UI
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")

-- service
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local ShareWorld = NPL.export()

function ShareWorld:Init(callback)
    if KeepworkServiceSession:GetUserWhere() == 'LOCAL' and not KeepworkServiceSession:IsSignedIn() then
        return
    end

	ShareWorld.callback = callback
    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

    if GameLogic.IsReadOnly() or not currentEnterWorld or currentEnterWorld.is_zip then
        self:ShowWorldCode(currentEnterWorld.kpProjectId)
        return false
    end

    local filepath = self:GetPreviewImagePath()
    if not GameLogic.IsReadOnly() and not ParaIO.DoesFileExist(filepath, false) then
        PackageShareWorld.TakeSharePageImage()
    end

    if not KeepworkService:IsSignedIn() then
        function Handle()
            KeepworkServiceProject:GetProjectIdByWorldName(
                currentEnterWorld.foldername,
                currentEnterWorld.shared,
                function()
                    Compare:GetCurrentWorldInfo(
                        function()
                            Compare:Init(currentEnterWorld.worldpath, function(result)
                                if result then
                                    self:CheckRealName(function()                                        
                                        self:ShowPage()
                                    end)
                                end
                            end)
                        end
                    )
                end
            )
        end

        if not UserInfo:CheckDoAutoSignin(Handle) then
            LoginModal:ShowPage()
            Mod.WorldShare.Store:Set('user/AfterLogined', Handle)
        end

        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...")
    Compare:Init(currentEnterWorld.worldpath, function(result)
        Mod.WorldShare.MsgBox:Close()
        if result then
            self:CheckRealName(function()
                self:ShowPage()
            end)
        end
    end)
end

function ShareWorld:CheckRealName(callback)
    if not callback or type(callback) ~= "function" then
        return false
    end

    if KeepworkServiceSession:IsRealName() then
        callback()
    else
        RegisterModal:ShowClassificationPage(callback, true)
    end
end

function ShareWorld:ShowPage()
    local params = Mod.WorldShare.Utils.ShowWindow(640, 415, "Mod/WorldShare/cellar/Theme/ShareWorld/ShareWorld.html", "ShareWorld")

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/ShareWorld')
        Mod.WorldShare.Store:Remove("world/shareMode")
    end

    local ShareWorldImp = Mod.WorldShare.Store:Get('page/ShareWorld')
    local filepath = self:GetPreviewImagePath()

    if ParaIO.DoesFileExist(filepath) and ShareWorldImp then
        ShareWorldImp:SetNodeValue("ShareWorldImage", filepath)
    end

    self:Refresh()
end

function ShareWorld:GetPreviewImagePath()
    local worldpath = ParaWorld.GetWorldDirectory() or ""
    return format("%spreview.jpg", worldpath)
end

function ShareWorld:SetPage()
    Mod.WorldShare.Store:Set('page/ShareWorld', document:GetPageCtrl())
end

function ShareWorld:ClosePage()
    local ShareWorldPage = Mod.WorldShare.Store:Get('page/ShareWorld')

    if ShareWorldPage then
        ShareWorldPage:CloseWindow()
    end
end

function ShareWorld:Refresh(times)
    local ShareWorldPage = Mod.WorldShare.Store:Get('page/ShareWorld')

    if ShareWorldPage then
        ShareWorldPage:Refresh(times or 0.01)
    end
end

function ShareWorld:GetWorldSize()
    local worldpath = ParaWorld.GetWorldDirectory()

    if not worldpath then
        return false
    end

    local filesTotal = LocalService:GetWorldSize(worldpath)

    return Mod.WorldShare.Utils.FormatFileSize(filesTotal)
end

function ShareWorld:GetRemoteRevision()
    return tonumber(Mod.WorldShare.Store:Get("world/remoteRevision")) or 0
end

function ShareWorld:GetCurrentRevision()
    return tonumber(Mod.WorldShare.Store:Get("world/currentRevision")) or 0
end

function ShareWorld:OnClick()
    local canBeShare = true
    local msg = ''

    if WorldCommon:IsModified() then
        canBeShare = false
        msg = L"当前世界未保存，是否继续上传世界？"
    end

    if canBeShare and self:GetRemoteRevision() > self:GetCurrentRevision() then
        canBeShare = false
        msg = L"当前本地版本小于远程版本，是否继续上传？"
    end

    local function Handle()
        Mod.WorldShare.Store:Set('world/currentWorld', Mod.WorldShare.Store:Get('world/currentEnterWorld'))

        SyncMain:CheckTagName(function()
            SyncMain:SyncToDataSource(function(result, msg)
                Compare:GetCurrentWorldInfo(function()
				    if self.callback and type(self.callback) == 'function' then
                        self.callback(true)
                    end
                end)
			end)

            self:ClosePage()

            -- act week
            if self:GetCurrentRevision() > self:GetRemoteRevision() then
                local ActWeek = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.lua")
                if ActWeek then
                    ActWeek.AchieveActTarget()
                end
            end
        end)
    end

    if not canBeShare then
        _guihelper.MessageBox(
            msg,
            function(res)
                if (res and res == 6) then
                    Handle()
                end
            end
        )

        return false
    end

    Handle()
end

function ShareWorld:Snapshot()
    local ShareWorldPage = Mod.WorldShare.Store:Get('page/ShareWorld')
    PackageShareWorld.TakeSharePageImage()
    self:UpdateImage(true)

    if (self:GetRemoteRevision() == self:GetCurrentRevision()) then
        CommandManager:RunCommand("/save")
        self:ClosePage()
        self:Init()
    end
end

function ShareWorld:UpdateImage(bRefreshAsset)
    local ShareWorldPage = Mod.WorldShare.Store:Get('page/ShareWorld')

    if (ShareWorldPage) then
        local filepath = self:GetPreviewImagePath()

        ShareWorldPage:SetUIValue("ShareWorldImage", filepath)

        if (bRefreshAsset) then
            ParaAsset.LoadTexture("", filepath, 1):UnloadAsset()
        end

        self:Refresh()
    end
end

function ShareWorld:ShowWorldCode(projectId)
    Mod.WorldShare.MsgBox:Show(L"请稍候...")

    KeepworkServiceProject:GenerateMiniProgramCode(
        projectId,
        function(bSucceed, wxacode)
            Mod.WorldShare.MsgBox:Close()

            if not bSucceed then
                GameLogic.AddBBS(nil, L"生成二维码失败", 3000, "255 0 0")
                return false
            end

            Mod.WorldShare.Utils.ShowWindow(520, 305, "Mod/WorldShare/cellar/ShareWorld/Code.html?wxacode=".. (wxacode or ""), "Mod.WorldShare.ShareWorld.Code")
        end
    )
end

-- get keepwork project url
function ShareWorld:GetShareUrl()
    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

    if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
        return ''
    end

    return format("%s/pbl/project/%d/", KeepworkService:GetKeepworkUrl(), currentEnterWorld.kpProjectId)
end

function ShareWorld:GetWorldName()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    return currentEnterWorld.text
end
