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

-- bottles
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')

local Opus = NPL.export()

function Opus:Show()
    local params = self:ShowOpusBackground()
    self:ShowOpus()

    Screen:Connect("sizeChanged", Opus, Opus.OnScreenSizeChange, "UniqueConnection")

    -- params._page.OnClose = function()
    --     Screen:Disconnect("sizeChanged", Opus, Opus.OnScreenSizeChange)
    -- end
end

function Opus:CloseAll()
    local OpusBackgroundPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.OpusBackground')

    if OpusBackgroundPage then
        OpusBackgroundPage:CloseWindow()
    end

    self:CloseOpus()
    self:CloseHonour()
end

function Opus:CloseOpus()
    local OpusPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Opus')
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if OpusPage then
        OpusPage:CloseWindow()
    end

    if CreatePage then
        CreatePage:CloseWindow()
    end
end

function Opus:CloseHonour()
    local HonourPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Honour')

    if HonourPage then
        HonourPage:CloseWindow()
    end
end

function Opus:ShowOpusBackground()
    return Mod.WorldShare.Utils.ShowWindow(0, 0, 'Mod/WorldShare/cellar/Opus/OpusBackground.html', 'Mod.WorldShare.OpusBackground', 0, 0, "_fi", false)
end

function Opus:ShowOpus()
    Mod.WorldShare.Utils.ShowWindow(1024, 720, 'Mod/WorldShare/cellar/Opus/Opus.html', 'Mod.WorldShare.Opus', 768, 575, "_ct", false)
    Create:ShowCreateEmbed()
end

function Opus:ShowHonour()
    Mod.WorldShare.Utils.ShowWindow(1024, 720, 'Mod/WorldShare/cellar/Opus/Honour.html', 'Mod.WorldShare.Honour', 768, 575, "_ct", false)
end

function Opus.OnScreenSizeChange()
    local OpusBackgroundPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.OpusBackground')

    if not OpusBackgroundPage then
        return
    end

    OpusBackgroundPage:Rebuild()
end
