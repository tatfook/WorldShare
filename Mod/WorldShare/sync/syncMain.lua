--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync.SyncMain.lua");
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua");
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua");
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
NPL.load("(gl)Mod/WorldShare/main.lua");
NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua");
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");

local LocalLoadWorld	 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld");
local ShareWorld		 = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");
local SyncGUI            = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
local WorldCommon        = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MainLogin		     = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local loginMain          = commonlib.gettable("Mod.WorldShare.login.loginMain");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local LocalService       = commonlib.gettable("Mod.WorldShare.service.LocalService");
local HttpRequest		 = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local Encoding           = commonlib.gettable("commonlib.Encoding");
local EncodingS          = commonlib.gettable("System.Encoding");
local GitEncoding        = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local CommandManager     = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local ShareWorldPage     = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local WorldShare         = commonlib.gettable("Mod.WorldShare");
local KeepworkGen        = commonlib.gettable("Mod.WorldShare.helper.KeepworkGen");

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

SyncMain.SyncPage    = nil;
SyncMain.DeletePage  = nil;
SyncMain.BeyondPage  = nil;
SyncMain.finish      = true;
SyncMain.worldDir    = {};
SyncMain.foldername  = {};

function SyncMain:ctor()
end

function SyncMain:init()
	LOG.std(nil, "debug", "SyncMain", "init");
	
	SyncMain.worldName = nil;

	-- 没有登陆则直接使用离线模式
	if(loginMain.token and loginMain.current_type == 1) then
		SyncMain.syncCompare();
	end
end

function SyncMain.setSyncPage()
	SyncMain.SyncPage = document:GetPageCtrl();
end

function SyncMain.setDeletePage()
	SyncMain.DeletePage = document:GetPageCtrl();
end

function SyncMain.setBeyondPage()
	SyncMain.BeyondPage = document:GetPageCtrl();
end

function SyncMain.closeDeletePage()
    SyncMain.DeletePage:CloseWindow();

--    if(not WorldCommon.GetWorldInfo()) then
--        MainLogin.state.IsLoadMainWorldRequested = nil;
--        MainLogin:next_step();
--    end
end

function SyncMain.closeSyncPage()
	SyncMain.isStart = false;
	SyncMain.SyncPage:CloseWindow();
end

function SyncMain.closeBeyondPage()
	SyncMain.BeyondPage:CloseWindow();
end

function SyncMain:StartSyncPage()
	SyncMain.isStart = true;

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

function SyncMain:compareRevision(_LoginStatus, _callback)
	SyncMain.compareFinish = false;

	if(loginMain.token) then
		LOG.std(nil,"debug","_LoginStatus",_LoginStatus);
		if(not _LoginStatus) then
			SyncMain.tagInfor = WorldCommon.GetWorldInfo();
			LOG.std(nil,"debug","SyncMain.tagInfor",SyncMain.tagInfor);

			SyncMain.worldDir.default = GameLogic.GetWorldDirectory();
			SyncMain.worldDir.utf8    = Encoding.DefaultToUtf8(SyncMain.worldDir.default);

			LOG.std(nil,"debug","SyncMain.worldDir.utf8",SyncMain.worldDir.utf8)
			LOG.std(nil,"debug","SyncMain.worldDir.default",SyncMain.worldDir.default)

			SyncMain.foldername.default = SyncMain.worldDir.default:match("worlds/DesignHouse/([^/]*)/");
			LOG.std(nil,"debug","SyncMain.foldername.default",SyncMain.foldername.default)
			SyncMain.foldername.utf8    = SyncMain.worldDir.utf8:match("worlds/DesignHouse/([^/]*)/");
			LOG.std(nil,"debug","SyncMain.foldername.utf8",SyncMain.foldername.utf8)

			LOG.std(nil,"debug","selectedWorldInfor-old",SyncMain.selectedWorldInfor);
			loginMain.RefreshCurrentServerList();
			for key,value in ipairs(InternetLoadWorld.cur_ds) do
				if(value.foldername == SyncMain.foldername.utf8)then
					SyncMain.selectedWorldInfor = value;
				end
			end
			LOG.std(nil,"debug","selectedWorldInfor-new",SyncMain.selectedWorldInfor);

			if(SyncMain.selectedWorldInfor.is_zip) then
				_guihelper.MessageBox(L"不能同步ZIP文件");

				commonlib.TimerManager.SetTimeout(function()
					if(SyncMain.SyncPage)then
						SyncMain.closeSyncPage();
					end
				end,100);
				return;
			end
		end

		WorldRevisionCheckOut   = WorldRevision:new():init(SyncMain.worldDir.default);
		SyncMain.currentRevison = WorldRevisionCheckOut:Checkout();

		SyncMain.localFiles = LocalService:LoadFiles(SyncMain.worldDir.default,"",nil,1000,nil);

		--LOG.std(nil,"debug","self.foldername",self.foldername);
		for _,value in ipairs(SyncMain.localFiles) do
			LOG.std(nil,"debug","SyncMain.localFiles",value.filename);
		end

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
			if(loginMain.dataSourceType == 'github') then
				contentUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/master/revision.xml";
			elseif(loginMain.dataSourceType == 'gitlab') then
				SyncMain.commitId = SyncMain:getGitlabCommitId(SyncMain.foldername.utf8);

				if(SyncMain.commitId) then
					contentUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/" .. SyncMain.commitId .. "/revision.xml";
				else
					contentUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/master/revision.xml";
				end
				
				LOG.std("SyncMain","debug","contentUrl",contentUrl);
			end

			SyncMain.remoteRevison = 0;

			--LOG.std(nil,"debug","contentUrl",contentUrl);

			HttpRequest:GetUrl(contentUrl, function(data,err)
				--LOG.std(nil,"debug","contentUrl",contentUrl);
				--LOG.std(nil,"debug","data",data);
				--LOG.std(nil,"debug","err",err);

				SyncMain.remoteRevison = tonumber(data);
				if(not SyncMain.remoteRevison) then
					SyncMain.remoteRevison = 0;
				end

				--SyncMain.isFetchRemoteRevision = true;

				SyncMain.currentRevison = tonumber(SyncMain.currentRevison);
				LOG.std(nil,"debug","SyncMain.remoteRevison",SyncMain.remoteRevison);
				LOG.std(nil,"debug","SyncMain.currentRevison",SyncMain.currentRevison);

				if(err == 0) then
					_guihelper.MessageBox(L"网络错误");
					_callback(false);
					return
				else
					local result;

					if(SyncMain.currentRevison < SyncMain.remoteRevison) then
						result = "remoteBigger"
					elseif(SyncMain.remoteRevison == 0) then
						result = "justLocal";
					elseif(SyncMain.currentRevison > SyncMain.remoteRevison) then
						result = "localBigger";
					elseif(SyncMain.currentRevison == SyncMain.remoteRevison) then
						result = "equal";
					end

					SyncMain.compareFinish = true;

					_callback(result);
				end
			end);
		else
			if(not _LoginStatus) then
				CommandManager:RunCommand("/save");
				SyncMain.compareFinish = true;
				_callback("tryAgain");
			else
				_guihelper.MessageBox(L"本地世界沒有版本信息");
				SyncMain.compareFinish = true;
				return;
			end
		end
	end
