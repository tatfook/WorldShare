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
local WorldExitDialog = commonlib.gettable("Mod.WorldShare.login.WorldExitDialog");

-- @param callback: function(res) end. 
function WorldExitDialog.ShowPage(callback)
	WorldExitDialog.callback = callback;

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/WorldShare/login/WorldExitDialog.html",
			name = "Mod.WorldShare.WorldExitDialog",
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -500/2,
				y = -320/2,
				width = 500,
				height = 320,
		});
end

function WorldExitDialog.GetPreviewImagePath()
	return ParaWorld.GetWorldDirectory().."preview.jpg";
end

function WorldExitDialog:OnInit()
	WorldExitDialog.page = document:GetPageCtrl();
	WorldExitDialog.page:SetNodeValue("ShareWorldImage", WorldExitDialog.GetPreviewImagePath());
end

-- @param res: _guihelper.DialogResult
function WorldExitDialog.OnDialogResult(res)
	if(WorldExitDialog.page) then
		WorldExitDialog.page:CloseWindow();
	end
	if(WorldExitDialog.callback) then
		WorldExitDialog.callback(res);
	end
end