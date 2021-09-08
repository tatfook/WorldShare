--[[
Title: world menu command
Author(s): big
Date: 2020/8/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/command/Menu.lua")
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands")

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local EventTrackingService = NPL.load("(gl)Mod/WorldShare/service/EventTracking.lua")

-- UI
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
local OpusSetting = NPL.load("(gl)Mod/WorldShare/cellar/OpusSetting/OpusSetting.lua")
local MemberManager = NPL.load("(gl)Mod/WorldShare/cellar/MemberManager/MemberManager.lua")

local MenuCommand = NPL.export()

function MenuCommand:Init()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMenu.lua");
    Commands["menu"].desc = Commands["menu"].desc .. [[
/menu project.share
/menu project.index
/menu project.author
/menu project.setting
/menu project.apply
]]
end

function MenuCommand:Call(cmdName, cmdText, cmdParams)
    local name, cmdText = CmdParser.ParseString(cmdText);

    if name and type(name) == 'string' then
        local action = "click.menu." .. name

        EventTrackingService:Send(1, action)
    end

    if name == "project.share" then
        self:Share()
        return true
    elseif name == "project.index" then
        self:OpenUserOpusPage()
        return true
    elseif name == "project.author" then
        self:OpenUserPage()
        return true
    elseif name == "project.setting" then
        self:OpusSetting()
        return true
    elseif name == "project.member" then
        self:MemberManager()
        return true
    elseif name == "project.apply" then
        self:Apply()
        return true
    end

    return false
end

function MenuCommand:Share()
    ShareWorld:Init()
end

function MenuCommand:OpenUserOpusPage()
    ParaGlobal.ShellExecute("open", KeepworkService:GetShareUrl(), "", "", 1)
end

function MenuCommand:OpenUserPage()
    ParaGlobal.ShellExecute("open", format("%s/u/%s", KeepworkService:GetKeepworkUrl(), Mod.WorldShare.Store:Get("user/username") or ""), "", "", 1)
end

function MenuCommand:OpusSetting()
    OpusSetting:Show()
end

function MenuCommand:MemberManager()
    MemberManager:Show()
end

function MenuCommand:Apply()
    MemberManager:ShowApply()
end