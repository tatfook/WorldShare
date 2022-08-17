--[[
Title: MdParser
Author(s): big
CreateDate: 2018.09.14
ModifyDate: 2022.06.15
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

local HASHTAG = 'HASHTAG'
local DASH = 'DASH'
local CONTENT = 'CONTENT'
local CODE = 'CODE'
local BOLD = 'BOLD'

MdParser.hashTag = {} 

function MdParser:MdToHtml(data, toString)
    if not data or type(data) ~= 'string' then
        return
    end

    local dataList = commonlib.split(data, '\r\n')
    local htmlDataList = {}
    local htmlStr = ''

    if not dataList or type(dataList) ~= 'table' then
        return
    end

    for key, line in ipairs(dataList) do
        if self:GetLineType(line) == HASHTAG then
            local hashTagNum = self:GetHashTagNum(line)
            local handleLine = self:GetHashTagVal(hashTagNum, line)
            local isBold = false

            if string.find(handleLine, '^**') then
                isBold = true
                handleLine = handleLine:gsub('**', '')
            end

            local fontSize = 24 - hashTagNum * 2
            local lineFormat

            if isBold then
                lineFormat =
                    format(
                        '<div style="font-weight: bold;font-size: %dpx;base-font-size: %dpx;margin-top: 2px;margin-bottom: 3px;">%s</div>',
                        fontSize,
                        fontSize,
                        handleLine
                    )
            else
                lineFormat =
                    format(
                        '<div style="font-size: %dpx;base-font-size: %dpx;margin-top: 2px;margin-bottom: 3px;">%s</div>',
                        fontSize,
                        fontSize,
                        handleLine
                    )
            end

            htmlDataList[#htmlDataList + 1] = lineFormat

            if toString then
                htmlStr = htmlStr .. lineFormat .. '\r\n'
            end
        elseif self:GetLineType(line) == DASH then
            line = line:gsub('^- ', '')

            local text, link = string.match(line, '%[(.+)%]%((.+)%)')
            local lineFormat

            if text then
                lineFormat = format('<div><a href="%s" style="color: #E4CC04;">%s</a></div>', link, text) 
            else
                lineFormat = format('<div>%s</div>', line) 
            end

            htmlDataList[#htmlDataList + 1] = lineFormat

            if toString then
                htmlStr = htmlStr .. lineFormat .. '\r\n'
            end
        elseif self:GetLineType(line) == BOLD then
            local lineFormat = line

            lineFormat = lineFormat:gsub('^***', '<b style="font-size: 15px;base-font-size: 15px;">')
            lineFormat = lineFormat:gsub('***$', '</b>')

            if toString then
                htmlStr = htmlStr .. lineFormat .. '\r\n'
            end
        elseif self:GetLineType(line) == CONTENT then
            local lineFormat = format('<p>%s</p>', line) 
            htmlDataList[#htmlDataList + 1] = lineFormat

            if toString then
                htmlStr = htmlStr .. lineFormat .. '\r\n'
            end
        end
    end

    if toString then
        return htmlStr
    else
        return htmlDataList
    end
end

function MdParser:GetLineType(line)
    if line and
       type(line) == 'string' then
        if string.find(line, '^#') then
            return HASHTAG
        elseif string.find(line, '^-') then
            return DASH
        elseif string.find(line, '^```') then
            return CODE
        elseif string.find(line, '^***') then
            return BOLD
        else
            return CONTENT
        end
    end
end

function MdParser:MdToTable(data)
    self.tree = {}
    self.items = {}

    if not data or type(data) ~= 'string' then
        return
    end

    local dataList = commonlib.split(data, '\r\n')

    if not dataList or type(dataList) ~= 'table' then
        return
    end

    local currentType
    local curBlockStrList = {}

    local function HandleBlockType(blockType, line, isEnd)
        if blockType and isEnd then
            self:GetBlockStringList(curBlockStrList, line)
        end

        if blockType == TREE or
           blockType == ITEMS or
           isEnd then
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
    if line and
       type(line) == 'string' then
        if string.find(line, '^#') then
            local num = self:GetHashTagNum(line)

            if num == 2 then
                return TREE
            end

            if num == 3 then
                return ITEMS
            end
        end

        if string.find(line, '^- ') then
            return KEY
        end

        return
    end
end

function MdParser:GetHashTagNum(sinput)
    local count = 0

    local function CountHashTag(s)
        local exist = string.find(s, '^#')

        if exist then
            count = count + 1
            CountHashTag(string.sub(s, 2, #s))
        else
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
        return
    end

    curBlockStrList[#curBlockStrList + 1] = line

    return curBlockStrList
end

function MdParser:GetBlockTree(strBlockList)
    local items = {}
    local name

    for key, item in ipairs(strBlockList) do
        if key == 1 then
            items['displayName'] = self:GetHashTagVal(2, item)
            name = items['displayName']
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
            items['displayName'] = self:GetHashTagVal(3, item)
        else
            local keyName, keyVal = self:GetKeyVal(item)
            items[keyName] = keyVal
        end
    end

    return items
end

function MdParser:GetHashTagVal(hashTagNum, str)
    if not hashTagNum or
       type(hashTagNum) ~= 'number' or
       not str or
       type(str) ~= 'string' then
        return
    end

    if not self.hashTag[hashTagNum] then
        local reStr = '^'
    
        for i = 1, hashTagNum do
            reStr = reStr .. '#'
        end
    
        reStr = reStr .. ' '

        self.hashTag[hashTagNum] = reStr
    end

    local startIndex, endIndex = string.find(str, self.hashTag[hashTagNum])

    return string.sub(str, endIndex + 1, #str)
end

function MdParser:GetKeyVal(str)
    if not str or type(str) ~= 'string' then
        return
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
