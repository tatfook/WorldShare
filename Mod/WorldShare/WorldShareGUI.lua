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

local WorldShareGUI = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareGUI"));
local WorldCommon   = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local ShowLogin     = commonlib.gettable("Mod.WorldShare.ShowLogin");
local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
local LocalService  = commonlib.gettable("Mod.WorldShare.LocalService");

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
	self:compareRevision();

	if(self.currentRevison ~= self.githubRevison) then
		self:StartSyncPage();
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

function WorldShareGUI:compareRevision()
	self.getWorldInfo = WorldCommon:GetWorldInfo();
	self.worldDir     = GameLogic.GetWorldDirectory();
	self.xmlRevison   = WorldRevision:new():init(worldDir);

	if(ShowLogin.login) then --如果为登陆状态 则比较版本
		self.foldername = self.worldDir:match("worlds/DesignHouse/(%w+)/");

		self.currentRevison = self.xmlRevison["current_revision"];
		self.githubRevison  = 0;

		local contentUrl = "https://raw.githubusercontent.com/".. ShowLogin.login .."/".. self.foldername .."/master/revision.xml";
		GithubService:githubApiGet(contentUrl,function(err,msg,data)
			if(err == 200 and data ~= "") then
				self.githubRevison = data;
				Page:Refresh(0.01);
			end
		end)
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

