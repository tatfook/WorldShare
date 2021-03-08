--[[
Title: Share Type World
Author(s): big
Date: 2021.3.8
City: Foshan
use the lib:
------------------------------------------------------------
local ShareTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/ShareTypeWorld.lua')
------------------------------------------------------------
]]

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/World.lua')

local ShareTypeWorld = NPL.export()

function ShareTypeWorld:IsSharedWorld(world)
    if type(world) ~= 'table' then
        return false
    end

    if world.shared then
        return true
    end

    if type(world.project) == 'table' and ((world.project.memberCount or 0) > 1) then
        return true
    end

    return false
end

function ShareTypeWorld:Lock(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'请稍候...')

    KeepworkServiceWorld:GetLockInfo(
        world.kpProjectId,
        function(data)
            Mod.WorldShare.MsgBox:Close()

            local userId = Mod.WorldShare.Store:Get('user/userId')
            local clientPassword = Mod.WorldShare.Store:Getter('user/GetClientPassword')
            local canLocked = false

            if not data then
                canLocked = true
            else
                if data and data.owner and data.owner.userId == userId then
                    canLocked = true
                else
                    Mod.WorldShare.MsgBox:Dialog(
                        'MultiPlayerWolrdOthersOccupy',
                        format(
                            L'%s正在以独占模式编辑世界%s，请联系%s退出编辑或者以只读模式打开世界',
                            data.owner.username,
                            world.foldername,
                            data.owner.username
                        ),
                        {
                            Title = L'世界被占用',
                            Yes = L'知道了',
                            No = L'只读模式打开'
                        },
                        function(res)
                            if res and res == _guihelper.DialogResult.No then
                                Mod.WorldShare.Store:Set('world/readonly', true)
                                
                                if callback and type(callback) == 'function' then
                                    callback()
                                end
                            end
                        end,
                        _guihelper.MessageBoxButtons.YesNo
                    )
                end
            end

            if canLocked then
                Mod.WorldShare.MsgBox:Show(L'请稍候...')

                KeepworkServiceWorld:UpdateLock(
                    world.kpProjectId,
                    'exclusive',
                    world.revision,
                    nil,
                    clientPassword,
                    function(data)
                        Mod.WorldShare.MsgBox:Close()

                        if callback and type(callback) == 'function' then
                            callback()
                        end
                    end
                )
            end
        end
    )
end

function ShareTypeWorld:CompareVersion(result, callback)
    if result == Compare.REMOTEBIGGER then
        local currentRevision = Mod.WorldShare.Store:Get('world/currentRevision') or 0
        local remoteRevision = Mod.WorldShare.Store:Get('world/remoteRevision') or 0

        Mod.WorldShare.MsgBox:Dialog(
            'MultiPlayerWorldUpdate',
            format(L'你的本地版本%d比远程版本%d旧， 是否更新为最新的远程版本？', currentRevision, remoteRevision),
            {
                Title = L'多人世界',
                Yes = L'同步',
                No = L'只读模式打开'
            },
            function(res)
                if res and res == _guihelper.DialogResult.Yes then
                    if callback and type(callback) == 'function' then
                        callback('SYNC')
                    end
                end

                if res and res == _guihelper.DialogResult.No then
                    Mod.WorldShare.Store:Set('world/readonly', true)
                    if callback and type(callback) == 'function' then
                        callback('READONLY')
                    end
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    else
        if callback and type(callback) == 'function' then
            callback('NORMAL')
        end
    end
end