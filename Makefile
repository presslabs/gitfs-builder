include VERSIONS

# We check for $CI_BUILD_DIR env variable to set the target accordingly if we
# are within a CI environment
ifdef DRONE
	TARGET ?= /drone/gitfs/build
else
	TARGET ?= /target/build
endif

ifdef CI_COMMIT
	COMMIT ?= $(CI_COMMIT)
else
	COMMIT ?= '(none)'
endif

BUILD_DIST := $(shell lsb_release -sc)
ifdef CI_TAG
	BUILD_VERSION ?= ~ppa$(CI_TAG:v%=%)
else
ifdef CI_BRANCH
	BUILD_VERSION ?= ~ppa$(CI_BUILD_NUMBER)+$(CI_BRANCH)
else
	BUILD_VERSION ?= $(shell date +'~ppa%Y%m%d+%H%M%S')
endif
endif

BUILD_VERSION := $(BUILD_DIST)$(BUILD_VERSION)
BUILD_DIR := $(TARGET)

GITFS_DIR := $(BUILD_DIR)/gitfs-$(GITFS_VERSION)
PACKAGES_DIR := $(GITFS_DIR)/debian/packages

PREPARE_DEPS := $(addprefix prepare-, $(DEPENDENCIES))
BUILD_DEPS := $(addprefix build-, $(DEPENDENCIES))

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(PACKAGES_DIR):
	mkdir -p $(PACKAGES_DIR)

all: build

build: $(BUILD_DIR) prepare build-gitfs

prepare: $(PREPARE_DEPS) $(BUILD_DEPS) prepare-gitfs $(addprefix retrieve-package-, $(PACKAGES))

prepare-%: get-%
	@cp -r debian-$* $(BUILD_DIR)/$*-$($(shell echo $* | tr a-z- A-Z_)_VERSION)/debian

retrieve-package-%: $(PACKAGES_DIR)
	wget -q $($(shell echo $* | tr a-z- A-Z_)_URL) -O $(PACKAGES_DIR)/$(shell echo $*)-$($(shell echo $* | tr a-z- A-_)_VERSION).tar.gz
	echo debian/packages/$(shell echo $*)-$($(shell echo $* | tr a-z- A-_)_VERSION).tar.gz >> $(GITFS_DIR)/debian/source/include-binaries

get-%:
	wget -q $($(shell echo $* | tr a-z- A-Z_)_URL) -O $(BUILD_DIR)/$*_$($(shell echo $* | tr a-z- A-Z_)_VERSION).orig.tar.gz
	tar -xzf $(BUILD_DIR)/$*_$($(shell echo $* | tr a-z- A-Z_)_VERSION).orig.tar.gz -C $(BUILD_DIR)/

build-%:
	@echo Building $($*_VERSION) source
	cd $(BUILD_DIR)/$*-$($(shell echo $* | tr a-z- A-Z_)_VERSION) \
		&& dch -b -D $(BUILD_DIST) -v $($(shell echo $* | tr a-z- A-Z_)_VERSION)-$(BUILD_VERSION) "Automated build of $* $($*_VERSION) $(COMMIT)" \
		&& debuild -S -sa --lintian-opts --allow-root

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all prepare build clean get-% mkdir-%
