--[[
Title: BigSceneContext
Author(s): Big
Date: 2016.11
Desc: Example of demo scene context
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/Test/BigSceneContext.lua");
local DemoSceneContext = commonlib.gettable("Mod.big.BigSceneContext");
BigSceneContext:ApplyToDefaultContext();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContext.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local BigSceneContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), commonlib.gettable("Mod.big.BigSceneContext"));
function BigSceneContext:ctor()
    self:EnableAutoCamera(true);
end

-- static method: use this demo scene context as default context
function BigSceneContext:ApplyToDefaultContext()
	BigSceneContext:ResetDefaultContext();
	GameLogic.GetFilters():add_filter("DefaultContext", function(context)
	   return BigSceneContext:CreateGetInstance("BigSceneContext");
	end);
end

-- static method: reset scene context to vanila scene context
function BigSceneContext:ResetDefaultContext()
	GameLogic.GetFilters():remove_all_filters("DefaultContext");
end

function BigSceneContext:mouseReleaseEvent(event)
	if(event:button() == "left") then
		--_guihelper.MessageBox("You clicked in Demo Scene Context. Switching to default context?", function()
			--self:ResetDefaultContext();
			--GameLogic.ActivateDefaultContext();
		--end)
		return false;
	end
end
