--[[
Title: WorldCommon
Author(s): big
Date: 2020.12.2
City: Foshan
use the lib:
------------------------------------------------------------
local WorldCommon = NPL.load("(gl)Mod/WorldShare/cellar/WorldCommon/WorldCommon.lua")
------------------------------------------------------------
]] 

-- libs
-- origin world common class
local WorldCommonOrigin = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog")

-- service
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/World.lua')

local WorldCommon = NPL.export()

function WorldCommon:SaveWorldAs()
    if GameLogic.options:HasCopyright() then
		_guihelper.MessageBox(L"这个世界的作者申请了版权保护，无法复制世界。")
		return
	end

	local foldername = WorldCommonOrigin.GetWorldTag("name") or "no_name"

	if GameLogic.IsRemoteWorld() then
		GameLogic.RunCommand("/touchworld")
		GameLogic.SaveAll(true, true)
	end

    local newFoldername = foldername
    local localWorldList = LocalServiceWorld:GetWorldList()

	for i = 1, 10 do
        local beExisted = false
        for key, item in ipairs(localWorldList) do
            if item.foldername == newFoldername then
                beExisted = true
            end
        end

		if beExisted then
			newFoldername = foldername .. L"_副本" .. tostring(i)
		else
			break
		end	
	end

    self:ShowSaveWorldAsPage(newFoldername, function(confirmFoldername)
        local beExisted = false
        local localWorldList = LocalServiceWorld:GetWorldList()

        for key, item in ipairs(localWorldList) do
            if item and item.foldername and item.foldername == confirmFoldername then
                beExisted = true
                break
            end
        end

        local realFoldername = commonlib.Encoding.Utf8ToDefault(confirmFoldername) .. '_' .. System.Encoding.guid.uuid()
        local worldPath = Mod.WorldShare.Utils.GetWorldFolderFullPath() .. '/' .. realFoldername .. '/'

        if beExisted then
            _guihelper.MessageBox(
                format(L"世界%s已经存在, 是否覆盖?", result),
                function(res)
                    if(res and res == _guihelper.DialogResult.Yes) then
                        
                        self:SaveWorldAsImp(confirmFoldername, realFoldername, worldPath)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        else
            self:SaveWorldAsImp(confirmFoldername, realFoldername, worldPath)
        end
    end)
end

function WorldCommon:ShowSaveWorldAsPage(newFoldername, callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        500,
        220,
        'Mod/WorldShare/cellar/WorldCommon/SaveWorldAs.html?foldername=' .. newFoldername,
        'Mod.WorldShare.WorldCommon.SaveWorldAs'
    )

    if params and params._page then
        params._page.confirmCallback = callback
    end
end

function WorldCommon:SaveWorldAsImp(confirmFoldername, realFoldername, worldPath)
    local function Handle()
		if WorldCommonOrigin.CopyWorldTo(worldPath) then
			local save_world_handler = SaveWorldHandler:new():Init(worldPath)
            local xmlRoot = save_world_handler:LoadWorldXmlNode()

			if xmlRoot then
				for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
					-- change world name in tag. 
                    node.attr.name = confirmFoldername
                    node.attr.seed = confirmFoldername

					-- change Tag.xml to merge the original authors
					if node.attr.kpProjectId then
						node.attr.fromProjects = node.attr.fromProjects and (node.attr.fromProjects .. ',' ..node.attr.kpProjectId) or node.attr.kpProjectId
						node.attr.kpProjectId = nil
                    end

					save_world_handler:SaveWorldXmlNode(xmlRoot)
					break
				end
			end

			_guihelper.MessageBox(
                format(L'世界已经成功保存到: %s, 是否现在打开?', confirmFoldername),
                function(res)
                    if(res and res == _guihelper.DialogResult.Yes) then
                        WorldCommonOrigin.OpenWorld(worldPath, true)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
		end
	end

	if not GameLogic.IsVip('WorldDataSaveAs', true, function(result)
			if (result) then
				Handle()
			end
		end) then
		return
	end

	Handle()
end