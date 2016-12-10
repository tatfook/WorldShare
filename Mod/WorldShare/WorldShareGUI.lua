--[[
Title: BigGUI
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/WorldShareGUI.lua");
local WorldShareGUI = commonlib.gettable("Mod.WorldShare.WorldShareGUI");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");

local WorldShareGUI = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareGUI"));
local WorldCommon   = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local ShowLogin     = commonlib.gettable("Mod.WorldShare.ShowLogin");

WorldShareGUI.githubApi = "https://api.github.com/";

function WorldShareGUI:ctor()
end

function WorldShareGUI:init()
	Page = document:GetPageCtrl();
	LOG.std(nil, "debug", "WorldShareGUI", "init");
end

function WorldShareGUI:StartSyncPage()	
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/StartSync.html", 
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

	LOG.std(nil, "debug", "WorldShareGUI", "WorldShareGUI ShowLogin");
end

function WorldShareGUI:HideLogin()
	self.page:Close();
	LOG.std(nil, "debug", "WorldShareGUI", "WorldShareGUI HideLogin");
end

function WorldShareGUI:OnLogin()
	LOG.std(nil, "debug", "WorldShareGUI", "WorldShareGUI Login");
end

function WorldShareGUI:OnWorldLoad()
	local getWorldInfo = WorldCommon:GetWorldInfo();
	local worldDir     = GameLogic.GetWorldDirectory();
	local xmlRevison   = WorldRevision:new():init(worldDir);

	LOG.std(nil,"debug","getWorldInfo",getWorldInfo);
	LOG.std(nil,"debug","worldDir",worldDir);
	LOG.std(nil,"debug","revison",xmlRevison);

	if(ShowLogin.login) then --如果为登陆状态 则比较版本
		local foldername = worldDir:match("worlds/DesignHouse/(%w+)/");

		self.currentRevison = xmlRevison["current_revision"];
		self.githubRevison  = 0;

		self:getFileShaList(foldername,function(err, msg, data)
			local tree = data["tree"];
			for key,value in ipairs(tree) do
				if(value["path"] == "revision.xml" and value["type"] == "blob") then
					local contentUrl = "https://raw.githubusercontent.com/".. ShowLogin.login .."/".. foldername .."/master/revision.xml";
					self:githubApiGet(contentUrl,function(err,msg,data)
						self.githubRevison = data;
						Page:Refresh(0.01);
					end)
				end
			end
		end);

		if(self.currentRevison ~= self.githubRevison) then
			self:StartSyncPage();
		end
	end
end

function WorldShareGUI:OnLeaveWorld()
end

function WorldShareGUI:OnInitDesktop()
end

function WorldShareGUI:handleKeyEvent(event)
	if(event.keyname == "DIK_SPACE") then
		_guihelper.MessageBox("you pressed "..event.keyname.." from Demo GUI");
		return true;
	end
end

function WorldShareGUI:useLocal()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/StartSyncUseLocal.html", 
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

function WorldShareGUI:useGithub()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/StartSyncUseGithub.html", 
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

function WorldShareGUI:getFileShaList(_foldername, _callback)
	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/git/trees/master?recursive=1";

	self:githubApiGet(url,_callback);
end

function WorldShareGUI:getAllresponse(_callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "user/repos?access_token=" .. github_token["access_token"] .. "&type=owner";

    self:githubApiGet(url,_callback);
end

function WorldShareGUI:githubApiGet(_url,_callback)
	local github_token = ShowLogin.github_token;

	System.os.GetUrl({url = _url,
					  json = true,
					  headers = {Authorization  = github_token["token_type"].." "..github_token["access_token"],
								 ["User-Agent"] = "npl"}
					 },_callback);
end