end

function SyncMain.syncCompare(_LoginStatus)
	SyncMain:compareRevision(_LoginStatus, function(result)
		--echo(result);
		--echo(_LoginStatus);

		if(_LoginStatus) then
			if(result == "justLocal") then
				SyncMain.syncToDataSource();
			else
				SyncMain:StartSyncPage();
			end
		else
			if(result == "remoteBigger") then
				SyncMain:StartSyncPage();
			elseif(result == "tryAgain") then
				commonlib.TimerManager.SetTimeout(function()
					CommandManager:RunCommand("/save");
					SyncMain.syncCompare();
				end,1000)
			end
		end
	end);
end

function SyncMain.useLocal()
    SyncMain.SyncPage:CloseWindow();

    if(tonumber(SyncMain.currentRevison) < tonumber(SyncMain.remoteRevison)) then
        SyncMain:useLocalGUI();
    elseif(tonumber(SyncMain.currentRevison) > tonumber(SyncMain.remoteRevison)) then
        -- _guihelper.MessageBox("开始同步--将本地大小有变化的文件上传到github"); -- 上传或更新
        SyncMain:syncToDataSource();
    end
end

function SyncMain.useRemote()
    SyncMain.SyncPage:CloseWindow();

    if(tonumber(SyncMain.remoteRevison) < tonumber(SyncMain.currentRevison)) then
        SyncMain:useDataSourceGUI();
    elseif(tonumber(SyncMain.remoteRevison) > tonumber(SyncMain.currentRevison)) then
        -- _guihelper.MessageBox("开始同步--将github大小有变化的文件下载到本地");-- 下载或覆盖
        SyncMain:syncToLocal();
    end
end

function SyncMain.useOffline()
    SyncMain.ComparePage:CloseWindow();
end

function SyncMain:useLocalGUI()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/StartSyncUseLocal.html", 
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

function SyncMain:useDataSourceGUI()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/StartSyncUseDataSource.html", 
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

