--[[
Title: ShareItem
Author(s):  Big
Date: 2016.12.1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/Share/ShareItem.lua");
local ShareItem = commonlib.gettable("Mod.Share.ShareItem");
------------------------------------------------------------
]]
local ShareItem = commonlib.inherit(nil,commonlib.gettable("Mod.Share.ShareItem"));

function ShareItem:ctor()
end

function ShareItem:init()
	LOG.std(nil, "info", "ShareItem", "init");

	xmlRoot = GameLogic.GetFilters():apply_filters("show", xmlRoot);
	
	-- register a new block item, id < 512 is internal blocks, which is not recommended to modify. 
	GameLogic.GetFilters():add_filter("block_types", function(xmlRoot) 
		
		local blocks = commonlib.XPath.selectNode(xmlRoot, "/blocks/");

		if(blocks) then
			blocks[#blocks+1] = {name="block", attr={
				id = 512, 
				threeSideTex = "true",
				text = "Share Item",
				name = "DemoItem",
				texture="Texture/blocks/bookshelf_three.png",
				obstruction="true",
				solid="true",
				cubeMode="true",
			}}
			LOG.std(nil, "info", "DemoItem", "a new block is registered");
		end

		return xmlRoot;
	end)

	-- add block to category list to be displayed in builder window (E key)
	GameLogic.GetFilters():add_filter("block_list", function(xmlRoot) 
		for node in commonlib.XPath.eachNode(xmlRoot, "/blocklist/category") do
			if(node.attr.name == "tool") then
				node[#node+1] = {name="block", attr={name="DemoItem"} };
			end
		end
		return xmlRoot;
	end)

end

function ShareItem:OnWorldLoad()
	if(self.isInited) then
		return 
	end

	self.isInited = true;

	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
	local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
	local block_template = block_types.get(101);
	if(block_template) then
		
	end
end