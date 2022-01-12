--[[
Title: load read only world command
Author(s): big
CreateDate: 2020.09.25
ModifyDate: 2021.09.17
Desc: 
use the lib:
------------------------------------------------------------
local LoadReadOnlyWorldCommand = NPL.load('(gl)Mod/WorldShare/command/LoadReadOnlyWorldCommand.lua')
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable('MyCompany.Aries.Game.CmdParser')
local Commands = commonlib.gettable('MyCompany.Aries.Game.Commands')
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')

-- UI
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')

local LoadReadOnlyWorldCommand = NPL.export()

function LoadReadOnlyWorldCommand:Init()
    local loadreadonlyworld = {
        name='loadreadonlyworld', 
        quick_ref='/loadreadonlyworld [project_id]', 
        desc=[[]],
        mode_deny = '',
        handler = function(cmd_name, cmd_text, cmd_params)
            local options;
            options, cmd_text = CmdParser.ParseOptions(cmd_text)

            if cmd_params and cmd_params.value then
                if type(cmd_params.value) ~= 'string' and type(cmd_params.value) ~= 'number' then
                    return false
                end

                local projectId = tonumber(cmd_params.value)

                if not projectId then
                    return false
                end

                CommonLoadWorld:EnterWorldById(projectId)
            end
        end,
    }

    Commands['loadreadonlyworld'] = loadreadonlyworld

    return loadreadonlyworld
end
