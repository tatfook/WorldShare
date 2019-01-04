--[[
Title: Command Sign In
Author(s):  big
Date: 2019.01.02
place: Foshan
Desc: Registry world share command.
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/command/SignIn.lua")
------------------------------------------------------------
]]

local Event = commonlib.gettable("System.Core.Event")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")

local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

Commands["signin"] = {
	name="signin", 
	quick_ref= format("/signin -t %s -callback OnSignedIn", L"请先登陆"), 
	isLocal=false,
	desc=[[show login modal]], 
    handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local title, eventName = string.match(cmd_text or '', "%-t (%S+) %-callback (%S+)")

		if type(title) ~= 'string' or type(eventName) ~= 'string' then
			return false
		end

		ParaWorldLoginDocker.SignIn(
			title,
			function(result)
				if not eventName then
					return false
				end

				local event = Event:new():init(eventName)

				if type(event) == 'table' and type(result) == 'boolean' then
					event.cmd_text = result and 'succeed' or 'failed'
				end

				GameLogic:event(event)
			end
		)
    end
}