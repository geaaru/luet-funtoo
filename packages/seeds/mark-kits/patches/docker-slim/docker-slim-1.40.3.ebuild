# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit go-module

go-module_set_globals

SRC_URI="https://github.com/slimtoolkit/docker-slim/tarball/155f1b79556b7d100726f5ef4633f81a6ed27a2b -> docker-slim-1.40.3-155f1b7.tar.gz"

DESCRIPTION="Make your containers better, smaller, more secure and do less to get there"
HOMEPAGE="https://dockersl.im/ https://github.com/docker-slim/docker-slim"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

post_src_unpack() {
	mv "${WORKDIR}"/slimtoolkit-* "${S}" || die
}

src_compile() {
	BUILD_TIME="$(date -u '+%Y-%m-%d_%I:%M:%S%p')"

	LD_FLAGS="-s -w \
		-X github.com/docker-slim/docker-slim/pkg/version.appVersionTag=${PV} \
		-X github.com/docker-slim/docker-slim/pkg/version.appVersionRev=current \
		-X github.com/docker-slim/docker-slim/pkg/version.appVersionTime=${BUILD_TIME}"

	CGO_ENABLED=0 go generate github.com/docker-slim/docker-slim/pkg/appbom

	for cmd_name in slim{,-sensor}; do
		CGO_ENABLED=0 go build -ldflags="${LD_FLAGS}" -trimpath -a -tags 'netgo osusergo' -mod=vendor ./cmd/${cmd_name} || die "compile failed"
	done
}

src_install() {
	for cmd_name in slim{,-sensor}; do
		dobin ${cmd_name}
	done

	dodoc README.md
}