function WorldShareGUI:syncToGithub()
	self.files = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);

	if (self.worldDir == "") then
		_guihelper.MessageBox("上传目录为空");
		return;
	else 
		self.progressText = 'getting file sha list...';

		local curUploadIndex   = 0;
		local totalUploadIndex = #self.files;

		-- 上传新文件
		local uploadOne = function ()
			if (curUploadIndex < totalUploadIndex) then
				if (self.files[curUploadIndex].needUpload) then
					GithubService:upload(self.foldername, self.files[curUploadIndex].filename, self.files[curUploadIndex].file_content, function (err, msg, bIsUpload)
						if (bIsUpload) then
							self.progressText = self.files[curUploadIndex].filename .. ' upload successfully...' .. (curUploadIndex + 1) .. '/' .. totalUploadIndex;
							curUploadIndex = curUploadIndex + 1;

							if (curUploadIndex >= totalUploadIndex) then
								_guihelper.MessageBox('sync successfully!');
							else
								uploadOne(); --未上传完继续递归上传
							end
						else
							_guihelper.MessageBox(self.files[curUploadIndex].filename .. ' upload failed, please try again later...');
						end
					end);
				else
					curUploadIndex = curUploadIndex + 1;

					if (curUploadIndex >= totalUploadIndex) then
						_guihelper.MessageBox('sync successfully!');
					else
						uploadOne();
					end
				end
			end
		end

		-- 获取github仓文件
		-- get sha value of the files in github
		GithubService.getFileShaList(self.foldername, function (returnInfo)
			if (returnInfo ~= 'false') then --if success, then update files

				self.progressText    = 'get remote file sha list successfully...';
				local aLocalFileName = {};

				for i=0,#self.files do
					aLocalFileName[i] = self.files[i].filename;
					i = i + 1;
				end

				self.progressText = 'get local file list successfully...';

				local curIndex = 0;
				local totalIndex = #returnInfo.tree;

				local updateOne  = function ()         -- update files had existed in github one by one
					if (curIndex < totalIndex) then

						local bIsExisted = aLocalFileName.indexOf(returnInfo.tree[curIndex].path);

						-- compare the files in github with the ones in local host
						if (bIsExisted > -1) then
							-- if existed,
							self.files[bIsExisted].needChange = false;
							if (self.files[bIsExisted].sha1 ~= returnInfo.tree[curIndex].sha) then
								-- 如果本地文件大小有变化，则更新github上的文件
								-- if file existed, and has different sha value, update it
								GithubService.update(self.foldername, returnInfo.tree[curIndex].path, self.files[bIsExisted].file_content, returnInfo.tree[curIndex].sha, function (bIsUpdate)
									if (bIsUpdate) then
										self.progressText = returnInfo.tree[curIndex].path .. ' update successfully...' .. (curIndex + 1) .. '/' .. totalIndex;
										curIndex = curIndex + 1;

										if (curIndex >= totalIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
											self.progressText = 'all file update successfully...';
											uploadOne();
										else
											updateOne();
										end
									else
										_guihelper.MessageBox(returnInfo.tree[curIndex].path .. ' update failed, please try again later...');
									end
								end);
							else
								-- if file exised, and has same sha value, then contain it
								self.progressText = returnInfo.tree[curIndex].path .. ' has existed...' .. (curIndex + 1) .. '/' .. totalIndex;
								curIndex = curIndex + 1;

								if (curIndex >= totalIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
									self.progressText = 'all file update successfully...';
									uploadOne();
								else
									updateOne();
								end
							end
						else
							-- 如果本地不存在，则删除github文件
							-- if file does not exist, delete it
							if (returnInfo.tree[curIndex].type == 'blob') then
								GithubService.delete(self.foldername, returnInfo.tree[curIndex].path, returnInfo.tree[curIndex].sha, function (bIsDelete)
									if (bIsDelete) then
										self.progressText = returnInfo.tree[curIndex].path .. ' delete successfully...' .. (curIndex + 1) .. '/' .. totalIndex;
										curIndex = curIndex + 1;

										if (curIndex >= totalIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
											self.progressText = 'all file update successfully...';
											uploadOne();
										else
											updateOne();
										end
									else
										_guihelper.MessageBox('delete ' .. returnInfo.tree[curIndex].path .. ' failed, please try again later...');
									end
								end);
							else
								self.progressText = returnInfo.tree[curIndex].path .. 'has existed...' .. (curIndex + 1) .. '/' .. totalIndex;
								curIndex = curIndex + 1;

								if (curIndex >= totalIndex) then   -- check whether all files have updated or not. if false, update the next one, if true, upload files.
									self.progressText = 'all file update successfully...';
									uploadOne();
								else
									updateOne();
								end
							end

						end
					end
				end

				updateOne();

			else
				--if the repos is empty, then upload files 
				uploadOne();
			end
		end);
	end
end

function WorldShareGUI:syncToLocal()
	self.localFiles = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);

	if (self.worldDir == "") then
		_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
		return;
	else 
		self.progressText = L'获取文件sha列表';

		local curUpdateIndex   = 1;
		local curDownloadIndex = 1;
		local totalGithubIndex = nil
		local githubFiles      = {};

		-- LOG.std(nil,"debug","WorldShareGUI",curDownloadIndex);
		-- LOG.std(nil,"debug","WorldShareGUI",totalGithubIndex);

		-- 下载新文件
		local downloadOne = function()
			if (curDownloadIndex < totalGithubIndex) then
				if (githubFiles.tree[curDownloadIndex].needChange) then
					LocalService:download(self.foldername, githubFiles.tree[curDownloadIndex].filename, function (bIsDownload)
						if (bIsDownload) then
							self.progressText = githubFiles.tree[curDownloadIndex].filename .. ' 下载成功' .. (curDownloadIndex + 1) .. '/' .. totalGithubIndex;
							curDownloadIndex = curDownloadIndex + 1;

							if (curDownloadIndex >= totalGithubIndex) then
								_guihelper.MessageBox('同步完成');
							else
								downloadOne(); --继续递归上传
							end
						else
							_guihelper.MessageBox(self.localFiles[curDownloadIndex].filename .. ' 下载失败，请稍后再试');
						end
					end);
				else
					curDownloadIndex = curDownloadIndex + 1;

					if (curDownloadIndex >= totalGithubIndex) then
						_guihelper.MessageBox('同步完成');
					else
						downloadOne();--继续递归上传
					end
				end
			end
		end

		-- 更新本地文件
		local updateOne = function()         
			if (curUpdateIndex < totalGithubIndex) then
				local bIsExisted  = false;
				local githubIndex = nil;

				-- 用Gihub的文件和本地的文件对比
				for key,value in ipairs(githubFiles.tree) do
					if(value.path == self.localFiles[curUpdateIndex].filename) then
						bIsExisted  = true;
						githubIndex = key; 
						break;
					end
				end

				LOG.std(nil,"debug","bIsExisted",bIsExisted);
				LOG.std(nil,"debug","githubIndex",bIsExisted);
				-- compare the files in github with the ones in local host
				if (bIsExisted) then
					-- if existed
					githubFiles.tree[githubIndex].needChange = false;
					if (self.localFiles[curUpdateIndex].sha1 ~= githubFiles.tree[githubIndex].sha) then
						-- 更新已存在的文件
						-- if file existed, and has different sha value, update it
						LocalService.update(self.foldername, self.localFiles[curUpdateIndex].filename, self.localFiles[curUpdateIndex].sha1, function (bIsUpdate)
							if (bIsUpdate) then
								self.progressText = returnInfo.tree[curUpdateIndex].path .. ' 更新成功' .. (curUpdateIndex + 1) .. '/' .. totalGithubIndex;
								curUpdateIndex = curUpdateIndex + 1;

								-- 如果当前计数大于最大计数则更新
								if (curUpdateIndex >= totalGithubIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
									self.progressText = L'更新所有文件完成';
									downloadOne();
								else
									updateOne();
								end
							else
								_guihelper.MessageBox(returnInfo.tree[curUpdateIndex].path .. ' 更新失败,请稍后再试');
							end
						end);
					else
						-- if file exised, and has same sha value, then contain it
						self.progressText = returnInfo.tree[curUpdateIndex].path .. ' 文件更新完成' .. (curUpdateIndex + 1) .. '/' .. totalGithubIndex;
						curUpdateIndex = curUpdateIndex + 1;

						if (curUpdateIndex >= totalGithubIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
							self.progressText = '所有文件更新完成';
							downloadOne();
						else
							updateOne();
						end
					end
				else
					-- 如果过github不删除存在，则删除本地的文件
					-- if file does not exist, delete it
					deleteOne();
				end
			end
		end

		-- 删除文件
		local deleteOne = function()
			LocalService.delete(self.foldername, self.localFiles[curUpdateIndex].filename, self.localFiles[curUpdateIndex].sha1, function (bIsDelete)
				if (bIsDelete) then
					self.progressText = returnInfo.tree[curIndex].path .. ' 删除成功' .. (curIndex + 1) .. '/' .. totalIndex;
					curUpdateIndex = curUpdateIndex + 1;

					if (curUpdateIndex >= totalGithubIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
						self.progressText = '所有文件更新完成';
						uploadOne();
					else
						updateOne();
					end
				else
					_guihelper.MessageBox('删除 ' .. self.localFiles[curUpdateIndex].filename .. ' 失败, 请稍后再试');
				end
			end);
		end

		-- 获取github仓文件
		-- get sha value of the files in github
		GithubService:getFileShaList(self.foldername, function(err,msg,data)
			githubFiles = commonlib.copy(data);

			if (githubFiles ~= 'false') then --if success, then update files
				self.progressText    = '获取github仓文件成功';
				
				-- LOG.std(nil,"debug","WorldShareGUI",self.localFiles);
				-- LOG.std(nil,"debug","WorldShareGUI",#self.localFiles);

				for i=1,#githubFiles.tree do
					githubFiles.tree[i].needChange = true;
					i = i + 1;
				end

				self.progressText = '获取本地文件列表成功';

				totalGithubIndex = #githubFiles;
				updateOne();
			else
				--if the repos is empty, then upload files 
				downloadOne();
			end
		end);
	end
end
