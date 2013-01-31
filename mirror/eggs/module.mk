$(BUILD_DIR)/mirror/eggs/build.done: SANDBOX:=$(BUILD_DIR)/mirror/eggs/SANDBOX
$(BUILD_DIR)/mirror/eggs/build.done: export SANDBOX_UP:=$(SANDBOX_UP)
$(BUILD_DIR)/mirror/eggs/build.done: export SANDBOX_DOWN:=$(SANDBOX_DOWN)
$(BUILD_DIR)/mirror/eggs/build.done: \
		$(BUILD_DIR)/mirror/centos/build.done \
		$(SOURCE_DIR)/requirements-eggs.txt \
		$(SOURCE_DIR)/config.mk
	mkdir -p $(@D)
	sudo sh -c "$${SANDBOX_UP}"

	# Creating eggs mirror directory
	mkdir -p $(LOCAL_MIRROR_EGGS)

	# Avoiding eggs download duplication.
	sudo rsync -a --delete $(LOCAL_MIRROR_EGGS) $(SANDBOX)/tmp

	# Here we don't know if MIRROR_EGGS
	# is a list of links or a correct pip index.
	# That is why we use --index-url and --find-links options
	# for the same url.

	# Installing new version of pip.
	sudo chroot $(SANDBOX) pip --version 2>/dev/null | awk '{print $$2}' | grep -qE "^1.2.1$$" || \
		sudo chroot $(SANDBOX) pip-python install \
		--index-url $(MIRROR_EGGS) \
		--find-links $(MIRROR_EGGS) \
		pip==1.2.1

	# Downloading required pip packages.
	sudo chroot $(SANDBOX) pip install \
		--exists-action=i \
		--index-url $(MIRROR_EGGS) \
		--find-links $(MIRROR_EGGS) \
		--download /tmp/$(notdir $(LOCAL_MIRROR_EGGS)) \
		$(REQUIRED_EGGS)

	# # Copying downloaded eggs into eggs mirror
	rsync -a $(SANDBOX)/tmp/$(notdir $(LOCAL_MIRROR_EGGS))/ $(LOCAL_MIRROR_EGGS)

	sudo sh -c "$${SANDBOX_DOWN}"
	$(ACTION.TOUCH)