--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/SyncMain.lua");
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)Mod/WorldShare/login.lua");
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua");
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua");
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua");

local SyncGUI            = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
local WorldCommon        = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MainLogin		     = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local login              = commonlib.gettable("Mod.WorldShare.login");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local LocalService       = commonlib.gettable("Mod.WorldShare.service.LocalService");
local HttpRequest		 = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local Encoding           = commonlib.gettable("commonlib.Encoding");
local EncodingS          = commonlib.gettable("System.Encoding");
local GitEncoding        = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local CommandManager     = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local SaveWorldPage      = commonlib.gettable("MyCompany.Aries.Creator.SaveWorldPage")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local Page;

function SyncMain:ctor()
end

function SyncMain:init()
	LOG.std(nil, "debug", "SyncMain", "init");

	-- 没有登陆则直接使用离线模式
	if(login.token) then
		SyncMain:compareRevision();
		SyncMain:StartSyncPage();
	end

	GameLogic.GetFilters():add_filter("SaveWorldPage.ShowSharePage",function (bEnable)
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
				y = -270/2,
				width = 500,
				height = 270,
		});

		return false;
	end);
end

function SyncMain.setPage()
	Page = document:GetPageCtrl();
end

function SyncMain:StartSyncPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/StartSync.html", 
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

function SyncMain:compareRevision()
	if(login.token) then
		SyncMain.getWorldInfo = WorldCommon:GetWorldInfo();
		SyncMain.worldDir     = GameLogic.GetWorldDirectory();
		--LOG.std(nil,"debug","worldinfo",self.getWorldInfo);
		--LOG.std(nil,"debug","self.worldDir",self.worldDir);
		echo(WorldRevision,true);
		WorldRevisionCheckOut   = WorldRevision:new():init(SyncMain.worldDir);
		SyncMain.currentRevison = WorldRevisionCheckOut:Checkout();

		SyncMain.foldername = SyncMain.worldDir:match("worlds/DesignHouse/([^/]*)/");
		SyncMain.foldername = Encoding.DefaultToUtf8(SyncMain.foldername);
		SyncMain.localFiles = LocalService:LoadFiles(SyncMain.worldDir,"",nil,1000,nil);

		--LOG.std(nil,"debug","self.foldername",self.foldername);
		--LOG.std(nil,"debug","self.localFiles",self.localFiles);

		local hasRevision = false;
		for key,value in ipairs(SyncMain.localFiles) do
			--LOG.std(nil,"debug","filename",value.filename);
			if(value.filename == "revision.xml") then
				hasRevision = true;
				break;
			end
		end

		if(hasRevision) then
			local contentUrl;
			if(login.dataSourceType == 'github') then
				contentUrl = login.rawBaseUrl .. "/" .. login.dataSourceUsername .. "/" .. GitEncoding.base64(SyncMain.foldername) .. "/master/revision.xml";
			elseif(login.dataSourceType == 'gitlab') then
				contentUrl = login.rawBaseUrl .. "/" .. login.dataSourceUsername .. "/" .. GitEncoding.base64(SyncMain.foldername) .. "/blob/master/revision.xml";
			end

			SyncMain.remoteRevison = 0;

			--LOG.std(nil,"debug","contentUrl",contentUrl);

			HttpRequest:GetUrl(contentUrl, function(data,err)
				--LOG.std(nil,"debug","HttpRequest",err);

				if(err == 404 or err == 401) then
					Page:CloseWindow();
					SyncMain.firstCreate = 1;
					_guihelper.MessageBox(L"Github上暂无数据，请先分享世界");

					SaveWorldPage.ShowSharePage();
					return
				end

				SyncMain.remoteRevison = data;

				-- LOG.std(nil,"debug","self.githubRevison",self.githubRevison);

				if(tonumber(SyncMain.currentRevison) ~= tonumber(SyncMain.remoteRevison)) then
					Page:Refresh();
				else
					_guihelper.MessageBox(L"远程本地相等")
					Page:CloseWindow();
				end
			end);
		else
			commonlib.TimerManager.SetTimeout(function() 
				Page:CloseWindow();

				CommandManager:RunCommand("/save");
				SyncMain:compareRevision();
				SyncMain:StartSyncPage();
			end, 500)
		end
	end
