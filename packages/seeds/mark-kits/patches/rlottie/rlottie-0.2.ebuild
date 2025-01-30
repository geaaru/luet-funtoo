# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson

DESCRIPTION="A platform independent standalone library that plays Lottie Animations"
HOMEPAGE="https://github.com/Samsung/rlottie"
SRC_URI="https://api.github.com/repos/Samsung/rlottie/tarball/v0.2 -> rlottie-0.2.tar.gz"

LICENSE="BSD FTL JSON MIT"
SLOT="0/0.2"
KEYWORDS="*"
IUSE="debug test"

RESTRICT="!test? ( test )"

DEPEND="test? ( dev-cpp/gtest )"

fix_src_dirs() {
	pushd "${WORKDIR}"
	mv Samsung-rlottie-* rlottie-0.2
	popd
}

src_unpack() {
	default
	fix_src_dirs
}

src_configure() {

	# Fix compilation with gcc11
	sed -i -e "s|^#include <cstring>.*|#include <cstring>\n#include <limits>|g" \
		src/vector/vrle.cpp

	local emesonargs=(
		-D cache=true
		-D module=true
		-D thread=true

		-D cmake=false
		-D example=false

		$(meson_use debug dumptree)
		$(meson_use debug log)
		$(meson_use test)
	)

	meson_src_configure
}

src_test() {
	cd "${BUILD_DIR}" || die "Failed to switch into BUILD_DIR."
	eninja test
}
