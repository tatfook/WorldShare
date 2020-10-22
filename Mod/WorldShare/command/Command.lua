--[[
Title: world share command
Author(s): big
Date: 2020/9/25
Desc: 
use the lib:
------------------------------------------------------------
local WorldShareCommand = NPL.load("(gl)Mod/WorldShare/command/Command.lua")
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

-- command
local MenuCommand = NPL.load("(gl)Mod/WorldShare/command/Menu.lua")
local PipeCommand = NPL.load("(gl)Mod/WorldShare/command/Pipe.lua")
local LoadWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadWorld.lua")
local LoadPersonalWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadPersonalWorld.lua")
local LoadReadOnlyWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadReadOnlyWorld.lua")

local WorldShareCommand = NPL.export()

function WorldShareCommand:Init()
    MenuCommand:Init()
    LoadWorldCommand:Init()
    local pipe = PipeCommand:Init()
    local loadpersonalworld = LoadPersonalWorldCommand:Init()
    local loadreadonlyworld = LoadReadOnlyWorldCommand:Init()

    GameLogic.GetFilters():add_filter("register_command", function(_, SlashCommand)
        SlashCommand:RegisterSlashCommand(pipe)
        SlashCommand:RegisterSlashCommand(loadpersonalworld)
        SlashCommand:RegisterSlashCommand(loadreadonlyworld)
    end)

    CommandManager:Init()
end
