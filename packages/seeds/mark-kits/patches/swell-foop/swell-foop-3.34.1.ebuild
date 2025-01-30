# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit gnome3 vala meson

DESCRIPTION="Clear the screen by removing groups of colored and shaped tiles"
HOMEPAGE="https://wiki.gnome.org/Apps/Swell%20Foop"

LICENSE="GPL-2+ FDL-1.1+"
SLOT="0"
KEYWORDS="*"

IUSE=""

RDEPEND="
	>=dev-libs/glib-2.62.2:2
	>=media-libs/clutter-1.14:1.0
	>=media-libs/clutter-gtk-1.5:1.0
	>=x11-libs/gtk+-3.24.12:3
"
DEPEND="${RDEPEND}
	$(vala_depend)
	app-text/yelp-tools
	dev-libs/appstream-glib
	>=dev-util/intltool-0.50
	sys-devel/gettext
	virtual/pkgconfig
"

src_prepare() {
	sed -i -e 's|string\[4\] colors|string[] colors|g' src/game-view.vala || die
	gnome3_src_prepare
	vala_src_prepare
}
