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

local Grade = NPL.export()

function Grade:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/Grade/Grade.html", "Grade", 0, 0, "_fi", false)
end

function Grade:SetPage()
    Store:Set("page/Grade", document:GetPageCtrl())
end

function Grade:OnWorldLoad()
    local tagInfor = WorldCommon.GetWorldInfo()

    if not tagInfor or not tagInfor.kpProjectId then
        return false
    end
    
    local function Handle()
        KeepworkService:GetRatedProject(
            tagInfor.kpProjectId,
            function(data, err)
                if err ~= 200 or #data == 0 then
                    Utils.SetTimeOut(
                        function()
                            self:ShowNoticeButton()
                        end,
                        1000 * 60 * 3
                    )
                end
            end
        )
    end

    if not KeepworkService:IsSignedIn() then
        KeepworkService:GetUserTokenFromUrlProtocol()

        local token = Store:Get('user/token')

        if not token then
            LoginModal:ShowPage()
            Store:Set('user/AfterLogined', Handle)
            return false
        end

        KeepworkService:LoginWithTokenApi(Handle)
        return false
    end
    
    Handle()
end

function Grade:ClosePage()
    local GradePage = Store:Get('page/Grade')

    if (GradePage) then
        GradePage:CloseWindow()
    end
end

function Grade:ShowNoticeButton()
    TeacherAgent:AddTaskButton(
        "GradeNotice",
        "textures/worldshare_32bits.png#20 130 80 80",
        function()
            self:CloseNoticeButton()
            self:ShowPage()
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
    local tagInfor = WorldCommon.GetWorldInfo()

    if not tagInfor or not tagInfor.kpProjectId then
        return false
    end

    if not score or score == 0 then
        return false
    end

    local rate = score * 20

    KeepworkService:SetRatedProject(
        tagInfor.kpProjectId,
        rate,
        function(data, err)
            if err == 200 then
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
        1000 * 60 * 5
    )
end