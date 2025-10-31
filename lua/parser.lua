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

			expectUntilComma = function(self)
				local tokens = {}
				local token = self:read()

				while token.contents ~= "," and token.contents ~= ";" do
					table.insert(tokens, token)
					token = self:read()
				end

				return tokens, self.id
			end,

			expectUntil = function(self, char)
				local tokens = {}
				local token = self:read()

				while token.contents ~= char and token.contents ~= ";" do
					table.insert(tokens, token)
					token = self:read()
				end

				return tokens, self.id
			end,
			
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

local quickMaths = { "sin", "max", "sample", "pi", "cos", "tan", "sinh", "cosh", "tanh", "dot" }

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

function Node(class, ...)
	local node = {
		class = class or "Root",
		children = { ... },

		push = function(self, child)
			table.insert(self.children, child)
		end,
	}
	
	setmetatable(node, {
		__tostring = function(v)
			return tableToString(v)
		end
	})

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

function RPNtoAST(tokens)
	--print("RPN:", tableToString(tokens))
	local stack = {}

	for _, token in ipairs(tokens) do
		local t = token.contents or token

		if tonumber(t) then
			table.insert(stack, Node("Number", token))
		elseif t:match("^[%a_]+$") then -- RegEx sucks man
			table.insert(stack, Node("Variable", token))
		elseif t == "+" or t == "-" or t == "*" or t == "/" or t == "^" then
			local right = table.remove(stack)
			local left = table.remove(stack)
			table.insert(stack, Node("Operator", token, left, right))
		else
			error("Error code 1: Unknown token [" .. tostring(t).. "]")
		end
	end

	if #stack ~= 1 then
		print("BAD RPN:", tableToString(tokens))
		print("STACK:", tableToString(stack))
	end
	assert(#stack == 1, "Error code 2: Malformed RPN Expression")
	return stack[1]
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
			table.insert(outputStack, token)
		elseif lookAhead(1) and lookAhead(1).contents == "(" then
			table.insert(operatorStack, token)
		elseif token.type == 2 then
			local o2 = operatorStack[#operatorStack]
			while o2 and o2.contents ~= "(" and (precedence[o2.contents] > precedence[contents] or (precedence[o2.contents] == precedence[contents] and not rightHanded[contents])) do
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
				o2 = operatorStack[#operatorStack]
			end
			table.insert(operatorStack, token)
		elseif contents == ',' then
			local o2 = operatorStack[#operatorStack]
			while (o2 and o2.contents ~= "(") do
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
				o2 = operatorStack[#operatorStack]
			end
		elseif contents == '(' then
			table.insert(operatorStack, token)
		elseif contents == ')' then
			local o2 = operatorStack[#operatorStack]
			while (o2 and o2.contents ~= "(") do
				assert(#operatorStack ~= 0)
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
				o2 = operatorStack[#operatorStack]
			end
			assert(o2.contents == '(')
			table.remove(operatorStack, #operatorStack)
			o2 = operatorStack[#operatorStack]
			if (o2.contents ~= '(' and o2.contents ~= ')' and precedence[o2.contents] == nil) then
				table.remove(operatorStack, #operatorStack)
				table.insert(outputStack, o2)
			end
		elseif token.type == 1 then
			table.insert(outputStack, token)
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
	cursor:regressCursor()

	local startingId = cursor.id
	local tokens, id = cursor:expectUntilComma()

	local rpnStack = ParseLogic(tokens)
	local ASTNode = RPNtoAST(rpnStack)

	return ASTNode
end

function ParseIdentifier(cursor)
	cursor:regressCursor()
	local token = cursor:read()

	if tableFind(quickMaths, token.contents) then
		return ParseNumber(cursor)
	elseif cursor:read() == "(" then
		-- It's a function!
		return Node("FunctionCall", token, table.unpack(cursor:expectUntil(')')))
	else
		cursor:regressCursor()
		return Node("Identifier", token)
	end

	return false
end

function ParseVariableType(cursor)
	local token = cursor:read()
	if token.type == 1 then -- Identifier
		local parsed = ParseIdentifier(cursor)
		if not parsed then
			error("Error code 3: Identifier cannot be parsed!")
		end

		return parsed
	end
	if token.type == 3 then -- String
		return Node("String", token)
	end
	if token.type == 4 then -- Number/Logic
		return ParseNumber(cursor)
	end
	if token.type == 5 then -- Not all seperators are good!
		if token.contents == '(' then -- Number/Logic
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
	local rhs_node = ParseVariableType(cursor)
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

	return motherStack
	
	--print(tableToString(motherStack))
end