end

function SyncMain.deleteWorld()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/DeleteWorld.html",
		name = "DeleteWorld", 
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

function SyncMain.deleteWorldLocal(_callback)
	local world = InternetLoadWorld:GetCurrentWorld();

	if(not world) then
		_guihelper.MessageBox(L"请先选择世界");
		return;
	end

	_guihelper.MessageBox(format(L"确定删除本地世界:%s?", world.text or ""), function(res)
		--LOG.std(nil, "info", "InternetLoadWorld", "ask to delete world %s", world.text or "");

		if(res and res == _guihelper.DialogResult.Yes) then
			if(world.RemoveLocalFile and world:RemoveLocalFile()) then
				InternetLoadWorld.RefreshAll();
			elseif(world.remotefile) then
				-- local world, delete all files in folder and the folder itself.
				local targetDir = world.remotefile:gsub("^local://", "");

				if(GameLogic.RemoveWorldFileWatcher) then
					-- file watcher may make folder deletion of current world directory not working. 
					GameLogic.RemoveWorldFileWatcher();
				end

				if(commonlib.Files.DeleteFolder(targetDir)) then  
					LOG.std(nil, "info", "LocalLoadWorld", "world dir deleted: %s ", targetDir);
					-- InternetLoadWorld.RefreshCurrentServerList();
					local foldername = targetDir:match("worlds/DesignHouse/(%w+)");

					login.handleCur_ds = {};
					local hasGithub    = false;
					for key,value in ipairs(InternetLoadWorld.cur_ds) do
						if(value.foldername == foldername and value.status == 3 or value.status == 4 or value.status == 5) then
							LOG.std(nil,"debug","value.status",value.status);
							value.status = 2;
							hasGithub = true;
						end

						if(value.foldername ~= foldername) then
							login.handleCur_ds[#login.handleCur_ds+1] = value;
						end
					end

					if(not hasGithub)then
						InternetLoadWorld.cur_ds = login.handleCur_ds;
					end

					if(type(_callback) == 'function') then
						_callback(foldername);
					else
						Page:CloseWindow();

	                    if(not WorldCommon.GetWorldInfo()) then
	                        MainLogin.state.IsLoadMainWorldRequested = nil;
	                        MainLogin:next_step();
	                    end
					end
				else
					_guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
				end
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function SyncMain.deleteWorldGithubLogin()
	-- LOG.std(nil,"debug","login.selectedWorldInfor",login.selectedWorldInfor);

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/DeleteWorldLogin.html", 
		name = "DeleteWorldLogin", 
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

function SyncMain.deleteWorldGithub(_password)
	local foldername = login.selectedWorldInfor.foldername;

	local AuthUrl    = "https://api.github.com/authorizations";
	local AuthParams = '{"scopes":["delete_repo"], "note":"' .. ParaGlobal.timeGetTime() .. '"}';
	local basicAuth  = login.login .. ":" .. _password;
	local AuthToken  = "";

	basicAuth = Encoding.base64(basicAuth);

	LOG.std(nil,"debug","basicAuth",basicAuth);

	GithubService:GetUrl({
		url        = AuthUrl,
		headers    = {
						Authorization  = "Basic " .. basicAuth,
						["User-Agent"]   = "npl",
				        ["content-type"] = "application/json"
			         },
		postfields = AuthParams
    },function(data,err)
    	LOG.std(nil,"debug","GetUrl",data);
    	local basicAuthData = data;

    	AuthToken = basicAuthData.token;

	    _guihelper.MessageBox(format(L"确定删除远程世界:%s?", foldername or ""), function(res)
	    	Page:CloseWindow();
	    	LOG.std(nil,"debug","res and res == _guihelper.DialogResult.Yes",res);
	    	LOG.std(nil,"debug","self.deleteFolderName",foldername);

	    	if(res and res == 6) then
	    		GithubService:deleteResp(foldername, AuthToken,function(data,err)
	    			LOG.std(nil,"debug","GithubService:deleteResp",err);

	    			if(err == 204) then
	    				GithubService:GetUrl({
							method  = "DELETE",
							url     = login.site.."/api/mod/WorldShare/models/worlds/",
							form    = {
								worldsName = login.selectedWorldInfor.foldername,
							},
							json    = true,
							headers = {Authorization = "Bearer "..login.token}
						},function(data,err)

							login.handleCur_ds = {};
							local hasLocal    = false;
							for key,value in ipairs(InternetLoadWorld.cur_ds) do
								if(value.foldername == foldername and value.status == 3 or value.status == 4 or value.status == 5) then
									LOG.std(nil,"debug","value.status",value.status);
									value.status = 1;
									hasLocal = true;
								end

								if(value.foldername ~= foldername) then
									login.handleCur_ds[#login.handleCur_ds+1] = value;
								end
							end

							if(not hasLocal)then
								InternetLoadWorld.cur_ds = login.handleCur_ds;
							end

			    			Page:CloseWindow();

				            NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
				            local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");

				            if(not WorldCommon.GetWorldInfo()) then
				                MainLogin.state.IsLoadMainWorldRequested = nil;
				                MainLogin:next_step();
				            end
						end);
			        else
			        	_guihelper.MessageBox(L"远程删除失败");

	    			end
	    		end)
	    	end
	    end);
	end)
end

function SyncMain.deleteWorldAll()
	login.deleteWorldLocal(function()
		login.deleteWorldGithubLogin();
	end);
end

function SyncMain.goBack()
    Page:CloseWindow();

    if(not WorldCommon.GetWorldInfo()) then
        MainLogin.state.IsLoadMainWorldRequested = nil;
        MainLogin:next_step();
    end
end

function SyncMain.shareWorld()
	SyncMain.remoteRevison = 0;

    if(SyncMain.firstCreate ~= 1) then
        SyncMain:compareRevision();
    end
end

function SyncMain.shareNow()
    Page:CloseWindow();

    if(SyncMain.firstCreate ~= 1 and tonumber(SyncMain.currentRevison) < tonumber(SyncMain.remoteRevison)) then
        _guihelper.MessageBox("当前本地版本小于远程版本，是否继续上传？", function(res)
            if(res and res == 6) then
                SyncMain:syncToDataSource();
            end
        end);
    elseif(tonumber(SyncMain.currentRevison) > tonumber(SyncMain.remoteRevison)) then
        SyncMain:syncToDataSource();
    end
end

function SyncMain.useLocal()
    Page:CloseWindow();

    if(tonumber(SyncMain.currentRevison) < tonumber(SyncMain.githubRevison)) then
        SyncMain:useLocal();
    elseif(tonumber(SyncMain.currentRevison) > tonumber(SyncMain.githubRevison)) then
        -- _guihelper.MessageBox("开始同步--将本地大小有变化的文件上传到github"); -- 上传或更新
        SyncMain:syncToGithub();
    end
end

function SyncMain.useGithub()
    Page:CloseWindow();

    if(tonumber(SyncMain.githubRevison) < tonumber(SyncMain.currentRevison)) then
        SyncMain:useGithub();
    elseif(tonumber(SyncMain.githubRevison) > tonumber(SyncMain.currentRevison)) then
        -- _guihelper.MessageBox("开始同步--将github大小有变化的文件下载到本地");-- 下载或覆盖
        SyncMain:syncToLocal();
    end
end

function SyncMain.useOffline()
    Page:CloseWindow();
end

function SyncMain:useLocalGUI()
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

function SyncMain:useGithubGUI()
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

function SyncMain:syncToLocal(_worldDir, _foldername, _callback)
	-- LOG.std(nil,"debug","worldDir",_worldDir);

	-- 加载进度UI界面
	local syncToLocalGUI = SyncGUI:new();

	if(_worldDir) then
		self.worldDir   = _worldDir;
		self.foldername = _foldername;
	end

	self.localFiles = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);

	if (self.worldDir == "") then
		_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
		return;
	else 
		local curUpdateIndex    = 1;
		local curDownloadIndex  = 1;
		local totalLocalIndex   = nil;
		local totalGithubIndex  = nil;
		local githubFiles       = {};
		local syncGUItotal      = 0;
		local syncGUIIndex      = 0;
		local syncGUIFiles      = "";

		-- LOG.std(nil,"debug","WorldShareGUI",curDownloadIndex);
		-- LOG.std(nil,"debug","WorldShareGUI",totalGithubIndex);

		-- 下载新文件
		local function downloadOne()
			if (curDownloadIndex <= totalGithubIndex) then

				-- LOG.std(nil,"debug","githubFiles.tree[curDownloadIndex]",githubFiles.tree[curDownloadIndex]);
				-- LOG.std(nil,"debug","curDownloadIndex",curDownloadIndex);

				if (githubFiles.tree[curDownloadIndex].needChange) then
					if(githubFiles.tree[curDownloadIndex].type == "blob") then
						-- LOG.std(nil,"debug","githubFiles.tree[curDownloadIndex].type",githubFiles.tree[curDownloadIndex].type);
						LocalService:download(self.foldername, githubFiles.tree[curDownloadIndex].path, function (bIsDownload,response)
							if (bIsDownload) then

								syncGUIIndex = syncGUIIndex + 1;
								-- syncGUIFiles = githubFiles.tree[curDownloadIndex].path;

								if(response.filename == "revision.xml") then
									self.githubRevison = response.content;
								end

								if(syncGUIIndex == syncGUItotal) then
									finish();
								end

								syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);
							else
								_guihelper.MessageBox(self.localFiles[curDownloadIndex].filename .. ' 下载失败，请稍后再试');
							end
						end);
					end

					curDownloadIndex = curDownloadIndex + 1;
				else
					curDownloadIndex = curDownloadIndex + 1;
				end

				if (curDownloadIndex > totalGithubIndex) then
					-- 同步完成
					if(syncGUIIndex == syncGUItotal) then
						finish();
					end
				else
					downloadOne(); --继续递归上传
				end
			end
		end

		-- 更新本地文件
		local function updateOne()
			if (curUpdateIndex <= totalLocalIndex) then
				LOG.std(nil,"debug","curUpdateIndex",curUpdateIndex);
				local bIsExisted  = false;
				local githubIndex = nil;

				-- 用Gihub的文件和本地的文件对比
				for key,value in ipairs(githubFiles.tree) do
					if(value.path == self.localFiles[curUpdateIndex].filename) then
						LOG.std(nil,"debug","value.path",value.path);
						bIsExisted  = true;
						githubIndex = key; 
						break;
					end
				end

				-- 本地是否存在Github上的文件
				if (bIsExisted) then
					githubFiles.tree[githubIndex].needChange = false;
					-- LOG.std(nil,"debug","self.localFiles[curUpdateIndex].filename",self.localFiles[curUpdateIndex].filename);
					-- LOG.std(nil,"debug","self.localFiles[curUpdateIndex].sha1",self.localFiles[curUpdateIndex].sha1);
					-- LOG.std(nil,"debug","githubFiles.tree[githubIndex].sha",githubFiles.tree[githubIndex].sha);

					if (self.localFiles[curUpdateIndex].sha1 ~= githubFiles.tree[githubIndex].sha) then
						-- 更新已存在的文件
						LocalService:update(self.foldername, githubFiles.tree[githubIndex].path, function (bIsUpdate,response)
							if (bIsUpdate) then
								curUpdateIndex = curUpdateIndex + 1;

								syncGUIIndex   = syncGUIIndex   + 1;
								-- syncGUIFiles   = githubFiles.tree[githubIndex].path;
								-- LOG.std(nil,"debug","syncGUIIndex",syncGUIIndex);

								if(response.filename == "revision.xml") then
									self.githubRevison = response.content;
								end

								SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

								-- 如果当前计数大于最大计数则更新
								if (curUpdateIndex > totalLocalIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
									-- _guihelper.MessageBox(L'同步完成-A');
									downloadOne();
								else
									updateOne();
								end
							else
								_guihelper.MessageBox(githubFiles.tree[githubIndex].path .. ' 更新失败,请稍后再试');
							end
						end);
					else
						-- if file exised, and has same sha value, then contain it
						-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 文件更新完成' .. (curUpdateIndex + 1) .. '/' .. totalLocalIndex);
						curUpdateIndex = curUpdateIndex + 1;

						syncGUIIndex   = syncGUIIndex   + 1;
						-- syncGUIFiles   = githubFiles.tree[githubIndex].path;

						LOG.std(nil,"debug","syncGUIIndex",syncGUIIndex);
						-- LOG.std(nil,"debug","githubFiles.tree[githubIndex].path",githubFiles.tree[githubIndex].path);

						syncToLocalGUI:updateDataBar(syncGUIIndex,syncGUItotal, syncGUIFiles);

						if (curUpdateIndex > totalLocalIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
							-- _guihelper.MessageBox(L'同步完成-B');
							downloadOne();
						else
							updateOne();
						end
					end
				else
					LOG.std(nil,"debug","delete-filename",self.localFiles[curUpdateIndex].filename);
					LOG.std(nil,"debug","delete-sha1",self.localFiles[curUpdateIndex].sha1);

					-- 如果过github不删除存在，则删除本地的文件
					deleteOne();
				end
			end
		end

		-- 删除文件
		local function deleteOne()
			LocalService:delete(self.foldername, self.localFiles[curUpdateIndex].filename, function (bIsDelete)
				if (bIsDelete) then
					curUpdateIndex = curUpdateIndex + 1;

					if (curUpdateIndex > totalLocalIndex) then
						downloadOne();
					else
						updateOne();
					end
				else
					_guihelper.MessageBox('删除 ' .. self.localFiles[curUpdateIndex].filename .. ' 失败, 请稍后再试');
				end
			end);
		end

		local function finish()

			--成功是返回信息给login
			if(_callback) then
				_callback(true,self.githubRevison);
			end
		end

		-- 获取github仓文件
		GithubService:getFileShaList(self.foldername, function(data, err)
			if(err ~= 404) then
				if(err == 409) then
					syncToLocalGUI:updateDataBar(-1,-1);
					_guihelper.MessageBox(L"Github上暂无数据");
				end

				LOG.std(nil,"debug","syncToLocal",data);

				githubFiles = data;

				totalLocalIndex  = #self.localFiles;
				totalGithubIndex = #githubFiles.tree;

				for i=1,#githubFiles.tree do
					githubFiles.tree[i].needChange = true;

					if(githubFiles.tree[i].type == "blob") then
						syncGUItotal = syncGUItotal + 1;
					end

					i = i + 1;
				end

				syncToLocalGUI:updateDataBar(syncGUIIndex,syncGUItotal);

				LOG.std(nil,"debug","totalLocalIndex",totalLocalIndex);
				LOG.std(nil,"debug","totalGithubIndex",totalGithubIndex);

				if (totalLocalIndex ~= 0) then
					updateOne();
				else
					downloadOne(); --如果文档文件夹为空，则直接开始下载
				end
			else
				_guihelper.MessageBox(L"获取GITHUB文件失败，请稍后再试！");
			end
		end);
	end
end

function SyncMain:syncToDataSource()
	-- 加载进度UI界面
	local syncToDataSourceGUI = SyncGUI:new();

	local function syncNow()
		SyncMain.localFiles = LocalService:LoadFiles(SyncMain.worldDir,"",nil,1000,nil);

		if (SyncMain.worldDir == "") then
			_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
			return;
		else
			SyncMain.progressText = L'获取文件sha列表';

			local curUpdateIndex    = 1;
			local curUploadIndex    = 1;
			local totalLocalIndex   = nil;
			local totalGithubIndex  = nil;
			local githubFiles       = {};
			local syncGUItotal      = 0;
			local syncGUIIndex      = 0;
			local syncGUIFiles      = "";

			-- LOG.std(nil,"debug","WorldShareGUI",curUploadIndex);
			-- LOG.std(nil,"debug","WorldShareGUI",totalGithubIndex);

			-- 上传新文件
			local function uploadOne()
				if (curUploadIndex <= totalLocalIndex) then
					-- LOG.std(nil,"debug","self.localFiles",self.localFiles[curUploadIndex].needChange);
					-- LOG.std(nil,"debug","self.localFiles",self.localFiles[curUploadIndex]);

					if (SyncMain.localFiles[curUploadIndex].needChange) then

						SyncMain.localFiles[curUploadIndex].needChange = false;
						SyncMain:uploadService(self.foldername, self.localFiles[curUploadIndex].filename, self.localFiles[curUploadIndex].file_content_t,function (bIsDownload,data)
							if (bIsDownload) then
								-- self.progressText = self.localFiles[curUploadIndex].filename .. ' 上传成功' .. (curUploadIndex + 1) .. '/' .. totalGithubIndex;
								
								syncGUIIndex   = syncGUIIndex + 1;
								-- LOG.std(nil,"debug","data",data);

								--LOG.std(nil,"debug","upload---syncGUIIndex",syncGUIIndex);
								--LOG.std(nil,"debug","upload---syncGUIFiles",syncGUIFiles);
								syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

								curUploadIndex = curUploadIndex + 1;

								if(syncGUItotal == syncGUIIndex) then
									finish();
								end
							else
								_guihelper.MessageBox(self.localFiles[curUploadIndex].filename .. ' 上传失败，请稍后再试');
							end
						end);
					else
						curUploadIndex = curUploadIndex + 1;
					end

					if (curUploadIndex > totalLocalIndex) then
						if(syncGUItotal == syncGUIIndex) then
							finish();
						end
						-- _guihelper.MessageBox('同步完成-D');
					else
						uploadOne(); --继续递归上传
					end
				end
			end

			-- 更新Github文件
			local function updateOne()
				if (curUpdateIndex <= totalGithubIndex) then
					--LOG.std(nil,"debug","curUpdateIndex",curUpdateIndex);
					--LOG.std(nil,"debug","totalGithubIndex",totalGithubIndex);
					local bIsExisted  = false;
					local LocalIndex  = nil;

					-- 用Gihub的文件和本地的文件对比
					for key,value in ipairs(self.localFiles) do
						if(value.filename == githubFiles.tree[curUpdateIndex].path) then
							bIsExisted  = true;
							LocalIndex  = key; 
							break;
						end
					end

					-- compare the files in github with the ones in local host
					if (bIsExisted) then
						-- if existed
						self.localFiles[LocalIndex].needChange = false;
						-- LOG.std(nil,"debug","githubFiles.tree[curUpdateIndex].path",githubFiles.tree[curUpdateIndex].path);
						-- LOG.std(nil,"debug","githubFiles.tree[curUpdateIndex].sha",githubFiles.tree[curUpdateIndex].sha);
						-- LOG.std(nil,"debug","self.localFiles.sha1",self.localFiles[LocalIndex].sha1);

						if (githubFiles.tree[curUpdateIndex].sha ~= self.localFiles[LocalIndex].sha1) then
							-- 更新已存在的文件
							-- if file existed, and has different sha value, update it
							SyncMain:updateService(self.foldername, self.localFiles[LocalIndex].filename, self.localFiles[LocalIndex].file_content_t, githubFiles.tree[curUpdateIndex].sha, function (bIsUpdate,content)
								if (bIsUpdate) then
									syncGUIIndex   = syncGUIIndex + 1;
									syncGUIFiles   = self.localFiles[LocalIndex].filename;
									LOG.std(nil,"debug","budeng---syncGUIIndex",syncGUIIndex);
									LOG.std(nil,"debug","budeng---syncGUIFiles",syncGUIFiles);

									syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

									curUpdateIndex = curUpdateIndex + 1;

									-- 如果当前计数大于最大计数则更新
									if (curUpdateIndex > totalGithubIndex) then
										-- _guihelper.MessageBox(L'同步完成-A');
										finish();
										uploadOne();
									else
										updateOne();
									end
								else
									-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 更新失败,请稍后再试');
								end
							end);
						else
							-- if file exised, and has same sha value, then contain it
							-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 文件更新完成' .. (curUpdateIndex + 1) .. '/' .. totalGithubIndex);
							syncGUIIndex   = syncGUIIndex + 1;
							syncGUIFiles   = self.localFiles[LocalIndex].filename;

							LOG.std(nil,"debug","deng---syncGUIIndex",syncGUIIndex);
							LOG.std(nil,"debug","deng---syncGUIFiles",syncGUIFiles);

							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

							curUpdateIndex = curUpdateIndex + 1;

							if (curUpdateIndex > totalGithubIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
								-- _guihelper.MessageBox(L'同步完成-B');
								uploadOne();
							else
								updateOne();
							end
						end
					else
						-- LOG.std(nil,"debug","delete-filename",self.localFiles[LocalIndex].filename);
						-- LOG.std(nil,"debug","delete-sha1",self.localFiles[LocalIndex].filename);

						-- 如果过github不删除存在，则删除本地的文件
						-- if file does not exist, delete it
						deleteOne();
					end
				end
			end

			-- 删除Github文件
			function deleteOne()
				if(githubFiles.tree[curUpdateIndex].type == "blob") then

					SyncMain:deleteService(self.foldername, githubFiles.tree[curUpdateIndex].path, githubFiles.tree[curUpdateIndex].sha, function (bIsDelete)
						if (bIsDelete) then
							-- _guihelper.MessageBox (self.localFiles[curUpdateIndex].filename .. ' 删除成功' .. (curUpdateIndex + 1) .. '/' .. totalLocalIndex);
							curUpdateIndex = curUpdateIndex + 1;

							if (curUpdateIndex > totalGithubIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
								-- _guihelper.MessageBox(L'同步完成-C');

								finish();
								uploadOne();
							else
								updateOne();
							end
						else
							_guihelper.MessageBox('删除 ' .. self.localFiles[curUpdateIndex].filename .. ' 失败, 请稍后再试');
						end
					end);
				else
					curUpdateIndex = curUpdateIndex + 1;

					if (curUpdateIndex > totalGithubIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
						uploadOne();
					else
						updateOne();
					end
				end
			end

			local function finish()
				if(syncGUItotal == syncGUIIndex) then
					LOG.std(nil,"debug","send",login.selectedWorldInfor.tooltip)

					local modDateTable = {};

					for modDateEle in string.gmatch(login.selectedWorldInfor.tooltip,"[^:]+") do
						modDateTable[#modDateTable+1] = modDateEle;
					end

					GithubService:GetUrl({
						url = login.site.."/api/mod/WorldShare/models/worlds/refresh",
						postfields = '{"modDate":"'..modDateTable[1]..'","worldsName":"'..self.foldername..'","revision":"'..self.currentRevison..'"}',
						headers = {Authorization    = "Bearer "..login.token,
								   ["content-type"] = "application/json"},
					},function(data) 

					end);

					self.githubRevison = self.currentRevison;
				end
			end

			-- 获取github仓文件
			-- get sha value of the files in github
			SyncMain:getFileShaListService(self.foldername, function(data,err)
				local hasReadme = false;

				for key,value in ipairs(self.localFiles) do
					if(value.filename == "README.md") then
						hasReadme = true;
						break;
					end
				end

				if(not hasReadme) then
					local filePath = self.worldDir .. "README.md";
					local file = ParaIO.open(filePath, "w");
					local content = "made by http://www.paracraft.cn/";

					file:write(content,#content);
					file:close();

					--LOG.std(nil,"debug","filePath",filePath);

					local readMeFiles = {
						filename       = "README.md",
						file_path      = Encoding.DefaultToUtf8(self.worldDir) .. "README.md",
						file_content_t = content
					};

					--LOG.std(nil,"debug","localFiles",readMeFiles);

					self.localFiles[#self.localFiles + 1] = readMeFiles;
				end

				totalLocalIndex  = #self.localFiles;
				syncGUItotal     = #self.localFiles;

				for i=1,#self.localFiles do
					-- LOG.std(nil,"debug","localFiles",self.localFiles[i]);
					self.localFiles[i].needChange = true;
					i = i + 1;
				end

				LOG.std(nil,"debug","err",err);
				if (err ~= 409 and err ~= 404) then --409代表已经创建过此仓
					githubFiles = data;
					
					LOG.std(nil,"debug","syncGUItotal",syncGUItotal);
					syncToDataSourceGUI:updateDataBar(syncGUIIndex,syncGUItotal);

					totalGithubIndex = #githubFiles.tree;

					LOG.std(nil,"debug","githubFilesErr",err .. " success!");
					updateOne();
				else
					--if the repos is empty, then upload files 
					uploadOne();
				end
			end);
		end
	end

	------------------------------------------------------------------------

	if(self.firstCreate == 1) then
		SyncMain:create(self.foldername,function(data,err)
			-- LOG.std(nil,"debug","GithubService:create",data);

			if(err == 422 or err == 201) then
				syncNow();
			else
				--if(data.name ~= self.foldername) then
				_guihelper.MessageBox(L"创建Github仓失败");
				return;
				--end
			end
		end);
	else
		LOG.std(nil,"debug","SyncMain:syncToGithub","非首次同步");
		syncNow();
	end
end

function SyncMain:create(_foldername,_callback)
	if(login.dataSourceType == "github") then
		GithubService:create(_foldername,_callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:init(_foldername,_callback);
	end
end

function SyncMain:uploadService(_foldername,_filename,_file_content_t,_callback)
	if(login.dataSourceType == "github") then
		GithubService:upload(_foldername,_filename,_file_content_t,_callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:writeFile(_foldername,_filename,_file_content_t,_callback);
	end
end

function SyncMain:updateService(_foldername, _filename, _file_content_t, _sha, _callback)
	if(login.dataSourceType == "github") then
		GithubService:update(_foldername, _filename, _file_content_t, _sha, _callback);
	elseif(login.dataSourceType == "gitlab") then
		
	end
end

function SyncMain:deleteService(_foldername, _path, _sha, _callback)
	if(login.dataSourceType == "github") then
		GithubService:delete(_foldername, _path, _sha, _callback);
	elseif(login.dataSourceType == "gitlab") then
		
	end
end

function SyncMain:getFileShaListService(_foldername, _callback)
	if(login.dataSourceType == "github") then
		GithubService:getFileShaList(_foldername, _callback);
	elseif(login.dataSourceType == "gitlab") then

	end
end