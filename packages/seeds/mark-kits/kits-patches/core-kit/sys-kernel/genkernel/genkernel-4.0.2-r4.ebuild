# Distributed under the terms of the GNU General Public License v2

EAPI="3"

VERSION_BUSYBOX='1.21.1'
VERSION_DMRAID='1.0.0.rc16-3'
VERSION_MDADM='3.1.5'
VERSION_E2FSPROGS='1.42'
VERSION_FUSE='2.8.6'
VERSION_ISCSI='2.0.877'
VERSION_UNIONFS_FUSE='0.24'
VERSION_GPG='1.4.11'

MY_HOME="mirror://funtoo/${PN}"
RH_HOME="ftp://sources.redhat.com/pub"
DM_HOME="http://people.redhat.com/~heinzm/sw/dmraid/src"
BB_HOME="http://www.busybox.net/downloads"

COMMON_URI="mirror://funtoo/dmraid-${VERSION_DMRAID}.tar.bz2
		mirror://funtoo/busybox-${VERSION_BUSYBOX}.tar.bz2
		https://github.com/open-iscsi/open-iscsi/archive/${VERSION_ISCSI}.tar.gz -> open-iscsi-${VERSION_ISCSI}.tar.gz
		mirror://funtoo/e2fsprogs-${VERSION_E2FSPROGS}.tar.gz
		mirror://funtoo/fuse-${VERSION_FUSE}.tar.gz
		mirror://funtoo/unionfs-fuse-${VERSION_UNIONFS_FUSE}.tar.bz2
		mirror://funtoo/gnupg-${VERSION_GPG}.tar.bz2"

GITHUB_REPO="${PN}"
GITHUB_USER="funtoo"
GITHUB_TAG="29204cbbf64a14bbbd10df3ea6b8a373d5a66e13"

inherit bash-completion-r1 eutils
SRC_URI="https://www.github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/${GITHUB_TAG} -> ${PN}-${GITHUB_TAG}.tar.gz ${COMMON_URI}"
KEYWORDS="*"

DESCRIPTION="Gentoo automatic kernel building scripts"
HOMEPAGE="http://www.gentoo.org"

LICENSE="GPL-2"
SLOT="0"
RESTRICT="mirror"
IUSE="lvm btrfs cryptsetup ibm selinux"

DEPEND="sys-fs/e2fsprogs
	selinux? ( sys-libs/libselinux )"
RDEPEND="${DEPEND}
		btrfs? ( sys-fs/btrfs-progs )
		cryptsetup? ( sys-fs/cryptsetup[static] )
		lvm? ( sys-fs/lvm2[static] )
		sys-fs/mdadm[static]
		app-misc/pax-utils
		!<sys-apps/openrc-0.9.9"

src_prepare() {
	cd "${WORKDIR}"/${GITHUB_USER}-${PN}-*
	S="$(pwd)"
	#use selinux && sed -i 's/###//g' "${S}"/gen_compile.sh || die
	sed -i -e "s/##VERSION##/${PV}/" "${S}"/genkernel || die
	mkdir patches/busybox/1.21.1/
	cp "${FILESDIR}"/busybox-1.21.1-glibc.patch patches/busybox/1.21.1/
	epatch "${FILESDIR}"/initramfs.patch
	for modfile in $(find ${S} -name modules_load); do
		sed -i -e '/MODULES_FS/s/"$/ squashfs overlay hfsplus isofs udf loop nls_utf8"/' \
			-e '/MODULES_CRYPTO/s/"$/ algif_skcipher af_alg crc32_generic"/' ${modfile}
	done
}

src_compile() {
	return
}

src_compile() {
	if [[ ${PV} == 9999* ]]; then
		emake || die
	fi
}

src_install() {
	# This block updates genkernel.conf
	sed \
		-e "s:VERSION_BUSYBOX:$VERSION_BUSYBOX:" \
		-e "s:VERSION_MDADM:$VERSION_MDADM:" \
		-e "s:VERSION_DMRAID:$VERSION_DMRAID:" \
		-e "s:VERSION_E2FSPROGS:$VERSION_E2FSPROGS:" \
		-e "s:VERSION_FUSE:$VERSION_FUSE:" \
		-e "s:VERSION_ISCSI:$VERSION_ISCSI:" \
		-e "s:VERSION_UNIONFS_FUSE:$VERSION_UNIONFS_FUSE:" \
		-e "s:VERSION_GPG:$VERSION_GPG:" \
		"${S}"/genkernel.conf > "${T}"/genkernel.conf \
		|| die "Could not adjust versions"
	insinto /etc
	doins "${T}"/genkernel.conf || die "doins genkernel.conf"

	doman genkernel.8 || die "doman"
	dodoc AUTHORS ChangeLog README TODO || die "dodoc"

	dobin genkernel || die "dobin genkernel"

	rm -f genkernel genkernel.8 AUTHORS ChangeLog README TODO genkernel.conf

	insinto /usr/share/genkernel
	doins -r "${S}"/* || die "doins"
	use ibm && cp "${S}"/ppc64/kernel-2.6-pSeries "${S}"/ppc64/kernel-2.6 || \
		cp "${S}"/arch/ppc64/kernel-2.6.g5 "${S}"/arch/ppc64/kernel-2.6

	# Copy files to /usr/share/genkernel/src
	elog "Copying files to /usr/share/genkernel/src..."
	mkdir -p "${D}"/usr/share/genkernel/src
	cp -f \
		"${DISTDIR}"/dmraid-${VERSION_DMRAID}.tar.bz2 \
		"${DISTDIR}"/e2fsprogs-${VERSION_E2FSPROGS}.tar.gz \
		"${DISTDIR}"/busybox-${VERSION_BUSYBOX}.tar.bz2 \
		"${DISTDIR}"/fuse-${VERSION_FUSE}.tar.gz \
		"${DISTDIR}"/unionfs-fuse-${VERSION_UNIONFS_FUSE}.tar.bz2 \
		"${DISTDIR}"/gnupg-${VERSION_GPG}.tar.bz2 \
		"${DISTDIR}"/open-iscsi-${VERSION_ISCSI}.tar.gz \
		"${D}"/usr/share/genkernel/src || die "Copying distfiles..."

	newbashcomp "${FILESDIR}"/genkernel.bash "${PN}"
	insinto /etc
	doins "${FILESDIR}"/initramfs.mounts
}
