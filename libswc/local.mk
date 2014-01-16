# swc: libswc/local.mk

dir := libswc

LIBSWC_LINK := libswc.so
LIBSWC_SO   := $(LIBSWC_LINK).$(VERSION_MAJOR)
LIBSWC_LIB  := $(LIBSWC_SO).$(VERSION_MINOR)

ifneq ($(ENABLE_STATIC), 0)
$(dir)_TARGETS += $(dir)/libswc.a
endif

ifneq ($(ENABLE_SHARED), 0)
$(dir)_SHARED_TARGETS :=            \
    $(dir)/$(LIBSWC_LIB)            \
    $(dir)/$(LIBSWC_SO)             \
    $(dir)/$(LIBSWC_LINK)
$(dir)_TARGETS += libswc-shared
endif

# Dependencies
$(dir)_PACKAGES =   \
    libdrm          \
    libevdev        \
    libudev         \
    pixman-1        \
    wayland-server  \
    wld             \
    xkbcommon

SWC_SOURCES =                       \
    libswc/compositor.c             \
    libswc/view.c                   \
    libswc/util.c                   \
    libswc/output.c                 \
    libswc/plane.c                  \
    libswc/surface.c                \
    libswc/region.c                 \
    libswc/input_focus.c            \
    libswc/keyboard.c               \
    libswc/pointer.c                \
    libswc/seat.c                   \
    libswc/data_device_manager.c    \
    libswc/data_device.c            \
    libswc/data.c                   \
    libswc/mode.c                   \
    libswc/evdev_device.c           \
    libswc/xkb.c                    \
    libswc/shm.c                    \
    libswc/drm.c                    \
    libswc/drm_buffer.c             \
    protocol/wayland-drm-protocol.c \
    launch/protocol.c

# Public interface
SWC_SOURCES +=                      \
    libswc/swc.c                    \
    libswc/window.c                 \
    libswc/shell.c                  \
    libswc/shell_surface.c          \
    libswc/bindings.c

ifeq ($(ENABLE_XWAYLAND),1)
$(dir)_CFLAGS += -DENABLE_XWAYLAND
$(dir)_PACKAGES +=                  \
    xcb                             \
    xcb-composite                   \
    xcb-ewmh

SWC_SOURCES +=                      \
    libswc/xserver.c                \
    libswc/xwm.c                    \
    protocol/xserver-protocol.c
endif

SWC_STATIC_OBJECTS = $(SWC_SOURCES:%.c=%.o)
SWC_SHARED_OBJECTS = $(SWC_SOURCES:%.c=%.lo)

# Explicitly state dependencies on generated files
objects = $(foreach obj,$(1),$(dir)/$(obj).o $(dir)/$(obj.lo))
$(call objects,drm drm_buffer): protocol/wayland-drm-server-protocol.h
$(call objects,xserver): protocol/xserver-server-protocol.h

$(dir)/libswc.a: $(SWC_STATIC_OBJECTS)
	$(call quiet,AR) cru $@ $^

$(dir)/$(LIBSWC_LIB): $(SWC_SHARED_OBJECTS)
	$(link) -shared -Wl,-soname,$(LIBSWC_SO) -Wl,-no-undefined $(libswc_PACKAGE_LIBS)

$(dir)/$(LIBSWC_SO): $(dir)/$(LIBSWC_LIB)
	$(call quiet,SYM,ln -sf) $(notdir $<) $@

$(dir)/$(LIBSWC_LINK): $(dir)/$(LIBSWC_SO)
	$(call quiet,SYM,ln -sf) $(notdir $<) $@

.PHONY: libswc-shared
libswc-shared: $($(dir)_SHARED_TARGETS)

.PHONY: install-libswc.a
install-libswc.a: $(dir)/libswc.a | $(DESTDIR)$(LIBDIR)
	install -m0644 $< "$(DESTDIR)$(LIBDIR)"

.PHONY: install-libswc-shared
install-libswc-shared: $(dir)/$(LIBSWC_LIB) | $(DESTDIR)$(LIBDIR)
	install -m0755 $< "$(DESTDIR)$(LIBDIR)"
	ln -sf $(LIBSWC_LIB) "$(DESTDIR)$(LIBDIR)/$(LIBSWC_SO)"
	ln -sf $(LIBSWC_SO) "$(DESTDIR)$(LIBDIR)/$(LIBSWC_LINK)"

check-dependencies-libswc:
	$(call check_deps,libswc,$(SWC_PACKAGES))

install-libswc: $($(dir)_TARGETS:$(dir)/%=install-%) | $(DESTDIR)$(INCLUDEDIR)
	install -m0644 libswc/swc.h "$(DESTDIR)$(INCLUDEDIR)"

CLEAN_FILES += $(SWC_SHARED_OBJECTS) $(SWC_STATIC_OBJECTS) $($(dir)_SHARED_TARGETS)

include common.mk
