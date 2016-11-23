--[[
Title: BigCommand
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/big/BigCommand.lua");
local BigCommand = commonlib.gettable("Mod.big.BigCommand");
------------------------------------------------------------
]]
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local BigCommand = commonlib.inherit(nil,commonlib.gettable("Mod.big.BigCommand"));

function BigCommand:ctor()
end

function BigCommand:init()
	LOG.std(nil, "info", "BigCommand", "init");
	self:InstallCommand();
end

function BigCommand:InstallCommand()
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
