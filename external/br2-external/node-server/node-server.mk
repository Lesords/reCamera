################################################################################
#
# node-server (LuaScriptVision)
#
################################################################################

NODE_SERVER_VERSION = dev
NODE_SERVER_SITE = https://github.com/Lesords/LuaScriptVision.git
NODE_SERVER_SITE_METHOD = git
NODE_SERVER_GIT_SUBMODULES = YES
NODE_SERVER_LICENSE = Apache-2.0
NODE_SERVER_DEPENDENCIES = host-nodejs mosquitto alsa-lib

# Configure step: run CMake with SG200X toolchain
define NODE_SERVER_CONFIGURE_CMDS
	mkdir -p $(@D)/build && \
	cd $(@D)/build && \
	$(BR2_CMAKE) \
		-DCMAKE_TOOLCHAIN_FILE=$(@D)/cmake/toolchain-sg200x.cmake \
		-DSG200X_SDK_PATH=$(shell realpath $(BUILD_DIR)/../../../../) \
		-DCMAKE_BUILD_TYPE=Release \
		-DENABLE_CVI_CAMERA=ON \
		..
endef

# Build step: compile with make
define NODE_SERVER_BUILD_CMDS
	$(MAKE) -C $(@D)/build -j$(PARALLEL_JOBS)
endef

# Install step: deploy binaries and resources to target
define NODE_SERVER_INSTALL_TARGET_CMDS
	# Create the necessary directories for node-red
	mkdir -p $(TARGET_DIR)/home/recamera/.node-red/node_modules

	# Install npm packages
	$(NPM) install --no-audit --no-update-notifier --no-fund --save --save-prefix=~ --production --engine-strict --prefix $(TARGET_DIR)/home/recamera/.node-red node-red-contrib-sscma
	$(NPM) install --no-audit --no-update-notifier --no-fund --save --save-prefix=~ --production --engine-strict --prefix $(TARGET_DIR)/home/recamera/.node-red node-red-contrib-os
	$(NPM) install --no-audit --no-update-notifier --no-fund --save --save-prefix=~ --production --engine-strict --prefix $(TARGET_DIR)/home/recamera/.node-red node-red-contrib-seeed-canbus
	$(NPM) install --no-audit --no-update-notifier --no-fund --save --save-prefix=~ --production --engine-strict --prefix $(TARGET_DIR)/home/recamera/.node-red node-red-contrib-seeed-recamera

	$(NPM) install --no-audit --no-update-notifier --no-fund --save --save-prefix=~ --production --engine-strict --prefix $(TARGET_DIR)/home/recamera/.node-red @flowfuse/node-red-dashboard@1.26.0
	$(NPM) install --no-audit --no-update-notifier --no-fund --save --save-prefix=~ --production --engine-strict --prefix $(TARGET_DIR)/home/recamera/.node-red socketcan@4.0.5

	# Overlay updated node-red-contrib-sscma from git
	git clone --depth 1 -b main https://github.com/Lesords/node-red-contrib-nodes.git $(@D)/_contrib_overlay && \
	cp -rf $(@D)/_contrib_overlay/node-red-contrib-sscma/* $(TARGET_DIR)/home/recamera/.node-red/node_modules/node-red-contrib-sscma/

	# Install binaries
	$(INSTALL) -D -m 0755 $(@D)/build/node_server $(TARGET_DIR)/usr/local/bin/node_server

	# Install Lua scripts
	mkdir -p $(TARGET_DIR)/usr/local/share/lua-scripts
	cp -rf $(@D)/scripts/lib $(TARGET_DIR)/usr/local/share/lua-scripts/
	cp -r $(@D)/scripts/*.lua $(TARGET_DIR)/usr/local/share/lua-scripts/

	# Install startup script
	cp -r $(@D)/tools/S90node_server $(TARGET_DIR)/etc/init.d/
endef

$(eval $(generic-package))
