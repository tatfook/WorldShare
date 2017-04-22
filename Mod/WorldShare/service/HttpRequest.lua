--[[
Title: HttpRequest
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
------------------------------------------------------------
]]

local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest");

HttpRequest.tryTimes = 0;

function HttpRequest:GetUrl(_params,_callback)
	System.os.GetUrl(_params,function(err, msg, data)
		LOG.std(nil,"debug","System ERR",{err});

		if(err == 200 or err == 201 or err == 202 or err == 204) then
			_callback(data,err);
			return;
		else
			HttpRequest:retry(err, msg, data, _params, _callback);
		end
	end);
end

function HttpRequest:retry(_err, _msg, _data, _params, _callback)
	LOG.std(nil,"debug","HttpRequest ERR",{_err});

	if(_err == 422 or _err == 404 or _err == 409 or _err == 401) then -- 失败时可直接返回的代码
		_callback(_data,_err); 
		return;
	end

	if(HttpRequest.tryTimes >= 3) then
		_callback(_data,_err);
		HttpRequest.tryTimes = 0;
		return;
	end

	if(_err == 200 or _err == 201 or _err == 204) then
		_callback(_data,_err);
		HttpRequest.tryTimes = 0;
		return
	else
		HttpRequest.tryTimes = HttpRequest.tryTimes + 1;
		
		commonlib.TimerManager.SetTimeout(function()
			HttpRequest:GetUrl(_params, _callback); -- 如果获取失败则递归获取数据
		end, 2100);
	end
end
