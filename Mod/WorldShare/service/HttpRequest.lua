--[[
Title: HttpRequest
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
------------------------------------------------------------
]]
local HttpRequest = NPL.export()

HttpRequest.tryTimes = 1
HttpRequest.maxTryTimes = 3
HttpRequest.defaultSuccessCode = {200, 201, 202, 204}
HttpRequest.defaultFailCode = {400, 401, 404, 409, 422, 500}

function HttpRequest:GetUrl(params, callback, noTryStatus)
    if type(params) ~= "table" and type(params) ~= "string" then
        return false
    end

    local formatParams = {}

    if type(params) == "string" then
        formatParams = {
            method = "GET",
            url = params,
            json = true,
            headers = {}
        }
    end

    if type(params) == "table" then
        formatParams = {
            method = params.method or "GET",
            url = params.url,
            json = params.json,
            headers = params.headers
        }

        if formatParams.headers['Content-Type'] or
           formatParams.headers['content-type'] then
            formatParams.json = false
        end
    end

    if formatParams.method == "GET" and type(params) == "table" then
        local url = params.url
        local paramsString = ""

        for key, value in pairs(params.form or {}) do
            if type(value) == 'string' or type(value) == 'number' then
                paramsString = paramsString .. key .. "=" .. value .. "&"
            end
        end

        paramsString = string.sub(paramsString, 1, -2)

        if paramsString and paramsString ~= "" then
            formatParams.url = format("%s?%s", url, paramsString)
        end
    end

    if formatParams.method ~= "GET" then
        formatParams.form = params.form or {}
    end

    System.os.GetUrl(
        formatParams,
        function(err, msg, data)
            ---- debug code ----
            local debugUrl = type(params) == "string" and params or formatParams.url
            local method = type(params) == "table" and params.method and params.method or "GET"

            LOG.std("HttpRequest", "debug", "Request", "Status Code: %s, Method: %s, URL: %s, Params: %s", err, method, debugUrl, NPL.ToJson(formatParams, true))
            ---- debug code ----

            -- no try status code, return directly
            if type(noTryStatus) == "table" then
                for _, code in pairs(noTryStatus) do
                    if err == code then
                        if type(callback) == "function" then
                            callback(data, err)
                        end

                        HttpRequest.tryTimes = 1
                        return false
                    end
                end
            elseif type(noTryStatus) == "number" then
                if err == noTryStatus then
                    if type(callback) == "function" then
                        callback(data, err)
                    end

                    HttpRequest.tryTimes = 1
                    return false
                end
            end

            -- fail return
            for _, code in pairs(HttpRequest.defaultFailCode) do
                if err == code then
                    if type(callback) == "function" then
                        callback(data, err)
                    end

                    HttpRequest.tryTimes = 1
                    return false
                end
            end

            -- success return
            for _, code in pairs(HttpRequest.defaultSuccessCode) do
                if err == code then
                    if type(callback) == "function" then
                        callback(data, err)
                    end

                    HttpRequest.tryTimes = 1
                    return true
                end
            end

            -- fail try
            HttpRequest:Retry(err, msg, data, params, callback)
        end
    )
end

function HttpRequest:Retry(err, msg, data, params, callback)
    -- beyond the max try times, must be return
    if HttpRequest.tryTimes >= HttpRequest.maxTryTimes then
        if (type(callback) == "function") then
            callback(data, err)
        end

        HttpRequest.tryTimes = 1
        return
    end

    -- continue try
    HttpRequest.tryTimes = HttpRequest.tryTimes + 1

    commonlib.TimerManager.SetTimeout(
        function()
            HttpRequest:GetUrl(params, callback)
        end,
        2100
    )
end

function HttpRequest:Get(url, params, headers, success, error, noTryStatus)
    if not url then
        return false
    end

    local getParams = {
        method = "GET",
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus
    )
end

function HttpRequest:Post(url, params, headers, success, error, noTryStatus)
    if not url then
        return false
    end

    local getParams = {
        method = "POST",
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus
    )

end

function HttpRequest:Put(url, params, headers, success, error, noTryStatus)
    if not url then
        return false
    end

    local getParams = {
        method = "PUT",
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus
    )
end

function HttpRequest:Delete(url, params, headers, success, error, noTryStatus)
    if not url then
        return false
    end

    local getParams = {
        method = "DELETE",
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus
    )
end

function HttpRequest:PostFields(url, headers, content, success, error)
    System.os.GetUrl({ url = url, headers = headers, postfields = content }, function(err, msg, data)
        LOG.std("HttpRequest", "debug", "Request", "Status Code: %s, Method: %s, URL: %s", err, "POST", url)

        if err == 200 then
            if type(success) == 'function' then
                success(data, err)
            end
        else
            if type(error) == 'function' then
                error(data, err)
            end
        end
    end)
end