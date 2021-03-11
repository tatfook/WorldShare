--[[
Title: Permission
Author(s):  big
Date: 2020.05.22
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Permission = NPL.load("(gl)Mod/WorldShare/cellar/Permission/Permission.lua")
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local KeepworkServicePermission = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Permission.lua")

-- bottles
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local VipNotice = NPL.load("(gl)Mod/WorldShare/cellar/VipNotice/VipNotice.lua")

local Permission = NPL.export()

function Permission:CheckPermission(authName, bOpenUIIfNot, callback, uiType)
    if not authName or type(authName) ~= "string" then
        authName = ""
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
                KeepworkServicePermission:Authentication(authName, function(result, key, desc)
                    if result == false then
                        if not uiType or uiType == 'Vip' then
                            self:ShowFailDialog(key, desc)
                        end

                        if uiType == 'Teacher' then
                            _guihelper.MessageBox(L'此功能需要特殊权限')
                        end

                        if uiType == 'Institute' then
                            _guihelper.MessageBox(desc)
                        end
                    end

                    if callback and type(callback) == "function" then
                        callback(result)
                    end
                end)
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
            if type(callback) == "function" then
                callback(false)
            end
        end
    end
end

function Permission:ShowFailDialog(key, desc)
    VipNotice:ShowPage(key, desc)
end