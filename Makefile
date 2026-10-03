# keycutter-skill — local test & lint gate
#
# Run `make check` before committing. A fresh public clone can run the same.
#   test       — run the bats suite in test/
#   shellcheck — lint the shell scripts and the keycutter command
#   check      — shellcheck + test

.PHONY: test shellcheck check

SHELL_SOURCES := skills/keycutter/scripts/* bin/keycutter

test:
	bats skills/keycutter/test/

shellcheck:
	shellcheck $(SHELL_SOURCES)

check: shellcheck test
