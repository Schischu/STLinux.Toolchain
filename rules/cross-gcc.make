# -*-makefile-*-
#
# Copyright (C) 2006 by Robert Schwebel
#               2008, 2009 by Marc Kleine-Budde <mkl@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
CROSS_PACKAGES-$(PTXCONF_CROSS_GCC) += cross-gcc

#
# Paths and names
#
CROSS_GCC_VERSION	:= $(call remove_quotes,$(PTXCONF_CROSS_GCC_VERSION))
CROSS_GCC_DL_VERSION	:= $(call remove_quotes,$(PTXCONF_CROSS_GCC_DL_VERSION))
CROSS_GCC_MD5		:= $(call remove_quotes,$(PTXCONF_CROSS_GCC_MD5))
CROSS_GCC		:= gcc-$(CROSS_GCC_DL_VERSION)
CROSS_GCC_SUFFIX	:= tar.bz2
CROSS_GCC_SOURCE	:= $(SRCDIR)/$(CROSS_GCC).$(CROSS_GCC_SUFFIX)
CROSS_GCC_DIR		:= $(BUILDDIR_CROSS_DEBUG)/$(CROSS_GCC)
CROSS_GCC_BUILDDIR	:= $(CROSS_BUILDDIR)/$(CROSS_GCC)-build

CROSS_GCC_URL	 	:= \
	$(call ptx/mirror, GNU, gcc/$(CROSS_GCC)/$(CROSS_GCC).$(CROSS_GCC_SUFFIX)) \
	http://www.duckbox.de/ptxdist/temporary-src/gcc/$(CROSS_GCC).$(CROSS_GCC_SUFFIX) \
	http://ptxdist.sat-universum.de/$(CROSS_GCC).$(CROSS_GCC_SUFFIX)
	

ptx/abs2rel := $(PTXDIST_WORKSPACE)/scripts/ptxd_abs2rel.sh

# ----------------------------------------------------------------------------
# Get
# ----------------------------------------------------------------------------

$(CROSS_GCC_SOURCE):
	@$(call targetinfo)
	@$(call get, CROSS_GCC)

# ----------------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------------

$(STATEDIR)/cross-gcc.extract:
	@$(call targetinfo)
	@$(call clean, $(CROSS_GCC_DIR))
	@$(call extract, CROSS_GCC, $(BUILDDIR_CROSS_DEBUG))
	@$(call patchin, CROSS_GCC, $(CROSS_GCC_DIR))
ifdef PTXCONF_CROSS_ECJ
	@cp $(CROSS_ECJ_SOURCE) $(CROSS_GCC_DIR)/ecj.jar
endif
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

CROSS_GCC_PATH	:= PATH=$(CROSS_PATH)
CROSS_GCC_ENV	:= $(PTX_HOST_ENV)

#
# autoconf
#
CROSS_GCC_AUTOCONF_COMMON := \
	$(PTX_HOST_CROSS_AUTOCONF_BUILD) \
	$(PTX_HOST_CROSS_AUTOCONF_HOST) \
	$(PTX_HOST_CROSS_AUTOCONF_TARGET) \
	\
	$(PTXCONF_TOOLCHAIN_CONFIG_SYSROOT) \
	$(PTXCONF_TOOLCHAIN_CONFIG_MULTILIB) \
	\
	$(PTXCONF_CROSS_GCC_CONFIG_EXTRA) \
	$(PTXCONF_CROSS_GCC_CONFIG_LIBC) \
	$(PTXCONF_CROSS_GCC_CONFIG_CXA_ATEXIT) \
	$(PTXCONF_CROSS_GCC_CONFIG_LTO) \
	\
	$(PTXCONF_CROSS_GCC_CONFIG_NLS) \
	\
	--enable-symvers=gnu \
	\
	--with-pkgversion=$(PTXCONF_CROSS_GCC_PKGVERSION) \
	--enable-threads=$(PTXCONF_CROSS_GCC_THREADS) \
	--with-system-zlib

ifdef PTXCONF_HOST_MPCX2
CROSS_GCC_AUTOCONF_COMMON += --with-mpcx2=$(PTXCONF_SYSROOT_HOST)
endif

ifdef PTXCONF_HOST_GMP
CROSS_GCC_AUTOCONF_COMMON += --with-gmp=$(PTXCONF_SYSROOT_HOST)
endif

ifdef PTXCONF_HOST_MPFR
CROSS_GCC_AUTOCONF_COMMON += --with-mpfr=$(PTXCONF_SYSROOT_HOST)
endif

ifdef PTXCONF_HOST_LIBELF
CROSS_GCC_AUTOCONF_COMMON += --with-libelf=$(PTXCONF_SYSROOT_HOST)
endif

CROSS_GCC_AUTOCONF_COMMON += --without-ppl
	
