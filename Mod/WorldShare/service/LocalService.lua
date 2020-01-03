﻿--[[
Title: LocalService
Author(s):  big
Date:  2016.12.11
Desc: 
use the lib:
------------------------------------------------------------
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
------------------------------------------------------------
]]
NPL.load("./FileDownloader/FileDownloader.lua")
local Files = commonlib.gettable("commonlib.Files")

local SystemEncoding = commonlib.gettable("System.Encoding")
local CommonlibEncoding = commonlib.gettable("commonlib.Encoding")
local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")

local LocalService = NPL.export()

LocalService.filter = "*"
LocalService.nMaxFileLevels = 0
LocalService.nMaxFilesNum = 500
LocalService.output = {}

function LocalService:LoadFiles(worldDir)
    if not worldDir or #worldDir == 0 then
        return {}
    end

    self.output = {}
    self.worldDir = worldDir

    local result = Files.Find({}, self.worldDir, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)

    self:FilesFind(result, self.worldDir)

    for _, item in ipairs(self.output) do
        item.filename = CommonlibEncoding.DefaultToUtf8(item.filename)
    end

    return self.output
end

function LocalService:FilesFind(result, path, subPath)
    local curResult = commonlib.copy(result)
    local curPath = commonlib.copy(path)
    local curSubPath = commonlib.copy(subPath)

    if (type(curResult) == "table") then
        local convertLineEnding = {[".xml"] = true, [".bmax"] = true, [".txt"] = true, [".md"] = true, [".lua"] = true}
        local zipFile = {[".xml"] = true, [".bmax"] = true}

        for key, item in ipairs(curResult) do
            if (item.filesize ~= 0) then
                item.file_path = curPath .. "/" .. item.filename

                if (curSubPath) then
                    item.filename = curSubPath .. "/" .. item.filename
                end

                local sExt = item.filename:match("%.[^&.]+$")

                if (sExt == ".bak") then
                    item = false
                else
                    local bConvert = false

                    if (convertLineEnding[sExt] and zipFile[sExt]) then
                        bConvert = not self:IsZip(item.file_path)
                    elseif (convertLineEnding[sExt]) then
                        bConvert = true
                    end

                    if (bConvert) then
                        item.file_content_t = self:GetFileContent(item.file_path):gsub("\r\n", "\n") or ""
                        item.filesize = #item.file_content_t or 0
                        item.sha1 = SystemEncoding.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex")
                    else
                        item.file_content_t = self:GetFileContent(item.file_path) or ""
                        item.sha1 = SystemEncoding.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex")
                    end

                    item.needChange = true

                    self.output[#self.output + 1] = item
                end
            else
                local newPath = curPath .. "/" .. item.filename
                local newResult = Files.Find({}, newPath, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)
                local newSubPath = nil

                if (curSubPath) then
                    newSubPath = curSubPath .. "/" .. item.filename
                else
                    newSubPath = item.filename
                end

                self:FilesFind(newResult, newPath, newSubPath)
            end
        end
    end
end

function LocalService:GetFileContent(filePath)
    local file = ParaIO.open(filePath, "r")
    if (file:IsValid()) then
        local fileContent = file:GetText(0, -1)
        file:close()
        return fileContent
    end
end

function LocalService:Write(foldername, path, content)
    if not foldername or not path then
        return false
    end

    foldername = CommonlibEncoding.Utf8ToDefault(foldername)
    path = CommonlibEncoding.Utf8ToDefault(path)

    local root = Mod.WorldShare.Utils.GetWorldFolderFullPath()
    local allPath = {}

    for segmentation in string.gmatch(path, "[^/]+") do
        allPath[#allPath + 1] = segmentation
    end

    for key, item in ipairs(allPath) do
        if key ~= #allPath then
            local curFolderPath = ''

            for i=1, key do
                curFolderPath = format("%s/%s", curFolderPath, allPath[i] or '')
            end

            local curCreatePath = format("%s/%s%s/", root, foldername, curFolderPath)

            ParaIO.CreateDirectory(curCreatePath)
        end
    end

    local writePath = format("%s/%s/%s", root, foldername, path)

    local write = ParaIO.open(writePath, "w")

    write:write(content, #content)
    write:close()
end

function LocalService:Delete(foldername, filename)
    local deletePath = format(
                        "%s/%s/%s",
                        Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                        CommonlibEncoding.Utf8ToDefault(foldername or ''),
                        CommonlibEncoding.Utf8ToDefault(filename or '')
                       )

    ParaIO.DeleteFile(deletePath)
end

function LocalService:IsZip(path)
    local file = ParaIO.open(path, "r")
    local fileType = nil

    if (file:IsValid()) then
        local o = {}

        file:ReadBytes(2, o)

        if (o[1] and o[2]) then
            fileType = o[1] .. o[2]
        end

        file:close()
    end

    if (fileType and fileType == "8075") then
        return true
    else
        return false
    end
end

function LocalService:MoveZipToFolder(foldername, zipPath)
    if not ParaAsset.OpenArchive(zipPath, true) then
        return false
    end

    local parentDir = zipPath:gsub("[^/\\]+$", "")

    local fileList = {}
    -- ":.", any regular expression after : is supported. `.` match to all strings.
    commonlib.Files.Find(fileList, "", 0, 10000, ":.", zipPath)

    local worldpath = format("%s/%s", Mod.WorldShare.Utils.GetWorldFolderFullPath(), CommonlibEncoding.Utf8ToDefault(foldername))

    for _, item in ipairs(fileList) do
        if item.filesize > 0 then
            local file = ParaIO.open(format("%s%s", parentDir, item.filename), "r")

            if file:IsValid() then
                local folderArray = {}
                local content = file:GetText(0, -1)
                local filename = item.filename

                -- tricky: we do not know which encoding the filename in the zip archive is,
				-- so we will assume it is utf8, we will convert it to default and then back to utf8.
				-- if the file does not change, it might be utf8. 
				local trueFilename = ''
                local defaultEncodingFilename = CommonlibEncoding.Utf8ToDefault(filename)

				if defaultEncodingFilename == filename then
					trueFilename = filename
				else
					if CommonlibEncoding.DefaultToUtf8(defaultEncodingFilename) == filename then
						trueFilename = defaultEncodingFilename
					else
						trueFilename = filename
					end
                end

                if trueFilename == "revision.xml" then
                    Mod.WorldShare.Store:Set('remoteRevision', content)
                end

                for segmentation in string.gmatch(trueFilename, "[^/]+") do
                    folderArray[#folderArray + 1] = segmentation
                end

                -- remove file path
                folderArray[#folderArray] = nil

                if #folderArray >= 1 then
                    -- create folder
                    for _, folderItem in pairs(folderArray) do
                        ParaIO.CreateDirectory(format('%s/%s/', worldpath, folderItem))
                    end
                end

                -- create file
                local writeFile = ParaIO.open(format("%s/%s", worldpath, trueFilename), "w")

                if writeFile:IsValid() then
                    writeFile:write(content, #content)
                    writeFile:close()
                else
                    LOG.std(nil, "info", "LocalService", "failed to write to %s", format("%s/%s", worldpath, trueFilename));
                end

                file:close()
            end
        end
    end

    ParaAsset.CloseArchive(zipPath)
end

-- get all world total files size
function LocalService:GetWorldSize(worldDir)
    local files =
        commonlib.Files.Find(
        {},
        worldDir,
        5,
        5000,
        function(item)
            return true
        end
    )

    local filesTotal = 0
    for key, value in ipairs(files) do
        filesTotal = filesTotal + tonumber(value.filesize)
    end

    return filesTotal
end

function LocalService:GetZipWorldSize(zipWorldDir)
    return ParaIO.GetFileSize(zipWorldDir)
end

function LocalService:GetZipRevision(zipWorldDir)
    local zipParentDir = zipWorldDir:gsub("[^/\\]+$", "")

    ParaAsset.OpenArchive(zipWorldDir, true)

    local revision = 0
    local output = {}

    Files.Find(output, "", 0, 500, ":revision.xml", zipWorldDir)

    if #output ~= 0 then
        local file = ParaIO.open(zipParentDir .. output[1].filename, "r")

        if file:IsValid() then
            revision = file:GetText(0, -1)
            file:close()
        end
    end

    ParaAsset.CloseArchive(zipWorldDir)

    return revision
end

function LocalService:SetTag(worldDir, newTag)
    if (type(worldDir) == "string" and type(newTag) == "table") then
        local tagTable = {
            {
                attr = newTag,
                name = "pe:world"
            },
            name = "pe:mcml"
        }

        local xmlString = commonlib.Lua2XmlString(tagTable, true, true)

        local filePath = worldDir .. "/tag.xml"

        local file = ParaIO.open(filePath, "w")

        file:write(xmlString, #xmlString)
        file:close()
    end
end

function LocalService:GetTag(worldDir)
    if (not worldDir) then
        return {}
    end

    local filePath = format("%s/tag.xml", worldDir)
    local tag = ParaXML.LuaXML_ParseFile(filePath)

    if (type(tag) == "table" and type(tag[1]) == "table" and type(tag[1][1]) == "table") then
        return tag[1][1]["attr"]
    else
        return {}
    end
end

function LocalService:SaveWorldInfo(ctx, node)
    if (type(ctx) ~= 'table' or
        type(node) ~= 'table' or
        type(node.attr) ~= 'table') then
        return false
    end

    node.attr.clientversion = self:GetClientVersion() or ctx.clientversion

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    node.attr.kpProjectId = currentWorld and currentWorld.kpProjectId or ctx.kpProjectId
end

function LocalService:LoadWorldInfo(ctx, node)
    if (type(ctx) ~= 'table' or
        type(node) ~= 'table' or
        type(node.attr) ~= 'table') then
        return false
    end

    ctx.clientversion = node.attr.clientversion
    ctx.kpProjectId = node.attr.kpProjectId
end

function LocalService:GetClientVersion(node)
    return System and System.options and System.options.ClientVersion and System.options.ClientVersion
end

function LocalService:ClearUserWorlds()
    local userworldsPath = format("%s/%s", LocalLoadWorld.GetWorldFolderFullPath(), "userworlds")

    local fileLists = Files.Find(nil, userworldsPath, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)

    for key, item in ipairs(fileLists) do
        if item.fileattr and item.fileattr == 16 then
            if (GameLogic.RemoveWorldFileWatcher) then
                GameLogic.RemoveWorldFileWatcher()
            end

            Files.DeleteFolder(format("%s/%s", userworldsPath, item.filename))
        end

        if item.fileattr and item.fileattr == 0 then
            ParaIO.DeleteFile(format("%s/%s", userworldsPath, item.filename))
        end
    end
end