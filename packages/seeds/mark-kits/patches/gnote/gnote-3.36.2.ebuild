# Distributed under the terms of the GNU General Public License v2

EAPI=7
GNOME3_LA_PUNT="yes"

inherit autotools gnome3 readme.gentoo-r1

DESCRIPTION="Desktop note-taking application"
HOMEPAGE="https://wiki.gnome.org/Apps/Gnote"

LICENSE="GPL-3+ FDL-1.1"
SLOT="0"
KEYWORDS="*"

IUSE="debug"

# Automagic:
# glib-2.32 dep
# >=dev-libs/unittest++-1.5.1 (but not detected due to missing .pc)
COMMON_DEPEND="
	>=app-crypt/libsecret-0.8
	>=app-text/gtkspell-3.0:3
	>=dev-cpp/glibmm-2.62.0
	>=dev-cpp/gtkmm-3.18:3.0
	>=dev-libs/boost-1.34:=
	>=dev-libs/glib-2.62.2:2[dbus]
	>=dev-libs/libxml2-2:2
	dev-libs/libxslt
	>=sys-apps/util-linux-2.16:=
	>=x11-libs/gtk+-3.24.12:3
"
RDEPEND="${COMMON_DEPEND}
	gnome-base/gsettings-desktop-schemas
"
DEPEND="${DEPEND}
	app-text/docbook-xml-dtd:4.1.2
	>=dev-util/intltool-0.35.0
	dev-util/itstool
	virtual/pkgconfig
"

src_prepare() {
	# Do not alter CFLAGS
	sed 's/-DDEBUG -g/-DDEBUG/' -i configure.ac configure || die
	# Fix compilation with GCC11
	sed -i -e 's|^#include "abstractaddin.hpp"|#include <cstddef>\n#include "abstractaddin.hpp"|g' \
		src/abstractaddin.cpp || die

	# Prevent m4_copy error when running aclocal, bug #581308
	# m4_copy: won't overwrite defined macro: glib_DEFUN
	rm m4/glib-gettext.m4 || die

	eautoreconf
	gnome3_src_prepare

	if has_version net-fs/wdfs; then
		DOC_CONTENTS="You have net-fs/wdfs installed. app-misc/gnote will use it to
		synchronize notes."
	else
		DOC_CONTENTS="Gnote can use net-fs/wdfs to synchronize notes.
		If you want to use that functionality just emerge net-fs/wdfs.
		Gnote will automatically detect that you did and let you use it."
	fi
}

src_configure() {
	ECONF_SOURCES="${S}" econf \
		--disable-static \
		$(use_enable debug)
}

src_install() {
	gnome3_src_install
	readme.gentoo_create_doc
}

pkg_postinst() {
	gnome3_pkg_postinst
	readme.gentoo_print_elog
}
