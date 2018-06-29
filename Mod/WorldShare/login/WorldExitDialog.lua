--[[
Title: World Exit Dialog
Author(s):  LiXizhi
Date: 2017/5/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/WorldExitDialog.lua");
local WorldExitDialog = commonlib.gettable("Mod.WorldShare.login.WorldExitDialog");
WorldExitDialog.ShowPage();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local WorldExitDialog = commonlib.gettable("Mod.WorldShare.login.WorldExitDialog")

local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")

-- @param callback: function(res) end.
function WorldExitDialog.ShowPage(callback)
    WorldExitDialog.callback = callback

    Utils:ShowWindow(500, 320, "Mod/WorldShare/login/WorldExitDialog.html", "Mod.WorldShare.WorldExitDialog")
end

function WorldExitDialog.GetPreviewImagePath()
    return ParaWorld.GetWorldDirectory() .. "preview.jpg"
end

function WorldExitDialog:OnInit()
    WorldExitDialog.page = document:GetPageCtrl()
    WorldExitDialog.page:SetNodeValue("ShareWorldImage", WorldExitDialog.GetPreviewImagePath())
end

-- @param res: _guihelper.DialogResult
function WorldExitDialog.OnDialogResult(res)
    if (WorldExitDialog.page) then
        WorldExitDialog.page:CloseWindow()
    end
    if (WorldExitDialog.callback) then
        WorldExitDialog.callback(res)
    end
end

function WorldExitDialog.snapshot()
    ShareWorldPage.TakeSharePageImage()
    WorldExitDialog.UpdateImage(true)
end

function WorldExitDialog.UpdateImage(bRefreshAsset)
    if (WorldExitDialog.page) then
        local filepath = ShareWorldPage.GetPreviewImagePath()
        WorldExitDialog.page:SetUIValue("ShareWorldImage", filepath)

        if (bRefreshAsset) then
            ParaAsset.LoadTexture("", filepath, 1):UnloadAsset()
        end
    end
end
