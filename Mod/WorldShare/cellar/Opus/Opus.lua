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
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

-- bottles
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')

local Opus = NPL.export()

function Opus:Show()
    local params = self:ShowOpusBackground()

    Screen:Connect("sizeChanged", Opus, Opus.OnScreenSizeChange, "UniqueConnection")

    params._page.OnClose = function()
        Screen:Disconnect("sizeChanged", Opus, Opus.OnScreenSizeChange)
    end
    
    params._page:SetValue('opus_content', '')

    Opus.cur_sel = '1'

    self:ShowOpus()
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

    Mod.WorldShare.Store:Remove('world/searchText')

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
            y = -535 / 2,
            width = 1024,
            height = 720,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
        }
    )
    Create:ShowCreateEmbed()
end

function Opus:ShowMyHome()
    local username = Mod.WorldShare.Store:Get('user/username')

    Mod.WorldShare.Store:Set('world/searchFolderName', username .. '_main')
    Create:ShowCreateEmbed(nil, nil, nil, -530)
end

function Opus:CloseMyHome()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreatePage then
        CreatePage:CloseWindow()
        Mod.WorldShare.Store:Remove('world/searchFolderName')
    end
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
            y = -535 / 2,
            width = 1024,
            height = 720,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
        }
    )
end

function Opus:ShowCertificate(texture, date)
    local username = Mod.WorldShare.Store:Get('user/username')
    local nickname = Mod.WorldShare.Store:Get('user/nickname')

    if nickname and type(nickname) == 'string' then
        username = string.format("%s(%s)", nickname, username)
    end

    Page.Show({
        username = username,
        datetime = os.date("%Y-%m-%d", commonlib.timehelp.GetTimeStampByDateTime(date)),
        certurl = texture,
    }, {
        url = "%vue%/Page/User/Certificate.html",
    });
end

function Opus.OnScreenSizeChange()
    local OpusBackgroundPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.OpusBackground')

    if not OpusBackgroundPage then
        return
    end

    OpusBackgroundPage:Rebuild()
    OpusBackgroundPage.sel(Opus.cur_sel)
end
