--[[
Title: Utils
Author(s): big
CreateDate: 2018.06.21
ModifyDate: 2021.11.15
Desc: 
-------------------------------------------------------
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')
-------------------------------------------------------
]]

-- libs
local Encoding = commonlib.gettable('commonlib.Encoding')
local Translation = commonlib.gettable('MyCompany.Aries.Game.Common.Translation')
local LocalLoadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.LocalLoadWorld')

-- service
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

-- config
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')

local Utils = NPL.export()
local self = Utils

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
function Utils.ShowWindow(option, height, url, name, x, y, align, allowDrag, zorder, isTopLevel, bToggleShowHide)
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

        if bToggleShowHide == false then
            bToggleShowHide = false
        else
            bToggleShowHide = true
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
            align = align or '_ct',
            x = -x / 2,
            y = -y / 2,
            width = width,
            height = height,
            cancelShowAnimation = true,
            bToggleShowHide = bToggleShowHide,
        }

        if isTopLevel then
            params.isTopLevel = isTopLevel
        end
    end

    if params.url and type(params.url) == 'string' then
        local matchUrl, matched = string.gsub(params.url, '^%(ws%)', '') -- ws: worldshare
    
        if matched == 1 then
            if not string.match(matchUrl, '%.html$') then
                matchUrl = matchUrl .. '/' .. matchUrl .. '.html'
            end
    
            params.url = 'Mod/WorldShare/cellar/' .. matchUrl
        end
    
        local matchUrl, matched = string.gsub(params.url, '^%(ep%)', '') -- ep: explorerapp
    
        if matched == 1 then
            if not string.match(matchUrl, '%.html$') then
                matchUrl = matchUrl .. '/' .. matchUrl .. '.html'
            end
    
            params.url = 'Mod/ExplorerApp/components/' .. matchUrl
        end
    
        if Mod.WorldShare.Utils.IsEnglish() then
            local enUrl = string.gsub(params.url, '.html', '.en.html')
    
            if ParaIO.DoesFileExist(enUrl, true) then
                params.url = enUrl
            end
        end
    end

    System.App.Commands.Call('File.MCMLWindowFrame', params)

    if not params or not params._page then
        return params
    end

    Mod.WorldShare.Store:Set('page/' .. tostring(params.name), params._page)

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/' .. tostring(params.name))
    end

    return params
end

function Utils.GetProjectId(url)
    if (tonumber(url or '') or 9999999) < 9999999 then
        return url
    end

    local pid = string.match(url or '', '^p(%d+)$')

    if not pid then
        pid = string.match(url or '', '/pbl/project/(%d+)')
    end

    return pid or false
end

function Utils.FormatFileSize(size, unit)
    local s
    size = tonumber(size)

    function GetPreciseDecimal(nNum, n)
        if type(nNum) ~= 'number' then
            return nNum
        end

        n = n or 0
        n = math.floor(n)
        local fmt = '%.' .. n .. 'f'
        local nRet = tonumber(string.format(fmt, nNum))

        return nRet
    end

    if (size and size ~= '') then
        if (not unit) then
            s = GetPreciseDecimal(size / 1024 / 1024, 2) .. 'M'
        elseif (unit == 'KB') then
            s = GetPreciseDecimal(size / 1024, 2) .. 'KB'
        end
    else
        s = nil
    end

    return s or '0'
end

function Utils.SetTimeOut(callback, times)
    commonlib.TimerManager.SetTimeout(callback, times or 100)
end

function Utils.FixCenter(width, height)
    local Screen = commonlib.gettable('System.Windows.Screen')

    local marginLeft = math.floor((Screen:GetWidth() / 2))
    local marginTop = math.floor((Screen:GetHeight() / 2))

    return format('margin-left:%s;margin-top: %s', marginLeft - width / 2, marginTop - height / 2)
end

function Utils.GetFileData(url)
    local file = ParaIO.open(url, 'r')
    local fileContent = ''

    if (file:IsValid()) then
        fileContent = file:GetText(0, -1)
        file:close()
    end

    return fileContent
end

