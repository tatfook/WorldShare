--[[
Title: Certificate Filter
Author(s):  Big
Date: 2021.7.10
Desc: 
use the lib:
------------------------------------------------------------
local CertificateFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Certificate/CertificateFilter.lua')
CertificateFilter:Init()
------------------------------------------------------------
]]

-- UI
local Certificate = NPL.load("(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua")

local CertificateFilter = NPL.export()

function CertificateFilter:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.certificate.show_certificate_notice_page',
        function(...)
            Certificate:ShowCertificateNoticePage(...)
        end
    )
end