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

-- =转成-p1p  +转成-p2p  /转成-p3p
function EncodingGithub.base64(text)
	if(text) then
		text = EncodingS.base64(text);
		text = text:gsub("[=]" ,"-p1p");
		text = text:gsub("[%+]","-p2p");
		text = text:gsub("[/]" ,"-p3p");

		--LOG.std(nil,"debug","text",text);

		return text;
	else
		return nil;
	end
end

function EncodingGithub.unbase64(text)
	if(text) then
		text = text:gsub("[-p1p]","=");
		text = text:gsub("[-p2p]","+");
		text = text:gsub("[-p3p]","/");

		return EncodingS.unbase64(text);
	else
		return nil;
	end
end