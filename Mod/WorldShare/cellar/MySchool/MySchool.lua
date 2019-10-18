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

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local MySchool = NPL.export()

function MySchool:Show()
    local function showpage()
        local params = Utils:ShowWindow(870, 650, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")
    
        params._page:CallMethod("nplbrowser_instance", "SetVisible", true)
    
        params._page.OnClose = function()
            Store:Remove('page/MySchoolPage')
            params._page:CallMethod("nplbrowser_instance", "SetVisible", false)
        end
    end

    if System.os.GetPlatform() ~= 'mac' then
        local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
            if not bStarted then
                return false
            end
            
            showpage()
        end)
    else
        showpage()
    end
end

function MySchool:SetPage()
    Store:Set('page/MySchoolPage', document:GetPageCtrl())
end

function MySchool:Close()
    local MySchoolPage = Store:Get('page/MySchoolPage')

    if MySchoolPage then
        MySchoolPage:CloseWindow()
    end
end

function MySchool.GetUrl()
    local token = Store:Get("user/token") or ''

    if System.os.GetPlatform() == 'mac' then
        return KeepworkService:GetKeepworkUrl() .. '/p/org/home?type=protocol&port=8099&token=' .. token
    else
        return KeepworkService:GetKeepworkUrl() .. '/p/org/home?port=8099&token=' .. token
    end
end