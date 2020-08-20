--[[
Title: Project Setting
Author: big  
Date: 2020.8.15
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local OpusSetting = NPL.load("(gl)Mod/WorldShare/cellar/OpusSetting/OpusSetting.lua")
------------------------------------------------------------
]]

--- service
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")

local OpusSetting = NPL.export()

function OpusSetting:Show()
    local params = Mod.WorldShare.Utils.ShowWindow(400, 280, "(ws)OpusSetting", "Mod.WorldShare.OpusSetting")

    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId then
        return false
    end

    KeepworkServiceProject:GetProject(currentWorld.kpProjectId, function(data, err)
        if type(data) == 'table' and data.visibility then
            if data.visibility == 0 then
                -- public
                params._page:GetNode("public"):SetAttribute("checked", "checked")
                params._page:SetValue("private", false)
            elseif data.visibility == 1 then
                -- private
                params._page:SetValue("public", false)
                params._page:GetNode("private"):SetAttribute("checked", "checked")
            end

            params._page:Refresh(0.01)
        end
    end)
end

function OpusSetting:SetPublic(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId then
        return false
    end

    local params = {}

    if value == "public" then
        params.visibility = 0
    elseif value == "private" then
        params.visibility = 1
    end

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L"设置成功", 3000, "0 255 0")
        else
            GameLogic.AddBBS(nil, L"设置失败", 3000, "255 0 0")
        end
    end)
end
