SHELL=/bin/bash


all:
	@echo "Maybe you want to do: make update ?"

init:
	git submodule update --init --recursive
	cd dep && git checkout compiled && cd ..

update:
	git pull && git submodule foreach --recursive git pull