function SyncMain:syncToLocal(_callback)
	if(not SyncMain.finish) then
		--_guihelper.MessageBox(L"同步尚未结束");
		--return;
	end

	SyncMain.localSync = {};
	SyncMain.finish = false;

	-- 加载进度UI界面
	local syncToLocalGUI = SyncGUI:new();

	--LOG.std(nil,"debug","worldDir",_worldDir);

	if(loginMain.dataSourceType == "gitlab") then
		SyncMain:setGitlabProjectId(SyncMain.foldername.utf8);
	end

	if (SyncMain.worldDir.default == "") then
		_guihelper.MessageBox(L"下载失败，原因：下载目录为空");
		return;
	else
		SyncMain.curUpdateIndex        = 1;
		SyncMain.curDownloadIndex      = 1;
		SyncMain.totalLocalIndex       = nil;
		SyncMain.totalDataSourceIndex  = nil;
		SyncMain.dataSourceFiles       = {};

		local syncGUItotal = 0;
		local syncGUIIndex = 0;
		local syncGUIFiles = "";

		-- LOG.std(nil,"debug","SyncMainGUI",SyncMain.curDownloadIndex);
		-- LOG.std(nil,"debug","SyncMainGUI",SyncMain.totalDataSourceIndex);

		syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'获取文件sha列表');

		function SyncMain.localSync.finish()
			SyncMain.finish = true;

			syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, "同步完成");
			local localWorlds = InternetLoadWorld.cur_ds;

			for key, value in ipairs(localWorlds) do
				if(SyncMain.foldername.utf8 == value["foldername"]) then
					LOG.std(nil,"debug","SyncMain.foldername",SyncMain.foldername.utf8);
					localWorlds[key].status   = 3;
					localWorlds[key].revision = SyncMain.remoteRevison;
					loginMain.refreshPage();
				end
			end

			--成功是返回信息给login
			if(_callback) then
				local params = {};
				params.revison     = SyncMain.remoteRevison;
				-- params.filesTotals = LocalService:GetWorldFileSize(SyncMain.foldername.utf8);

				_callback(true,params);
			end
		end

		-- 下载新文件
		function SyncMain.localSync.downloadOne()
			-- LOG.std(nil,"debug","githubFiles.tree[SyncMain.curDownloadIndex]",githubFiles.tree[SyncMain.curDownloadIndex]);
			-- LOG.std(nil,"debug","SyncMain.curDownloadIndex",SyncMain.curDownloadIndex);

			if (SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].needChange) then
				if(SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].type == "blob") then
					-- LOG.std(nil,"debug","githubFiles.tree[SyncMain.curDownloadIndex].type",githubFiles.tree[SyncMain.curDownloadIndex].type);
					LocalService:download(SyncMain.foldername.utf8, SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].path, function (bIsDownload, response)
						if (bIsDownload) then
							syncGUIIndex = syncGUIIndex + 1;
							syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename);

							if(response.filename == "revision.xml") then
								SyncMain.remoteRevison = response.content;
							end

							if(SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
								SyncMain.localSync.finish();
							else
								SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1;
								SyncMain.localSync.downloadOne();
							end
						else
							_guihelper.MessageBox(L'下载失败，请稍后再试');
							--syncToLocalGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				end
			else
				if(SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
					SyncMain.localSync.finish();
				else
					SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1;
					SyncMain.localSync.downloadOne();
				end
			end
		end

		-- 删除文件
		function SyncMain.localSync.deleteOne()
			LocalService:delete(SyncMain.foldername.utf8, SyncMain.localFiles[SyncMain.curUpdateIndex].filename, function (data, err)
				if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
					SyncMain.localSync.downloadOne();
				else
					SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
					SyncMain.localSync.updateOne();
				end
			end);
		end

		-- 更新本地文件
		function SyncMain.localSync.updateOne()
			LOG.std(nil,"debug","SyncMain.curUpdateIndex ",SyncMain.curUpdateIndex);
			local bIsExisted      = false;
			local dataSourceIndex = nil;

			-- 用数据源的文件和本地的文件对比
			for key, value in ipairs(SyncMain.dataSourceFiles) do
				if(value.path == SyncMain.localFiles[SyncMain.curUpdateIndex].filename) then
					LOG.std(nil,"debug","value.path",value.path);
					bIsExisted = true;
					dataSourceIndex = key; 
					break;
				end
			end

			-- 本地是否存在数据源上的文件
			if (bIsExisted) then
				SyncMain.dataSourceFiles[dataSourceIndex].needChange = false;
				-- LOG.std(nil,"debug","self.localFiles[SyncMain.curUpdateIndex ].filename",self.localFiles[SyncMain.curUpdateIndex ].filename);
				-- LOG.std(nil,"debug","self.localFiles[SyncMain.curUpdateIndex ].sha1",self.localFiles[SyncMain.curUpdateIndex ].sha1);
				-- LOG.std(nil,"debug","githubFiles.tree[dataSourceIndex].sha",githubFiles.tree[dataSourceIndex].sha);

				if (SyncMain.localFiles[SyncMain.curUpdateIndex].sha1 ~= SyncMain.dataSourceFiles[dataSourceIndex].sha) then
					-- 更新已存在的文件
					LocalService:update(SyncMain.foldername.utf8, SyncMain.dataSourceFiles[dataSourceIndex].path, function (bIsUpdate, response)
						if (bIsUpdate) then
							if(response.filename == "revision.xml") then
								SyncMain.remoteRevison = response.content;
							end

							syncGUIIndex = syncGUIIndex + 1;
							syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename);

							if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
								SyncMain.localSync.downloadOne();
							else
								SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
								SyncMain.localSync.updateOne();
							end
						else
							_guihelper.MessageBox(L'更新失败,请稍后再试');
							--syncToLocalGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				else
					syncGUIIndex = syncGUIIndex + 1;
					syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.dataSourceFiles[dataSourceIndex].path);

					if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
						SyncMain.localSync.downloadOne();
					else
						SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
						SyncMain.localSync.updateOne();
					end
				end
			else
				LOG.std(nil,"debug","delete-filename",SyncMain.localFiles[SyncMain.curUpdateIndex].filename);
				LOG.std(nil,"debug","delete-sha1",SyncMain.localFiles[SyncMain.curUpdateIndex].sha1);

				-- 如果过github不删除存在，则删除本地的文件
				SyncMain.localSync.deleteOne();
			end
		end

		-- 获取数据源仓文件
		SyncMain:getFileShaListService(SyncMain.foldername.utf8, function(data, err)
			if(err ~= 404) then
				if(err == 409) then
					_guihelper.MessageBox(L"数据源上暂无数据");
					syncToLocalGUI.finish();
					return;
				end

				LOG.std(nil,"debug","SyncMain:getFileShaListService-data",data);

				SyncMain.localFiles      = LocalService:LoadFiles(SyncMain.worldDir.default,"",nil,1000,nil);
				SyncMain.dataSourceFiles = data;

				SyncMain.totalLocalIndex      = #SyncMain.localFiles;
				SyncMain.totalDataSourceIndex = #SyncMain.dataSourceFiles;

				for key,value in ipairs(SyncMain.dataSourceFiles) do
					value.needChange = true;

					if(value.type == "blob") then
						syncGUItotal = syncGUItotal + 1;
					end
				end

				syncToLocalGUI:updateDataBar(syncGUIIndex , syncGUItotal, L"开始同步");

				LOG.std(nil,"debug","SyncMain.totalLocalIndex",SyncMain.totalLocalIndex);
				LOG.std(nil,"debug","SyncMain.totalDataSourceIndex",SyncMain.totalDataSourceIndex);

				if (SyncMain.totalLocalIndex ~= 0) then
					SyncMain.localSync.updateOne();
				else
					--downloadOne(); --如果文档文件夹为空，则直接开始下载
					LocalService:downloadZip(SyncMain.foldername.utf8, SyncMain.commitId ,function(bSuccess, remoteRevison)
						if(bSuccess) then
							SyncMain.remoteRevison = remoteRevison;
							syncGUIIndex = syncGUItotal;
							SyncMain.localSync.finish();
						else
							_guihelper.MessageBox(L'下载失败，请稍后再试');
						end
					end);
				end
			else
				_guihelper.MessageBox(L"获取数据源文件失败，请稍后再试！");
				syncToLocalGUI.finish();
			end
		end, SyncMain.commitId);
	end
end

function SyncMain:syncToDataSource()
	if(SyncMain:checkWorldSize()) then
		return;
	end

	if(not SyncMain.finish) then
		--_guihelper.MessageBox(L"同步尚未结束");
		--return;
	end
	SyncMain.remoteSync = {};
	SyncMain.finish = false;

	-- 加载进度UI界面
	local syncToDataSourceGUI = SyncGUI:new();

	local function syncToDataSourceGo()
		if (SyncMain.worldDir.default == "") then
			_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
			return;
		else
			SyncMain.curUpdateIndex        = 1;
			SyncMain.curUploadIndex        = 1;
			SyncMain.totalLocalIndex       = nil;
			SyncMain.totalDataSourceIndex  = nil;
			SyncMain.dataSourceFiles       = {};

			SyncMain.revisionUpload = false;
			SyncMain.revisionUpdate = false;

			local syncGUItotal = 0;
			local syncGUIIndex = 0;
			local syncGUIFiles = "";

			syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'获取文件sha列表');

			LOG.std(nil,"debug","SyncMain.curUploadIndex",SyncMain.curUploadIndex);
			LOG.std(nil,"debug","SyncMain.totalDataSourceIndex",SyncMain.totalDataSourceIndex);

			function SyncMain.remoteSync.revision(_callback)
				LOG.std(nil,"debug","SyncMain.revisionUpload",SyncMain.revisionUpload);
				LOG.std(nil,"debug","SyncMain.revisionUpdate",SyncMain.revisionUpdate);

				if(SyncMain.revisionUpload) then
					SyncMain:uploadService(SyncMain.foldername.utf8, "revision.xml", SyncMain.revisionContent, function (bIsUpload, filename)
						if (bIsUpload) then
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);

							_callback();
						else
							_guihelper.MessageBox(L"revision上传失败");
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
						end
					end);
				end

				if(SyncMain.revisionUpdate) then
					SyncMain:updateService(SyncMain.foldername.utf8, "revision.xml", SyncMain.revisionContent, SyncMain.revisionSha1, function (bIsUpdate, filename)
						if (bIsUpdate) then
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);

							_callback();
						else
							_guihelper.MessageBox(L"revision更新失败");
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
						end
					end);
				end
			end

			function SyncMain.remoteSync.finish()
				LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);
				LOG.std(nil,"debug","send",SyncMain.selectedWorldInfor.tooltip);

				SyncMain.remoteSync.revision(function()
					syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'同步完成');

					SyncMain:getCommits(function(data, err)
						LOG.std(nil,"debug","data",data);
						LOG.std(nil,"debug","err",err);

						if(data) then
							local lastCommits = data[1];
							lastCommitFile = lastCommits.title:gsub("keepwork commit: ","");
							lastCommitSha  = "";

							if(lastCommitFile == "revision.xml") then
								lastCommitSha = lastCommits.id;

								SyncMain.finish = true;

								local modDateTable = {};
								local readme;

								if(SyncMain.selectedWorldInfor.tooltip)then
									for modDateEle in string.gmatch(SyncMain.selectedWorldInfor.tooltip,"[^:]+") do
										modDateTable[#modDateTable+1] = modDateEle;
									end

									modDateTable = modDateTable[1];
								else
									modDateTable = os.date("%Y-%m-%d-%H-%M-%S");
								end
					
								local hasPreview = false;

								for key,value in ipairs(SyncMain.localFiles) do
									if(value.filename == "preview.jpg") then
										hasPreview = true;
									end
								end

								for key,value in ipairs(SyncMain.localFiles) do
									if(value.filename == "README.md") then
										readme = LocalService:getFileContent(SyncMain.worldDir.default .. "README.md");
										readme = Encoding.DefaultToUtf8(readme);

										LOG.std(nil,"debug","SyncMain.worldDir.default",SyncMain.worldDir.default);
										LOG.std(nil,"debug","readme",readme);
									end
								end

								local preview = {};
								preview[0] = {};
								preview[0].previewUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/master/preview.jpg";
								preview = NPL.ToJson(preview,true);

								local filesTotals = SyncMain.selectedWorldInfor.size;

								local params = {};
								params.modDate		   = modDateTable;
								params.worldsName      = SyncMain.foldername.utf8;
								params.revision        = SyncMain.currentRevison;
								params.hasPreview      = hasPreview;
								params.dataSourceType  = loginMain.dataSourceType;
								params.gitlabProjectId = GitlabService.projectId;
								params.readme          = readme; --EncodingS.base64(readme);
								params.preview         = preview;
								params.filesTotals	   = filesTotals;
								params.commitId		   = lastCommitSha;

								LOG.std(nil,"debug","params",params);

								-- SyncMain:genWorldMD(params);

								HttpRequest:GetUrl({
									url     = loginMain.site .. "/api/mod/worldshare/models/worlds/refresh",
									json    = true,
									form    = params,
									headers = {
										Authorization    = "Bearer " .. loginMain.token,
										["content-type"] = "application/json",
									},
								},function(data, err)
									LOG.std(nil,"debug","finish",data);
									LOG.std(nil,"debug","finish",err);

									if(err == 200) then
										params.opusId = data.msg.opusId;

										local requestParams = {
											url  = loginMain.site .. "/api/mod/worldshare/models/worlds",
											json = true,
											headers = {Authorization = "Bearer "..loginMain.token},
											form = {amount = 10000},
										}

										LOG.std(nil,"debug","requestParams",requestParams);

										SyncMain:genWorldMD(params, function()
											HttpRequest:GetUrl(requestParams,function(worldList, err)
												LOG.std(nil,"debug","genWorldIndex-worldList-data",worldList);
												SyncMain:genIndexMD(worldList);
												loginMain.RefreshCurrentServerList();
											end);
										end);
									end
								end);

								if(SyncMain.firstCreate) then
									SyncMain.firstCreate = false;
								end
							else
								_guihelper.MessageBox(L"上传失败");
							end

							LOG.std(nil,"debug","lastCommits",lastCommits);
							LOG.std(nil,"debug","lastCommitFile",lastCommitFile);
							LOG.std(nil,"debug","lastCommitSha",lastCommitSha);
						else
							_guihelper.MessageBox(L"上传失败");
						end
					end);
				end)
			end

			-- 上传新文件
			function SyncMain.remoteSync.uploadOne()
				LOG.std(nil,"debug","uploadOne-status",SyncMain.curUploadIndex);
				LOG.std(nil,"debug","SyncMain.totalLocalIndex",SyncMain.totalLocalIndex);

				if(SyncMain.localFiles[SyncMain.curUploadIndex].filename == "revision.xml" and SyncMain.localFiles[SyncMain.curUploadIndex].needChange) then
					--LOG.std(nil,"debug","findRevision");
					SyncMain.revisionUpload  = true;
					SyncMain.revisionContent = SyncMain.localFiles[SyncMain.curUploadIndex].file_content_t;

					if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
						SyncMain.remoteSync.finish();
					else
						SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
						SyncMain.remoteSync.uploadOne(); --继续递归上传
					end

					return;
				end

				--LOG.std(nil,"debug","SyncMain.localFiles[SyncMain.curUploadIndex]", SyncMain.localFiles[SyncMain.curUploadIndex]);

				if (SyncMain.localFiles[SyncMain.curUploadIndex].needChange) then
					SyncMain.localFiles[SyncMain.curUploadIndex].needChange = false;
					SyncMain:uploadService(SyncMain.foldername.utf8, SyncMain.localFiles[SyncMain.curUploadIndex].filename, SyncMain.localFiles[SyncMain.curUploadIndex].file_content_t,function (bIsUpload, filename)
						if (bIsUpload) then
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename .. " （" .. loginMain.GetWorldSize(SyncMain.localFiles[SyncMain.curUploadIndex].filesize, "KB") .. "） " .. "上传完成");

							if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
								LOG.std(nil,"debug","SyncMain.localFiles",SyncMain.localFiles);
								SyncMain.remoteSync.finish();
							else
								SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
								SyncMain.remoteSync.uploadOne(); --继续递归上传
							end
						else
							--_guihelper.MessageBox(L"上传失败");
							--syncGUIIndex = syncGUIIndex + 1;
							--syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);

							--syncToDataSourceGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				else
