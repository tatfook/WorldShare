--[[
Title: WorldShareEntity
Author(s):  big
Date: 2016.12.9
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
	LOG.std(nil, "debug", "WorldShareEntity", "init");
end
