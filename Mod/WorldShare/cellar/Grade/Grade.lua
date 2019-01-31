--[[
Title: Grade
Author(s):  big
Date: 2019.01.16
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Grade = NPL.load("(gl)Mod/WorldShare/cellar/Grade/Grade.lua")
------------------------------------------------------------
]]

local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local GradeLocalData = NPL.load("(gl)Mod/WorldShare/database/GradeLocaldata.lua")

local Grade = NPL.export()

function Grade:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/Grade/Grade.html", "Grade", 0, 0, "_fi", false)
end

function Grade:SetPage()
    Store:Set("page/Grade", document:GetPageCtrl())
end

function Grade:OnWorldLoad()
    if Store:Get("world/noGrade") then
        return false
    end

    if not GradeLocalData:IsProjectIdExist(self:GetProjectId()) then
        Utils.SetTimeOut(
            function()
                self:ShowNoticeButton()
            end,
            (1000 * 60 * 3)
        )
    end
end

function Grade:ClosePage()
    local GradePage = Store:Get('page/Grade')

    if (GradePage) then
        GradePage:CloseWindow()
    end
end

function Grade:GetProjectId()
    local tagInfo = WorldCommon.GetWorldInfo()
    local openKpProjectId = Store:Get('world/openKpProjectId')
    local urlKpProjectId = KeepworkService:GetProjectFromUrlProtocol()

    if tagInfo and tagInfo.kpProjectId then
        return tagInfo.kpProjectId
    end

    if urlKpProjectId then
        return urlKpProjectId
    end

    if openKpProjectId then
        return openKpProjectId
    end
end

function Grade:ShowNoticeButton()
    if TeacherAgent:IsEnabled() then
        TeacherAgent:SetEnabled()
    end

    TeacherAgent:AddTaskButton(
        "GradeNotice",
        "textures/worldshare_32bits.png#20 130 80 80",
        function()
            self:CloseNoticeButton()

            local function Handle()
                Store:Remove('user/loginText')
                if KeepworkService:IsSignedIn() then
                    self:ShowPage()
                else
                    self:ShowNoticeButton()
                end
            end

            if not KeepworkService:IsSignedIn() then
                KeepworkService:GetUserTokenFromUrlProtocol()

                local token = Store:Get('user/token')

                if not token then
                    Store:Set("user/loginText", L"登录后，可为作品打分")
                    LoginModal:ShowPage()
                    Store:Set('user/AfterLogined', Handle)
                    return false
                end
        
                KeepworkService:LoginWithTokenApi(Handle)
                return false
            end
            
            Handle()
        end,
        0,
        100,
        L'点击评分'
    )

    TeacherAgent:SetEnabled(true)
end

function Grade:CloseNoticeButton()
    TeacherAgent:RemoveTaskButton('GradeNotice')
    TeacherAgent:SetEnabled()
end

function Grade:Refresh(time, callback)
    local GradePage = Store:Get('page/Grade')

    if (GradePage) then
        GradePage:Refresh(time or 0.01)
    end
end

function Grade:Confirm(score)
    local tagInfo = WorldCommon.GetWorldInfo()

    if not self:GetProjectId() then
        return false
    end

    if not score or score == 0 then
        return false
    end

    local rate = score * 20

    KeepworkService:SetRatedProject(
        self:GetProjectId(),
        rate,
        function(data, err)
            if err == 200 then
                GradeLocalData:RecordProjectId(self:GetProjectId())
                _guihelper.MessageBox(L"感谢您为该作品打分！")
            end
        end
    )

    self:ClosePage()
end

function Grade:Later()
    self:ClosePage()

    Utils.SetTimeOut(
        function()
            self:ShowNoticeButton()
        end,
        (1000 * 60 * 5)
    )
end