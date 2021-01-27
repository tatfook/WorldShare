--[[
Title: minimap UI window
Author(s): 
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/cellar/VipNotice/QRCodeWnd.lua");
local QRCodeWnd = commonlib.gettable("Mod.WorldShare.cellar.VipNotice.QRCodeWnd");
QRCodeWnd:Show();
-------------------------------------------------------
]]

-- libs
local Window = commonlib.gettable("System.Windows.Window")

local QRCodeWnd = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.cellar.VipNotice.QRCodeWnd"))

function QRCodeWnd:Show()
	local width = 144
	local height = 144

	if (not self.window) then
		local window = Window:new()

		window:EnableSelfPaint(true)
		window:SetAutoClearBackground(false)

		self.window = window
	end

	self.window:Show({
		name = "QRCodeWnd", 
		url = "Mod/WorldShare/cellar/VipNotice/QRCode/QRCodeWnd.html",
		alignment = "_ct",
		left = -221,
		top = -156,
		width = width,
		height = height,
		zorder = 1,
	})
end

function QRCodeWnd:Hide()
	self.window:CloseWindow(true)
end
