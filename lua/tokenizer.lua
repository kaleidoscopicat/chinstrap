--[[
@name: tokenizer.lua
@desc: The actual logical... well, tokenizer, for the
       compiler.
]]--

print("tokenizer.lua -> Loaded!")
local enum_TokenTypes = {
    "Keyword",
    "Identifier",
    "Operator",
    "LiteralString",
    "LiteralNumber",
    "Symbol",
    "Comment",
    "Unknown",
}

enum_TokenTypes["Enum"] = function(name)
    for index, value in ipairs(enum_TokenTypes) do
        if index ~= "Enum" then
            if value == name then
                return index-1
            end
        end
    end

    return -1
end

local operators = { '+', '-', '*', '/', '^', '%', '=', '==', '!=', '<', '>', '<=', '>=' }
local symbols = { '(', ')', '{', '}', '[', ']', ',', ';' }
local keywords = { "if", "else", "while", "for", "return", "function", "break", "continue", "true", "false", "null" }

function table_find(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then return i end
    end
    return nil
end

function cleanup(weakTable)
    local strongTable = {}
    for _, v in ipairs(weakTable) do
        if v ~= "" then
            table.insert(strongTable, v)
        end
    end

    return strongTable
end

function quickCheckOperative(lineCache)
    local char = lineCache[1]
    if char == nil then return true end
    if #char ~= 1 then return true end

    if char == '\\' then
        return false
    else
        return true
    end
end

function splitTokens(line)
    local tokens = {}
    local token = ""
    local i = 1
    local insideString = false

    while i <= #line do
        local char = line:sub(i,i)

        if char == "\"" then
            if insideString then
                token = token .. char
                table.insert(tokens, token)
                token = ""
                insideString = false
            else
                if token ~= "" then table.insert(tokens, token) end
                token = char
                insideString = true
            end
        elseif insideString then
            token = token .. char
        elseif table_find(operators, char) or table_find(symbols, char) then
            if token ~= "" then table.insert(tokens, token) end
            table.insert(tokens, char)
            token = ""
        elseif char:match("%s") then
            if token ~= "" then table.insert(tokens, token) end
            token = ""
        else
            token = token .. char
        end
        i = i + 1
    end
    if token ~= "" then table.insert(tokens, token) end
    return tokens
end

function arithmetic(tokens)
    local numA, numB, currentOp = nil, nil, nil
    for i, token in ipairs(tokens) do
        if token.Type == enum_TokenTypes.Enum("LiteralNumber") then
            if not numA then
                numA = token.Result
            elseif currentOp and not numB then
                numB = token.Result
                local res = nil
                if currentOp == "+" then res = numA + numB
                elseif currentOp == "-" then res = numA - numB
                elseif currentOp == "*" then res = numA * numB
                elseif currentOp == "/" then res = numA / numB
                elseif currentOp == "^" then res = numA ^ numB
                elseif currentOp == "%" then res = numA % numB
                end
                token.Result = res
                numA, numB, currentOp = res, nil, nil
            end
        elseif token.Type == enum_TokenTypes.Enum("Operator") then
            currentOp = token.Contents
        end
    end
end

function comp(lines)
    local tokenTable = {}

    for _, line in ipairs(lines) do
        if line:sub(1,2) == "$$" then
            table.insert(tokenTable, {
                { Contents = line, Result = nil, Type = enum_TokenTypes.Enum("Comment") }
            })
        else
            local rawTokens = splitTokens(line)
            rawTokens = cleanup(rawTokens)
            local lineTokens = {}

            for _, tk in ipairs(rawTokens) do
                local t = {}
                -- Numbers
                local n = tonumber(tk)
                if n then
                    t.Contents = tk
                    t.Result = n
                    t.Type = enum_TokenTypes.Enum("LiteralNumber")
                -- Strings
                elseif tk:sub(1,1) == "\"" and tk:sub(-1,-1) == "\"" then
                    t.Contents = tk
                    t.Result = tk:sub(2,-2)
                    t.Type = enum_TokenTypes.Enum("LiteralString")
                -- Keywords
                elseif table_find(keywords, tk) then
                    t.Contents = tk
                    t.Result = nil
                    t.Type = enum_TokenTypes.Enum("Keyword")
                -- Operators
                elseif table_find(operators, tk) then
                    t.Contents = tk
                    t.Result = nil
                    t.Type = enum_TokenTypes.Enum("Operator")
                -- Symbols
                elseif table_find(symbols, tk) then
                    t.Contents = tk
                    t.Result = nil
                    t.Type = enum_TokenTypes.Enum("Symbol")
                else
                    t.Contents = tk
                    t.Result = nil
                    t.Type = enum_TokenTypes.Enum("Identifier")
                end
                table.insert(lineTokens, t)
            end

            arithmetic(lineTokens)
            table.insert(tokenTable, lineTokens)
        end
    end

    return tokenTable
end

function hasResult(compTokens)
    return compTokens["Result"] ~= nil
end