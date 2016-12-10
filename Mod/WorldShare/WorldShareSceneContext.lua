--[[
Title: WorldShareSceneContext
Author(s): Big
Date: 2016.12.9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/WorldShareSceneContext.lua");
local DemoSceneContext = commonlib.gettable("Mod.WorldShare.WorldShareSceneContext");
WorldShareSceneContext:ApplyToDefaultContext();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContext.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local WorldShareSceneContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), commonlib.gettable("Mod.WorldShare.WorldShareSceneContext"));

function WorldShareSceneContext:ctor()
    self:EnableAutoCamera(true);
end

-- static method: use this demo scene context as default context
function WorldShareSceneContext:ApplyToDefaultContext()
	WorldShareSceneContext:ResetDefaultContext();

	GameLogic.GetFilters():add_filter("DefaultContext", function(context)
	   return WorldShareSceneContext:CreateGetInstance("WorldShareSceneContext");
	end);
end

-- static method: reset scene context to vanila scene context
function WorldShareSceneContext:ResetDefaultContext()
	GameLogic.GetFilters():remove_all_filters("DefaultContext");
end

function WorldShareSceneContext:mouseReleaseEvent(event)
	if(event:button() == "left") then
		_guihelper.MessageBox("You clicked in Demo Scene Context. Switching to default context?", function()
			self:ResetDefaultContext();
			GameLogic.ActivateDefaultContext();
		end)
		return false;
	end
end
