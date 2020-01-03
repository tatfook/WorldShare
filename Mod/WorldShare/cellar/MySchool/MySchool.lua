--[[
Title: my school page
Author(s):  big
Date: 2019.09.11
Desc: 
use the lib:
------------------------------------------------------------
local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
------------------------------------------------------------
]]

local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer")

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local MySchool = NPL.export()

function MySchool:Show()
    local function showpage()
        local params = Mod.WorldShare.Utils.ShowWindow(870, 650, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")

        params._page:CallMethod("nplbrowser_instance", "SetVisible", true)
    
        params._page.OnClose = function()
            Mod.WorldShare.Store:Remove('page/MySchoolPage')
            params._page:CallMethod("nplbrowser_instance", "SetVisible", false)
        end
    end

    if System.os.GetPlatform() ~= 'mac' then
        local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
            if not bStarted then
                return false
            end

            NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");	
            local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");	
            NplBrowserLoaderPage.Check()
            if not NplBrowserLoaderPage.IsLoaded() then
                ParaGlobal.ShellExecute("open", MySchool.GetUrl(), "", "", 1);	
                return
            end
            
            showpage()
        end)
    else
        showpage()
    end
end

function MySchool:SetPage()
    Mod.WorldShare.Store:Set('page/MySchoolPage', document:GetPageCtrl())
end

function MySchool:Close()
    local MySchoolPage = Mod.WorldShare.Store:Get('page/MySchoolPage')

    if MySchoolPage then
        MySchoolPage:CloseWindow()
    end
end

function MySchool.GetUrl()
    local token = Mod.WorldShare.Store:Get("user/token") or ''

    if System.os.GetPlatform() == 'mac' then
        return KeepworkService:GetKeepworkUrl() .. '/p/org/home?type=protocol&port=8099&token=' .. token
    else
        return KeepworkService:GetKeepworkUrl() .. '/p/org/home?port=8099&token=' .. token
    end
end