--[[
Title: MdParser
Author(s): big
CreateDate: 2018.09.14
ModifyDate: 2021.11.08
Place: Foshan
Desc: parse markdown document
-------------------------------------------------------
local MdParser = NPL.load('(gl)Mod/WorldShare/parser/MdParser.lua')
-------------------------------------------------------
]]
local MdParser = NPL.export()

local TREE = 'TREE'
local ITEMS = 'ITEMS'
local KEY = 'KEY'

function MdParser:MdToTable(data)
    self.tree = {}
    self.items = {}

    if (not data or type(data) ~= 'string') then
        return false
    end

    local dataList = commonlib.split(data, '\r\n')

    if (not dataList or type(dataList) ~= 'table') then
        return false
    end

    local currentType
    local curBlockStrList = {}

    local function HandleBlockType(blockType, line, isEnd)
        if blockType and isEnd then
            self:GetBlockStringList(curBlockStrList, line)
        end

        if (blockType == TREE or blockType == ITEMS or isEnd) then
            if currentType == TREE then
                local items, name = self:GetBlockTree(curBlockStrList)

                if name then
                    self.tree[name] = items
                end
            end
    
            if currentType == ITEMS then
                local items = self:GetBlockItems(curBlockStrList)

                self.items[#self.items + 1] = items
            end

            if isEnd then
                currentType = nil
                curBlockStrList = {}

                return true
            else
                currentType = blockType
                curBlockStrList = {}
            end
        end

        self:GetBlockStringList(curBlockStrList, line)
    end

    for key, line in ipairs(dataList) do
        local blockType = self:GetType(line)

        -- end point
        if key == #dataList then
            HandleBlockType(blockType, line, true)
        else
            if blockType then
                HandleBlockType(blockType, line)
            end
        end
    end

    return self.tree or {}, self.items or {}
end

function MdParser:GetType(line)
    if string.find(line, '^#') then
        local num = self:GetHashTagNum(line)

        if (num == 2) then
            return TREE
        end

        if (num == 3) then
            return ITEMS
        end
    end

    if string.find(line, '^- ') then
        return KEY
    end

    return false
end

function MdParser:GetHashTagNum(sinput)
    local count = 0

    local function CountHashTag(s)
        local exist = string.find(s, '^#')
        
        if (exist) then
            count = count + 1
            CountHashTag(string.sub(s, 2, #s))
            return
        end

        if (not exist) then
            if string.sub(s, 1, 1) ~= ' ' then
                count = 0
            end
        end
    end

    CountHashTag(sinput)

    return count
end

function MdParser:GetBlockStringList(curBlockStrList, line)
    if not curBlockStrList or type(curBlockStrList) ~= 'table' then
        return false
    end

    curBlockStrList[#curBlockStrList + 1] = line

    return curBlockStrList
end

function MdParser:GetBlockTree(strBlockList)
    local items = {}
    local name

    for key, item in ipairs(strBlockList) do
        if key == 1 then
            items['displayName'] = self:GetTreeVal(item)
        else
            local keyName, keyVal = self:GetKeyVal(item)
            items[keyName] = keyVal

            if keyName == 'name' then
                name = keyVal
            end
        end
    end

    return items, name
end

function MdParser:GetBlockItems(strBlockList)
    local items = {}

    for key, item in ipairs(strBlockList) do
        if key == 1 then
            items['displayName'] = self:GetItemsVal(item)
        else
            local keyName, keyVal = self:GetKeyVal(item)
            items[keyName] = keyVal
        end
    end

    return items
end

function MdParser:GetTreeVal(str)
    if not str or type(str) ~= 'string' then
        return false
    end

    local startIndex, endIndex = string.find(str, '^## ')

    return string.sub(str, endIndex + 1, #str)
end

function MdParser:GetItemsVal(str)
    if not str or type(str) ~= 'string' then
        return false
    end

    local startIndex, endIndex = string.find(str, '^### ')

    return string.sub(str, endIndex + 1, #str)
end

function MdParser:GetKeyVal(str)
    if not str or type(str) ~= 'string' then
        return false
    end

    local startIndex, endIndex = string.find(str, '^- ')

    local keyStr = string.sub(str, endIndex + 1, #str)

    if not keyStr then
        return '', ''
    end

    keyStr = string.gsub(keyStr, ' ', '')

    local keyArray = commonlib.split(keyStr, ':')

    return keyArray[1] or '', keyArray[2] or '' 
end
