--[[
Title: Member Manager
Author: big  
Date: 2020.8.17
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local MemberManager = NPL.load("(gl)Mod/WorldShare/cellar/MemberManager/MemberManager.lua")
------------------------------------------------------------
]]

-- UI
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

--- service
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local MemberManager = NPL.export()

MemberManager.memberList = {}
MemberManager.applyList = {}
MemberManager.sel = 1
MemberManager.addUsersHandleIndex = 0
MemberManager.userIds = {}

function MemberManager:Show()
    Mod.WorldShare.Utils.ShowWindow(500, 320, "(ws)MemberManager", "Mod.WorldShare.MemberManager")

    self:GetApplyList()
    self:GetMembers()
end

function MemberManager:ShowApply()
    LoginModal:CheckSignedIn(L"请先登录!", function(bSucceed)
        if bSucceed then
            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
            local userId = Mod.WorldShare.Store:Get('user/userId')

            if currentEnterWorld and currentEnterWorld.user and currentEnterWorld.user.id == userId then
                _guihelper.MessageBox(L"此项属于你，无需申请")
                return
            end

            Mod.WorldShare.Utils.ShowWindow(400, 260, "(ws)MemberManager/Apply.html", "Mod.WorldShare.MemberManager.Apply")
        end
    end)
end

function MemberManager:GetApplyList()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return false
    end
    
    KeepworkServiceProject:GetApplyList(currentWorld.kpProjectId, function(data, err)
        if type(data) ~= 'table' then
            return false
        end

        local applyList = {}

        for key, item in ipairs(data) do
            if item and item.object and item.object.username and item.state and item.state == 0 then
                applyList[#applyList + 1] = {
                    username = item.object.username,
                    message = item.legend or "",
                    date = os.date("%Y/%m/%d", Mod.WorldShare.Utils:UnifiedTimestampFormat(item.updatedAt or "")),
                    id = item.id
                }
            end
        end

        self.applyList = applyList

        local MemberManagerPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.MemberManager')

        if MemberManagerPage then
            MemberManagerPage:Rebuild()
        end
    end)
end

function MemberManager:GetMembers()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return false
    end

    KeepworkServiceProject:GetMembers(currentWorld.kpProjectId, function(data, err)
        if type(data) ~= 'table' then
            return false
        end

        local memberList = {}
        local username = Mod.WorldShare.Store:Get("user/username")

        for key, item in ipairs(data) do
            if username ~= item.username then
                memberList[#memberList + 1] = {
                    username = item.username,
                    id = item.id,
                    date = os.date("%Y/%m/%d", Mod.WorldShare.Utils:UnifiedTimestampFormat(item.createdAt or "")),
                }
            end
        end

        self.memberList = memberList

        local MemberManagerPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.MemberManager')

        if MemberManagerPage then
            MemberManagerPage:Rebuild()
        end
    end)
end

function MemberManager:HandleApply(id, isAllow)
    KeepworkServiceProject:HandleApply(id, isAllow, function(data, err)
        GameLogic.AddBBS(nil, L"操作成功", 3000, "0 255 0")

        self:GetApplyList()
    end)
end

function MemberManager:RemoveUser(id)
    KeepworkServiceProject:RemoveUserFromMember(id, function(data, err)
        GameLogic.AddBBS(nil, L"删除成功", 3000, "0 255 0")

        self:GetMembers()
    end)
end

function MemberManager:AddUsers(users, recursive)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return false
    end

    if type(users) ~= 'table' or #users == 0 then
        return false
    end

    if self.addUsersHandleIndex ~= 0 and not recursive then
        return false
    end

    if #users == self.addUsersHandleIndex then
        KeepworkServiceProject:AddMembers(currentWorld.kpProjectId, self.userIds, function(data, err)
            if err ~= 200 then
                GameLogic.AddBBS(nil, L"批量添加用户失败", 3000, "255 0 0")
            else
                GameLogic.AddBBS(nil, L"批量添加用户成功", 3000, "0 255 0")

                local MemberManagerPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.MemberManager')

                if MemberManagerPage then
                    MemberManagerPage:SetValue("edit_member_list", "")
                    MemberManagerPage:Refresh(0.01)
                end
            end
        end)

        self.addUsersHandleIndex = 0
        self.userIds = {}
        return true
    end

    self.addUsersHandleIndex = self.addUsersHandleIndex + 1

    KeepworkServiceSession:CheckUsernameExist(users[self.addUsersHandleIndex], function(bExisted, userinfo)
        if not bExisted then
            GameLogic.AddBBS(nil, format(L"用户名%s不存在，请查证", users[self.addUsersHandleIndex]), 3000, "255 0 0")
            self.addUsersHandleIndex = 0
            return false
        end

        if not userinfo or not userinfo.id then
            return false
        end

        self.userIds[#self.userIds + 1] = userinfo.id

        self:AddUsers(users, true)
    end)
end

function MemberManager:Apply(message)    
    KeepworkServiceProject:Apply(message, function(data, err)
       if err == 200 then
            GameLogic.AddBBS(nil, L"申请成功，等待项目创建者处理", 3000, "0 255 0")

            local ApplyPage = Mod.WorldShare.Store:Get("page/Mod.WorldShare.MemberManager.Apply")

            if ApplyPage then
                ApplyPage:CloseWindow()
            end
       else
            GameLogic.AddBBS(nil, L"申请失败", 3000, "255 0 0")
       end
    end)
end
