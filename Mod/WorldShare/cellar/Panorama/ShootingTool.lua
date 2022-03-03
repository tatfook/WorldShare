local Screen = commonlib.gettable("System.Windows.Screen")
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager")
local viewport = ViewportManager:GetSceneViewport()
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")

local ShootingTool = NPL.export()

--https://keepwork.com/dreamanddead/working/panorama
ShootingTool.arr = {
    {0, 3.14},
    {0, -1.57},
    {0, 0},
    {0, 1.57},
    {-1.57, 3.14},
    {1.57, 3.14}
}

local cameraDis = 0.000001

function ShootingTool:init()
	self.currentTime = os.time()
	local entityPlayer = GameLogic.EntityManager.GetFocus()
    local x, y, z = entityPlayer:GetBlockPos()
    GameLogic.RunCommand(format("/goto %d,%d,%d", x,y,z))

    self.center = {x=x,y=y,z=z}

    self.rootPath = ""
	if System.os.GetExternalStoragePath() ~= "" then
		self.rootPath = System.os.GetExternalStoragePath() .. "paracraft/"
	else
		self.rootPath = ParaIO.GetWritablePath()
	end

	local width = Screen:GetWidth()
	local height = Screen:GetHeight()
	self._width = math.max(width, height)
	self._height = math.min(width, height)
end

ShootingTool.offsets = {
    {-1, 0, 0},
    {0, 0, 1},
    {1, 0, 0},
    {0, 0, -1},
    {0, 1, 0},
    {0, -1, 0},
}

function ShootingTool:setEye(i)
	
    local pitch, yaw = unpack(self.arr[i])
    ParaCamera.SetEyePos(cameraDis, pitch, yaw)
    local of = self.offsets[i]
    local x,y,z = self.center.x,self.center.y,self.center.z
    -- x = x + of[1]*cameraDis
    -- y = y + of[1]*cameraDis
    -- z = z + of[1]*cameraDis
    GameLogic.RunCommand(format("/goto %d,%d,%d", x,y,z))
end

--name : 1,2,3,4,5,6。  共6个方向
function ShootingTool:tempfile_path(name)
	return string.format("%sScreen Shots/cubemap_tmp_%s_%s.jpg", self.rootPath, self.currentTime, name)
end

function ShootingTool:delete_tempfile(name)
	ParaIO.DeleteFile(self:tempfile_path(name))
end

function ShootingTool:doShoot(name)
	-- GameLogic.RunCommand("/property -all-2 PasueScene true")
	ParaUI.GetUIObject("root").visible = false
	
	ParaEngine.ForceRender();ParaEngine.ForceRender();
	local tempfile = self:tempfile_path(name)
	ParaMovie.TakeScreenShot(tempfile)

end

function ShootingTool:hideAllUI()
	local root = ParaUI.GetUIObject("root")
	local children = root:GetChildren();
	print("children",children)
end

function ShootingTool:doCrop(name,delay,callback)
	-- GameLogic.RunCommand("/t 2 /property -all-2 PasueScene false")
	ParaUI.GetUIObject("root").visible = true
	local r = ParaUI.GetUIObject("root")

	local offset = (self._width - self._height) / 2 * self._width / self._height
	local c = ParaUI.CreateUIObject("container", "RenderCubMapImage" .. name, "_lt", -offset, 0, self._width * self._width / self._height, self._height);
	c.zorder = 90000
	c.background = self:tempfile_path(name)
	r:AddChild(c)

	ParaEngine.ForceRender()
	ParaEngine.ForceRender()

	commonlib.TimerManager.SetTimeout(function()
		local filepath = string.format("%sScreen Shots/%s.jpg", self.rootPath, name-1)
		ParaMovie.TakeScreenShot(filepath, self._height, self._height)
		ParaUI.DestroyUIObject(c)
		self:delete_tempfile(name)
		if callback then
			callback()
		end
	end,delay)
end

--自动拍6张照片
function ShootingTool:autoShoot(callback)
	GameLogic.RunCommand("/hide player")
	CameraController.AnimateFieldOfView(1.57, 10);
	ParaScene.GetAttributeObject():SetField("BlockInput", true)
	ParaCamera.GetAttributeObject():SetField("BlockInput", true)

	ParaUI.ShowCursor(false)
	ParaScene.EnableMiniSceneGraph(false);
	
	GameLogic.RunCommand("/hide desktop")
	GameLogic.RunCommand("/hide tips")
	GameLogic.RunCommand("/hide")

	local onFinish = function ()
		GameLogic.RunCommand("/show desktop")
		GameLogic.RunCommand("/show tips")
		GameLogic.RunCommand("/show")

		ParaUI.ShowCursor(true)
		ParaScene.EnableMiniSceneGraph(true);

		-- GameLogic.RunCommand("/fov 1")
		CameraController.AnimateFieldOfView(1, 10);
		
		GameLogic.RunCommand("/cameradist 10")
		GameLogic.RunCommand("/camerapitch 0")

		ParaScene.GetAttributeObject():SetField("BlockInput", false)
		ParaCamera.GetAttributeObject():SetField("BlockInput", false)
		if callback then
			callback()
		end
	end
	local delay = 2000
	for i=1,#self.arr do
		commonlib.TimerManager.SetTimeout(function()
			self:setEye(i)
			commonlib.TimerManager.SetTimeout(function()
				self:doShoot(i)
				ParaEngine.ForceRender();ParaEngine.ForceRender()
					self:doCrop(i,delay*0.5,function ( ... )
						if i==#self.arr then 
							onFinish()
						end
					end)
			end,delay*0.4)
		end,delay*(i-1))
	end
end
