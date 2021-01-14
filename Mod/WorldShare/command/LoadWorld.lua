--[[
Title: load world command
Author(s): big
Date: 2020.10.9
Desc: 
use the lib:
------------------------------------------------------------
local LoadWorldCommand = NPL.load('(gl)Mod/WorldShare/command/LoadWorld.lua')
-------------------------------------------------------
]]

-- UI
local UserConsole = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Main.lua')

-- service
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

-- libs
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')

local LoadWorldCommand = NPL.export()

function LoadWorldCommand:Init()
    -- cmd load world
    GameLogic.GetFilters():add_filter(
        "cmd_loadworld", 
        function(cmd_text, options)
            if options and options.fork then
                self:Fork(cmd_text)
                return
            end

            if options and not options.s then
                local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                if currentEnterWorld then
                    local pid = UserConsole:GetProjectId(cmd_text)
                    
                    if pid then
                        Mod.WorldShare.MsgBox:Show(L"请稍候...")
                        KeepworkServiceProject:GetProject(pid, function(data, err)
                            Mod.WorldShare.MsgBox:Close()
                            if err ~= 200 or not data or type(data) ~='table' or not data.name then
                                GameLogic.AddBBS(nil, L"无法找到该资源", 300, '255 0 0')
                                return
                            end

                            _guihelper.MessageBox(
                                format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, data.name),
                                function(res)
                                    if res and res == _guihelper.DialogResult.Yes then
                                        local optionsStr = ''
            
                                        for key, item in pairs(options) do
                                            if key ~= 's' then
                                                optionsStr = optionsStr .. '-' .. key .. ' '
                                            end
                                        end
            
                                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                                    end
                                end,
                                _guihelper.MessageBoxButtons.YesNo
                            )
                        end)
                    else
                        local worldname = L'自定义世界'

                        if cmd_text == 'home' then
                            worldname = L'家园'
                        end

                        _guihelper.MessageBox(
                            format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, worldname),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    local optionsStr = ''
        
                                    for key, item in pairs(options) do
                                        if key ~= 's' then
                                            optionsStr = optionsStr .. '-' .. key .. ' '
                                        end
                                    end
        
                                    CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    end
                    return
                end
            end

            if options and options.personal then
                CommandManager:RunCommand("/loadpersonalworld " .. cmd_text)
                return
            end

            local refreshMode = nil

            if options and options.force then
                refreshMode = 'force'
            end

            local failed = nil

            if options and options.failed then
                failed = true
            end

            local pid = UserConsole:GetProjectId(cmd_text)

            if pid then
                UserConsole:HandleWorldId(pid, refreshMode, failed)
                return false
            else
                return cmd_text
            end
        end
    )
end

function LoadWorldCommand:Fork(cmdText)
    local projectId, worldName = string.match(cmdText, "^(%w+)[ ]+(%w+)$")

    if not projectId or not worldName or type(tonumber(projectId)) ~= 'number' then
        return
    end

    projectId = tonumber(projectId)

    local worldPath = 'worlds/DesignHouse/' .. commonlib.Encoding.Utf8ToDefault(worldName)

    if ParaIO.DoesFileExist(worldPath .. '/tag.xml', false) then
        WorldCommon.OpenWorld(worldPath, true)
        return
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...")

    KeepworkServiceProject:GetProject(projectId, function(data, err)
        if not data or
           type(data) ~= 'table' or
           not data.name or
           not data.username or
           not data.world or
           not data.world.commitId then
            return
        end

        GitService:DownloadZIP(
            data.name,
            data.username,
            data.world.commitId,
            function(bSuccess, downloadPath)
                LocalService:MoveZipToFolder(worldPath, downloadPath)

                local tag = LocalService:GetTag(worldPath)
                
                if not tag and type(tag) ~= 'table' then
                    return
                end

                tag.fromProjects = tag.kpProjectId
                tag.kpProjectId = nil

                LocalService:SetTag(worldPath, tag)

                Mod.WorldShare.MsgBox:Close()
                WorldCommon.OpenWorld(worldPath, true)
            end
        )
    end)
end
