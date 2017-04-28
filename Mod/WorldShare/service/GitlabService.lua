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
NPL.load("(gl)Mod/WorldShare/login.lua");
NPL.load("(gl)Mod/WorldShare/main.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)Mod/WorldShare/SyncMain.lua");

local HttpRequest   = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local login		    = commonlib.gettable("Mod.WorldShare.login");
local GitEncoding   = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local WorldShare    = commonlib.gettable("Mod.WorldShare");
local Encoding      = commonlib.gettable("commonlib.Encoding");
local SyncMain      = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService");

GitlabService.inited = false;

function GitlabService:apiGet(_url, _callback)
	_url = login.apiBaseUrl .. "/" .._url

	LOG.std(nil,"debug","apiGet-url",_url);
	HttpRequest:GetUrl({
		url     = _url,
		json    = true,
		headers = {
			["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
		},
	},_callback);
end

function GitlabService:apiPost(_url, _params, _callback)
	_url = login.apiBaseUrl .. "/" .._url

	HttpRequest:GetUrl({
		url       = _url,
		json      = true,
		headers   = {
			["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = _params,
	},_callback);
end

function GitlabService:apiPut(_url, _params, _callback)
	_url = login.apiBaseUrl .. "/" .._url

	HttpRequest:GetUrl({
		method     = "PUT",
		url        = _url,
		json       = true,
	  	headers    = {
		  	["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = _params
	},_callback);
end

function GitlabService:apiDelete(_url, _params, _callback)
	_url = login.apiBaseUrl .. "/" .._url

	local github_token = login.dataSourceToken;
	
	LOG.std(nil,"debug","GitlabService:apiDelete",github_token);
	LOG.std(nil,"debug","login.apiBaseUrl .. _url",_url);

	HttpRequest:GetUrl({
		method     = "DELETE",
		url        = _url,
		json       = true,
	  	headers    = {
	  		["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = _params,
	},function(data ,err) 
		LOG.std(nil,"debug","GitlabService:data",data);
		LOG.std(nil,"debug","GitlabService:err",err);
		_callback(data, err)
	end);
end

function GitlabService:getFileUrlPrefix(_projectId)
	if(not _projectId) then
		_projectId = GitlabService.projectId;
	end

    return '/projects/' .. _projectId .. '/repository/files/';
end

function GitlabService:getCommitMessagePrefix()
    return "keepwork commit: ";
end

-- 获得文件列表
function GitlabService:getTree(_callback, _projectId)
	if(not _projectId) then
		_projectId = GitlabService.projectId;
	end

    local url = '/projects/' .. _projectId .. '/repository/tree?recursive=true';

	GitlabService:apiGet(url,function(data, err)
		for key,value in ipairs(data) do
			value.sha = value.id;
		end

		_callback(data,err);
	end);
end

-- commit
function GitlabService:listCommits(data, cb, errcb)
    --data.ref_name = data.ref_name || 'master';
    local url = '/projects/' .. GitlabService.projectId .. '/repository/commits';
    GitlabService:httpRequest('GET', url, data, cb, errcb);
end

-- 写文件
function GitlabService:writeFile(_filename, _file_content_t, _callback, _projectId) --params, cb, errcb
    local url = GitlabService:getFileUrlPrefix(_projectId) .. _filename;
	LOG.std(nil,"debug","GitlabService:writeFile",url);

	local params = {
		commit_message = GitlabService:getCommitMessagePrefix() .. _filename,
		branch		   = "master",
		content 	   = _file_content_t,
	}

	GitlabService:apiPost(url, params, function(data, err)
		LOG.std(nil,"debug","GitlabService:writeFile",data);
		LOG.std(nil,"debug","GitlabService:writeFile",err);

		if(err == 201) then
			_callback(true,_filename, data, err);
		else
			_callback(false,_filename, data, err);
		end
	end);
end

--更新文件
function GitlabService:update(_filename, _file_content_t, _sha, _callback, _projectId)
	local url = GitlabService:getFileUrlPrefix(_projectId) .. _filename;

	local params = {
		commit_message = GitlabService:getCommitMessagePrefix() .. _filename,
		branch		   = "master",
		content 	   = _file_content_t,
	}

	GitlabService:apiPut(url, params, function(data, err)
		LOG.std(nil,"debug","GitlabService:update",data);
		LOG.std(nil,"debug","GitlabService:update",err);

		if(err == 200) then
			_callback(true,_filename, data, err);
		else
			_callback(false,_filename, data, err);
		end
	end);
end

-- 获取文件
function GitlabService:getContent(_path, _callback, _projectId)
    local url = GitlabService:getFileUrlPrefix(_projectId) .. _path .. '?ref=master';

	--LOG.std(nil,"debug","apiGet-url",url);
	GitlabService:apiGet(url, function(data, err)
		LOG.std(nil,"debug","apiGet-data",data);
		LOG.std(nil,"debug","apiGet-err",err);

		_callback(data.content, err);
	end);
end

-- 获取文件
function GitlabService:getContentWithRaw(_foldername, _path, _callback)
	_foldername = GitEncoding.base64(_foldername);

	local url  = login.rawBaseUrl .. "/" .. login.dataSourceUsername .. "/" .. _foldername .. "/raw/master/" .. _path;

	HttpRequest:GetUrl({
		url     = url,
		json    = true,
		headers = {
			["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
		},
	},function(data, err)
		if(err == 200) then
			_callback(data, err);
		end
	end);
end

-- 删除文件
function GitlabService:deleteFile(_path, _sha, _callback, _projectId)
    local url = GitlabService:getFileUrlPrefix(_projectId) .. _path;

	local params = {
		commit_message = GitlabService:getCommitMessagePrefix() .. _path,
		branch         = 'master',
	}

	LOG.std(nil,"debug","deleteFile",url);
	GitlabService:apiDelete(url, params, function(data, err)
		LOG.std(nil,"debug","deleteFile",data);
		LOG.std(nil,"debug","deleteFilerr",err);
		_callback(data, err);
	end);
end

--删除仓
function GitlabService:deleteResp(_foldername, _callback, _projectId)
	if(not _projectId) then
		_projectId = GitlabService.projectId;
	end

	local url = "/projects/" .. _projectId;

	GitlabService:apiDelete(url, {}, _callback);
end

--通过仓名获取仓ID
function GitlabService:getProjectIdByName(_name, _callback)
	local url   = "/projects";
	
	GitlabService:apiGet(url .. "?owned=true",function(projectList,err)
		--LOG.std(nil,"debug","projectList",projectList);
		for i=1,#projectList do
            if (projectList[i].name == _name) then
				_callback(projectList[i].id);
			end
		end
	end);
end

-- 初始化
function GitlabService:init(_foldername, _callback)
	_foldername = GitEncoding.base64(_foldername);
	local url   = "/projects";

	GitlabService:apiGet(url .. "?owned=true",function(projectList,err)
		if(projectList) then
			for i=1,#projectList do
				if (projectList[i].name == _foldername) then
					GitlabService.projectId = projectList[i].id;

					if(SyncMain.worldName) then
						WorldShare:SetWorldData("gitLabProjectId", GitlabService.projectId, SyncMain.worldName);
						WorldShare:SaveWorldData(SyncMain.worldName);
					else
						WorldShare:SetWorldData("gitLabProjectId", GitlabService.projectId);
						WorldShare:SaveWorldData();
					end

					_callback(true,err);
					return;
				end

				local params = {
					name = _foldername,
					request_access_enabled = true,
					visibility = "public",
				};

				GitlabService:apiPost(url, params, function(data,err)
					if(data.id ~= nil) then
						GitlabService.projectId = data.id;

						if(SyncMain.worldName) then
							WorldShare:SetWorldData("gitLabProjectId", GitlabService.projectId, SyncMain.worldName);
							WorldShare:SaveWorldData(SyncMain.worldName);
						else
							WorldShare:SetWorldData("gitLabProjectId", GitlabService.projectId);
							WorldShare:SaveWorldData();
						end

						LOG.std(nil,"debug","GitlabService.projectId",GitlabService.projectId);
						LOG.std(nil,"debug","err",err);
						_callback(true,err);
						return;
					end
				end);
			end
		else
			_callback(false,err);
		end
        
	end);
end