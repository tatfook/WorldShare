--[[
Title: cube map render
Author(s): big
Date: 2020.10.10
Desc: 
use the lib:
------------------------------------------------------------
local CubeMapRender = NPL.load("(gl)Mod/WorldShare/render/CubeMap.lua")
-------------------------------------------------------
]]

-- lib
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local Screen = commonlib.gettable("System.Windows.Screen")
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager")

local CubeMapRender = NPL.export()

function CubeMapRender:Generate(worldpath, callback)
    ParaUI.GetUIObject("root").visible = false;
    ParaUI.ShowCursor(false);
    ParaScene.EnableMiniSceneGraph(false);
    ParaEngine.ForceRender();ParaEngine.ForceRender();

    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

    if not currentEnterWorld or type(currentEnterWorld) ~= "table" then
        return false
    end

    ParaIO.CreateDirectory(currentEnterWorld.worldpath .. "CubeMap/")

    CommandManager:RunCommand("/fps true")
    CommandManager:RunCommand("/fov 1.75")

    Mod.WorldShare.Utils.SetTimeOut(function()
        CommandManager:RunCommand("/camerapitch 0")
        CommandManager:RunCommand("/camerayaw 3.14")
    end, 500)

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(currentEnterWorld.worldpath .. "CubeMap/face0.jpg", 600, 600, true)

        CommandManager:RunCommand("/camerapitch 0")
        CommandManager:RunCommand("/camerayaw -1.57")
    end, 1000)

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(currentEnterWorld.worldpath .. "CubeMap/face1.jpg", 600, 600, true)

        CommandManager:RunCommand("/camerapitch 0")
        CommandManager:RunCommand("/camerayaw 0")
    end, 1500)

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(currentEnterWorld.worldpath .. "CubeMap/face2.jpg", 600, 600, true)

        CommandManager:RunCommand("/camerapitch 0")
        CommandManager:RunCommand("/camerayaw 1.57")
    end, 2000)

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(currentEnterWorld.worldpath .. "CubeMap/face3.jpg", 600, 600, true)

        CommandManager:RunCommand("/camerapitch -1.57")
        CommandManager:RunCommand("/camerayaw 3.14")
    end, 2500)

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(currentEnterWorld.worldpath .. "CubeMap/face4.jpg", 600, 600, true)

        CommandManager:RunCommand("/camerapitch 1.57")
        CommandManager:RunCommand("/camerayaw 3.14")
    end, 3000)

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(currentEnterWorld.worldpath .. "CubeMap/face5.jpg", 600, 600, true)

        ParaUI.ShowCursor(true);
        ParaUI.GetUIObject("root").visible = true;
        ParaScene.EnableMiniSceneGraph(true);
        CommandManager:RunCommand("/fps false")

        if callback and type(callback) == "function" then
            callback()
        end
    end, 3500)
end

function CubeMapRender:RenderCubeMapImage(filepath)
    local tempfile = Mod.WorldShare.Utils.GetTempFolderFullPath() .. "cubemap_render.jpg"

    CommandManager:RunCommand("/hide tips")
    ParaUI.GetUIObject("root").visible = false;
    ParaUI.ShowCursor(false);
    ParaScene.EnableMiniSceneGraph(false);
    ParaEngine.ForceRender();ParaEngine.ForceRender();

    local viewport = ViewportManager:GetSceneViewport()
    viewport:SetPosition("_ctt", 0, 0, Screen:GetHeight(), Screen:GetHeight())

    Mod.WorldShare.Utils.SetTimeOut(function()
        ParaMovie.TakeScreenShot(tempfile, Screen:GetWidth(), Screen:GetHeight())

        viewport:SetPosition("_fi", 0,0,0,0)

        CommandManager:RunCommand("/hide tips")
        ParaUI.GetUIObject("root").visible = true;
        ParaUI.ShowCursor(true);
        ParaScene.EnableMiniSceneGraph(true);
        
        local _width = Screen:GetWidth();
        local _height = Screen:GetHeight();

        local r = ParaUI.GetUIObject("root");

        local c = ParaUI.CreateUIObject("container", "RenderCubMapImage", "_lt", -(_width - _height), 0, _width + (_width - _height) * 2, _height);
        c.background = tempfile
        c.zorder = 10
        
        r:AddChild(c)

        Mod.WorldShare.Utils.SetTimeOut(function()
            ParaMovie.TakeScreenShot((filepath), _height, _height)
            ParaUI.DestroyUIObject(c)
        end, 100)
    end, 100)
end