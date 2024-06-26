.PHONY: init
init:
	bash ./scripts/init

.PHONY: test
test:
	bash ./scripts/test $(test)

.PHONY: lint
lint:
	luacheck lua/recode

.PHONY: stylua
stylua:
	stylua --color always --check lua

.PHONY: stylua-fix
stylua-fix:
	stylua lua

.PHONY: testcov
testcov:
	touch luacov.stats.out
	SEQUENTIAL=1 TEST_COV=1 $(MAKE) --no-print-directory test
	@luacov-console lua/recode
	@luacov-console -s
	@luacov

.PHONY: testcov-html
testcov-html:
	NOCLEAN=1 $(MAKE) --no-print-directory testcov
	luacov -r html
	xdg-open luacov-html/index.html
