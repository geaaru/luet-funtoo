# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit flag-o-matic autotools linux-info

DESCRIPTION="Tools for Linux Kernel Stream Control Transmission Protocol implementation"
HOMEPAGE="http://lksctp.sourceforge.net/"
SRC_URI="https://github.com/sctp/lksctp-tools/tarball/37d5f1225573b91d706a5e547d081f79963a9deb -> lksctp-tools-1.0.21-37d5f12.tar.gz"

LICENSE="|| ( GPL-2+ LGPL-2.1 )"
SLOT="0"
KEYWORDS="*"
IUSE="kernel_linux static-libs"

# This is only supposed to work with Linux to begin with.
DEPEND=">=sys-kernel/linux-headers-2.6"
RDEPEND=""

REQUIRED_USE="kernel_linux"

CONFIG_CHECK="~IP_SCTP"
WARNING_IP_SCTP="CONFIG_IP_SCTP:\tis not set when it should be."

DOCS=( AUTHORS ChangeLog INSTALL NEWS README ROADMAP )

post_src_unpack() {
	mv sctp-lksctp-tools-* "${S}"
}

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	append-flags -fno-strict-aliasing

	local myeconfargs=(
		--docdir="${EPREFIX%/}"/usr/share/doc/${PF}
		--enable-shared
		$(use_enable static-libs static)
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	dodoc doc/*txt
	newdoc src/withsctp/README README.withsctp

	find "${ED}" -name '*.la' -delete || die
	if ! use static-libs ; then
		find "${ED}" -name "*.a" -delete || die
	fi
}

# vim: filetype=ebuild