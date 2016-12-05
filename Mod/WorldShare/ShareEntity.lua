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
local ShareEntity = commonlib.inherit(nil,commonlib.gettable("Mod.Share.ShareEntity"));

function ShareEntity:ctor()
end

function ShareEntity:init()
	LOG.std(nil, "info", "ShareEntity", "init");
end
