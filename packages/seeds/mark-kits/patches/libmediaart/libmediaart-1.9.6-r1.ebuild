# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit gnome2 meson vala
VALA_USE_DEPEND="vapigen"

DESCRIPTION="Manages, extracts and handles media art caches"
HOMEPAGE="https://gitlab.gnome.org/GNOME/libmediaart"

LICENSE="LGPL-2.1+"
SLOT="2.0"
KEYWORDS="*"
IUSE="gtk-doc +introspection -qt5 test vala"
RESTRICT="!test? ( test )"
REQUIRED_USE="
	vala? ( introspection )
"

RDEPEND="
	>=dev-libs/glib-2.38.0:2
	!qt5? ( >=x11-libs/gdk-pixbuf-2.12:2 )
	introspection? ( >=dev-libs/gobject-introspection-1.30:= )
	qt5? ( dev-qt/qtgui:5 )
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-libs/gobject-introspection-common
	virtual/pkgconfig
	gtk-doc? ( dev-util/gtk-doc )
	vala? ( $(vala_depend) )
"

src_prepare() {
	use vala && vala_src_prepare
	default
}

src_configure() {
	local image_library
	if use qt5 ; then
		image_library=qt5
	else
		image_library=gdk-pixbuf
	fi

	local emesonargs=(
		-Dimage_library=${image_library}
		$(meson_use introspection)
		$(meson_use vala vapi)
		$(meson_use test tests)
		$(meson_use gtk-doc gtk_doc)
	)
	meson_src_configure
}
