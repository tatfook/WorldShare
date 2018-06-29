--[[
Title: Utils
Author(s): big
Date: 2018.06.21
Desc: generate KeepWork documentation 
-------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
-------------------------------------------------------
]]
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")

function Utils:ShowWindow(width, height, url, name, x, y, align, allowDrag)
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
        bToggleShowHide  = true
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params)

    return params
end

function Utils.formatFileSize(size, unit)
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

    local marginLeft = math.floor((Screen:GetWidth()/2))
    local marginTop = math.floor((Screen:GetHeight()/2))

    return format("margin-left:%s;margin-top: %s", marginLeft - width/2, marginTop - height/2)
end