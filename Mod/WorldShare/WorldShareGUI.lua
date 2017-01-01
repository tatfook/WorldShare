--[[
Title: WorldShareGUI
Author(s):  big
Date:  2016.12.10
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
NPL.load("(gl)Mod/WorldShare/GithubService.lua");
NPL.load("(gl)Mod/WorldShare/LocalService.lua");
NPL.load("(gl)Mod/WorldShare/SyncGUI.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)Mod/WorldShare/EncodingGithub.lua");

local WorldShareGUI  = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareGUI"));
local SyncGUI        = commonlib.gettable("Mod.WorldShare.SyncGUI");
local WorldCommon    = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldRevision  = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local ShowLogin      = commonlib.gettable("Mod.WorldShare.ShowLogin");
local GithubService  = commonlib.gettable("Mod.WorldShare.GithubService");
local LocalService   = commonlib.gettable("Mod.WorldShare.LocalService");
local Encoding       = commonlib.gettable("commonlib.Encoding");
local EncodingS      = commonlib.gettable("System.Encoding");
local EncodingGithub = commonlib.gettable("Mod.WorldShare.EncodingGithub");

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
	-- 没有登陆则直接使用离线模式
	if(ShowLogin.login) then
		self:compareRevision();
		self:StartSyncPage();
	end
end

function WorldShareGUI:OnLeaveWorld()
end

function WorldShareGUI:OnInitDesktop()
end

function WorldShareGUI:handleKeyEvent(event)
	-- if(event.keyname == "DIK_SPACE") then
	-- 	_guihelper.MessageBox("you pressed "..event.keyname.." from Demo GUI");
	-- 	return true;
	-- end
end

function WorldShareGUI:compareRevision()
	if(ShowLogin.login) then
		self.getWorldInfo      = WorldCommon:GetWorldInfo();
		--LOG.std(nil,"debug","worldinfo",self.getWorldInfo);

		self.worldDir          = GameLogic.GetWorldDirectory();
		--LOG.std(nil,"debug","self.worldDir",self.worldDir);

		WorldRevisionCheckOut  = WorldRevision:new():init(self.worldDir);
		self.currentRevison    = WorldRevisionCheckOut:Checkout();

		self.foldername = self.worldDir:match("worlds/DesignHouse/([^/]*)/");
		self.foldername = Encoding.DefaultToUtf8(self.foldername);
		-- LOG.std(nil,"debug","self.foldername",self.foldername);

		self.localFiles = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);
		-- LOG.std(nil,"debug","self.localFiles",self.localFiles);

		local hasRevision = false;
		for key,value in ipairs(self.localFiles) do
			LOG.std(nil,"debug","filename",value.filename);
			if(value.filename == "revision.xml") then
				hasRevision = true;
				break;
			end
		end

		if(hasRevision) then
			self.githubRevison  = 0;

			local contentUrl = "https://raw.githubusercontent.com/".. ShowLogin.login .."/".. EncodingGithub.base64(self.foldername) .."/master/revision.xml";
			LOG.std(nil,"debug","contentUrl",contentUrl);

			GithubService:githubGet(contentUrl, function(data,err)
				if(err == 404) then
					Page:CloseWindow();
					self.firstCreate = 1;
					_guihelper.MessageBox(L"Github上暂无数据，请先分享世界");
				end

				self.githubRevison = data;

				if(tonumber(self.currentRevison) ~= tonumber(self.githubRevison)) then
					Page:Refresh(0.01);
				else
					_guihelper.MessageBox(L"远程本地相等")
					Page:CloseWindow();
				end
				
			end);
		else
			commonlib.TimerManager.SetTimeout(function() 
				Page:CloseWindow();
			end, 500)
			
			_guihelper.MessageBox(L"首次请先保存一次再上传");
		end
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

function WorldShareGUI:syncToLocal(_worldDir, _foldername, _callback)
	LOG.std(nil,"debug","worldDir",_worldDir);

	-- 加载进度UI界面
	SyncGUI:ctor();

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
		function downloadOne()
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

								SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);
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
		function updateOne()
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

						SyncGUI:updateDataBar(syncGUIIndex,syncGUItotal, syncGUIFiles);

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
		function deleteOne()
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

		function finish()

			--成功是返回信息给ShowLogin
			if(_callback) then
				_callback(true,self.githubRevison);
			end
		end

		-- 获取github仓文件
		GithubService:getFileShaList(self.foldername, function(data, err)
			if(err ~= 404) then
				if(err == 409) then
					SyncGUI:updateDataBar(-1,-1);
					_guihelper.MessageBox(L"Github上暂无数据");
				else
					NPL.FromJson(data,githubFiles);
				end

				totalLocalIndex  = #self.localFiles;
				totalGithubIndex = #githubFiles.tree;

				for i=1,#githubFiles.tree do
					githubFiles.tree[i].needChange = true;

					if(githubFiles.tree[i].type == "blob") then
						syncGUItotal = syncGUItotal + 1;
					end

					i = i + 1;
				end

				SyncGUI:updateDataBar(syncGUIIndex,syncGUItotal);

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

function WorldShareGUI:syncToGithub()
	-- 加载进度UI界面
	SyncGUI:ctor();

	function syncNow()
		self.localFiles = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);

		if (self.worldDir == "") then
			_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
			return;
		else 
			self.progressText = L'获取文件sha列表';

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
			function uploadOne()
				if (curUploadIndex <= totalLocalIndex) then
					-- LOG.std(nil,"debug","self.localFiles",self.localFiles[curUploadIndex].needChange);
					-- LOG.std(nil,"debug","self.localFiles",self.localFiles[curUploadIndex]);

					if (self.localFiles[curUploadIndex].needChange) then

						self.localFiles[curUploadIndex].needChange = false;
						GithubService:upload(self.foldername, self.localFiles[curUploadIndex].filename, self.localFiles[curUploadIndex].file_content_t,function (bIsDownload,data)
							if (bIsDownload) then
								-- self.progressText = self.localFiles[curUploadIndex].filename .. ' 上传成功' .. (curUploadIndex + 1) .. '/' .. totalGithubIndex;
								
								syncGUIIndex   = syncGUIIndex   + 1;
								-- LOG.std(nil,"debug","data",data);

								--LOG.std(nil,"debug","upload---syncGUIIndex",syncGUIIndex);
								--LOG.std(nil,"debug","upload---syncGUIFiles",syncGUIFiles);
								SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

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
			function updateOne()
				if (curUpdateIndex <= totalGithubIndex) then
					LOG.std(nil,"debug","curUpdateIndex",curUpdateIndex);
					LOG.std(nil,"debug","totalGithubIndex",totalGithubIndex);
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
							GithubService:update(self.foldername, self.localFiles[LocalIndex].filename, self.localFiles[LocalIndex].file_content_t, githubFiles.tree[curUpdateIndex].sha, function (bIsUpdate,content)
								if (bIsUpdate) then
									syncGUIIndex   = syncGUIIndex + 1;
									syncGUIFiles   = self.localFiles[LocalIndex].filename;
									LOG.std(nil,"debug","budeng---syncGUIIndex",syncGUIIndex);
									LOG.std(nil,"debug","budeng---syncGUIFiles",syncGUIFiles);

									SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

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

							SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

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

					GithubService:delete(self.foldername, githubFiles.tree[curUpdateIndex].path, githubFiles.tree[curUpdateIndex].sha, function (bIsDelete)
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

			function finish()
				if(syncGUItotal == syncGUIIndex) then
					LOG.std(nil,"debug","send",ShowLogin.selectedWorldInfor.tooltip)

					local modDateTable = {};

					for modDateEle in string.gmatch(ShowLogin.selectedWorldInfor.tooltip,"[^:]+") do
						modDateTable[#modDateTable+1] = modDateEle;
					end

					GithubService:GetUrl({
						url = ShowLogin.site.."/api/mod/WorldShare/models/worlds/refresh",
						postfields = '{"modDate":"'..modDateTable[1]..'","worldsName":"'..self.foldername..'","revision":"'..self.currentRevison..'"}',
						headers = {Authorization    = "Bearer "..ShowLogin.token,
								   ["content-type"] = "application/json"},
					},function(data) 

					end);

					self.githubRevison = self.currentRevison;
				end
			end

			-- 获取github仓文件
			-- get sha value of the files in github
			GithubService:getFileShaList(self.foldername, function(data,err)
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
					LOG.std(nil,"debug","localFiles",self.localFiles[i]);
					self.localFiles[i].needChange = true;
					i = i + 1;
				end

				if (err ~= 409 and err ~= 404) then --409代表已经创建过此仓
					NPL.FromJson(data,githubFiles);
					
					SyncGUI:updateDataBar(syncGUIIndex,syncGUItotal);

					totalGithubIndex = #githubFiles.tree;
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
		GithubService:create(self.foldername,function(data,err)
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
		LOG.std(nil,"debug","WorldShareGUI:syncToGithub","非首次同步");
		syncNow();
	end
end
