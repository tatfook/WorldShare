--[[
Title: VersionChange
Author(s):  big
Date: 2018.06.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/VersionChange.lua")
local VersionChange = commonlib.gettable("Mod.WorldShare.login.VersionChange")
------------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");

local mcml = commonlib.gettable("System.Windows.mcml");
local VersionChange = commonlib.gettable("Mod.WorldShare.login.VersionChange")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")

mcml:StaticInit()

function VersionChange:init()
    self:ShowPage()
end

function VersionChange:SetPage()
    VersionChange.VersionPage = document:GetPageCtrl()
end

function VersionChange:ClosePage()
    if(VersionChange.VersionPage) then
        VersionChange.VersionPage:CloseWindow()
    end
end

function VersionChange:ShowPage()
    Utils:ShowWindow(300, 400, "Mod/WorldShare/login/VersionChange.html", "VersionChange")
end

function VersionChange:GetVersionSource()
    
end
