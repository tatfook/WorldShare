--[[
Title: SyncGUI
Author(s):  big
Date: 	2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua");
local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/SyncMain.lua");

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local SyncGUI = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.sync.SyncGUI"));

local Page;

SyncGUI.current = 0;
SyncGUI.total   = 0;
SyncGUI.files   = "";
SyncGUI.isStart = false;

function SyncGUI:ctor()
	SyncGUI.current = 0;
	SyncGUI.total   = 0;
	SyncGUI.files   = "同步中，请稍后...";
	SyncGUI.isStart = true;

	SyncMain.curUpdateIndex        = 1;
	SyncMain.curUploadIndex        = 1;
	SyncMain.totalLocalIndex       = nil;
	SyncMain.totalDataSourceIndex  = nil;
	SyncMain.dataSourceFiles       = {};

	SyncMain.curDownloadIndex      = 1;
	SyncMain.dataSourceIndex       = 0;

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/SyncGUI.html", 
		name = "SyncWorldShare", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 0,
		allowDrag = true,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -500/2,
			y = -270/2,
			width = 500,
			height = 270,
		cancelShowAnimation = true,
	});
end

function SyncGUI:OnInit()
	Page = document:GetPageCtrl();
	self.progressbar = Page:GetNode("progressbar");
end

function SyncGUI.finish()
	SyncGUI.isStart = false;
	Page:CloseWindow();
end

function SyncGUI:retry()
	if(not SyncMain.finish) then
		_guihelper.MessageBox(L"同步尚未结束");
		return;
	end

	SyncGUI.finish();
	SyncMain:compareRevision();
	SyncMain:StartSyncPage();
end

function SyncGUI:updateDataBar(_current, _total, _files)
	local databar = Page:GetNode("databar");
	
	SyncGUI.current  = _current;
	SyncGUI.total    = _total;

	if(_files)then
		SyncGUI.files = _files;
	else
		SyncGUI.files = "同步中，请稍后...";
	end

	SyncGUI.progressbar:SetAttribute("Maximum",SyncGUI.total);
	SyncGUI.progressbar:SetAttribute("Value",SyncGUI.current);

	Page:Refresh(0.01);
end

