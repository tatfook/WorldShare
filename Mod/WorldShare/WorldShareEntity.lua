--[[
Title: BigEntity
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/WorldShareEntity.lua");
local WorldShareEntity = commonlib.gettable("Mod.WorldShare.WorldShareEntity");
------------------------------------------------------------
]]
local WorldShareEntity = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareEntity"));

function WorldShareEntity:ctor()
end

function WorldShareEntity:init()
	LOG.std(nil, "info", "WorldShareEntity", "init");
end
