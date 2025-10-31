--[[
@name: parser.lua
@desc: Takes in an array of tokens from 'tokenizer.lua', and
processes them into an Abstract Syntax Tree.
]]--

local cursor_mt = {
	__add = function(a, b)
		if type(a) == "table" and type(b) == "number" then
			local nextId = a.id + b
			if nextId <= #a.source then a.id = nextId end
		end
		return a
	end,
	
	__eq = function(a, b)
		if type(a) == "table" and type(b) == "number" then
			return a.id == b
		end
		
		return false
	end,
	
	__sub = function(a, b)
		if type(a) == "table" and type(b) == "number" then
			local prevId = a.id - b
			if prevId <= #a.source then a.id = prevId end
		end
		return a
	end
}

local Cursor = {
	new = function(source)
		local newCursor = {
			id = 1,
			source = source,
			
			progressCursor = function(self)
				local nextId = self.id + 1
				if nextId <= #self.source then self.id = nextId return true end
				return false
			end,
			
			regressCursor = function(self)
				local prevId = self.id - 1
				if prevId <= #self.source then self.id = prevId return true end
				return false
			end,
			
			read = function(self, line)
				if not line then line = self.id end
				if line <= #self.source then self:progressCursor() return self.source[line] end
				return nil
			end,
			
			testToken = function(self, value)
				local token = self:read()
				if token == nil then return false end
				if type(token) ~= "table" then return false end
				if token["contents"] == nil then return false end
				if token["type"] == nil then return false end
				return token.contents == value
			end,

			expectUntilComma = function(self, value)
				local tokens = {}
				local token = self:read()

				while token.contents ~= "," and token.contents ~= ";" do
					table.insert(tokens, token)
					token = self:read()
				end

				return tokens, self.id
			end
			
			liquidate = function(self)
				self.source = nil
				self.id = nil
				setmetatable(self, nil)
				for k in pairs(self) do
					self[k] = nil
				end
			end
		}
		
		setmetatable(newCursor, cursor_mt)
		return newCursor
	end
}

function tableFind(t, v)
	for _, tV in ipairs(t) do
		if v == tV then
			return true
		end
	end
	
	return false
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

function Node(_class, ...)
	local class = _class or "Root"
	local args = table.pack(...) or {}
	
	local mt = {
		__tostring = function(v)
			return tableToString(v)
		end
	}
	local node = {
		class = class,
		children = args,
		pop = function(self, child)
			table.insert(self.children, child)
		end,
	}
	
	setmetatable(node, mt)
	return node
end

function IReader(t)
	local i = 0
	local n = #t
	return function()
		i = i + 1
		if i <= n then
			return i, t[i], function(o)
				local j = o + i
				if j <= n then return t[j], j end
			end
		end
	end
end

function Is(object, value)
	return object.contents == value
end

function ParseLogic(tokens)
	local outputStack = {}
	local operatorStack = {}
	
	local precedence = {
		["^"] = 4,
		["*"] = 3,
		["/"] = 3,
		["+"] = 2,
		["-"] = 2,
	}
	
	local rightHanded = {
		["^"] = true
	}
	
	for index, token, lookAhead in IReader(tokens) do
		local contents = token.contents
		if tonumber(contents) ~= nil then
			table.insert(outputStack, tonumber(contents))
		elseif lookAhead(1) and lookAhead(1).contents == "(" then
			table.insert(operatorStack, contents)
		elseif token.type == 2 then
			local o2 = operatorStack[#operatorStack]
			while o2 and o2 ~= "(" and (precedence[o2] > precedence[contents] or (precedence[o2] == precedence[contents] and not rightHanded[contents])) do
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
				o2 = operatorStack[#operatorStack]
			end
			table.insert(operatorStack, contents)
		elseif contents == ',' then
			local o2 = operatorStack[#operatorStack]
			while (o2 ~= "(") do
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
				o2 = operatorStack[#operatorStack]
			end
		elseif contents == '(' then
			table.insert(operatorStack, contents)
		elseif contents == ')' then
			local o2 = operatorStack[#operatorStack]
			while (o2 ~= "(") do
				assert(#operatorStack ~= 0)
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
				o2 = operatorStack[#operatorStack]
			end
			assert(o2 == '(')
			table.remove(operatorStack, #operatorStack)
			o2 = operatorStack[#operatorStack]
			if (o2 ~= '(' and o2 ~= ')' and precedence[o2] == nil) then
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
			end
		elseif token.type == 1 then
			table.insert(outputStack, contents)
		end 
		::continue::
	end
	
	while #operatorStack > 0 do
		local operator = operatorStack[#operatorStack]
		assert(operator ~= "(")
		table.remove(operatorStack, #operatorStack)
		table.insert(outputStack, operator)
	end
	
	return outputStack
end

function ParseNumber(cursor)

end

function ParseAssignmentRHS(cursor)
	local token = cursor:read()
	if token.type == 1 then -- Identifier
		return Node("Identifier", token)
	end
	if token.type == 3 then -- String
		return Node("String", token)
	end
	if token.type == 4 then -- Number/Logic
		return Node("Number", token)
	end
	if token.type == 5 then -- Not all seperators are good!
		if token.contents == '(' then -- Logic
			return ParseNumber(cursor)
		end
		if token.contents == '{' then -- Table
			return Node("Table", token)
		end
	end
	return false
end

function ParseAssignment(tokenList)
	local cursor = Cursor.new(tokenList)
	local lhs = cursor:read()
	if lhs.type ~= 1 then
		return false
	end
	if not cursor:testToken("=") then
		return false
	end
	local rhs_node = ParseAssignmentRHS(cursor)
	if not rhs_node then
		return false
	end
	if not cursor:testToken(";") then
		return false
	end
	local lhs_node = Node("Identifier", lhs)
	return Node("Assign", lhs_node, rhs_node)
end

function ParseTokens(tokenList)
	local motherStack = {}
	local stack = {}
	
	for i, token, lookAhead in IReader(tokenList) do
		if token.type ~= 7 and token.type ~= 6 then
			table.insert(stack, token)
			if Is(token, ";") then
				table.insert(motherStack, stack)
				stack = {}
			end
		end
	end
	
	for i, line in ipairs(motherStack) do
		local assignmentNode = ParseAssignment(line)
		if (assignmentNode) then
			motherStack[i] = assignmentNode
		end
	end
	
	print(tableToString(motherStack))
end


ParseTokens({
  [1] =     {
      contents = "myVariable",
      type = 1,
    },
  [2] =     {
      contents = "=",
      type = 2,
    },
  [3] =     {
      contents = "\"Hello, World!\"",
      type = 3,
    },
  [4] =     {
      contents = ";",
      type = 5,
    },
  [5] =     {
      contents = "$ Hello, this is a comment!",
      type = 6,
    },
  [6] =     {
      contents = "",
      type = 7,
    },
  [7] =     {
      contents = "$ this is a line comment",
      type = 6,
    },
  [8] =     {
      contents = "",
      type = 7,
    },
  [9] =     {
      contents = "a",
      type = 1,
    },
  [10] =     {
      contents = "=",
      type = 2,
    },
  [11] =     {
      contents = "10",
      type = 4,
    },
  [12] =     {
      contents = ";",
      type = 5,
    },
  [13] =     {
      contents = "$ still a comment!!",
      type = 6,
    },
  [14] =     {
      contents = "",
      type = 7,
    },
})