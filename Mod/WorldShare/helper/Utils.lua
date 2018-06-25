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

function Utils:ShowWindow(width, height, url, name, x, y)
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
        zorder = 0,
        allowDrag = true,
        bShow = bShow,
        directPosition = true,
        align = "_ct",
        x = -x / 2,
        y = -y / 2,
        width = width,
        height = height,
        cancelShowAnimation = true
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