--					syncGUIIndex = syncGUIIndex + 1;
--					syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.localFiles[SyncMain.curUploadIndex].filename);

					if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
						SyncMain.remoteSync.finish();
					else
						SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
						SyncMain.remoteSync.uploadOne(); --继续递归上传
					end
				end
			end

			-- 删除数据源文件
			function SyncMain.remoteSync.deleteOne()
				LOG.std(nil,"debug","deleteOne-status");
				if(SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].type == "blob") then
					SyncMain:deleteFileService(SyncMain.foldername.utf8, SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].path, SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].sha, function (bIsDelete)
						if (bIsDelete) then
							SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;

							if (SyncMain.curUpdateIndex > SyncMain.totalDataSourceIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
								SyncMain.remoteSync.uploadOne();
							else
								SyncMain.remoteSync.updateOne();
							end
						else
							_guihelper.MessageBox(L"删除失败");
							--syncToDataSourceGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				else
					if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
						SyncMain.remoteSync.uploadOne();
					else
						SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
						SyncMain.remoteSync.updateOne();
					end
				end
			end

			-- 更新数据源文件
			function SyncMain.remoteSync.updateOne()
				LOG.std(nil,"debug","updateOne-status",SyncMain.curUpdateIndex);
				LOG.std(nil,"debug","updateOne-status",SyncMain.totalDataSourceIndex);

				local bIsExisted  = false;
				local LocalIndex  = nil;
				local curGitFiles = SyncMain.dataSourceFiles[SyncMain.curUpdateIndex];

				if(curGitFiles.type == "blob") then
					-- 用数据源的文件和本地的文件对比
					for key,value in ipairs(SyncMain.localFiles) do
						if(value.filename == curGitFiles.path) then
							bIsExisted  = true;
							LocalIndex  = key; 
							break;
						end
					end

					if(bIsExisted and SyncMain.localFiles[LocalIndex].filename == "revision.xml") then
						LOG.std(nil,"debug","findUpdateRevision");
						SyncMain.revisionUpdate  = true;
						SyncMain.revisionContent = SyncMain.localFiles[LocalIndex].file_content_t;
						SyncMain.revisionSha1    = SyncMain.localFiles[LocalIndex].sha1;
						SyncMain.localFiles[LocalIndex].needChange = false;

						if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
							SyncMain.remoteSync.uploadOne();
						else
							SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1; -- 如果不等最大计数则更新
							SyncMain.remoteSync.updateOne();
						end

						return;
					end

					syncGUIIndex = syncGUIIndex + 1;
					syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.localFiles[LocalIndex].filename .. "比对中");

					LOG.std(nil,"debug","dataSourceFiles",curGitFiles.path);

					if (bIsExisted) then
						SyncMain.localFiles[LocalIndex].needChange = false;
						LOG.std(nil,"debug","curGitFiles.sha",curGitFiles.sha);
						LOG.std(nil,"debug","SyncMain.localFiles[LocalIndex].sha1",SyncMain.localFiles[LocalIndex].sha1);

						if (curGitFiles.sha ~= SyncMain.localFiles[LocalIndex].sha1) then
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.localFiles[LocalIndex].filename .. "上传中");
							-- 更新已存在的文件
							SyncMain:updateService(SyncMain.foldername.utf8, SyncMain.localFiles[LocalIndex].filename, SyncMain.localFiles[LocalIndex].file_content_t, curGitFiles.sha, function (bIsUpdate, filename)
								if (bIsUpdate) then
									syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename .. "上传完成");

									if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
