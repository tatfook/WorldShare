--[[
Title: World Exit Dialog
Author(s):  Big, LiXizhi
Date: 2017/5/15
Desc: 
use the lib:
------------------------------------------------------------
local WorldExitDialog = NPL.load("(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua")
WorldExitDialog.ShowPage();
------------------------------------------------------------
]]
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local WorldExitDialog = NPL.export()
local self = WorldExitDialog;

-- @param callback: function(res) end.
function WorldExitDialog.ShowPage(callback)
    local params = Utils:ShowWindow(500, 320, "Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.html", "WorldExitDialog")

    params._page.OnClose = function()
        Store:Remove('page/WorldExitDialog')
    end

    local WorldExitDialogPage = Store:Get('page/WorldExitDialog')
    if(WorldExitDialogPage) then
        if(not GameLogic.IsReadOnly() and not ParaIO.DoesFileExist(self.GetPreviewImagePath(), false)) then
            WorldExitDialog.Snapshot()
        end
        WorldExitDialogPage.callback = callback
    end
end

function WorldExitDialog.GetPreviewImagePath()
    return ParaWorld.GetWorldDirectory() .. "preview.jpg"
end

function WorldExitDialog:OnInit()
    local WorldExitDialogPage = document:GetPageCtrl()

    Store:Set('page/WorldExitDialog', WorldExitDialogPage)

    WorldExitDialogPage:SetNodeValue("ShareWorldImage", self.GetPreviewImagePath())
end

-- @param res: _guihelper.DialogResult
function WorldExitDialog.OnDialogResult(res)
    local WorldExitDialogPage = Store:Get('page/WorldExitDialog')

    if (WorldExitDialogPage) then
        WorldExitDialogPage:CloseWindow()
    end

    if (WorldExitDialogPage.callback) then
        WorldExitDialogPage.callback(res)
    end
end

function WorldExitDialog.Snapshot()
    ShareWorldPage.TakeSharePageImage()
    WorldExitDialog.UpdateImage(true)
end

function WorldExitDialog.UpdateImage(bRefreshAsset)
    local WorldExitDialogPage = Store:Get('page/WorldExitDialog')

    if (WorldExitDialogPage) then
        local filepath = ShareWorldPage.GetPreviewImagePath()
        WorldExitDialogPage:SetUIValue("ShareWorldImage", filepath)

        if (bRefreshAsset) then
            ParaAsset.LoadTexture("", filepath, 1):UnloadAsset()
        end
    end
end
