PREFIX := /usr
BINDIR := $(PREFIX)/bin

install:
	cp -f rose-chroot.sh $(BINDIR)/rose-chroot

uninstall:
	$(RM) $(BINDIR)/rose-chroot

.PHONY: install uninstall