function Utils:IsEquivalent(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then
        return false
    end

    if (#a ~= #b) then
        return false
    end

    for key, value in pairs(a) do
        if not b[key] then
            return false
        end

        if type(value) == 'table' then
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
    if type(target) ~= 'table' or type(source) ~= 'table' then
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
    glue = glue or ''

    local k, v
    local result = ''

    for k, v in ipairs(pieces) do
        if (k == 1) then
            result = tostring(v)
        else
            result = string.format('%s%s%s', result, glue, tostring(v))
        end
    end

    return result
end

function Utils.UrlEncode(str)
    if (str) then
		str = string.gsub(str, '\n', '\r\n')
		str = string.gsub(str, '([^%w _ %- . ~])',
			function (c) return string.format ('%%%02X', string.byte(c)) end)
		str = string.gsub(str, ' ', '+')
	end
	return str
end

function Utils.EncodeURIComponent(str)
    if (str) then
		str = string.gsub(str, '\n', '\r\n')
		str = string.gsub(str, '([^%w _ %- . ~])',
			function (c) return string.format ('%%%02X', string.byte(c)) end)
		str = string.gsub(str, ' ', '%%20')
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

function Utils.GetRootFolderFullPath()
    if System.os.GetExternalStoragePath() ~= '' then
        return System.os.GetExternalStoragePath() .. 'paracraft/'
    else
        return ParaIO.GetWritablePath()
    end
end

function Utils.GetTempFolderFullPath()
    if System.os.GetExternalStoragePath() ~= '' then
        return System.os.GetExternalStoragePath() .. 'paracraft/temp/'
    else
        return ParaIO.GetWritablePath() .. 'temp/'
    end
end

function Utils:GetWorldPathByFolderName(folderName)
    return self.GetWorldFolderFullPath() .. '/' .. commonlib.Encoding.Utf8ToDefault(folderName) .. '/'
end

function Utils:GetFolderName()
    local originWorldPath = ParaWorld.GetWorldDirectory()

    originWorldPath = string.gsub(originWorldPath, '\\', '/')

    if string.sub(originWorldPath, -1, -1) == '/' then
        originWorldPath = string.sub(originWorldPath, 0, -2)
    end

    local pathArray = {}

    for item in string.gmatch(originWorldPath, '[^/]+') do
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
        return os.time(os.date('!*t'))
    else
        return os.time()
    end
end

-- 0000-00-00 00-00 --> 000000000
function Utils:UnifiedTimestampFormat(data)
    if not data then
        return 0
    end

    local years = 0
    local months = 0
    local days = 0
    local hours = 0
    local minutes = 0

    if string.find(data, 'T') then
        local date = string.match(data or '', '^%d+-%d+-%d+')
        local time = string.match(data or '', '%d+:%d+')

        years = string.match(date or '', '^(%d+)-')
        months = string.match(date or '', '-(%d+)-')
        days = string.match(date or '', '-(%d+)$')

        hours = string.match(time or '', '^(%d+):')
        minutes = string.match(time or '', ':(%d+)')

        local timestamp = os.time{ year = years, month = months, day = days, hour = hours, min = minutes }

        if timestamp then
            return timestamp + 8 * 3600
        else
            return 0
        end
    else
        local date = string.match(data or '', '^%d+-%d+-%d+')
        local time = string.match(data or '', '%d+-%d+$')

        years = string.match(date or '', '^(%d+)-')
        months = string.match(date or '', '-(%d+)-')
        days = string.match(date or '', '-(%d+)$')

        hours = string.match(time or '', '^(%d+)-')
        minutes = string.match(time or '', '-(%d+)$')

        local timestamp = os.time{ year = years, month = months, day = days, hour = hours, min = minutes }

        return timestamp or 0
    end
end

-- 0000-00-00 00:00:00 --> 000000000
function Utils:DatetimeToTimestamp(str)
    local years = string.match(str or '', '^(%d+)-')
    local months = string.match(str or '', '-(%d+)-')
    local days = string.match(str or '', '-(%d+) ')

    local hours = string.match(str or '', ' (%d+):')
    local minutes = string.match(str or '', ':(%d+):')
    local seconds = string.match(str or '', ':(%d+)$')

    local timestamp = os.time{ year = years, month = months, day = days, hour = hours, min = minutes, sec = seconds }

    return timestamp or 0
end

-- 000000000 --> 0000-00-00 00:00:00
function Utils:TimestampToDatetime(timestamp)
    return os.date('%Y-%m-%d %H:%M:%S', timestamp)
end

-- get week number by timestamp
function Utils.GetWeekNum(timestamp)
    timestamp = timestamp or 0

    local weekNum = os.date('*t',timestamp).wday - 1

    if weekNum == 0 then
        weekNum = 7
    end

    return weekNum
end

-- open a keepwork url with keepwork token
function Utils.OpenKeepworkUrlByToken(url)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    Mod.WorldShare.MsgBox:Show(L'请稍后...')
    KeepworkServiceSession:GetWebToken(function(token)
        Mod.WorldShare.MsgBox:Close()
        if not token or type(token) ~= 'string' then
            return false
        end

        local keepworkUrl = KeepworkService:GetKeepworkUrl()

        if url and not (string.match(url, 'https://') or string.match(url, 'http://')) then
            url = keepworkUrl .. url
        end

        local openUrl = format('%s/p?url=%s&token=%s', keepworkUrl, self.EncodeURIComponent(url), token)
    
        ParaGlobal.ShellExecute('open', openUrl, '', '', 1)
    end)
end

function Utils.WordsLimit(text, size, charCount)
    size = size or 150
    charCount = charCount or 25

    if _guihelper.GetTextWidth(text) > size then
        local function chsize(char)
            if not char then
                return 0
            elseif char > 240 then
                return 4
            elseif char > 225 then
                return 3
            elseif char > 192 then
                return 2
            else
                return 1
            end
        end

        local len = 0
        local count = 0
        local currentIndex = 1

        while currentIndex <= #text do
            local charsizenum = chsize(string.byte(text, currentIndex))

            currentIndex = currentIndex + charsizenum

            if len >= charCount then
                break
            end

            if charsizenum ~= 0 then
                count = count + 1

                if charsizenum >= 3 then
                    len = len + 3.2
                else
                    len = len + 1.5
                end
            end
        end

        text = System.Core.UniString:new(text):sub(1, count).text .. '...'
    end

    return text
end

function Utils.RemoveLineEnding(str)
    str = string.gsub(str, ' ', '')
    str = string.gsub(str, '\r', '')
    str = string.gsub(str, '\n', '')

    return str
end

function Utils:IsSharedWorld(world)
    if type(world) ~= 'table' then
        return false
    end

    if world.shared then
        return true
    end

    if type(world.project) == 'table' and ((world.project.memberCount or 0) > 1) then
        return true
    end

    local shared = string.match(world.worldpath or '', 'shared') == 'shared' and true or false

    if shared then
        return true
    end

    return false
end

function Utils.IsSummerUser()
    local isVip = Mod.WorldShare.Store:Get('user/isVip')
    local isVipSchool = System.User.isVipSchool
    return isVipSchool or isVip
    -- if System.options.isDevMode then
    --     return isVipSchool or isVip
    -- end
    -- return false
end

function Utils:RecentDatetimeFormat(timestamp)
    timestamp = tonumber(timestamp) or 0
    local now = os.time()

    local timeDiff = now - timestamp

    if timeDiff < 0 then
        return ''
    end

    ------------ min ------------

    if timeDiff > 0 and timeDiff < 30 then
        return L'刚刚'
    end

    if timeDiff >= 30 and timeDiff < 60 then
        return L'1分钟前'
    end

    if timeDiff >= 60 and timeDiff < 120 then
        return L'2分钟前'
    end

    if timeDiff >= 120 and timeDiff < 180 then
        return L'3分钟前'
    end

    if timeDiff >= 180 and timeDiff < 240 then
        return L'4分钟前'
    end

    if timeDiff >= 240 and timeDiff < 300 then
        return L'5分钟前'
    end

    if timeDiff >= 300 and timeDiff < 360 then
        return L'6分钟前'
    end

    if timeDiff >= 360 and timeDiff < 420 then
        return L'7分钟前'
    end

    if timeDiff >= 420 and timeDiff < 480 then
        return L'8分钟前'
    end

    if timeDiff >= 480 and timeDiff < 540 then
        return L'9分钟前'
    end

    if timeDiff >= 540 and timeDiff < 600 then
        return L'10分钟前'
    end

    ------------ hours ------------

    if timeDiff >= 600 and timeDiff < 86400 then
        local h = math.ceil(timeDiff / 3600)

        return format(L'%d小时前', h)
    end

    ------------ days ------------

    if timeDiff > 36000 and timeDiff < 2592000 then
        local d = math.ceil(timeDiff / 86400)

        return format(L'%d天前', d)
    end

    ------------ months ------------

    if timeDiff > 2592000 and timeDiff < 31104000 then
        local m = math.ceil(timeDiff / 2592000)

        return format(L'%d个月前', m)
    end

    ------------ years ------------

    if timeDiff > 31104000 and timeDiff < 622080000 then
        local y = math.ceil(timeDiff / 31104000)

        return format(L'%d年前', y)
    end

    return os.date('%Y-%m-%d %H:%M', timestamp)
end

function Utils:GetConfig(field)
    local env = ''
    for key, item in pairs(Config.env) do
        if key == Config.defaultEnv then
            env = Config.defaultEnv
        end
    end

    return Config[field][env]
end

function Utils.ShortNumber(num)    
    if type(num) ~= 'number' then
        return 0
    end

    if num < 10000 then
        return num
    end

    if num >= 10000 and num < 100000000 then
        return math.floor(num / 10000) .. '万'
    end

    if num >= 100000000 and num < 1000000000000 then
        return math.floor(num / 100000000) .. '亿'
    end

    if num > 1000000000000 then
        return 0    
    end
end