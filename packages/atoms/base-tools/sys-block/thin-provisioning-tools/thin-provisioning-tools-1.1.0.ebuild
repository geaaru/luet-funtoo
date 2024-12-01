# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cargo llvm

DESCRIPTION="A suite of tools for thin provisioning on Linux"
HOMEPAGE="https://github.com/jthornber/thin-provisioning-tools"
SRC_URI="https://github.com/jthornber/thin-provisioning-tools/tarball/b745ab35057bdd0a4f1406938916621dcf2b7ef6 -> thin-provisioning-tools-1.1.0-b745ab3.tar.gz
https://distfiles.macaronios.org/06/49/9c/06499c89766f70bd2e13a933f82f457460c2867de468b88512669125315adcc0f8adf6185d9763b546932a23ad0f7455abb1157143089825bf691390d37b9e7d -> thin-provisioning-tools-1.1.0-funtoo-crates-bundle-e6bcd5eebd467dfbc838a2d66983434bdfc5c475a529c26b830ec5058fe8c87140d969fc3a1e9f1cb09f13ab09e55e4db2a2aa3f05a8bdd08b6cf875096e1835.tar.gz"


LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"

IUSE="io-uring"

# for io-uring rio create needed to be different than declared in cargo.toml (exactly, from gentoo ebuild: '[rio]=https://github.com/jthornber/rio;2979a720f671e836302c01546f9cc9f7988610c8;rio-%commit%')
# doing block by version and hope, that will be fixed in next release
DEPEND="
	io-uring? ( !!<=sys-block/thin-provisioning-tools-1.0.14 )
	sys-fs/lvm2
"

# bindgen needs libclang.so 

BDEPEND="${RDEPEND}
	virtual/pkgconfig
	>=virtual/rust-1.75
	app-text/asciidoc
	sys-devel/clang
	sys-fs/lvm2
"


PATCHES=(
	"${FILESDIR}/${PN}-1.0.6-build-with-cargo.patch"
)

DOCS=(
	CHANGES
	COPYING
	README.md
	doc/TODO.md
	doc/thinp-version-2/notes.md
)

# Rust
QA_FLAGS_IGNORED="usr/sbin/pdata_tools"


src_unpack() {
	cargo_src_unpack
	rm -rf ${S}
	mv ${WORKDIR}/jthornber-thin-provisioning-tools-* ${S} || die

	# Patch rio library to ignore unused qualifications.
	# Needed for io-uring use flag.
	sed -i -e '/unused_qualifications/d' \
		${WORKDIR}/funtoo-crates-bundle-${PN}/*rio-*/src/lib.rs
}

src_configure() {
	# it look like sys-devel/clang problem or llvm.eclass need update
	export BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS} -I/usr/lib/clang/$(get_llvm_slot)/include"

	local myfeatures=( $(usex io-uring io_uring '') )
	cargo_src_configure
}

src_install() {
	# took from gentoo cargo.eclass:cargo_target_dir function
	cargo_target_dir="${CARGO_TARGET_DIR:-target}/$(usex debug debug release)"

	emake \
		DESTDIR="${D}" \
		DATADIR="${ED}/usr/share" \
		PDATA_TOOLS="${cargo_target_dir}/pdata_tools" \
		install

	einstalldocs
}

# vim: filetype=ebuild ts=4 noet