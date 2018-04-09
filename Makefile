#########################################################################
# common include file for application Makefiles
#
# Makefile Usage:
# > make
# > make install
# > make remove
#
# to exclude certain files from being added to the zipfile during packaging
# include a line like this:ZIP_EXCLUDE= -x keys\*
# that will exclude any file who's name begins with 'keys'
# to exclude using more than one pattern use additional '-x <pattern>' arguments
# ZIP_EXCLUDE= -x \*.pkg -x storeassets\*
#
# Important Notes: 
# To use the "install" and "remove" targets to install your
# application directly from the shell, you must do the following:
#
# 1) Make sure that you have the curl command line executable in your path
# 2) Set the variable ROKU_DEV_TARGET in your environment to the IP 
#    address of your Roku box. (e.g. export ROKU_DEV_TARGET=192.168.1.1.
#    Set in your this variable in your shell startup (e.g. .bashrc)
##########################################################################  
APPNAME = subsonic
PKGREL = ./
ZIPREL = ./
SOURCEREL = ..
ZIP_EXCLUDE = \*.swp \*~ \*\.~ Makefile README.rst \*.git/\* \*.odp \*.zip \*.pkg tags .gitignore .buildpath .project **/.DS_Store
BUILDDATE = $(shell date +%y%m%d)
HTTPSTATUS = $(shell curl --silent --write-out "\n%{http_code}\n" $(ROKU_DEV_TARGET))

ifndef ROKU_DEV_TARGET
	ROKU_DEV_TARGET = roku
endif

ifdef DEVPASSWORD
    USERPASS = rokudev:$(DEVPASSWORD)
else
    USERPASS = rokudev
endif

.PHONY: all $(APPNAME)

$(APPNAME): 
	@echo "*** Creating $(APPNAME).zip ***"

	@echo "  >> removing old application zip $(ZIPREL)/$(APPNAME).zip"
	@if [ -e "$(ZIPREL)/$(APPNAME).zip" ]; \
	then \
		rm  $(ZIPREL)/$(APPNAME).zip; \
	fi

	@echo "  >> creating destination directory $(ZIPREL)"	
	@if [ ! -d $(ZIPREL) ]; \
	then \
		mkdir -p $(ZIPREL); \
	fi

	@echo "  >> setting directory permissions for $(ZIPREL)"
	@if [ ! -w $(ZIPREL) ]; \
	then \
		chmod 755 $(ZIPREL); \
	fi

# zip .png files without compression
	mkdir -p $(ZIPREL)
	@echo "  >> creating application zip $(ZIPREL)/$(APPNAME).zip"	
	zip -0 -r "$(ZIPREL)/$(APPNAME).zip" . -i \*.png -x $(ZIP_EXCLUDE)
	zip -9 -r "$(ZIPREL)/$(APPNAME).zip" . -x \*.png $(ZIP_EXCLUDE)

	@echo "*** developer zip  $(APPNAME) complete ***"

install: $(APPNAME)
	@echo "Installing $(APPNAME) to host $(ROKU_DEV_TARGET)"
	@if [ "$(HTTPSTATUS)" == " 401" ]; \
	then \
		curl --user $(USERPASS) --digest -s -S -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).zip" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \
	else \
		curl -s -S -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).zip" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \
	fi

old_install: $(APPNAME)
	@echo "Installing $(APPNAME) to host $(ROKU_DEV_TARGET)"
	#@curl -s -S -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).zip" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"
	curl -S -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).zip" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install

update_manifest:
	@echo "  >> updating build_version"
	$(shell sed -i s/^build_version=.*/build_version=$(BUILDDATE)/ manifest)
	sed -i s/^build_version=.*/build_version=$(BUILDDATE)/ manifest

pkg: update_manifest install
	mkdir -p $(PKGREL)
	@echo "*** Creating Package ***"


	@echo "  >> creating destination directory $(PKGREL)"	
	@if [ ! -d $(PKGREL) ]; \
	then \
		mkdir -p $(PKGREL); \
	fi

	@echo "  >> setting directory permissions for $(PKGREL)"
	@if [ ! -w $(PKGREL) ]; \
	then \
		chmod 755 $(PKGREL); \
	fi

	@echo "Packaging  $(APPNAME) on host $(ROKU_DEV_TARGET)"
	@read -p "Password: " REPLY ; echo $$REPLY | xargs -i curl -s -S -Fmysubmit=Package -Fapp_name=$(APPNAME)/$(VERSION) -Fpasswd={} -Fpkg_time=`expr \`date +%s\` \* 1000` "http://$(ROKU_DEV_TARGET)/plugin_package" | grep '^<font face=' | sed 's/.*href=\"\([^\"]*\)\".*/\1/' | sed 's#pkgs/##' | xargs -i curl -s -S -o $(PKGREL)/$(APPNAME)_$(BUILDDATE)_{} http://$(ROKU_DEV_TARGET)/pkgs/{}

	@echo "*** Package  $(APPNAME) complete ***" 
remove:
	@echo "Removing $(APPNAME) from host $(ROKU_DEV_TARGET)"
	@curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"
