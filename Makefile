MERCURY_DIR := Mercury
SRCDIR := src
BUILDDIR := .build
BUILDSRC := $(BUILDDIR)/src
APP := aurobool
SOURCES := $(wildcard $(SRCDIR)/*.m)

.PHONY: all build run test clean

all: build

build:
	mkdir -p $(BUILDSRC)
	cp $(SOURCES) $(BUILDSRC)/
	cd $(BUILDSRC) && mmc --make main
	cp $(BUILDSRC)/main ./$(APP)

run: build
	./$(APP)

clean:
	rm -f $(APP)
	rm -rf $(BUILDDIR)
	rm -rf $(MERCURY_DIR)
	rm -rf *.err