#	--with-gxx-include-dir="\\\${prefix}/target%{_stm_target_include_dir}/c++/%{version}"
# --without-ppl

#	--disable-decimal-float \
#	--disable-fixed-point \
#	--disable-win32-registry \

#
# language selection
#
CROSS_GCC_LANG-$(PTXCONF_CROSS_GCC_LANG_C)		+= c
CROSS_GCC_LANG-$(PTXCONF_CROSS_GCC_LANG_CXX)		+= c++
CROSS_GCC_LANG-$(PTXCONF_CROSS_GCC_LANG_JAVA)		+= java
CROSS_GCC_LANG-$(PTXCONF_CROSS_GCC_LANG_FORTRAN)	+= fortran

CROSS_GCC_AUTOCONF := \
	$(CROSS_GCC_AUTOCONF_COMMON) \
	$(PTX_HOST_CROSS_AUTOCONF_PREFIX) \
	\
	--enable-languages=$(subst $(space),$(comma),$(CROSS_GCC_LANG-y)) \
	--enable-c99 \
	--enable-long-long \
	\
	$(PTXCONF_CROSS_GCC_CONFIG_SHARED) \
	$(PTXCONF_CROSS_GCC_CONFIG_LIBSSP) \
	$(PTXCONF_CROSS_GCC_CONFIG_LIBGOMP) \
	$(PTXCONF_CROSS_GCC_CONFIG_LIBITM) \
	--disable-checking

#	--enable-libstdcxx-debug
#	--enable-profile
#	$(if $(filter 3.%,$(CROSS_GCC_VERSION)),,--enable-checking=release)

$(STATEDIR)/cross-gcc.prepare:
	@$(call targetinfo)
	@$(call clean, $(CROSS_GCC_BUILDDIR))
	mkdir -p $(CROSS_GCC_BUILDDIR)
	cd $(CROSS_GCC_BUILDDIR) && \
		$(CROSS_GCC_PATH) $(CROSS_GCC_ENV) \
		$(CROSS_GCC_DIR)/configure $(CROSS_GCC_AUTOCONF)
	@$(call touch)

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/cross-gcc.compile:
	@$(call targetinfo)
	@ln -sf `which $(HOSTCC)` $(PTXCONF_SYSROOT_HOST)/bin/$(GNU_BUILD)-gcc
	cd $(CROSS_GCC_BUILDDIR) && $(CROSS_GCC_PATH) \
		$(MAKE) $(PARALLELMFLAGS_BROKEN)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/cross-gcc.install:
	@$(call targetinfo)
	@cd $(CROSS_GCC_BUILDDIR) && \
		$(CROSS_GCC_PATH) $(MAKE) $(PARALLELMFLAGS_BROKEN) install

	@cd "$(PTXCONF_SYSROOT_CROSS)/$(PTX_TOUPLE_TARGET)/lib"; \
	dst="$(SYSROOT)/usr/lib"; \
	rel="$$($(ptx/abs2rel) "$${dst}" "$${PWD}")" && \
	for file in \
		libg2c.*so* \
		libgcc_s.*so* \
		libgfortran.*so* \
		libgomp.*so* \
		libmudflap.*so* \
		libmudflapth.*so* \
		libssp.*so* \
		libstdc++.*so* \
		; do \
		[ \! -e "$${file}" ] && continue; \
		\
		dst_file="$${dst}/$${file}"; \
		rel_file="$${rel}/$${file}"; \
		if [ -L "$${file}" ]; then \
			cp -vdR "$${file}" "$${dst_file}"; \
		else \
			ln -vfs "$${rel_file}" "$${dst_file}"; \
		fi || exit 1; \
	done

	@find $(PTXCONF_SYSROOT_CROSS) -name "*.la" | while read la_file; do \
		rm -v $${la_file}; \
	done

	@$(call touch)


#	ln -sfv $(SYSROOT)/../lib/gcc/$(PTXCONF_GNU_TARGET)/$(CROSS_GCC_VERSION)/libgcc.a \
#		$(SYSROOT)/../lib/gcc/$(PTXCONF_GNU_TARGET)/$(CROSS_GCC_VERSION)/libgcc_eh.a 
#
#	ln -sfv $(SYSROOT)/../lib/gcc/$(PTXCONF_GNU_TARGET)/$(CROSS_GCC_VERSION)/libgcc.a \
#		$(SYSROOT)/../lib/gcc/$(PTXCONF_GNU_TARGET)/$(CROSS_GCC_VERSION)/libgcc_s.a 

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

cross-gcc_clean:
	rm -rf $(STATEDIR)/cross-gcc.*
	rm -rf $(CROSS_GCC_DIR)
	rm -rf $(CROSS_GCC_BUILDDIR)

# vim: syntax=make
