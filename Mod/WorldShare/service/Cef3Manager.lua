--[[
Title: Cef3 Manager
Author(s):  big
Date: 2020.05.29
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/Cef3Manager.lua")
local Cef3Manager = commonlib.gettable("Mod.WorldShare.service.Cef3Manager")
Cef3Manager:Connect("finishLoadCef3", self, function() echo("connect: finish load") end, "UniqueConnection")
------------------------------------------------------------
]]

local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage")
local Cef3Manager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.WorldShare.service.Cef3Manager"))

Cef3Manager:Property({"bLoaded", false});

Cef3Manager:Signal("finishLoadCef3", function() end)

function Cef3Manager:Init()
    Mod.WorldShare.Utils.SetTimeOut(function()
        NplBrowserLoaderPage.Check(function()
            self:finishLoadCef3()
            self.bLoaded = true
        end)
    end, 1000)
end