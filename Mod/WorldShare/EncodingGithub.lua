--[[
Title: EncodingGithub
Author(s):  big
Date:  2016.12.29
Desc: 
use the lib: corvent base64 and fit to github
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/EncodingGithub.lua");
local EncodingGithub = commonlib.gettable("Mod.WorldShare.EncodingGithub");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");

local EncodingGithub = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.EncodingGithub"));
local EncodingS      = commonlib.gettable("System.Encoding");

-- =转成2个-  +转成3个-  /转成4个- 
function EncodingGithub.base64(text)
	if(text) then
		text = EncodingS.base64(text);
		text = text:gsub("[=]" ,"--");
		text = text:gsub("[%+]","---");
		text = text:gsub("[/]" ,"----");

		LOG.std(nil,"debug","text",text);

		return text;
	else
		return nil;
	end
end

function EncodingGithub.unbase64(text)
	if(text) then
		text = text:gsub("[--]","=");
		text = text:gsub("[---]","+");
		text = text:gsub("[----]","/");

		return EncodingS.unbase64(text);
	else
		return nil;
	end
end