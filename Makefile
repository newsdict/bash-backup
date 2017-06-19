BIN ?= backup.sh
PREFIX ?= /usr/local

install:
	mkdir -p $(PREFIX)/share/bash-backup
	cp -r ./* $(PREFIX)/share/bash-backup
	ln -s $(PREFIX)/share/bash-backup/bin/backup.sh $(PREFIX)/bin/backup.sh
	chmod a+x $(PREFIX)/bin/backup.sh

uninstall:
	rm -rf $(PREFIX)/share/bash-backup
	rm -f $(PREFIX)/bin/backup.sh