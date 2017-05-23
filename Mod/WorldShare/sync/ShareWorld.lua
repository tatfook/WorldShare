--[[
Title: share world to datasource
Author(s): big
Date: 2017.5.12
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");
ShareWorld.ShowPage()
-------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
NPL.load("(gl)Mod/WorldShare/login/loginMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local SyncMain       = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
local loginMain		 = commonlib.gettable("Mod.WorldShare.login.loginMain");
local WorldCommon    = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local ShareWorld     = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.sync.ShareWorld"));

ShareWorld.SharePage = nil

function ShareWorld:ctor()

end

function ShareWorld.ShowPage()
	if(loginMain.login_type == 1) then
		loginMain.showLoginModalImp();
		return;
	elseif(loginMain.login_type == 3) then
		ShareWorld.shareCompare();
	end
end

function ShareWorld.ShowPageImp()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "Mod/WorldShare/sync/ShareWorld.html",
		name = "SaveWorldPage.ShowSharePage",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		isTopLevel = true,
		directPosition = true,
			align = "_ct",
			x = -500/2,
			y = -400/2,
			width = 500,
			height = 400,
	});
end

function ShareWorld:init()
	local filepath = SyncMain.worldDir.default .. "preview.jpg";
	--LOG.std(nil,"debug","filepath",filepath);
	ShareWorld.SharePage:SetNodeValue("ShareWorldImage", filepath);

	ShareWorld.SharePage:Refresh();
end

function ShareWorld.setSharePage()
	ShareWorld.SharePage = document:GetPageCtrl();
end

function ShareWorld.closeSharePage()
	ShareWorld.SharePage:CloseWindow();
end

function ShareWorld.getWorldSize()
	SyncMain.tagInfor = WorldCommon.GetWorldInfo();
	LOG.std(nil,"debug","SyncMain.tagInfor",SyncMain.tagInfor);

	return SyncMain.tagInfor.size;
end

function ShareWorld.shareCompare()
	SyncMain:compareRevision(nil, function(result)
		if(result and result == "tryAgain") then
			ShareWorld.shareCompare();
		elseif(result == "zip") then
			return;
		elseif(result) then
			ShareWorld.ShowPageImp();
			ShareWorld.CompareResult = result;
			ShareWorld.SharePage:Refresh();
			ShareWorld:init();
		else
			ShareWorld.SharePage:CloseWindow();
		end
	end);
end

function ShareWorld.shareNow()
	ShareWorld.SharePage:CloseWindow();

	LOG.std(nil,"debug","ShareWorld.CompareResult", ShareWorld.CompareResult);

    if(ShareWorld.CompareResult == "remoteBigger") then
        _guihelper.MessageBox("当前本地版本小于远程版本，是否继续上传？", function(res)
            if(res and res == 6) then
                SyncMain:syncToDataSource();
            end
        end);
    elseif(ShareWorld.CompareResult == "localBigger" or ShareWorld.CompareResult == "justLocal" or ShareWorld.CompareResult == "equal") then
        SyncMain:syncToDataSource();
	end
end

function ShareWorld.snapshot()
	ShareWorldPage.TakeSharePageImage();
	ShareWorld.UpdateImage(true)
end

function ShareWorld.UpdateImage(bRefreshAsset)
	if(ShareWorld.SharePage) then
		local filepath = ShareWorldPage.GetPreviewImagePath();
		ShareWorld.SharePage:SetUIValue("ShareWorldImage", filepath);
		if(bRefreshAsset) then
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end
	end
end

function ShareWorld.getWorldUrl(bEncode)
	if(loginMain.login_type == 1) then
		return "";
	end

	local foldername;

	if(bEncode) then
		foldername = commonlib.Encoding.url_encode("world_" .. SyncMain.foldername.utf8);
	else
		foldername = SyncMain.foldername.utf8;
	end

	local url = loginMain.site .. "/" .. loginMain.username .. "/paracraft/" .. foldername;
	return url;
end

function ShareWorld.openWorldWebPage()
	local url = ShareWorld.getWorldUrl(true);
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