--										for key,value in ipairs(SyncMain.localFiles) do
--											LOG.std(nil,"debug","filename",value.filename);
--											LOG.std(nil,"debug","needChange",value.needChange);
--										end
										
										SyncMain.remoteSync.uploadOne();
									else
										SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1; -- 如果不等最大计数则更新
										SyncMain.remoteSync.updateOne();
									end
								else
									_guihelper.MessageBox(L"更新失败");
									syncGUIIndex = syncGUIIndex + 1;
									syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
									--syncToDataSourceGUI.finish();
									--SyncMain.finish = true;
								end
							end);
						else
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.localFiles[LocalIndex].filename .. "版本一致，跳过");

							if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
								for key,value in ipairs(SyncMain.localFiles) do
									LOG.std(nil,"debug","filename",value.filename);
									LOG.std(nil,"debug","needChange",value.needChange);
								end
								SyncMain.remoteSync.uploadOne();
							else
								SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
								SyncMain.remoteSync.updateOne();
							end
						end
					else
						-- LOG.std(nil,"debug","delete-filename",self.localFiles[LocalIndex].filename);
						-- LOG.std(nil,"debug","delete-sha1",self.localFiles[LocalIndex].filename);

						-- 如果过数据源不删除存在，则删除本地的文件
						SyncMain.remoteSync.deleteOne();
					end
				else
					if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
						SyncMain.remoteSync.uploadOne();
					else
						SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
						SyncMain.remoteSync.updateOne();
					end
				end
			end

			-- 获取数据源仓文件
			SyncMain:getFileShaListService(SyncMain.foldername.utf8, function(data, err)
				LOG.std(nil,"debug","SyncMain:getFileShaListService-data",data);
				LOG.std(nil,"debug","SyncMain:getFileShaListService-err",err);

				local hasReadme = false;
				local hasGitAttribute = false;

				for key,value in ipairs(SyncMain.localFiles) do
					if(value.filename == "README.md") then
						hasReadme = true;
					end

					if(value.filename == ".gitattribute") then
						hasGitAttribute = true;
					end
				end

				if(not hasReadme) then
					local filePath = SyncMain.worldDir.default .. "README.md";
					local file = ParaIO.open(filePath, "w");
					local content = Encoding.Utf8ToDefault(KeepworkGen.readmeDefault);

					file:write(content,#content);
					file:close();

					--LOG.std(nil,"debug","filePath",filePath);

					local readMeFiles = {
						filename       = "README.md",
						file_path      = filePath,
						file_content_t = content,
					};

					--LOG.std(nil,"debug","localFiles",readMeFiles);
					local otherFile = commonlib.copy(SyncMain.localFiles[#SyncMain.localFiles]);
					SyncMain.localFiles[#SyncMain.localFiles] = readMeFiles;
					SyncMain.localFiles[#SyncMain.localFiles + 1] = otherFile;
				end

				if(not hasGitAttribute) then
					local filePath = SyncMain.worldDir.default .. ".gitattribute";
					local file = ParaIO.open(filePath, "w");
					local content = LocalService.gitAttribute;

					file:write(content,#content);
					file:close();

					local gitAttributeFiles = {
						filename       = ".gitattribute",
						file_path      = filePath,
						file_content_t = content,
					};

					local tableLength = #SyncMain.localFiles;

					for i = tableLength, 1 do
						SyncMain.localFiles[tableLength + 1] = SyncMain.localFiles[tableLength];
					end

					SyncMain.localFiles[1] = gitAttributeFiles;
				end

				SyncMain.totalLocalIndex = #SyncMain.localFiles;
				syncGUItotal = #SyncMain.localFiles;

				for i=1,#SyncMain.localFiles do
					-- LOG.std(nil,"debug","localFiles",self.localFiles[i]);
					SyncMain.localFiles[i].needChange = true;
					i = i + 1;
				end

				if (err ~= 409 and err ~= 404) then --409代表已经创建过此仓
					SyncMain.dataSourceFiles = data;
					SyncMain.totalDataSourceIndex = #SyncMain.dataSourceFiles;

					SyncMain.remoteSync.updateOne();
				else
					SyncMain.remoteSync.uploadOne();
				end
			end);
		end
	end

	------------------------------------------------------------------------

	if(SyncMain.remoteRevison == 0) then
		SyncMain:create(SyncMain.foldername.utf8,function(data, err)
			--LOG.std(nil,"debug","SyncMain:create",data);
			--LOG.std(nil,"debug","SyncMain:create",err);

			if(data == true or err == 422 or err == 201) then
				syncToDataSourceGo();
			else
				--if(data.name ~= self.foldername) then
				_guihelper.MessageBox(L"数据源创建失败");
				syncToDataSourceGUI.finish();
				return;
				--end
			end
		end);
	else
		LOG.std(nil,"debug","SyncMain:syncToGithub","非首次同步");

		if(loginMain.dataSourceType == "gitlab") then
			SyncMain:setGitlabProjectId(SyncMain.foldername.utf8);
		end

		syncToDataSourceGo();
	end
end

function SyncMain:showBeyondVolume()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/BeyondVolume.html", 
		name = "BeyondVolume", 
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

function SyncMain.getBeyondMsg()
	local str = format("世界" .. SyncMain.foldername.utf8 .. "文件总大小超过了%dMB, 请清理不必要的文件后才能上传。(VIP用户最大可上传%dMB)", 15, 50);

	return str;
end

function SyncMain.openWorldFolder()
	SyncMain.closeBeyondPage();
	local path = ParaIO.GetCurDirectory(0) .. LocalLoadWorld.GetWorldFolder() .. "/" .. SyncMain.foldername.default;
	ParaGlobal.ShellExecute("open", path, "", "", 1);
end

function SyncMain:checkWorldSize()
	local files = commonlib.Files.Find({}, SyncMain.worldDir.default, 5, 5000, function(item)
		return true;
	end);

	local filesTotal = 0;
	for key, value in ipairs(files) do
		filesTotal = filesTotal + tonumber(value.filesize);
	end
	
	local maxSize = 15 * 1024 * 1024;

	LOG.std(nil,"debug","worldSize",filesTotal);

	if(filesTotal > maxSize) then
		SyncMain:showBeyondVolume();
		return true;
	else
		return false;
	end
end

function SyncMain:setGitlabProjectId(_foldername)
	for key,value in ipairs(SyncMain.remoteWorldsList) do
		if(value.worldsName == _foldername) then
			GitlabService.projectId = value.gitlabProjectId;
		end
	end
end

function SyncMain:getGitlabCommitId(_foldername)
	if(not SyncMain.remoteWorldsList) then
		SyncMain.remoteWorldsList = {};
	end

	for key,value in ipairs(SyncMain.remoteWorldsList) do
		if(value.worldsName == _foldername) then
			return value.commitId;
		end
	end
end

function SyncMain:genIndexMD(_worldList, _callback)
	local function gen(keepworkId)
		SyncMain:getFileShaListService(loginMain.keepWorkDataSource, function(data, err)
			LOG.std(nil,"debug","genIndexMD",data);

			local hasIndex      = false;
			local indexPath     = "";
			SyncMain.indexFile  = "";

			local indexPath = loginMain.username .. "/paracraft/index.md";

			for key,value in ipairs(data) do
				if(value.path == indexPath) then
					hasIndex = true;
				end
			end

			local function updateIndexFile()
				LOG.std(nil,"debug","hasIndexO",hasIndex);
				if(hasIndex) then
					LOG.std(nil,"debug","hasIndex",hasIndex);
					SyncMain:getDataSourceContent(loginMain.keepWorkDataSource, indexPath, function(data, err)
						--LOG.std(nil,"debug","getDataSourceContent",data);
						--LOG.std(nil,"debug","getDataSourceContent",err);

						--local content = Encoding.unbase64(data);
						--local paramsText = KeepworkGen:GetContent(content);
						--local params = KeepworkGen:getCommand("worldList", paramsText);
						local worldList;

						if(_worldList)then
							LOG.std(nil,"debug","_worldListA")
							worldList = _worldList;
						else
							LOG.std(nil,"debug","_worldListB")
							worldList = SyncMain.remoteWorldsList;
						end

						worldList = KeepworkGen:setCommand("worldList",worldList);
						SyncMain.indexFile = KeepworkGen:SetAutoGenContent("", worldList)

						LOG.std(nil,"debug","SyncMain.indexFile",SyncMain.indexFile);

						SyncMain:updateService(
							loginMain.keepWorkDataSource,
							indexPath,
							SyncMain.indexFile,
							"",
							function(isSuccess, path)
								LOG.std(nil,"debug","updateService-indexFile",isSuccess)
								LOG.std(nil,"debug","updateService-indexFile",path)
								if(_callback) then
									_callback();
								end
							end,
							keepworkId
						);
					end, keepworkId)
				else
					local worldList;

					if(_worldList)then
						LOG.std(nil,"debug","_worldListA")
						worldList = _worldList;
					else
						LOG.std(nil,"debug","_worldListB")
						worldList = SyncMain.remoteWorldsList;
					end

					worldList = KeepworkGen:setCommand("worldList",worldList);
					SyncMain.indexFile = KeepworkGen:SetAutoGenContent("", worldList);

					LOG.std(nil,"debug","SyncMain.indexFile",SyncMain.indexFile);

					SyncMain:uploadService(
						loginMain.keepWorkDataSource,
						indexPath,
						SyncMain.indexFile,
						function(data, err) 
							if(_callback) then
								_callback();
							end
						end,
						keepworkId
					);
				end
			end

			updateIndexFile();
		end, nil, keepworkId);
	end
	
	if(loginMain.dataSourceType == "github") then
		gen();
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getProjectIdByName(loginMain.keepWorkDataSource,function(keepworkId)
			echo("keepworkId");
			echo(keepworkId);
			gen(keepworkId);
		end);
	end
end

function SyncMain:genWorldMD(worldInfor, _callback)
	local function gen(keepworkId)
		SyncMain:getFileShaListService(loginMain.keepWorkDataSource, function(data, err)
			LOG.std(nil,"debug","genWorldMD",data);
			local hasWorldFile  = false;
			local worldFilePath = "";
			local worldUrl      = "";
			local username      = "";
			SyncMain.worldFile  = "";

			if(loginMain.dataSourceType == "gitlab") then
				worldUrl = "http://git.keepwork.com/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/repository/archive.zip?ref=master";
			else

			end

			local worldFilePath =  loginMain.username .. "/paracraft/world_" .. worldInfor.worldsName .. ".md";

			for key,value in ipairs(data) do
				if(value.path == worldFilePath) then
					hasWorldFile = true;
				end
			end

			local function updateWorldFile()
				if(hasWorldFile) then
					LOG.std(nil,"debug","hasWorldFile",hasWorldFile);
					SyncMain:getDataSourceContent(loginMain.keepWorkDataSource, worldFilePath, function(data, err)
						local content    = Encoding.unbase64(data);
						local paramsText = KeepworkGen:GetContent(content);
						local params     = KeepworkGen:getCommand("world3D", paramsText);

						--if(params.version ~= worldInfor.revision) then
						local world3D = {
							worldName	  = worldInfor.worldsName,
							worldUrl	  = worldUrl,
							logoUrl		  = worldInfor.preview,
							desc		  = "",
							username	  = username,
							visitCount    = 1,
							favoriteCount = 1,
							updateDate	  = worldInfor.modDate,
							version		  = worldInfor.revision,
							filesTotals   = worldInfor.filesTotals,
							opusId        = worldInfor.opusId,
						}

						world3D = KeepworkGen:setCommand("world3D",world3D);
						SyncMain.worldFile = KeepworkGen:SetAutoGenContent(content, world3D);

						LOG.std(nil,"debug","worldFile",SyncMain.worldFile);

						SyncMain:updateService(
							loginMain.keepWorkDataSource,
							worldFilePath,
							SyncMain.worldFile,
							"",
							function(isSuccess, path)
								LOG.std(nil,"debug","updateService-worldFile",isSuccess)
								LOG.std(nil,"debug","updateService-worldFile",path)
								if(_callback) then
									_callback();
								end
							end,
							keepworkId
						);
						--end
					end, keepworkId)
				else
					LOG.std(nil,"debug","hasWorldFile",hasWorldFile);
					local world3D = {
						worldName	  = worldInfor.worldsName,
						worldUrl	  = worldUrl,
						logoUrl		  = worldInfor.preview,
						desc		  = "",
						username	  = username,
						visitCount    = 1,
						favoriteCount = 1,
						updateDate	  = worldInfor.modDate,
						version		  = worldInfor.revision,
						opusId        = worldInfor.opusId,
						filesTotals   = worldInfor.filesTotals,
					}

					world3D = KeepworkGen:setCommand("world3D",world3D);

					SyncMain.worldFile = KeepworkGen:SetAutoGenContent("", world3D)
					SyncMain.worldFile = SyncMain.worldFile .. "\n\r" .. worldInfor.readme;
					SyncMain.worldFile = SyncMain.worldFile .. "\n\r" .. KeepworkGen:setCommand("comment");

					LOG.std(nil,"debug","worldFile",SyncMain.worldFile);
				
					SyncMain:uploadService(
						loginMain.keepWorkDataSource,
						worldFilePath,
						SyncMain.worldFile,
						function(data, err)
							if(_callback) then
								_callback();
							end
						end,
						keepworkId
					);
				end
			end

			updateWorldFile();
		end, nil, keepworkId);
	end

	if(loginMain.dataSourceType == "github") then
		gen();
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getProjectIdByName(loginMain.keepWorkDataSource,function(keepworkId)
			gen(keepworkId);
		end);
	end
end

function SyncMain:deleteWorldMD(_path, _callback)
	local function deleteFile(keepworkId)
		local path = loginMain.username ..  "/paracraft/world_" ..   _path;
		LOG.std(nil,"debug","path",path);
		SyncMain:deleteFileService(loginMain.keepWorkDataSource, path, "", function(data, err)
			_callback();
		end, keepworkId)
	end

	if(loginMain.dataSourceType == "github") then
		deleteFile();
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getProjectIdByName(loginMain.keepWorkDataSource,function(keepworkId)
			deleteFile(keepworkId);
		end);
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
		isTopLevel = true,
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
	--local world      = InternetLoadWorld:GetCurrentWorld();
	local foldername = SyncMain.selectedWorldInfor.foldername;

	--LOG.std(nil,"debug","world",world);
	--LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);

	if(not SyncMain.selectedWorldInfor) then
		_guihelper.MessageBox(L"请先选择世界");
		return;
	end

	local function deleteNow()
		if(SyncMain.selectedWorldInfor.RemoveLocalFile and SyncMain.selectedWorldInfor:RemoveLocalFile()) then
			InternetLoadWorld.RefreshAll();
		elseif(SyncMain.selectedWorldInfor.remotefile) then
			local targetDir = SyncMain.selectedWorldInfor.remotefile:gsub("^local://", ""); -- local world, delete all files in folder and the folder itself.

			LOG.std(nil,"debug","SyncMain.deleteWorldLocal",targetDir);
			
			if(SyncMain.selectedWorldInfor.is_zip) then

				if(ParaIO.DeleteFile(targetDir)) then
					if(type(_callback) == 'function') then
						_callback(foldername);
					end
				else
					_guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
				end
			else
				if(GameLogic.RemoveWorldFileWatcher) then
					GameLogic.RemoveWorldFileWatcher(); -- file watcher may make folder deletion of current world directory not working.
				end

				if(commonlib.Files.DeleteFolder(targetDir)) then  
					if(type(_callback) == 'function') then
						_callback(foldername);
					end
				else
					_guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
				end
			end

			SyncMain.DeletePage:CloseWindow();
			loginMain.RefreshCurrentServerList();

			if(not WorldCommon.GetWorldInfo()) then
				MainLogin.state.IsLoadMainWorldRequested = nil;
				MainLogin:next_step();
			end
		end
	end

	if(SyncMain.selectedWorldInfor.status == nil or SyncMain.selectedWorldInfor.status == 1) then
		deleteNow();
	else
		_guihelper.MessageBox(format(L"确定删除本地世界:%s?", SyncMain.selectedWorldInfor.text or ""), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				deleteNow();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end

	
end

function SyncMain.deleteWorldRemote()
	if(loginMain.dataSourceType == "github") then
		SyncMain.deleteWorldGithubLogin();
	elseif(loginMain.dataSourceType == "gitlab") then
		SyncMain.deleteWorldGitlab();
	end
end

function SyncMain.deleteWorldGithubLogin()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/DeleteWorldGithub.html", 
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
	local foldername = SyncMain.selectedWorldInfor.foldername;
	foldername = Encoding.Utf8ToDefault(foldername);

	local AuthUrl    = "https://api.github.com/authorizations";
	local AuthParams = {
		scopes = {
			"delete_repo",
		},
		note   = ParaGlobal.timeGetTime(),
	};
	local basicAuth  = loginMain.dataSourceUsername .. ":" .. _password;
	local AuthToken  = "";

	basicAuth = Encoding.base64(basicAuth);

	HttpRequest:GetUrl({
		url     = AuthUrl,
		json    = true,
		headers = {
			Authorization    = "Basic " .. basicAuth,
			["User-Agent"]   = "npl",
			["content-type"] = "application/json"
		},
		form    = AuthParams
    },function(data,err)
    	local basicAuthData = data;
    	AuthToken = basicAuthData.token;

	    _guihelper.MessageBox(format(L"确定删除Gihub远程世界:%s?", foldername or ""), function(res)
	    	SyncMain.DeletePage:CloseWindow();

	    	if(res and res == 6) then
	    		GithubService:deleteResp(foldername, AuthToken, function(data,err)
	    			--LOG.std(nil,"debug","GithubService:deleteResp",err);
	    			if(err == 204) then
	    				SyncMain.deleteKeepworkWorldsRecord();
	    			else
						_guihelper.MessageBox(L"远程仓库不存在，请联系管理员");
						if(not WorldCommon.GetWorldInfo()) then
							MainLogin.state.IsLoadMainWorldRequested = nil;
							MainLogin:next_step();
						end
					end
	    		end)
	    	end
	    end);
	end)
end

function SyncMain.deleteWorldGitlab()
	local foldername = SyncMain.selectedWorldInfor.foldername;
	
	SyncMain:setGitlabProjectId(foldername);

	_guihelper.MessageBox(format(L"确定删除Gitlab远程世界:%s?", foldername or ""), function(res)
	    SyncMain.DeletePage:CloseWindow();

	    if(res and res == 6) then
	    	GitlabService:deleteResp(foldername, function(data, err)
				if(err == 202) then
					SyncMain.deleteKeepworkWorldsRecord();
				else
					_guihelper.MessageBox(L"远程仓库不存在，请联系管理员");
					if(not WorldCommon.GetWorldInfo()) then
						MainLogin.state.IsLoadMainWorldRequested = nil;
						MainLogin:next_step();
					end
				end
			end);
	    end
	end);
end

function SyncMain.deleteKeepworkWorldsRecord()
	local foldername = SyncMain.selectedWorldInfor.foldername;
	local url = loginMain.site .. "/api/mod/worldshare/models/worlds";

	LOG.std(nil,"debug","deleteKeepworkWorldsRecord",url);
	LOG.std(nil,"debug","deleteKeepworkWorldsRecord",foldername);
	LOG.std(nil,"debug","deleteKeepworkWorldsRecord",loginMain.token);

	HttpRequest:GetUrl({
		method  = "DELETE",
		url     = url,
		form    = {
			worldsName = foldername,
		},
		json    = true,
		headers = {
			Authorization = "Bearer " .. loginMain.token,
		},
	},function(data, err)
		LOG.std(nil,"debug","deleteKeepworkWorldsRecord",data)
		LOG.std(nil,"debug","deleteKeepworkWorldsRecord",err)

		if(err == 204) then
			loginMain.RefreshCurrentServerList();

			SyncMain.DeletePage:CloseWindow();

			if(not WorldCommon.GetWorldInfo()) then
				MainLogin.state.IsLoadMainWorldRequested = nil;
				MainLogin:next_step();
			end

			SyncMain:deleteWorldMD(foldername,function()
				HttpRequest:GetUrl({
					url  = loginMain.site.."/api/mod/worldshare/models/worlds",
					json = true,
					headers = {Authorization = "Bearer "..loginMain.token},
					form = {amount = 100},
				},function(worldList, err)
					LOG.std(nil,"debug","worldList-data",worldList);
					SyncMain:genIndexMD(worldList);
				end);
			end)
		end
	end);
end

function SyncMain.deleteWorldAll()
	SyncMain.deleteWorldLocal(function()
		SyncMain.deleteWorldRemote();
	end);
end

function SyncMain:create(_foldername,_callback)
	if(loginMain.dataSourceType == "github") then
		GithubService:create(_foldername,_callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:init(_foldername,_callback);
	end
end

function SyncMain:getDataSourceContent(_foldername, _path, _callback, _projectId)
	if(loginMain.dataSourceType == "github") then
		GithubService:getContent(_foldername, _path, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getContent(_path, _callback,_projectId);
	end
end

function SyncMain:uploadService(_foldername, _filename, _file_content_t, _callback, _projectId)
	if(loginMain.dataSourceType == "github") then
		GithubService:upload(_foldername,_filename,_file_content_t,_callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:writeFile(_filename,_file_content_t,_callback, _projectId);
	end
end

function SyncMain:updateService(_foldername, _filename, _file_content_t, _sha, _callback, _projectId)
	if(loginMain.dataSourceType == "github") then
		GithubService:update(_foldername, _filename, _file_content_t, _sha, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:update(_filename, _file_content_t, _sha, _callback, _projectId);
	end
end

function SyncMain:deleteFileService(_foldername, _path, _sha, _callback, _projectId)
	if(loginMain.dataSourceType == "github") then
		GithubService:deleteFile(_foldername, _path, _sha, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:deleteFile(_path, _sha, _callback, _projectId);
	end
end

function SyncMain:getFileShaListService(_foldername, _callback, _commitId, _projectId)
	if(loginMain.dataSourceType == "github") then
		GithubService:getFileShaList(_foldername, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getTree(_callback, _commitId, _projectId);
	end
end

function SyncMain:getCommits(_callback, _projectId)
	if(loginMain.dataSourceType == "github") then
		GithubService:getCommits(_foldername, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:listCommits(_callback, _projectId);
	end
end