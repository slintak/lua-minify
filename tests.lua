local lu, LuaMinify = require("luaunit"), require("minify")

-- mimick the minify() function, but without printing out the AST
local function minify(ast, global_scope, root_scope)
	LuaMinify.MinifyVariables(global_scope, root_scope)
	LuaMinify.StripAst(ast)
end

-- mimick the beautify() function, but without printing out the AST
local function unminify(ast, global_scope, root_scope)
	LuaMinify.BeautifyVariables(global_scope, root_scope)
	LuaMinify.FormatAst(ast)
end

-- wrappers that work with only the AST (at the cost of reparsing the var info)
local function _minify(ast)
	minify(ast, LuaMinify.AddVariableInfo(ast))
end
local function _unminify(ast)
	unminify(ast, LuaMinify.AddVariableInfo(ast))
end

-- Test basic functionality: parse Lua code snippet (into AST) and reformat it
function test_basics()
	-- two keywords
	local source = 'return true'
	local ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	-- function call (identifier and string literal)
	source = 'print("Hello world")'
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)

	-- a basic minify() example
	source = [[function foo(bar)
		return bar
	end]]
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	_minify(ast)
	lu.assertEquals(LuaMinify.AstToString(ast), "function a(b)return b end")

	-- now unminify() again
	_unminify(ast)
	lu.assertEquals(LuaMinify.AstToString(ast), [[

function G_1(L_1_arg1)
	return L_1_arg1
end]])
end

-- Test invalid syntax and some corner cases, mainly to improve code coverage
function test_errors()
	-- tokenizer
	lu.assertErrorMsgContains('Bad symbol `$` in source.',
		LuaMinify.CreateLuaTokenStream, '$')
	lu.assertErrorMsgContains('Unfinished long string.',
		LuaMinify.CreateLuaTokenStream, '\n[[')
	lu.assertErrorMsgContains('Invalid Escape Sequence `?`.',
		LuaMinify.CreateLuaTokenStream, '"\\?"')
	-- syntax parser
	lu.assertErrorMsgContains('1:1: Unexpected symbol',
		LuaMinify.CreateLuaParser, '/')
	lu.assertErrorMsgContains('1:8: `=` expected.',
		LuaMinify.CreateLuaParser, 'foobar 4')
	lu.assertErrorMsgContains('1:16: Ident expected.',
		LuaMinify.CreateLuaParser, 'local function 2')
end

-- Test if parser can handle vararg functions
function test_varargs()
	-- pure vararg function, anonymous
	local source = 'return function(...) end'
	local ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	_minify(ast)
	lu.assertEquals(LuaMinify.AstToString(ast), 'return function(...)end')
	-- vararg function that has additional arguments, anonymous
	source = 'return function(a, b, ...) end'
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	_minify(ast)
	lu.assertEquals(LuaMinify.AstToString(ast), 'return function(a,b,...)end')
	-- pure vararg function, named
	source = 'function foo(...) end'
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	_minify(ast)
	lu.assertEquals(LuaMinify.AstToString(ast), 'function a(...)end')
	-- vararg function that has additional arguments, named
	source = 'function bar(c, d, ...) end'
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	_minify(ast)
	lu.assertEquals(LuaMinify.AstToString(ast), 'function a(b,c,...)end')
end

lu.LuaUnit:run(...)
