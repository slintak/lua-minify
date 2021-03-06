# Makefile
LUA ?= lua

tests: luacheck selftest unittests

luacheck:
	luacheck minify.lua tests.lua

selftest:
	# Run various transformations on the program itself.
	# They should all represent the same AST, and thus end up
	# as identical output. We also execute some of the transformed
	# programs, to make sure their functionality remained intact.

	@echo
	@echo Running self test:

	$(LUA) minify.lua minify minify.lua > minify1.out
	$(LUA) minify.lua minify minify1.out > minify2.out
	diff -u minify1.out minify2.out

	$(LUA) minify1.out minify minify.lua > minify3.out
	diff -u minify1.out minify3.out

	$(LUA) minify.lua unminify minify.lua > unminify1.out
	$(LUA) minify.lua unminify minify1.out > unminify2.out

	$(LUA) unminify1.out minify minify.lua > minify4.out
	diff -u minify1.out minify4.out
	$(LUA) unminify2.out unminify minify.lua > unminify3.out
	$(LUA) unminify2.out unminify minify1.out > unminify4.out
	diff -u unminify1.out unminify3.out
	diff -u unminify2.out unminify4.out

	$(LUA) minify.lua minify unminify1.out > minify5.out
	$(LUA) minify.lua minify unminify2.out > minify6.out
	diff -u minify1.out minify5.out
	diff -u minify1.out minify6.out

	rm minify*.out unminify*.out

unittests: luaunit.lua
	@echo
	@echo Running unit tests:
	$(LUA) -lluacov tests.lua -v
	# now repeat the tests a second time, with a minified version of luaunit!
	mv luaunit.lua luaunit.lua.orig
	$(LUA) ./minify.lua minify luaunit.lua.orig > luaunit.lua
	$(LUA) tests.lua -v
	mv -f luaunit.lua.orig luaunit.lua

luaunit.lua:
	# retrieve tagged release of luaunit.lua from github
	curl -LsS --retry 5 https://github.com/bluebird75/luaunit/raw/LUAUNIT_V3_3/$@ -o $@

coverage:
	# usage help (invocation with no arguments)
	$(LUA) -lluacov ./minify.lua > /dev/null 2>&1 || true
	# input file error
	$(LUA) -lluacov ./minify.lua minify non.existent > /dev/null 2>&1 || true
	# invalid command
	$(LUA) -lluacov ./minify.lua foobar minify.lua > /dev/null 2>&1 || true
	# normal operation
	$(LUA) -lluacov ./minify.lua minify minify.lua > /dev/null
	$(LUA) -lluacov ./minify.lua unminify minify.lua > /dev/null
	$(LUA) -lluacov ./minify.lua minify luaunit.lua > /dev/null
	$(LUA) -lluacov ./minify.lua unminify luaunit.lua > /dev/null
