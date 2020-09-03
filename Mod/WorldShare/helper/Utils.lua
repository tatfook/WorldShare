--[[
Title: Utils
Author(s): big
Date: 2018.06.21
Desc: 
-------------------------------------------------------
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
-------------------------------------------------------
]]
local Encoding = commonlib.gettable("commonlib.Encoding")
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")

local Utils = NPL.export()

-- show one page
-- @param option window width or selfdefined params
-- @param height window height
-- @param url page url
-- @param x window x position
-- @param y window y position
-- @param align align method
-- @param allowDrag Is allow window drag
-- @param window z-axis order
-- @return table
function Utils.ShowWindow(option, height, url, name, x, y, align, allowDrag, zorder)
    local params

    if type(option) == 'table' then
        params = option
    else
        local width = option

        if not x then
            x = width
        end

        if not y then
            y = height
        end

        params = {
            url = url,
            name = name,
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = zorder or 0,
            allowDrag = allowDrag == nil and true or allowDrag,
            bShow = nil,
            directPosition = true,
            align = align or "_ct",
            x = -x / 2,
            y = -y / 2,
            width = width,
            height = height,
            cancelShowAnimation = true,
            bToggleShowHide = true
        }
    end

    local matchUrl, matched = string.gsub(params.url, "^%(ws%)", "") -- ws: worldshare

    if matched == 1 then
        if not string.match(matchUrl, "%.html$") then
            matchUrl = matchUrl .. "/" .. matchUrl .. ".html"
        end

        params.url = "Mod/WorldShare/cellar/" .. matchUrl
    end

    local matchUrl, matched = string.gsub(params.url, "^%(ep%)", "") -- ep: explorerapp

    if matched == 1 then
        if not string.match(matchUrl, "%.html$") then
            matchUrl = matchUrl .. "/" .. matchUrl .. ".html"
        end

        params.url = "Mod/ExplorerApp/components/" .. matchUrl
    end

    System.App.Commands.Call("File.MCMLWindowFrame", params)

    if not params or not params._page then
        return params
    end

    Mod.WorldShare.Store:Set('page/' .. tostring(name), params._page)

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/' .. tostring(name))
    end

    return params
end

function Utils.FormatFileSize(size, unit)
    local s
    size = tonumber(size)

    function GetPreciseDecimal(nNum, n)
        if type(nNum) ~= "number" then
            return nNum
        end

        n = n or 0
        n = math.floor(n)
        local fmt = "%." .. n .. "f"
        local nRet = tonumber(string.format(fmt, nNum))

        return nRet
    end

    if (size and size ~= "") then
        if (not unit) then
            s = GetPreciseDecimal(size / 1024 / 1024, 2) .. "M"
        elseif (unit == "KB") then
            s = GetPreciseDecimal(size / 1024, 2) .. "KB"
        end
    else
        s = nil
    end

    return s or "0"
end

function Utils.SetTimeOut(callback, times)
    commonlib.TimerManager.SetTimeout(callback, times or 100)
end

function Utils.FixCenter(width, height)
    NPL.load("(gl)script/ide/System/Windows/Screen.lua")
    local Screen = commonlib.gettable("System.Windows.Screen")

    local marginLeft = math.floor((Screen:GetWidth() / 2))
    local marginTop = math.floor((Screen:GetHeight() / 2))

    return format("margin-left:%s;margin-top: %s", marginLeft - width / 2, marginTop - height / 2)
end

function Utils.GetFileData(url)
    local file = ParaIO.open(url, "r")
    local fileContent = ""

    if (file:IsValid()) then
        fileContent = file:GetText(0, -1)
        file:close()
    end

    return fileContent
end

function Utils:IsEquivalent(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    if (#a ~= #b) then
        return false
    end

    for key, value in pairs(a) do
        if not b[key] then
            return false
        end

        if type(value) == "table" then
            if not self:IsEquivalent(value, b[key]) then
                return false
            end
        else
            if value ~= b[key] then
                return false
            end
        end
    end

    return true
end

function Utils.MergeTable(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return false
    end

    target = commonlib.copy(target)
    source = commonlib.copy(source)

    for key, value in pairs(source) do
        target[key] = value
    end

    return target
end

function Utils.Implode(glue, pieces)
    glue = glue or ""

    local k, v
    local result = ""

    for k, v in ipairs(pieces) do
        if (k == 1) then
            result = tostring(v)
        else
            result = string.format("%s%s%s", result, glue, tostring(v))
        end
    end

    return result
end

function Utils.UrlEncode(str)
    if (str) then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w _ %- . ~])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub(str, " ", "+")
	end
	return str
end

function Utils.EncodeURIComponent(str)
    if (str) then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w _ %- . ~])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub(str, " ", "%%20")
	end
	return str
end

function Utils.IsEnglish()
    if Translation.GetCurrentLanguage() == 'enUS' then
        return true
    else
        return false
    end
end

function Utils.GetWorldFolderFullPath()
    return LocalLoadWorld.GetWorldFolderFullPath()
end

function Utils:GetFolderName()
    local originWorldPath = ParaWorld.GetWorldDirectory()

    originWorldPath = string.gsub(originWorldPath, "\\", "/")

    if string.sub(originWorldPath, -1, -1) == "/" then
        originWorldPath = string.sub(originWorldPath, 0, -2)
    end

    local pathArray = {}

    for item in string.gmatch(originWorldPath, "[^/]+") do
        pathArray[#pathArray + 1] = item
    end

    local foldernameDefault = pathArray[#pathArray]

    if not foldernameDefault then
        return ''
    end

    return Encoding.DefaultToUtf8(foldernameDefault)
end

function Utils:GetCurrentTime(isUTC)
    if isUTC then
        return os.time(os.date("!*t"))
    else
        return os.time()
    end
end

-- 0000-00-00 00-00
function Utils:UnifiedTimestampFormat(data)
    if not data then
        return 0
    end

    local years = 0
    local months = 0
    local days = 0
    local hours = 0
    local minutes = 0

    if string.find(data, "T") then
        local date = string.match(data or "", "^%d+-%d+-%d+")
        local time = string.match(data or "", "%d+:%d+")

        years = string.match(date or "", "^(%d+)-")
        months = string.match(date or "", "-(%d+)-")
        days = string.match(date or "", "-(%d+)$")

        hours = string.match(time or "", "^(%d+):")
        minutes = string.match(time or "", ":(%d+)")

        local timestamp = os.time{ year = years, month = months, day = days, hour = hours, min = minutes }

        if timestamp then
            return timestamp + 8 * 3600
        else
            return 0
        end
    else
        local date = string.match(data or "", "^%d+-%d+-%d+")
        local time = string.match(data or "", "%d+-%d+$")

        years = string.match(date or "", "^(%d+)-")
        months = string.match(date or "", "-(%d+)-")
        days = string.match(date or "", "-(%d+)$")

        hours = string.match(time or "", "^(%d+)-")
        minutes = string.match(time or "", "-(%d+)$")

        local timestamp = os.time{ year = years, month = months, day = days, hour = hours, min = minutes }

        return timestamp or 0
    end
end

-- 0000-00-00 00:00:00
function Utils:DatetimeToTimestamp(str)
    local years = string.match(str or "", "^(%d+)-")
    local months = string.match(str or "", "-(%d+)-")
    local days = string.match(str or "", "-(%d+) ")

    local hours = string.match(str or "", " (%d+):")
    local minutes = string.match(str or "", ":(%d+):")
    local seconds = string.match(str or "", ":(%d+)$")

    local timestamp = os.time{ year = years, month = months, day = days, hour = hours, min = minutes, sec = seconds }

    return timestamp or 0
end