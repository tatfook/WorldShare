--[[
Title: Save World
Author(s): big
Date:  2020.3.19
Desc: 
use the lib:
------------------------------------------------------------
local SaveWorld = NPL.load("(gl)Mod/WorldShare/cellar/SaveWorld/SaveWorld.lua")
------------------------------------------------------------
]]

local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")

local SaveWorld = NPL.export()

function SaveWorld:Save(callback)
    if KeepworkServiceSession:IsSignedIn() then
        if KeepworkServiceSession:IsCurrentWorldsFolder() then
            if type(callback) == 'function' then
                callback()
            end
        else
            Mod.WorldShare.MsgBox:Dialog(
                "SaveWorldSignInSave",
                format(L"此世界储存在本地%s世界文件夹中，如需保存当前编辑内容，请另存为个人世界", KeepworkServiceSession:IsTempWorldsFolder() and L'临时' or L'其他用户'),
                {
                    Yes = L"取消",
                    No = L"另存为个人世界"
                },
                function(res)
                    if res == 4 then
                        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                        local username = Mod.WorldShare.Store:Get('user/username')

                        if not currentWorld or not currentWorld.worldpath or currentWorld.worldpath == '' or not username or username == '' then
                            return false
                        end

                        local dest = string.gsub(currentWorld.worldpath, '/worlds/%w+/', '/worlds/' .. username .. '/')

                        LocalService:CopyWorldTo(dest)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo,
                {
                    Yes = { marginLeft = '50px' },
                    No = { width = '120px' },
                }
            )
        end
    else
        Mod.WorldShare.MsgBox:Dialog(
            "SaveWorldOfflineSave",
            L'是否希望将该“临时世界”编辑内容作为个人世界保存在个人文件夹中？如果保存为个人文件，请先登录。',
            {
                Yes = L"暂时保存为临时文件",
                No = L"登录并保存为个人世界"
            },
            function(res)
                if res == 8 then
                    if KeepworkServiceSession:IsTempWorldsFolder() then
                        if type(callback) == 'function' then
                            callback()
                        end
                    else
                        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                        if not currentWorld or not currentWorld.worldpath or currentWorld.worldpath == '' then
                            return false
                        end

                        local dest = string.gsub(currentWorld.worldpath, '/worlds/%w+/', '/worlds/DesignHouse/')

                        LocalService:CopyWorldTo(dest)
                    end
                elseif res == 4 then
                    LoginModal:Init(function(result)
                        if result then
                            if KeepworkServiceSession:IsCurrentWorldsFolder() then
                                if type(callback) == 'function' then
                                    callback()
                                end
                            else
                                Mod.WorldShare.MsgBox:Dialog(
                                    "SaveWorldOfflineSaveConfirm",
                                    L'登录成功，点击"确认"按钮将当前世界另存为个人世界。',
                                    {
                                        Yes = L"取消",
                                        No = L"确认"
                                    },
                                    function(res)
                                        if res == 4 then
                                            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                                            local username = Mod.WorldShare.Store:Get('user/username')
    
                                            if not currentWorld or not currentWorld.worldpath or currentWorld.worldpath == '' or not username or username == '' then
                                                return false
                                            end
    
                                            local dest = string.gsub(currentWorld.worldpath, '/worlds/%w+/', '/worlds/' .. username .. '/')
    
                                            LocalService:CopyWorldTo(dest)
                                        end
                                    end,
                                    _guihelper.MessageBoxButtons.YesNo
                                )
                            end
                        end
                    end)
                end
            end,
            _guihelper.MessageBoxButtons.YesNo,
            {
                Window = { width = '440px' },
                Container = { width = '430px' },
                Yes = { width = '150px', marginLeft = '50px' },
                No = { width = '160px' }
            }
        )
    end

    return true
end

function SaveWorld:SaveAs(callback)
    if KeepworkServiceSession:IsSignedIn() then
        if KeepworkServiceSession:IsCurrentWorldsFolder() then
            if type(callback) == 'function' then
                callback()
            end
        else
            Mod.WorldShare.MsgBox:Dialog(
                "SaveWorldSignInSaveAsConfirm",
                format(L'此世界储存在本地%s世界文件夹中，如需另存为当前编辑内容，请另存为个人世界。', KeepworkServiceSession:IsTempWorldsFolder() and L'临时' or L'其他用户'),
                {
                    Yes = L"取消",
                    No = L"确认"
                },
                function(res)
                    if res == 4 then
                        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                        local username = Mod.WorldShare.Store:Get('user/username')

                        if not currentWorld or not currentWorld.worldpath or currentWorld.worldpath == '' or not username or username == '' then
                            return false
                        end

                        local dest = string.gsub(currentWorld.worldpath, '/worlds/%w+/', '/worlds/' .. username .. '/')

                        LocalService:CopyWorldTo(dest)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        end
    else
        Mod.WorldShare.MsgBox:Dialog(
            "SaveWorldOfflineSaveAsConfirm",
            L'是否希望将该"临时世界"编辑内容作为个人世界保存在个人文件夹中？如果保存为个人文件，请先登录。',
            {
                Yes = L"暂时保存为临时文件",
                No = L"登录并保存为个人世界"
            },
            function(res)
                if res == 8 then
                    if KeepworkServiceSession:IsTempWorldsFolder() then
                        if type(callback) == 'function' then
                            callback()
                        end
                    else
                        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                        if not currentWorld or not currentWorld.worldpath or currentWorld.worldpath == '' then
                            return false
                        end

                        local dest = string.gsub(currentWorld.worldpath, '/worlds/%w+/', '/worlds/DesignHouse/')

                        LocalService:CopyWorldTo(dest)
                    end
                end

                if res == 4 then
                    LoginModal:Init(function(result)
                        if result then
                            if KeepworkServiceSession:IsCurrentWorldsFolder() then
                                if type(callback) == 'function' then
                                    callback()
                                end
                            else
                                Mod.WorldShare.MsgBox:Dialog(
                                    "SaveWorldOfflineSaveConfirm",
                                    L'登录成功，点击"确认"按钮将当前世界另存为个人世界。',
                                    {
                                        Yes = L"取消",
                                        No = L"确认"
                                    },
                                    function(res)
                                        if res == 4 then
                                            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                                            local username = Mod.WorldShare.Store:Get('user/username')
    
                                            if not currentWorld or not currentWorld.worldpath or currentWorld.worldpath == '' or not username or username == '' then
                                                return false
                                            end
    
                                            local dest = string.gsub(currentWorld.worldpath, '/worlds/%w+/', '/worlds/' .. username .. '/')
    
                                            LocalService:CopyWorldTo(dest)
                                        end
                                    end,
                                    _guihelper.MessageBoxButtons.YesNo
                                )
                            end
                        end
                    end)
                end
            end,
            _guihelper.MessageBoxButtons.YesNo,
            {
                Window = { width = '440px' },
                Container = { width = '430px' },
                Yes = { width = '150px', marginLeft = '50px' },
                No = { width = '160px' }
            }
        )
    end

    return true
end