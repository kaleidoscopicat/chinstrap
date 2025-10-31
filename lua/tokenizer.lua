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
    '+', '-', '/', '*', '^', '%', '=', '!', '>', '<'
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

    local inString = false
    local currentQuote = nil

    for lineNum, line in ipairs(lines) do
        local currentToken = newToken()

        for i = 1, #line do
            local char = line:sub(i, i)
            local isWhitespace = char:match("%s")

            if inString then
                -- We're inside a string literal, so include all characters (including spaces)
                currentToken.contents = currentToken.contents .. char
                if char == currentQuote then
                    -- End of string literal, finalize it
                    finalizeToken(currentToken)
                    currentToken = newToken()
                    inString = false
                    currentQuote = nil
                end

            else
                -- Not inside a string
                if char == '"' or char == "'" then
                    -- Beginning of a string literal
                    finalizeToken(currentToken)
                    currentToken = newToken(char, enum_TokenTypes.Enum("LiteralString"))
                    inString = true
                    currentQuote = char
                elseif isWhitespace then
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
                        finalizeToken(currentToken)
                        currentToken = newToken()
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
                        finalizeToken(currentToken)
                        currentToken = newToken()
                    elseif tonumber(char) ~= nil then 
                        -- Build a number literal token.
                        currentToken.type = enum_TokenTypes.Enum("LiteralNumber")
                        currentToken.contents = currentToken.contents .. char
                    elseif char == '$' then
                        -- Start of a comment. Pop current token.
                        finalizeToken(currentToken)

                        -- Capture everything until end of line as comment contents
                        local commentText = line:sub(i)
                        currentToken = newToken(commentText, enum_TokenTypes.Enum("Comment"))
                        finalizeToken(currentToken)

                        -- Move to end of line
                        currentToken = newToken()
                        break
                    else
                        -- Assume it's an identifier.
                        if currentToken.type ~= enum_TokenTypes.Enum("Identifier")
                            and currentToken.type ~= enum_TokenTypes.Enum("Keyword") then
                            currentToken.type = enum_TokenTypes.Enum("Identifier")
                        end

                        currentToken.contents = currentToken.contents .. char
                    end
                end
            end
        end

        finalizeToken(currentToken)
        currentToken = newToken("\n", enum_TokenTypes.Enum("Whitespace"))
        nowInComment = false
        finalizeToken(currentToken)
    end

    local shouldBindString = false
    local currentBind = ""
    local startIndex = nil
    local i = 1

    while i <= #tokenList do
        local token = tokenList[i]

        if token.contents == '"' then
            shouldBindString = not shouldBindString
            if shouldBindString then
                startIndex = i
                currentBind = '"'
            else
                currentBind = currentBind .. '"'
                tokenList[startIndex] = {
                    contents = currentBind,
                    type = enum_TokenTypes.Enum("LiteralString")
                }

                for j = i, startIndex + 1, -1 do
                    table.remove(tokenList, j)
                end

                i = startIndex
                shouldBindString = false
                startIndex = nil
                currentBind = ""
            end

        elseif shouldBindString then
            currentBind = currentBind .. token.contents
        end

        i = i + 1
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

--> The 'debug' callout
print(tableToString(RetrieveTokens({
    'myVariable = "Hello, World!"; $ Hello, this is a comment!',
    '$ this is a line comment',
    'a = 10; $ still a comment!!'
})))