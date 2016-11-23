--[[
Title: BigEntity
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/big/DemoEntity.lua");
local BigEntity = commonlib.gettable("Mod.big.BigEntity");
------------------------------------------------------------
]]
local BigEntity = commonlib.inherit(nil,commonlib.gettable("Mod.big.BigEntity"));

function BigEntity:ctor()
end

function BigEntity:init()
	LOG.std(nil, "info", "BigEntity", "init");
end
