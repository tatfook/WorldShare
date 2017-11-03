--[[
Title: GitlabService
Author(s):  big
Date:  2017.4.15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService");
------------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)Mod/WorldShare/main.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");

local HttpRequest   = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local loginMain     = commonlib.gettable("Mod.WorldShare.login.loginMain");
local GitEncoding   = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local WorldShare    = commonlib.gettable("Mod.WorldShare");
local Encoding      = commonlib.gettable("commonlib.Encoding");
local SyncMain      = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService");

GitlabService.inited  = false;
GitlabService.tree    = {};
GitlabService.newTree = {};
GitlabService.blob    = {};
GitlabService.getTreePage     = 1;
GitlabService.getTreePer_page = 100;

function GitlabService:checkSpecialCharacter(filename)
	local specialCharacter = {"【" , "】" , "《" , "》" , "·" , " ", "，", "●"};

	for key, item in pairs(specialCharacter) do
		if(string.find(_filename,item)) then
			commonlib.TimerManager.SetTimeout(function()
				_guihelper.MessageBox(format(L"%s文件包含了特殊字符或空格，请重命名文件，否则无法上传。", filename));
			end,500);
			
			return true;
		end
	end

	return false;
end

function GitlabService:checkProjectId(projectId, foldername, callback)
	if(not projectId) then
		projectId = GitlabService.projectId;
	end

	if(not projectId) then
		if(foldername) then
			GitlabService:getProjectIdByName(foldername, function(projectId)
				if(projectId) then
					GitlabService.projectId = projectId;
					
					if(type(callback) == "function") then
						callback(projectId);
					end
				else
					_guihelper.MessageBox(L"获取projectId失败");
				end
			end);
		else
			_guihelper.MessageBox(L"获取projectId失败");
		end
	else
		if(type(callback) == "function") then
			callback(projectId);
		end
	end
end

function GitlabService:apiGet(url, callback)
	url = loginMain.apiBaseUrl .. "/" .. url;

	HttpRequest:GetUrl({
		url     = url,
		json    = true,
		headers = {
			["PRIVATE-TOKEN"] = loginMain.dataSourceToken,
			["User-Agent"]    = "npl",
		},
	},function(data ,err) 
		if(type(callback) == "function") then
			callback(data, err);
		end
	end);
end

function GitlabService:apiPost(url, params, callback)
	url = loginMain.apiBaseUrl .. "/" .. url;

	HttpRequest:GetUrl({
		method    = "POST",
		url       = url,
		json      = true,
		headers   = {
			["PRIVATE-TOKEN"] = loginMain.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = params,
	},function(data ,err)
		if(type(callback) == "function") then
			callback(data, err);
		end
	end);
end

function GitlabService:apiPut(url, params, callback)
	url = loginMain.apiBaseUrl .. "/" .. url;

	HttpRequest:GetUrl({
		method     = "PUT",
		url        = url,
		json       = true,
	  	headers    = {
		  	["PRIVATE-TOKEN"] = loginMain.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = params
	},function(data ,err) 
		if(type(callback) == "function") then
			callback(data, err);
		end
	end);
end

function GitlabService:apiDelete(url, params, callback)
	url = loginMain.apiBaseUrl .. "/" .. url;
	
	HttpRequest:GetUrl({
		method     = "DELETE",
		url        = _url,
		json       = true,
	  	headers    = {
	  		["PRIVATE-TOKEN"] = loginMain.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = params,
	},function(data ,err) 
		if(type(callback) == "function") then
			callback(data, err);
		end
	end);
end

function GitlabService:getFileUrlPrefix(projectId)
    return 'projects/' .. projectId .. '/repository/files/';
end

function GitlabService:getCommitMessagePrefix()
    return "keepwork commit: ";
end

-- 获得文件列表
function GitlabService:getTree(callback, commitId, projectId, foldername)
	local function go(projectId)
		local url = 'projects/' .. projectId .. '/repository/tree?';
	
		if(commitId) then
			url = url .. "?ref=" .. commitId;
		end

		GitlabService.blob = {};
		GitlabService.tree = {};

		GitlabService:getTreeApi(url, function(data, err)
			if(err == 404) then
				if(type(callback) == "function") then
					callback(data, err);
				end
			else
				if(type(data) == "table") then
					for key,value in ipairs(data) do
						if(value.type == "tree") then
							GitlabService.tree[#GitlabService.tree + 1] = value;
						end

						if(value.type == "blob") then
							GitlabService.blob[#GitlabService.blob + 1] = value;
						end
					end

					local fetchTimes = 0;

					local function getSubTree()
						if(#GitlabService.tree ~= 0) then
							for key, value in ipairs(GitlabService.tree) do
								GitlabService:getSubTree(function(subTree, subFolderName, commitId, projectId)
									for checkKey, checkValue in ipairs(GitlabService.tree) do
										if(checkValue.path == subFolderName) then
											if(not checkValue.alreadyGet) then
												checkValue.alreadyGet = true;
											else
												return;
											end
										end
									end

									fetchTimes = fetchTimes + 1;

									for subKey, subValue in ipairs(subTree) do
										GitlabService.newTree[#GitlabService.newTree + 1] = subValue;
									end

									if(#GitlabService.tree == fetchTimes)then
										fetchTimes = 0;
										GitlabService.tree = commonlib.copy(GitlabService.newTree);
										GitlabService.newTree = {};

										getSubTree();
									end
								end, value.path, commitId, projectId);
							end
						elseif(#GitlabService.tree == 0) then
							for cbKey, cbValue in ipairs(GitlabService.blob) do
								cbValue.sha = cbValue.id;
							end

							if(type(callback) == "function") then
								callback(GitlabService.blob, 200);
							end
						end
					end

					getSubTree();
				else
					_guihelper.MessageBox(L"获取sha文件失败");
				end
			end
		end);
	end
	
	GitlabService:checkProjectId(projectId, foldername, go);
end

function GitlabService:getSubTree(callback, path, commitId, projectId)
	local url = 'projects/' .. projectId .. '/repository/tree' .. "?path=" .. path;
	
	if(commitId) then
		url = url .. "&ref=" .. commitId;
	end
	
	local tree = {};
	GitlabService:getTreeApi(url, function(data, err)
		for key,value in ipairs(data) do
			if(value.type == "tree") then
				tree[#tree + 1] = value;
			end

			if(value.type == "blob") then
				GitlabService.blob[#GitlabService.blob + 1] = value;
			end
		end

		if(type(callback) == "function") then
			callback(tree, path, commitId, projectId);
		end
	end);
end

function GitlabService:getTreeApi(url, callback)
	local url = url .. "&page=" .. GitlabService.getTreePage .. "&per_page=" .. GitlabService.getTreePer_page;

	GitlabService:apiGet(url, function(data, err)
		if(#data == 0)then
			GitlabService.getTreePage = 1;

			if(GitlabService.tmpTree) then
				if(type(callback) == "function") then
					callback(GitlabService.tmpTree, err);
				end
			else
				if(type(callback) == "function") then
					callback(data, err);
				end
			end

			GitlabService.tmpTree = nil;
		else
			if(GitlabService.tmpTree) then
				for _, value in ipairs(data) do
					GitlabService.tmpTree[#GitlabService.tmpTree + 1] = value;
				end
			else
				GitlabService.tmpTree = data;
			end

			GitlabService.getTreePage = GitlabService.getTreePage + 1;
			GitlabService:getTreeApi(url, callback);
		end
	end)
end

-- commit
function GitlabService:listCommits(callback, projectId, foldername)
	local function go(projectId)
		local url = 'projects/' .. projectId .. '/repository/commits';
		GitlabService:apiGet(url, callback);
	end

	GitlabService:checkProjectId(projectId, foldername, go);
end

-- 写文件
function GitlabService:writeFile(filename, content, callback, projectId, foldername)
	local function go(projectId)
		--[[if(GitlabService:checkSpecialCharacter(_filename)) then
			_callback(false, _filename);
			return;
		end]]

		local url = GitlabService:getFileUrlPrefix(projectId) .. Encoding.url_encode(filename);

		local params = {
			commit_message = GitlabService:getCommitMessagePrefix() .. filename,
			branch		   = "master",
			content 	   = content,
		}

		GitlabService:apiPost(url, params, function(data, err)
			if(err == 201 and type(callback) == "function") then
				callback(true, filename, data, err);
			else
				GitlabService:update(filename, content, sha, callback, projectId);
			end
		end);
	end

	GitlabService:checkProjectId(projectId, foldername, go);
end

--更新文件
function GitlabService:update(filename, content, sha, callback, projectId, foldername)
	local function go(projectId)
		--[[if(GitlabService:checkSpecialCharacter(_filename)) then
			_callback(false, _filename);
			return;
		end]]

		local url = GitlabService:getFileUrlPrefix(projectId) .. Encoding.url_encode(filename);

		local params = {
			commit_message = GitlabService:getCommitMessagePrefix() .. filename,
			branch		   = "master",
			content 	   = content,
		}

		GitlabService:apiPut(url, params, function(data, err)
			if(err == 200) then
				if(type(callback) == "function") then
					callback(true, filename, data, err);
				end
			else
				if(type(callback) == "function") then
					callback(false, filename, data, err);
				end
			end
		end);
	end

	GitlabService:checkProjectId(projectId, foldername, go);
end

-- 获取文件
function GitlabService:getContent(path, callback, projectId)
    local url = GitlabService:getFileUrlPrefix(projectId) .. path .. '?ref=master';

	GitlabService:apiGet(url, function(data, err)
		if(type(callback) == "function") then
			callback(data.content, err);
		end
	end);
end

-- 获取文件
function GitlabService:getContentWithRaw(foldername, path, callback)
	local foldername = GitEncoding.base32(foldername);

	local url  = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. foldername .. "/raw/master/" .. path;

	HttpRequest:GetUrl({
		url     = url,
		json    = true,
		headers = {
			["PRIVATE-TOKEN"] = loginMain.dataSourceToken,
			["User-Agent"]    = "npl",
		},
	},function(data, err)
		if(err == 200 and type(callback) == "function") then
			callback(data, err);
		end
	end);
end

-- 删除文件
function GitlabService:deleteFile(path, sha, callback, projectId, foldername)
	local function go(projectId)
		local url = GitlabService:getFileUrlPrefix(projectId) .. path;

		local params = {
			commit_message = GitlabService:getCommitMessagePrefix() .. path,
			branch         = 'master',
		}

		GitlabService:apiDelete(url, params, function(data, err)
			if(err == 204) then
				if(type(callback) == "function") then
					callback(true);
				end
			else
				if(type(callback) == "function") then
					callback(false);
				end
			end
		end);
	end
   
	GitlabService:checkProjectId(projectId, foldername, go);
end

--删除仓
function GitlabService:deleteResp(foldername, callback, projectId)
	local function go(projectId)
		local url = "/projects/" .. projectId;
		GitlabService:apiDelete(url, {}, callback);
	end

	GitlabService:checkProjectId(projectId, foldername, go);
end

--通过仓名获取仓ID
function GitlabService:getProjectIdByName(name, callback)
	local url = "projects";
	
	GitlabService:apiGet(url .. "?owned=true&page=1&per_page=100",function(projectList, err)
		--echo(projectList);
		for i=1,#projectList do
            if (string.lower(projectList[i].name) == string.lower(name)) then
				if(type(callback) == "function") then
					callback(projectList[i].id);
				end

				return;
			end
		end

		if(type(callback) == "function") then
			callback(false);
		end
	end);
end

-- 初始化
function GitlabService:init(foldername, callback)
	local url   = "projects";

	GitlabService:apiGet(url .. "?owned=true&page=1&per_page=100", function(projectList, err)
		if(projectList) then
			for i=1, #projectList do
				if (projectList[i].name == foldername) then
					GitlabService.projectId = projectList[i].id;

					if(type(callback) == "function") then
						callback(true, "exist");
					end

					return;
				end
			end

			local params = {
				name        = foldername,
				visibility  = "public",
				request_access_enabled = true,
			};

			GitlabService:apiPost(url, params, function(data, err)
				if(data.id ~= nil) then
					GitlabService.projectId = data.id;

					if(type(callback) == "function") then
						callback(true, "create");
					end
					
					return;
				end
			end);
		else
			if(type(callback) == "function") then
				callback(false, err);
			end
		end
	end);
end
