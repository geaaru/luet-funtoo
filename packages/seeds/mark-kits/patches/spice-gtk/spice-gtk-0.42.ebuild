# Distributed under the terms of the GNU General Public License v2
# 🦊 ❤ metatools: {autogen_id}

EAPI=7
PYTHON_COMPAT=( python3+ )

inherit desktop meson optfeature python-any-r1 readme.gentoo-r1 xdg

DESCRIPTION="Set of GObject and Gtk objects for connecting to Spice servers and a client GUI"
HOMEPAGE="https://www.spice-space.org https://cgit.freedesktop.org/spice/spice-gtk/"
SRC_URI="https://direct.funtoo.org/63/c1/b0/63c1b011961fa9ddca668d58b45e487469c86969e117cda35888af61bea6a367c49154380eb089211f3fdebca7f6e7c74eaee4166ea0603cfebd191e0e53d69b -> spice-gtk-0.42-with-submodules.tar.xz"
KEYWORDS="*"
S="${WORKDIR}/${PN}-v0.42"

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="+gtk3 +introspection lz4 mjpeg policykit sasl smartcard usbredir wayland webdav"

# TODO:
# * use external pnp.ids as soon as that means not pulling in gnome-desktop
# * re-enable 'vala' USE based dependency currently, this fails to find vapigen
RDEPEND="
	dev-libs/glib:2
	dev-libs/json-glib:0=
	media-libs/gst-plugins-base:1.0
	media-libs/gst-plugins-good:1.0
	media-libs/gstreamer:1.0[introspection?]
	media-libs/opus
	media-libs/libjpeg-turbo:=
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/pixman
	x11-libs/libX11
	gtk3? ( x11-libs/gtk+:3[introspection?] )
	introspection? ( dev-libs/gobject-introspection )
	dev-libs/openssl:=
	lz4? ( app-arch/lz4 )
	sasl? ( dev-libs/cyrus-sasl )
	smartcard? ( app-emulation/qemu[smartcard] )
	usbredir? (
		sys-apps/hwids
		sys-apps/usbredir
		virtual/acl
		virtual/libusb:1
		policykit? (
			sys-auth/polkit
		)
	)
	webdav? (
		net-libs/phodav:=
		net-libs/libsoup:=
	)
"
RDEPEND="${RDEPEND}
	amd64? ( x11-libs/libva:= )
	arm64? ( x11-libs/libva:= )
	x86? ( x11-libs/libva:= )
"
DEPEND="${RDEPEND}
	app-emulation/spice-protocol:=
"
BDEPEND="
	dev-perl/Text-CSV
	dev-util/glib-utils
	sys-devel/gettext
	virtual/pkgconfig
	$(python_gen_any_dep '
		dev-python/six[${PYTHON_USEDEP}]
		dev-python/pyparsing[${PYTHON_USEDEP}]
	')
"

python_check_deps() {
	python_has_version "dev-python/six[${PYTHON_USEDEP}]" &&
	python_has_version "dev-python/pyparsing[${PYTHON_USEDEP}]"
}

src_configure() {
	local emesonargs=(
		$(meson_feature gtk3 gtk)
		$(meson_feature introspection)
		$(meson_use mjpeg builtin-mjpeg)
		$(meson_feature policykit polkit)
		$(meson_feature lz4)
		$(meson_feature sasl)
		$(meson_feature smartcard)
		$(meson_feature usbredir)
		$(meson_feature webdav)
		$(meson_feature wayland wayland-protocols)
	)

	if use elibc_musl; then
		emesonargs+=(
			-Dcoroutine=gthread
		)
	fi

	if use usbredir; then
		emesonargs+=(
			-Dusb-acl-helper-dir=/usr/libexec
			-Dusb-ids-path="${EPREFIX}"/usr/share/misc/usb.ids
		)
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	if use usbredir && use policykit; then
		# bug #775554 (and bug #851657)
		fowners root:root /usr/libexec/spice-client-glib-usb-acl-helper
		fperms 4755 /usr/libexec/spice-client-glib-usb-acl-helper
	fi

	make_desktop_entry spicy Spicy "utilities-terminal" "Network;RemoteAccess;"
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "Sound support (via pulseaudio)" media-plugins/gst-plugins-pulse
}
