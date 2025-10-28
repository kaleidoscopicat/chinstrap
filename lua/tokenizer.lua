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
    "Seperator",
    "Comment",
    "Whitespace",
    "Unknown",
}

local seperators = { ';',
                     '(',
                     ')',
                     '{',
                     '}',
                     ',', -- SPECIAL USECASE
                     '"', -- SPECIAL USECASE
                     ":", -- SPECIAL USECASE
                    }
local operators = {
    '+', '-', '/', '*', '^', '%', '='
}
local keywords = {
    "if", "while", "return", "continue", "else", "elseif", "fn", "@property", "@uniform"
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

function tableFind(t, v)
    for _, tV in ipairs(t) do
        if v == tV then
            return true
        end
    end

    return false
end

function RetrieveTokens(lines)
    local tokenList = {}

    local function finalizeToken(token)
        if token.contents ~= "" then
            -- Match for keywords...
            if token.type == enum_TokenTypes.Enum("Identifier") and tableFind(keywords, token.contents) then
                token.type = enum_TokenTypes.Enum("Keyword")
            end
            table.insert(tokenList, token)
        end
    end

    local function newToken(contents, tokenType)
        return { contents = contents or "", type = tokenType or enum_TokenTypes.Enum("Unknown") }
    end

    for lineNum, line in ipairs(lines) do
        local currentToken = newToken()
        for i = 1, #line do
            local char = line:sub(i, i)
            local isWhitespace = char:match("%s")

            if isWhitespace then
                -- It's just whitespace, pop the token currently being written.
                finalizeToken(currentToken)
                currentToken = newToken()
            else
                -- Check for seperators...
                if tableFind(seperators, char) then
                    -- Pop the token currently being written.
                    
                    finalizeToken(currentToken)
                    currentToken = newToken()

                    -- We've reached a seperator, write this as a new token!
                    -- Parser should then process all from the previous seperator...
                    currentToken = {
                        contents = char,
                        type = enum_TokenTypes.Enum("Seperator")
                    }

                    -- Pop the seperator token.
                    table.insert(tokenList, currentToken)
                elseif tableFind(operators, char) then
                    -- Check for operators...

                    finalizeToken(currentToken)
                    currentToken = newToken()
                    -- Pop the token currently being written
                    
                    currentToken = {
                        contents = char,
                        type = enum_TokenTypes.Enum("Operator")
                    }

                    -- Pop the operator token.
                    table.insert(tokenList, currentToken)
                elseif tonumber(char) ~= nil then 
                    currentToken.type = enum_TokenTypes.Enum("LiteralNumber")
                    currentToken.contents = currentToken.contents.. char
                else
                    -- Assume it's an identifier.
                    if currentToken.type ~= enum_TokenTypes.Enum("Identifier") and currentToken.type ~= enum_TokenTypes.Enum("Keyword") then
                        currentToken.type = enum_TokenTypes.Enum("Identifier")
                    end

                    currentToken.contents = currentToken.contents.. char
                end
            end
        end

        finalizeToken(currentToken)
    end

    return tokenList
end

function tableToString(tbl, indent)
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if type(k) == "number" then
            toprint = toprint .. "[" .. k .. "] = "
        elseif type(k) == "string" then
            toprint = toprint .. k .. " = "
        end
        if type(v) == "table" then
            toprint = toprint .. tableToString(v, indent + 2) .. ",\n"
        elseif type(v) == "string" then
            toprint = toprint .. '"' .. v .. '",\n'
        else
            toprint = toprint .. tostring(v) .. ",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end