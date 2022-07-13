--[[
Title: DeleteWorld
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
------------------------------------------------------------
]]

-- libs
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')

-- service
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

local DeleteWorld = NPL.export()

function DeleteWorld:ShowPage()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/DeleteWorld/Theme/DeleteWorld.xml',
        'Mod.WorldShare.DeleteWorld',
        0,
        0,
        '_fi',
        false
    )
end

function DeleteWorld:ClosePage()
    local DeleteWorldPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.DeleteWorld')

    if DeleteWorldPage then
        DeleteWorldPage:CloseWindow()
    end
end

function DeleteWorld.GetSelectWorld()
    return Mod.WorldShare.Store:Get('world/currentWorld')
end

function DeleteWorld:DeleteWorld(callback)
    local isEnterWorld = Mod.WorldShare.Store:Get('world/isEnterWorld')
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentWorld then
        return
    end

    if isEnterWorld and not Mod.WorldShare.Store:Get('world/isShowExitPage') then
        if currentWorld.foldername == currentEnterWorld.foldername and
           currentWorld.shared == currentEnterWorld.shared and
           currentWorld.is_zip == currentEnterWorld.is_zip then
            if KeepworkServiceSession:IsSignedIn() then
                if currentWorld.shared then
                    if currentWorld.kpProjectId == currentEnterWorld.kpProjectId then
                        _guihelper.MessageBox(L'不能刪除正在编辑的世界')
                        return
                    end
                else
                    _guihelper.MessageBox(L'不能刪除正在编辑的世界')
                    return
                end
            else
                _guihelper.MessageBox(L'不能刪除正在编辑的世界')
                return
            end
        end
    end

    self.afterDeleteWorldCallback = callback
    self:ShowPage()
end

function DeleteWorld:DeleteLocal(callback, isSlient)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        GameLogic.AddBBS(nil, L'删除失败(NO INSTANCE)', 3000, '255 0 0')
        return false
    end

    local function Delete()
        if not currentWorld.worldpath then
            return false
        end

        if currentWorld.is_zip then
            if ParaIO.DeleteFile(currentWorld.worldpath) then
                if callback and type(callback) == 'function' then
                    callback()
                else
                    self:ClosePage()

                    if self.afterDeleteWorldCallback and type(self.afterDeleteWorldCallback) == 'function' then
                        self.afterDeleteWorldCallback()
                        self.afterDeleteWorldCallback = nil
                    end
                end
            else
                GameLogic.AddBBS(nil, L'无法删除，可能您没有足够的权限', 3000, '255 0 0')
            end
        else
            if GameLogic.RemoveWorldFileWatcher then
                GameLogic.RemoveWorldFileWatcher() -- file watcher may make folder deletion of current world directory not working.
            end

            if commonlib.Files.DeleteFolder(currentWorld.worldpath) then
                if callback and type(callback) == 'function' then
                    callback()
                else
                    self:ClosePage()

                    if self.afterDeleteWorldCallback and type(self.afterDeleteWorldCallback) == 'function' then
                        self.afterDeleteWorldCallback()
                        self.afterDeleteWorldCallback = nil
                    end
                end
            else
                GameLogic.AddBBS(nil, L'无法删除，可能您没有足够的权限', 3000, '255 0 0')
            end
        end
    end

    if currentWorld.status ~= 2 then
        if isSlient then
            Delete()
        else
            _guihelper.MessageBox(
                format(L'确定删除本地世界:%s?', currentWorld.text or ''),
                function(res)
                    if res and res == _guihelper.DialogResult.Yes then
                        Delete()
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        end
    end
end

function DeleteWorld:DeleteRemote(pwd, callback)
    if not pwd or type(pwd) ~= 'string' then
        return
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    _guihelper.MessageBox(
        format(L'确定删除远程世界(项目):%s?', currentWorld.foldername or ''),
        function(res)
            if res and res == 6 then
                KeepworkServiceProject:RemoveProject(
                    currentWorld.kpProjectId,
                    pwd,
                    function(data, err)
                        if err ~= 204 and err ~= 200 then
                            if data and type(data) == 'table' and data.message then
                                GameLogic.AddBBS(nil, format(L'删除失败，原因：%s(%s)', data.message or '' , data.code or ''), 8000, '255 0 0')
                            else
                                GameLogic.AddBBS(nil, format(L'删除失败(%s)',  err or ''), 3000, '255 0 0')
                            end
                            return
                        end

                        if currentWorld and currentWorld.worldpath and #currentWorld.worldpath > 0 then
                            local tag = LocalService:GetTag(currentWorld.worldpath)

                            if tag then
                                tag.kpProjectId = nil
                                LocalService:SetTag(currentWorld.worldpath, tag)
                            end
                        end

                        if callback and type(callback) == 'function' then
                            callback()
                        else
                            self:ClosePasswordAuthenticationOnDeletion()

                            if self.afterDeleteWorldCallback and type(self.afterDeleteWorldCallback) == 'function' then
                                self.afterDeleteWorldCallback()
                                self.afterDeleteWorldCallback = nil
                            end
                        end
                    end
                )
            end
        end
    )
end

function DeleteWorld:DeleteAll(pwd)
    self:DeleteRemote(
        pwd,
        function()
            self:ClosePasswordAuthenticationOnDeletion()

            self:DeleteLocal(function()
                if self.afterDeleteWorldCallback and type(self.afterDeleteWorldCallback) == 'function' then
                    self.afterDeleteWorldCallback()
                    self.afterDeleteWorldCallback = nil
                end
            end)
        end
    )
end

function DeleteWorld:ClosePasswordAuthenticationOnDeletion()
    local page = Mod.WorldShare.Store:Get('page/Mod.WorldShare.DeleteWorld.PasswordAuthenticationOnDeletion')

    if page then
        page:CloseWindow()
    end
end

function DeleteWorld:PasswordAuthenticationOnDeletion(deleteType, callback)
    self:ClosePage()

    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/DeleteWorld/Theme/PasswordAuthenticationOnDeletion.xml',
        'Mod.WorldShare.DeleteWorld.PasswordAuthenticationOnDeletion',
        0,
        0,
        '_fi',
        false
    )

    params._page.callback = function(pwd)
        if deleteType == 'all' then
            self:DeleteAll(pwd)
        elseif deleteType == 'remote' then
            self:DeleteRemote(pwd)
        end
    end
end
