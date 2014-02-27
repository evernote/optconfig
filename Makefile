NAME=optconfig
VERSION=1.0.3
RELEASE=1
SOURCE=$(NAME)-$(VERSION).tar.gz
ARCH=noarch
EXES=showconfig optconfig.sh ppenv.sh ppenv.csh
CLEAN_TARGETS=$(SPEC) $(NAME)-$(VERSION) $(SOURCE) # for in-house package

include $(shell starter)/rules.mk

$(NAME)-$(VERSION): $(FILES) $(EXES) $(CONFS) $(LIBS)
	mkdir -p $(NAME)-$(VERSION)
	if [ -n "$(EXES)" ]; then $(ENSURE_DIR) $(NAME)-$(VERSION)/bin && $(MAKE_EXES) $(EXES) $(NAME)-$(VERSION)/bin; fi
#perl libs
	$(ENSURE_DIR) $(NAME)-$(VERSION)/lib/perl/$(PERL_VERSION) && $(MAKE_LIBS) $(LIBS) $(NAME)-$(VERSION)/lib; (cd lib && tar cf - *.pm) | (cd $(NAME)-$(VERSION)/lib/perl/$(PERL_VERSION) && tar xf -)
#ruby libs
	$(ENSURE_DIR) $(NAME)-$(VERSION)/lib/site_ruby/$(RUBY_VERSION) && $(MAKE_LIBS) $(LIBS) $(NAME)-$(VERSION)/lib; (cd lib && tar cf - *.rb) | (cd $(NAME)-$(VERSION)/lib/site_ruby/$(RUBY_VERSION) && tar xf -)
	if [ -n "$(EXES)$(LIBS)" ]; then $(ENSURE_DIR) $(NAME)-$(VERSION)/man && $(MAKE_MANS) --release="$(NAME) $(VERSION)" $(EXES) $(LIBS) $(NAME)-$(VERSION)/man; fi
