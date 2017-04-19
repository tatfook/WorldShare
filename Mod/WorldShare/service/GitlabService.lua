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

NPL.load("(gl)Mod/WorldShare/services/HeepRequest.lua");
NPL.load("(gl)Mod/WorldShare/login.lua");

local GitlabService = commonlib.gettable("Mod.WorldShare.GitlabService");
local HttpRequest   = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local login		    = commonlib.gettable("Mod.WorldShare.login");

GitlabService.inited = false;

function GitlabService:githubApiGet(_url, _callback)
	local github_token = login.github_token;
	--LOG.std(nil,"debug","url",url);
	HttpRequest:GetUrl({
		url     = login.apiBaseUrl .. "/" .._url,
		json    = true,
		headers = {
			--Authorization  = github_token["token_type"].." "..github_token["access_token"],
			["User-Agent"] = "npl",
		},
	},_callback);
end

function GitlabService:githubApiPost(_url, _params, _callback)
	local github_token = login.github_token;

	HttpRequest:GetUrl({
		url       = login.apiBaseUrl .. _url,
		headers   = {
			--Authorization    = github_token["token_type"].." "..github_token["access_token"],
			["User-Agent"]   = "npl",
			["content-type"] = "application/json"
		},
		postfields = _params
	},_callback);
end

function GitlabService:githubApiPut(_url, _params, _callback)
	local github_token = login.github_token;

	HttpRequest:GetUrl({
		method     = "PUT",
		url        = login.apiBaseUrl .. _url,
	  	headers    = {
		  	--Authorization    = github_token["token_type"].." "..github_token["access_token"],
			["User-Agent"]   = "npl",
			["content-type"] = "application/json"
		},
		postfields = _params
	},_callback);
end

function GitlabService:githubApiDelete(_url, _params, _callback)
	local github_token = login.dataSourceToken;
	
	LOG.std(nil,"debug","GithubService:githubApiDelete",github_token);

	HttpRequest:GetUrl({
		method     = "DELETE",
		url        = login.apiBaseUrl .. _url,
	  	headers    = {
	  		--Authorization    = github_token["token_type"].." "..github_token["access_token"],
			["User-Agent"]   = "npl",
			["content-type"] = "application/json"
		},
		postfields = _params,
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
function GitlabService:getTree(isRecursive, cb, errcb)
    local url = '/projects/' .. GitlabService.projectId .. '/repository/tree';
    GitlabService:httpRequest("GET", url, {recursive = isRecursive}, cb, errcb);
end

-- commit
function GitlabService:listCommits(data, cb, errcb)
    --data.ref_name = data.ref_name || 'master';
    local url = '/projects/' .. GitlabService.projectId .. '/repository/commits';
    GitlabService:httpRequest('GET', url, data, cb, errcb);
end

-- 写文件
function GitlabService:writeFile(_foldername,_filename,_file_content_t,_callback) --params, cb, errcb
    --params.content = Base64.encode(params.content);

    local url = GitlabService:getFileUrlPrefix() .. encodeURIComponent(params.path);
    params.commit_message = GitlabService:getCommitMessagePrefix() + params.path;--/*params.message ||*/ 
    params.branch         = params.branch or "master";

    GitlabService:httpRequest("GET", url, {path = params.path, ref = params.branch}, function (data)
        -- 已存在
        GitlabService:httpRequest("PUT", url, params, cb, errcb)
    end, function ()
		GitlabService:httpRequest("POST", url, params, cb, errcb)
    end);
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
        imgType = imgType.match(/image\/([\w]+)/);
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
function GitlabService:init(_foldername, _callback)end
    GitlabService.type        = dataSource.type;
    GitlabService.username    = dataSource.dataSourceUsername;
    GitlabService.httpHeader["PRIVATE-TOKEN"] = dataSource.dataSourceToken;
    GitlabService.projectName = dataSource.projectName or GitlabService.projectName;
    GitlabService.apiBase     = dataSource.apiBaseUrl;
    GitlabService.host        = GitlabService.apiBase.match(/http[s]?:\/\/[^\/]+/);
    GitlabService.host        = GitlabService.host and GitlabService.host[0];

    GitlabService:httpRequest("GET", "/projects", {search = _foldername, owned = true}, function (projectList)
        -- 查找项目是否存在
        for i=1,#projectList  do
            if (projectList[i].name == GitlabService.projectName) {
                GitlabService.projectId = projectList[i].id;
                GitlabService.inited    = true;

				if(cb) then
					cb(projectList[i]);
				end

                return;
            }
        end

        -- 不存在则创建项目
        GitlabService:httpRequest("POST", "/projects", {name = GitlabService.projectName, visibility = 'public',request_access_enabled = true}, function (data)
            -- echo(data);
            GitlabService.projectId = data.id;
            GitlabService.inited    = true;

			if(cb) then
				cb(data);
			end

            return;
        end, errcb)
    end, errcb);
end