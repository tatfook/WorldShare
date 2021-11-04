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
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')

local ShareTypeWorld = NPL.export()

function ShareTypeWorld:IsSharedWorld(world)
    return Mod.WorldShare.Utils:IsSharedWorld(world)
end

function ShareTypeWorld:Lock(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    if not callback and type(callback) ~= 'function' then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'请稍候...')

    KeepworkServiceWorld:GetLockInfo(
        world.kpProjectId,
        function(data)
            Mod.WorldShare.MsgBox:Close()

            if not data then
                callback(true)
            else
                local userId = Mod.WorldShare.Store:Get('user/userId')

                if data and data.owner and data.owner.userId == userId then
                    callback(true)
                else
                    Mod.WorldShare.MsgBox:Dialog(
                    "MultiPlayerWolrdOthersOccupy",
                    format(
                        L"%s正在以独占模式编辑世界%s，请联系%s退出编辑或者以只读模式打开世界",
                        data.owner.username,
                        world.foldername,
                        data.owner.username
                    ),
                    {
                        Title = L"世界被占用",
                        Yes = L"知道了",
                        No = L"强制打开"
                    },
                    function(res)
                        if res and res == _guihelper.DialogResult.No then
                            _guihelper.MessageBox(
                                L'强制打开后，您可能会覆盖其他成员正在编辑的内容，是否继续？',
                                function(res)
                                    if res and res == _guihelper.DialogResult.Yes then
                                        callback(true)
                                    end
                                end,
                                _guihelper.MessageBoxButtons.YesNo
                            )
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo
                )
                end
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