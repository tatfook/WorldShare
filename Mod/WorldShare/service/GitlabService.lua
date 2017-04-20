--[[
Title: GitlabService
Author(s):  big
Date:  2017.4.15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/GitlabService.lua");
local GitlabService = commonlib.gettable("Mod.WorldShare.GitlabService");
------------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/services/HttpRequest.lua");
NPL.load("(gl)Mod/WorldShare/login.lua");

local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local HttpRequest   = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local login		    = commonlib.gettable("Mod.WorldShare.login");
local GitEncoding   = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");

GitlabService.inited = false;

function GitlabService:apiGet(_url, _callback)
	HttpRequest:GetUrl({
		url     = login.apiBaseUrl .. "/" .._url,
		json    = true,
		headers = {
			["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
		},
	},_callback);
end

function GitlabService:apiPost(_url, _params, _callback)
	HttpRequest:GetUrl({
		url       = login.apiBaseUrl .. _url,
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
	HttpRequest:GetUrl({
		method     = "PUT",
		url        = login.apiBaseUrl .. _url,
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
	local github_token = login.dataSourceToken;
	
	LOG.std(nil,"debug","GithubService:githubApiDelete",github_token);

	HttpRequest:GetUrl({
		method     = "DELETE",
		url        = login.apiBaseUrl .. _url,
		json       = true,
	  	headers    = {
	  		["PRIVATE-TOKEN"] = login.dataSourceToken,
			["User-Agent"]    = "npl",
			["content-type"]  = "application/json"
		},
		form = _params,
	},_callback);
end

function GitlabService:getFileUrlPrefix()
    return '/projects/' .. GitlabService.projectId .. '/repository/files/';
end

function GitlabService:getCommitMessagePrefix()
    return "keepwork commit: ";
end

function GitlabService:getCommitUrlPrefix(params)
    params = params or {};
    return 'http://' .. GitlabService.host .. '/' .. (params.username or GitlabService.username) .. '/' .. (params.projectName or GitlabService.projectName) .. '/' .. (params.path or '');
end

function GitlabService:getRawContentUrlPrefix(params)
    params = params or {};
    return 'http://' .. GitlabService.host .. '/' .. (params.username or GitlabService.username) .. '/' .. (params.projectName or GitlabService.projectName) .. '/raw/master/' .. (params.path or '');
end

function GitlabService:getContentUrlPrefix(params)
    params = params or {};
    return 'http://' .. GitlabService.host .. '/' .. (params.username or GitlabService.username) .. '/' .. (params.projectName or GitlabService.projectName) .. '/blob/master/' .. (params.path or '');
end

-- 获得文件列表
function GitlabService:getTree(_foldername,_callback)
	LOG.std(nil,"debug","getTree",GitlabService.projectId);
    local url = '/projects/' .. GitlabService.projectId .. '/repository/tree?recursive=true';
	GitlabService:apiGet(url,_callback);
end

-- commit
function GitlabService:listCommits(data, cb, errcb)
    --data.ref_name = data.ref_name || 'master';
    local url = '/projects/' .. GitlabService.projectId .. '/repository/commits';
    GitlabService:httpRequest('GET', url, data, cb, errcb);
end

-- 写文件
function GitlabService:writeFile(_filename,_file_content_t,_callback) --params, cb, errcb
    local url = GitlabService:getFileUrlPrefix() .. _filename;

	local params = {
		commit_message = GitlabService:getCommitMessagePrefix() .. _filename,
		branch		   = "master",
		content 	   = _file_content_t,
	}

	GitlabService:apiPost(url, params, function()
		_callback(true,_filename);
	end);

--    GitlabService:httpRequest("GET", url, {path = params.path, ref = params.branch}, function (data)
--        -- 已存在
--        GitlabService:httpRequest("PUT", url, params, cb, errcb)
--    end, function ()
--		GitlabService:httpRequest("POST", url, params, cb, errcb)
--    end);
end

-- 获取文件
function GitlabService:getContent(params, cb, errcb)
    local url  = GitlabService:getFileUrlPrefix() .. encodeURIComponent(params.path) .. '/raw';
    params.ref = params.ref or "master";
    GitlabService:httpRequest("GET", url, params, cb, errcb);
end

-- 删除文件
function GitlabService:deleteFile(params, cb, errcb)
    local url = GitlabService:getFileUrlPrefix() .. encodeURIComponent(params.path);
    params.commit_message = GitlabService:getCommitMessagePrefix() + params.path;-- /*params.message ||*/
    params.branch         = params.branch or 'master';
    GitlabService:httpRequest("DELETE", url, params, cb, errcb)
end

-- 上传图片
function GitlabService:uploadImage(params, cb, errcb)
    --params path, content
    local path    = params.path;
    local content = params.content;

    if (not path) then
		--之后修改
        --path = 'img_' .. (new Date()).getTime();
    end

    path = 'images/' .. path;
    --/*data:image/png;base64,iVBORw0KGgoAAAANS*/
    content = content.split(',');

    if (content.length > 1) then
        local imgType = content[0];
        content = content[1];
        --imgType = imgType.match(/image\/([\w]+)/);
        imgType = imgType and imgType[1];
        if (imgType) then
            path = path .. '.' .. imgType;
        end
    else
        content = content[0];
    end

    -- echo(content);
    GitlabService:writeFile({
        path = path,
        message  = GitlabService:getCommitMessagePrefix() .. path,
        content  = content,
        encoding = 'base64',
    }, function (data)
		--之后修改
        --cb && cb(gitlab.getRawContentUrlPrefix() + data.file_path);
    end, errcb);
end

-- 初始化
function GitlabService:init(_foldername, _callback)
	_foldername = GitEncoding.base64(_foldername);
	local url   = "/projects";

	GitlabService:apiGet(url .. "?owned=true",function(projectList,err)
        for i=1,#projectList do
            if (projectList[i].name == _foldername) then
				GitlabService.projectId = projectList[i].id;
                _callback(nil,201);
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
					LOG.std(nil,"debug","GitlabService.projectId",GitlabService.projectId);
					LOG.std(nil,"debug","err",err);
					_callback(nil,201);
					return;
				end
			end);
        end
	end);
end