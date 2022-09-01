--[[
Title: World Exit Dialog
Author(s): big, LiXizhi
CreateDate: 2017.05.15
ModifyDate: 2021.09.29
Desc:
use the lib:
------------------------------------------------------------
local WorldExitDialog = NPL.load('(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
WorldExitDialog.ShowPage()
------------------------------------------------------------
]]

-- lib
NPL.load('(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua')

local SnapshotPage = commonlib.gettable('MyCompany.Apps.ScreenShot.SnapshotPage')
local WorldRevision = commonlib.gettable('MyCompany.Aries.Creator.Game.WorldRevision')
local NplBrowserPlugin = commonlib.gettable('NplBrowser.NplBrowserPlugin')
local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')
local ParaWorldLoginAdapter = commonlib.gettable('MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter')
local TouchMiniKeyboard = commonlib.gettable('MyCompany.Aries.Game.GUI.TouchMiniKeyboard')

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

-- UI
local RedSummerCampMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
local Grade = NPL.load('./Grade.lua')
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')

local WorldExitDialog = NPL.export()
local self = WorldExitDialog

-- show exit world dialog page
-- @param callback: function(res) end.
-- @return void or boolean
function WorldExitDialog.ShowPage(callback)
    if Mod.WorldShare.Store:Get('world/isShowExitPage') then
        Desktop.ForceExit(false)
		return
	end

    if ParaEngine.GetAppCommandLineByParam('IsAppVersion', nil) then
        Desktop.ForceExit(false)
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld or type(currentEnterWorld) ~= 'table' then
        if GameLogic.IsReadOnly() then
            -- no world info when use offline mode
            Desktop.ForceExit(false)
        end

        return
    end

    if KeepworkServiceSession:IsSignedIn() then
        Mod.WorldShare.MsgBox:Show(
            L'请稍候...',
            10000,
            L'网络异常，再点一次关闭即可退出程序',
            nil,
            nil,
            10,
            nil,
            true
        )
    else
        Mod.WorldShare.MsgBox:Wait()
    end

    local function Handle()
        Mod.WorldShare.MsgBox:Close()

        local width = 660
        local height = 420

        local params = Mod.WorldShare.Utils.ShowWindow({
            url = 'Mod/WorldShare/cellar/WorldExitDialog/Theme/WorldExitDialog.html',
            name = 'Mod.WorldShare.WorldExitDialog',
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            directPosition = true,
            align = '_ct',
            x = -width / 2,
            y = -height / 2,
            width = width,
            height = height,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            enable_esc_key = true,
            zorder = 10
        })

        params._page.OnClose = function()
            Desktop.is_exiting = false
            Mod.WorldShare.Store:Remove('page/Mod.WorldShare.WorldExitDialog')
        end

        local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.WorldExitDialog')

        if WorldExitDialogPage then
            if not GameLogic.IsReadOnly() and not ParaIO.DoesFileExist(self.GetPreviewImagePath(), false) then
                WorldExitDialog.Snapshot()
            end
            WorldExitDialogPage.callback = callback
        end
    end

    if GameLogic.IsReadOnly() then
        if KeepworkServiceSession:IsSignedIn() and System.options.networkNormal then
            if currentEnterWorld.kpProjectId and currentEnterWorld.kpProjectId ~= 0 then
                Grade:IsRated(currentEnterWorld.kpProjectId, function(isRated)
                    self.isRated = isRated
                    Handle()
                end)
            else
                Handle()
            end
        else
            Handle()
        end
    else
        if KeepworkServiceSession:IsSignedIn() and System.options.networkNormal then
            Compare:Init(currentEnterWorld.worldpath, function(result)
                if not result then
                    return
                end

                if currentEnterWorld and
                   currentEnterWorld.kpProjectId and
                   currentEnterWorld.kpProjectId ~= 0 then
                    KeepworkServiceProject:GetProject(currentEnterWorld.kpProjectId, function(data)
                        if data and data.world and data.world.worldName then
                            self.currentWorldKeepworkInfo = data
                        end

                        Grade:IsRated(currentEnterWorld.kpProjectId, function(isRated)
                            self.isRated = isRated
                            Handle()
                        end)
                    end, {0})
    
                    return true
                end
    
                Handle()
            end)
        else
            Mod.WorldShare.Store:Set('world/currentRevision', GameLogic.options:GetRevision())
            Handle()
        end
    end
end

function WorldExitDialog:IsUserWorld()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local userId = Mod.WorldShare.Store:Get('user/userId')

    if currentEnterWorld and
       currentEnterWorld.kpProjectId and
       currentEnterWorld.kpProjectId ~= 0 and
       userId then
        if self.currentWorldKeepworkInfo and
           self.currentWorldKeepworkInfo.userId and
           self.currentWorldKeepworkInfo.userId == userId then
            return true
        else
            return false
        end
    else
        return false
    end
end

function WorldExitDialog.GetPreviewImagePath()
    return ParaWorld.GetWorldDirectory() .. 'preview.jpg'
end

function WorldExitDialog:Refresh(sec)
    local worldExitDialogPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.WorldExitDialog')

    if worldExitDialogPage then
        worldExitDialogPage:Refresh(sec or 0.01)
    end
end

-- @param res: _guihelper.DialogResult
function WorldExitDialog.OnDialogResult(res)
    Desktop.is_exiting = false

    local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.WorldExitDialog')

    if WorldExitDialogPage then
        WorldExitDialogPage:CloseWindow()
    end

    if res == _guihelper.DialogResult.No or res == _guihelper.DialogResult.Yes then
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        local function Handle()
            -- TODO: // check world folder because zip file
            if res == _guihelper.DialogResult.Yes then
                GameLogic.QuickSave()
            end

            local UserMacBindsService = NPL.load('(gl)Mod/WorldShare/service/UserMacBindsService.lua')
            local isBind = UserMacBindsService:IsBindDeviceFromLocal()
            if KeepworkServiceSession:IsSignedIn() or isBind then
                local titlename = GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡 Paracraft")
                local desc = GameLogic.GetFilters():apply_filters('GameDescription', L"3D动画编程创作工具")

                System.options.WindowTitle = string.format("%s -- ver %s", titlename, GameLogic.options.GetClientVersion());
                ParaEngine.SetWindowText(format("%s : %s", System.options.WindowTitle, desc));

                Mod.WorldShare.Store:Set('world/isShowExitPage', true)
                RedSummerCampMainPage.Show()

                Mod.WorldShare.Store:Remove('world/currentWorld')
                Mod.WorldShare.Store:Remove('world/currentEnterWorld')
                Mod.WorldShare.Store:Remove('world/isEnterWorld')

                TouchMiniKeyboard.CheckShow(false)

                return
            end

            if WorldExitDialogPage and WorldExitDialogPage.callback then
                NplBrowserPlugin.CloseAllBrowsers()
                WorldExitDialogPage.callback(res)
            end
        end

        -- unlock share world logic
        if Mod.WorldShare.Utils:IsSharedWorld(currentEnterWorld) then
            Mod.WorldShare.MsgBox:Wait()
            KeepworkServiceWorld:UnlockWorld(function() end)
            -- api error, force exit
            Mod.WorldShare.Utils.SetTimeOut(function()
                Mod.WorldShare.MsgBox:Close()
                Handle()
            end, 1000)
        else
            Handle()
        end

    else
        if WorldExitDialogPage and WorldExitDialogPage.callback then
            WorldExitDialogPage.callback(res)
        end
    end
end

function WorldExitDialog.Snapshot()
    if SnapshotPage.TakeSnapshot(
        ShareWorld:GetPreviewImagePath(),
        300,
        200,
        false
       ) then
        WorldExitDialog.UpdateImage(true)
    end
end

function WorldExitDialog.UpdateImage(bRefreshAsset)
    local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.WorldExitDialog')

    if WorldExitDialogPage then
        local filepath = ShareWorld:GetPreviewImagePath()

        WorldExitDialogPage:SetUIValue('ShareWorldImage', filepath)

        if bRefreshAsset then
            ParaAsset.LoadTexture('', filepath, 1):UnloadAsset()
        end

        -- increase version number
        GameLogic.QuickSave()
    end
end

function WorldExitDialog:CanSetStart()
    if not KeepworkServiceSession:IsSignedIn() then
        LoginModal:Init(function()
            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

            if currentEnterWorld and currentEnterWorld.kpProjectId and currentEnterWorld.kpProjectId ~= 0 then
                KeepworkServiceProject:GetProject(tonumber(currentEnterWorld.kpProjectId), function(data)
                    if data and data.world and data.world.worldName then
                        self.currentWorldKeepworkInfo = data
                    end

                    Grade:IsRated(currentEnterWorld.kpProjectId, function(isRated)
                        self.isRated = isRated
                        self:Refresh()
                    end)
                end)
            end
        end)

        return false
    end

    return true
end
