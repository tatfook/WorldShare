--[[
Title: Permission
Author(s):  big
CreateDate: 2020.05.22
ModifyDate: 2021.10.18
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Permission = NPL.load('(gl)Mod/WorldShare/cellar/Permission/Permission.lua')
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServicePermission = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Permission.lua')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local VipPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua')

local Permission = NPL.export()

function Permission:CheckPermission(authName, bOpenUIIfNot, callback, uiType)
    if not authName or type(authName) ~= 'string' then
        authName = ''
    end

    if bOpenUIIfNot then
        local desc = ''

        if not uiType or uiType == 'Vip' then
            desc = L'您需要登录并成为VIP用户，才能使用此功能'
        end

        if uiType == 'Teacher' then
            desc = L'此功能需要特殊权限，请先登录'
        end

        if uiType == 'Institute' then
            desc = L'此功能需要特殊权限，请先登录'
        end

        LoginModal:CheckSignedIn(desc, function(result)
            if not result then
                return false
            end

            local function Handle()
                -- update user info
                KeepworkServiceSession:Profile(
                    function(response)
                        if not response then
                            return
                        end

                        -- update user vip info
                        if response.vip and response.vip == 1 then
                            Mod.WorldShare.Store:Set('user/isVip', true)
                        else
                            Mod.WorldShare.Store:Set('user/isVip', false)
                        end

                        KeepworkServiceSession:SetUserLevels(response)

                        KeepworkServicePermission:Authentication(authName, function(result, key, desc)
                            if result == false then
                                if not uiType or uiType == 'Vip' then
                                    self:ShowFailDialog(key, desc)
                                end
        
                                if uiType == 'Teacher' then
                                    _guihelper.MessageBox(L'此功能需要教师权限，如需获取请联系管理员或者客服咨询')
                                end
        
                                if uiType == 'Institute' then
                                    _guihelper.MessageBox(desc)
                                end
                            end
        
                            if callback and type(callback) == 'function' then
                                callback(result)
                            end
                        end)
                    end
                )
            end

            if result == 'REGISTER' or result == 'FORGET' then
                return false
            end

            if result == 'THIRD' then
                return Handle
            end

            if result == true then
                Handle()
            end
        end)
    else
        if KeepworkServiceSession:IsSignedIn() then
            KeepworkServicePermission:Authentication(authName, callback)
        else
            if type(callback) == 'function' then
                callback(false)
            end
        end
    end
end

function Permission:ShowFailDialog(key, desc)
    VipPage.ShowPage(key, desc)
end