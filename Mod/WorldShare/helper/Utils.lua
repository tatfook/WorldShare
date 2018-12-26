--[[
Title: Utils
Author(s): big
Date: 2018.06.21
Desc: generate KeepWork documentation 
-------------------------------------------------------
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
-------------------------------------------------------
]]
local Utils = NPL.export()

function Utils:ShowWindow(width, height, url, name, x, y, align, allowDrag, zorder)
    if (not x) then
        x = width
    end

    if (not y) then
        y = height
    end

    local params = {
        url = url,
        name = name,
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = zorder or 0,
        allowDrag = allowDrag == nil and true or allowDrag,
        bShow = bShow,
        directPosition = true,
        align = align or "_ct",
        x = -x / 2,
        y = -y / 2,
        width = width,
        height = height,
        cancelShowAnimation = true,
        bToggleShowHide = true
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params)

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

function Utils:GetFileData(url)
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

function Utils:MergeTable(target, source)
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

function Utils:Implode(glue, pieces)
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