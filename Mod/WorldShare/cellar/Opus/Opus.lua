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

    params._page.OnClose = function()
        Screen:Disconnect("sizeChanged", Opus, Opus.OnScreenSizeChange)
    end
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
    return Mod.WorldShare.Utils.ShowWindow(
        {
            url = 'Mod/WorldShare/cellar/Opus/OpusBackground.html',
            name = 'Mod.WorldShare.OpusBackground',
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 0,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            cancelShowAnimation = true,
            bToggleShowHide = true,
        }
    )
end

function Opus:ShowOpus()
    Mod.WorldShare.Utils.ShowWindow(
        {
            url = 'Mod/WorldShare/cellar/Opus/Opus.html',
            name = 'Mod.WorldShare.Opus',
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 0,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = "_ct",
            x = -768 / 2,
            y = -495 / 2,
            width = 1024,
            height = 720,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1024,
            DesignResolutionHeight = 720,
        }
    )
    Create:ShowCreateEmbed()
end

function Opus:ShowHonour()
    Mod.WorldShare.Utils.ShowWindow(
        {
            url = 'Mod/WorldShare/cellar/Opus/Honour.html',
            name = 'Mod.WorldShare.Honour',
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 0,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = "_ct",
            x = -768 / 2,
            y = -495 / 2,
            width = 1024,
            height = 720,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1024,
            DesignResolutionHeight = 720,
        }
    )
end

function Opus.OnScreenSizeChange()
    local OpusBackgroundPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.OpusBackground')

    if not OpusBackgroundPage then
        return
    end

    OpusBackgroundPage:Rebuild()
end
