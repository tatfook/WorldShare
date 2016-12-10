--[[
Title: GithubService
Author(s):  big
Date:  2016.12.10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/GithubService.lua");
local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");

local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
local ShowLogin     = commonlib.gettable("Mod.WorldShare.ShowLogin");

GithubService.githubApi = "https://api.github.com/";

function GithubService:getFileShaList(_foldername, _callback)
	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/git/trees/master?recursive=1";

	self:githubApiGet(url,_callback);
end

function GithubService:getAllresponse(_callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "user/repos?access_token=" .. github_token["access_token"] .. "&type=owner";

    self:githubApiGet(url,_callback);
end

function GithubService:upload(_foldername, _fileName, _fileContent, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/contents/" .. fileName .. "?access_token=" .. github_token["access_token"];

	params = {
		message = 'file update',
		content = _fileContent
	}

	self:githubApiPut(url,params,_callback);
end

function GithubService:update(_foldername, _fileName, _fileContent, _sha, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/contents/" .. fileName .. "?access_token=" .. github_token["access_token"];

	params = {
		message = 'file update',
		content = _fileContent,
		sha     = _sha
	}

	self:githubApiPut(url,params,_callback);
end

function GithubService:delete(_foldername, _fileName, _sha, callback)
	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername  .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = {
			message = 'file delete',
			sha = _sha
	}

	self:githubApiDelete(url,params,_callback);
end

function GithubService:githubApiGet(_url,_callback)
	local github_token = ShowLogin.github_token;

	System.os.GetUrl({url = _url,
					  json = true,
					  headers = {Authorization  = github_token["token_type"].." "..github_token["access_token"],
								 ["User-Agent"] = "npl"}
					 },_callback);
end

function GithubService:githubApiPut(_url,_params,_callback)

end

function GithubService:githubApiDelete(_url,_params,_callback)

end