--[[
Title: World Exit Dialog
Author(s):  Big, LiXizhi
Date: 2017/5/15
Desc: 
use the lib:
------------------------------------------------------------
local WorldExitDialog = NPL.load("(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua")
WorldExitDialog.ShowPage()
------------------------------------------------------------
]]

-- lib
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")

-- service
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")

-- UI
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local Grade = NPL.load("./Grade.lua")

local WorldExitDialog = NPL.export()
local self = WorldExitDialog

-- show exit world dialog page
-- @param callback: function(res) end.
-- @return void or boolean
function WorldExitDialog.ShowPage(callback)
    UserConsole:ClosePage()

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...")

    local function Handle()
        Mod.WorldShare.MsgBox:Close()

        local width = 660
        local height = 420

        local params = Mod.WorldShare.Utils.ShowWindow({
            url = "Mod/WorldShare/cellar/Theme/WorldExitDialog/WorldExitDialog.html",
            name = "WorldExitDialog",
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            directPosition = true,
            align = "_ct",
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
            Mod.WorldShare.Store:Remove('page/WorldExitDialog')
        end

        local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/WorldExitDialog')

        if WorldExitDialogPage then
            if not GameLogic.IsReadOnly() and not ParaIO.DoesFileExist(self.GetPreviewImagePath(), false) then
                WorldExitDialog.Snapshot()
            end
            WorldExitDialogPage.callback = callback
        end
    end

    if GameLogic.IsReadOnly() then
        if KeepworkService:IsSignedIn() then
            if currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
                Grade:IsRated(currentWorld.kpProjectId, function(isRated)
                    self.isRated = isRated
                    Handle()
                end)

                return true
            end

            Handle()
        else
            Handle()
        end
    else
        if KeepworkService:IsSignedIn() then
            Compare:Init(currentWorld.worldpath, function(result)
                if not result then
                    return false
                end

                if currentWorld and currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
                    KeepworkServiceProject:GetProject(currentWorld.kpProjectId, function(data)
                        if data and data.world and data.world.worldName then
                            self.currentWorldKeepworkInfo = data
                        end

                        Grade:IsRated(currentWorld.kpProjectId, function(isRated)
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
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local userId = Mod.WorldShare.Store:Get('user/userId')

    if currentWorld and currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 and userId then
        if self.currentWorldKeepworkInfo and self.currentWorldKeepworkInfo.userId and self.currentWorldKeepworkInfo.userId == userId then
            return true
        else
            return false
        end
    else
        return false
    end
end

function WorldExitDialog.GetPreviewImagePath()
    return ParaWorld.GetWorldDirectory() .. "preview.jpg"
end

function WorldExitDialog:OnInit()
    Mod.WorldShare.Store:Set('page/WorldExitDialog', document:GetPageCtrl())

    document:GetPageCtrl():SetNodeValue("ShareWorldImage", self.GetPreviewImagePath())
end

function WorldExitDialog:Refresh(sec)
    local worldExitDialogPage = Mod.WorldShare.Store:Get('page/WorldExitDialog')

    if worldExitDialogPage then
        worldExitDialogPage:Refresh(sec or 0.01)
    end
end

-- @param res: _guihelper.DialogResult
function WorldExitDialog.OnDialogResult(res)
    local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/WorldExitDialog')

    if (WorldExitDialogPage) then
        WorldExitDialogPage:CloseWindow()
    end

    if res == _guihelper.DialogResult.No or res == _guihelper.DialogResult.Yes then
        local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

        if Mod.WorldShare.Utils:IsSharedWorld(currentEnterWorld) then
            Mod.WorldShare.MsgBox:Show(L"请稍候...")
            KeepworkServiceWorld:UnlockWorld(function()
                if WorldExitDialogPage.callback then
                    NplBrowserPlugin.CloseAllBrowsers()
                    WorldExitDialogPage.callback(res)
                end
            end)
        else
            if WorldExitDialogPage.callback then
                NplBrowserPlugin.CloseAllBrowsers()
                WorldExitDialogPage.callback(res)
            end
        end

    else
        if WorldExitDialogPage.callback then
            WorldExitDialogPage.callback(res)
        end
    end
end

function WorldExitDialog.Snapshot()
    ShareWorldPage.TakeSharePageImage()
    WorldExitDialog.UpdateImage(true)
end

function WorldExitDialog.UpdateImage(bRefreshAsset)
    local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/WorldExitDialog')

    if WorldExitDialogPage then
        local filepath = ShareWorldPage.GetPreviewImagePath()

        WorldExitDialogPage:SetUIValue("ShareWorldImage", filepath)

        if bRefreshAsset then
            ParaAsset.LoadTexture("", filepath, 1):UnloadAsset()
        end
    end
end

function WorldExitDialog:CanSetStart()
    if not KeepworkService:IsSignedIn() then
        LoginModal:Init(function()
            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

            if currentWorld and currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
                KeepworkServiceProject:GetProject(tonumber(currentWorld.kpProjectId), function(data)
                    if data and data.world and data.world.worldName then
                        self.currentWorldKeepworkInfo = data
                    end

                    Grade:IsRated(currentWorld.kpProjectId, function(isRated)
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
