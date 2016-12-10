--[[
Title: WorldShareCommand
Author(s):  big
Date: 2016.12.9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/WorldShareCommand.lua");
local WorldShareCommand = commonlib.gettable("Mod.WorldShare.WorldShareCommand");
------------------------------------------------------------
]]
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local WorldShareCommand = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareCommand"));

function WorldShareCommand:ctor()
end

function WorldShareCommand:init()
	LOG.std(nil, "debug", "ShareCommand", "init");
	self:InstallCommand();
end

function WorldShareCommand:InstallCommand()
	Commands["demo"] = {
		name="demo", 
		quick_ref="/demo", 
		desc="show a demo", 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			_guihelper.MessageBox("this is from demo command");
		end,
	};
	
	Commands["demo2"] = {
		name="demo2", 
		quick_ref="/demo2", 
		desc="show a demo", 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			
		end,
	};
end
