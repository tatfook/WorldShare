--[[
Title: Opus
Author: big  
Date: 2020.7.7
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
Opus:Show()
------------------------------------------------------------
]]

-- libs
local Screen = commonlib.gettable("System.Windows.Screen")

local Opus = NPL.export()

function Opus:Show()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, 'Mod/WorldShare/cellar/Opus/Opus.html', 'Mod.WorldShare.Opus', 0, 0, "_fi", false)

    echo('connect!!!!', true)
    Screen:Connect("sizeChanged", Opus, Opus.OnScreenSizeChange, "UniqueConnection")
    -- Opus.OnScreenSizeChange()

    params._page.OnClose = function()
        echo('disconnect!!!!!', true)
        Screen:Disconnect("sizeChanged", Opus, Opus.OnScreenSizeChange)
    end
end

function Opus:ShowOpus()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, 'Mod/WorldShare/cellar/Opus/Opus.html', 'Mod.WorldShare.Opus', 0, 0, "_fi", false)
end

function Opus:ShowHonour()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, 'Mod/WorldShare/cellar/Opus/Honour.html', 'Mod.WorldShare.Opus', 0, 0, "_fi", false)
end

function Opus.OnScreenSizeChange()
    echo('hello world!!!!11111111', true)
    local OpusPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Opus')

    if not OpusPage then
        return
    end

    OpusPage:Rebuild()
end
