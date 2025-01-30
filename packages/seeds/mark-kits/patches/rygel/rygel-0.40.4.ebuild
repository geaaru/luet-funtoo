# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit gnome.org meson systemd vala xdg

DESCRIPTION="Rygel is an open source UPnP/DLNA MediaServer"
HOMEPAGE="https://wiki.gnome.org/Projects/Rygel"

LICENSE="LGPL-2.1+ CC-BY-SA-3.0 GPL-2"
SLOT="0"
KEYWORDS="*"

IUSE="X +introspection +sqlite tracker test transcode gtk-doc"

# The deps for tracker? and transcode? are just the earliest available
# version at the time of writing this ebuild
RDEPEND="
	>=dev-libs/glib-2.62.2
	>=dev-libs/libgee-0.8:0.8
	>=dev-libs/libxml2-2.7:2
	>=media-libs/gupnp-dlna-0.9.4:2.0
	media-libs/gstreamer:1.0
	media-libs/gst-plugins-base:1.0
	>=media-libs/libmediaart-0.7:2.0
	media-plugins/gst-plugins-soup:1.0
	media-libs/gstreamer-editing-services:1.0
	>=net-libs/gssdp-0.13
	>=net-libs/gupnp-0.20.14
	>=net-libs/gupnp-av-0.12.8
	>=net-libs/libsoup-2.44:2.4
	>=sys-apps/util-linux-2.20
	x11-misc/shared-mime-info
	introspection? ( >=dev-libs/gobject-introspection-1.62.0:= )
	sqlite? (
		>=dev-db/sqlite-3.5:3
		dev-libs/libunistring:=
		x11-libs/gdk-pixbuf:2
	)
	tracker? ( >=app-misc/tracker-0.16:= )
	transcode? (
		media-libs/gst-plugins-bad:1.0
		media-plugins/gst-plugins-twolame:1.0
		media-plugins/gst-plugins-libav:1.0
	)
	X? ( >=x11-libs/gtk+-3:3 )
"
DEPEND="${RDEPEND}
	dev-util/gtk-doc-am
	>=sys-devel/gettext-0.19.7
	virtual/pkgconfig
"
BDEPEND="
	$(vala_depend)
	app-text/docbook-xml-dtd:4.5
	>=sys-devel/gettext-0.19.7
	virtual/pkgconfig
"

src_prepare() {
	vala_src_prepare
	default
}

src_configure() {
		#-Dman_pages=true
	local emesonargs=(
		$(meson_use gtk-doc api-docs)
		-Dsystemd-user-units-dir=$(systemd_get_userunitdir)
		-Dplugins=gst-launch$(use sqlite && echo ",lms,media-export")$(use tracker && echo ",tracker3")
		-Dengines=gstreamer
		-Dexamples=false
		$(meson_use test tests)
		$(meson_feature X gtk)
		$(meson_feature introspection)
	)
	meson_src_configure
}
