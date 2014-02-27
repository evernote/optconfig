NAME=optconfig
VERSION=1.0
RELEASE=1
SOURCE=$(NAME)-$(VERSION).tar.gz
EXES=
LIBS=
CONFS=
ARCH=noarch
CLEAN_TARGETS=$(SPEC) $(NAME)-$(VERSION) $(SOURCE) # for in-house package

include $(shell starter)/rules.mk
