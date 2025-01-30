#!/bin/bash
# Authors: Daniele Rondina
# Macaroni OS patches for Funtoo

# Fix zziplib to use python3+
rm -rf /var/git/meta-repo/kits/dev-kit/dev-libs/zziplib/
cp -rvf patches/zziplib/ /var/git/meta-repo/kits/dev-kit/dev-libs/

# Permits compilation of qt-webkit with ruby3.1
sed -i -e 's|^USE_RUBY=.*|USE_RUBY="ruby25 ruby26 ruby27 ruby31"|g' \
  /var/git/meta-repo/kits/qt-kit/dev-qt/qtwebkit/qtwebkit-*.ebuild

# ibus upgraded and available on geaaru-kit. TODO: open a PR to Funtoo

# xorg-server with wayland support available on geaaru-kit. TODO: open a PR to Funtoo
# after testing solution.

# Fix wrong DEPEND on source-hightlight
sed -i -e 's|>=dev-libs/boost-1.62.0\:=\[threads\]|dev-libs/boost|g' \
  /var/git/meta-repo/kits/dev-kit/dev-util/source-highlight/source-highlight-*.ebuild

# Fix typo on x11-base/xorg-drivers ebuild
sed -i -e 's|xf86-video-vboxvideo|xf86-video-vbox|g' \
  /var/git/meta-repo/kits/core-gl-kit/x11-base/xorg-drivers/xorg-drivers-*.ebuild

# Permit using vala 0.54
sed -i -e 's|0.50|0.54|g' \
  /var/git/meta-repo/kits/core-kit/eclass/vala.eclass

# Drop pam/elogind dependencies cross referencies
sed -i -e 's|elogind? ( .* )||g' -e 's|elogind||g' \
  /var/git/meta-repo/kits/core-kit/sys-libs/pam/pam-*.ebuild

sed -i -e '/sys-libs\/pam\[elogind\]/d' \
  /var/git/meta-repo/kits/core-gl-kit/x11-base/xorg-server/xorg-server-*.ebuild

# Using vala 0.54 seems break media-video/cheese that requires
# a new release
cp -vf patches/cheese/* /var/git/meta-repo/kits/gnome-kit/media-video/cheese/
cd /var/git/meta-repo/kits/gnome-kit/media-video/cheese/
ebuild cheese-44.1.ebuild digest && \
cd -

# Add missing patch for upnp on media-video/vlc
cp -vf patches/vlc/vlc-2.2.8-libupnp-slot-1.8.patch \
  /var/git/meta-repo/kits/media-kit/media-video/vlc/files/

# Fix installation of nmap with linear is been compiled with
# blas used flag.
# The patch add blas IUSE and patch configure.ac to
# fix linking with -lblas.
cp -vf patches/nmap/*.ebuild \
  /var/git/meta-repo/kits/net-kit/net-analyzer/nmap/

# Update libmediaart to fix compilation of rygel
cp -vf patches/libmediaart/* /var/git/meta-repo/kits/gnome-kit/media-libs/libmediaart/
cd /var/git/meta-repo/kits/gnome-kit/media-libs/libmediaart/ && \
ebuild libmediaart-1.9.6-r1.ebuild digest && \
cd -

# Update rygel to compile with new vala (upgrade to release v0.40.4)
cp -vf patches/rygel/* /var/git/meta-repo/kits/gnome-kit/net-misc/rygel/
cd /var/git/meta-repo/kits/gnome-kit/net-misc/rygel && \
ebuild rygel-0.40.4.ebuild digest && \
cd -

# Patch geary to fix compilation with vala-0.54. It seems missing
# the DEPEND libpaes too.
mkdir -p /etc/portage/patches/mail-client/geary/ && \
cp -vf patches/geary/geary_*.patch /etc/portage/patches/mail-client/geary/

# Upgrade mailutils (with patch to compile without autoconf-2.71)
cp -vf patches/mailutils/mailutils-3.16.ebuild /var/git/meta-repo/kits/net-kit/net-mail/mailutils && \
cd /var/git/meta-repo/kits/net-kit/net-mail/mailutils/ && \
ebuild mailutils-3.16.ebuild digest && \
cd -

# Upgrade gnome-music (continue to have the same issue)
cd /var/git/meta-repo/kits/gnome-kit/media-sound/gnome-music && \
cp -vf gnome-music-3.36.6.ebuild gnome-music-3.36.7.ebuild && \
ebuild gnome-music-3.36.7.ebuild digest && \
cd -

# Patch for irda-utils about error: ‘SIOCGSTAMP’ undeclared
cp -vf patches/irda-utils/irda-utils-0.9.18-r6.ebuild /var/git/meta-repo/kits/net-kit/net-wireless/irda-utils && \
mkdir -p /etc/portage/patches/net-wireless/irda-utils && \
cp -vf patches/irda-utils/files/irdadump.patch /etc/portage/patches/net-wireless/irda-utils/


# Patch dconf-editor (upgrade to 3.36.7 and fix vala integration)
cd /var/git/meta-repo/kits/gnome-kit/gnome-base/dconf-editor && \
cp -vf dconf-editor-3.36.0.ebuild dconf-editor-3.36.7.ebuild && \
ebuild dconf-editor-3.36.7.ebuild digest && \
cd -
mkdir -p /etc/portage/patches/gnome-base/dconf-editor/ &&
cp -vf patches/dconf-editor/dconf-editor_fdc90849223649509424bbefe14990de71db2b2b.patch \
  /etc/portage/patches/gnome-base/dconf-editor/

# Upgrade grsync to v1.3.1 with gtk+:3 support
cp -vf patches/grsync/grsync-1.3.1.ebuild /var/git/meta-repo/kits/desktop-kit/x11-misc/grsync
cd /var/git/meta-repo/kits/desktop-kit/x11-misc/grsync && \
ebuild grsync-1.3.1.ebuild digest && \
cd -

# Permit to compile gnome-calculator with vala 0.54
sed -i -e 's|^VALA_MAX_API_VERSION.*|VALA_MAX_API_VERSION=0.54|g' \
  /var/git/meta-repo/kits/gnome-kit/gnome-extra/gnome-calculator/gnome-calculator-3.36.0.ebuild

# Fix compilation of gnote with GCC 11.3
cp -vf patches/gnote/gnote-3.36.2.ebuild /var/git/meta-repo/kits/gnome-kit/app-misc/gnote/

# unoconv has a missing virtual deps virtual/ooo no more available
sed -i '/virtual\/ooo/d' /var/git/meta-repo/kits/desktop-kit/app-office/unoconv/unoconv-*.ebuild

# patch gnome-clocks for vala-0.54
mkdir -p /etc/portage/patches/gnome-extra/gnome-clocks/ && \
cp -vf patches/gnome-clocks/gnome-clocks-vala-0.54.patch /etc/portage/patches/gnome-extra/gnome-clocks/

# patch gnome-taquin for vala-0.54
mkdir -p /etc/portage/patches/games-puzzle/gnome-taquin && \
cp -vf patches/gnome-taquin/taquin_*.patch /etc/portage/patches/games-puzzle/gnome-taquin/

# patch swell-foop for vala-0.54
cp -vf patches/swell-foop/swell-foop-3.34.1.ebuild /var/git/meta-repo/kits/gnome-kit/games-puzzle/swell-foop/

# patch games-board/iagno for vala-0.54
mkdir -p /etc/portage/patches/games-board/iagno/ && \
cp -vf patches/iagno/iagno_*.patch /etc/portage/patches/games-board/iagno/

# dev-python/greenlet upgrade to v0.4.17 patch for py3.9
cp -vf patches/greenlet/greenlet-0.4.17.ebuild /var/git/meta-repo/kits/python-modules-kit/dev-python/greenlet/
cd /var/git/meta-repo/kits/python-modules-kit/dev-python/greenlet/ && \
ebuild greenlet-0.4.17.ebuild digest && \
cd -

# dev-python/netaddr (to autogen) 

# dev-python/matplotlib (to upgrade)
cp -vf patches/matplotlib/matplotlib-3.6.3.ebuild /var/git/meta-repo/kits/python-modules-kit/dev-python/matplotlib/
cd /var/git/meta-repo/kits/python-modules-kit/dev-python/matplotlib/ && \
ebuild matplotlib-3.6.3.ebuild digest && \
cd -

# dev-python/pillow (to upgrade)
cp -vf patches/pillow/pillow-10.0.1.ebuild  /var/git/meta-repo/kits/python-modules-kit/dev-python/pillow/
cd /var/git/meta-repo/kits/python-modules-kit/dev-python/pillow/ && \
ebuild pillow-10.0.1.ebuild digest && \
cd -

# Patch docker-slim
cp -vf package/docker-slim/docker-slim-1.40.3.ebuild /var/git/meta-repo/kits/core-kit/app-emulation/docker-slim/

# Packages missing on Next (but available on 1.4 needed for xfce and other)
# Temporary I will add these packages on geaaru-overlay
# media-libs/vo-aacenc
# media-libs/libbs2b
# media-libs/t1lib
# media-libs/libopenraw
# media-libs/libtiger
# media-vidoe/vcdimager (needed for k3b[vcd])
#
# Deps of media-video/kino packages are missing

# Patch rlottie for gcc11
cp patches/rlottie/rlottie-0.2.ebuild /var/git/meta-repo/kits/media-kit/media-libs/rlottie/

# Drop packagekit from kde-frameworks/frameworkintegration
sed -i -e '/app-admin\/packagekit-qt/d' \
  /var/git/meta-repo/kits/kde-kit/kde-frameworks/frameworkintegration/*.ebuild

# Patch for gnome-weather (following gnome-weather issue #127)
mkdir -p /etc/portage/patches/gnome-extra/gnome-weather/ && \
cp patches/gnome-weather/*.patch /etc/portage/patches/gnome-extra/gnome-weather/

# Patch qt5-build.eclass to fix compilation of qdbus package.
# (need rebuild of qtcore and qtdbus)
cp patches/eclass/qt5-build.patch /tmp/ && \
cd /var/git/meta-repo/kits/core-kit/eclass/ && \
patch -p1 < /tmp/qt5-build.patch && \
cd -

# Permit to compile simple-scan with vala 0.54
sed -i -e 's|^VALA_MAX_API_VERSION.*|VALA_MAX_API_VERSION=0.54|g' \
  /var/git/meta-repo/kits/gnome-kit/media-gfx/simple-scan/simple-scan-3.36.6.ebuild

# Fix slot dependency of app-text/libetonyek package
sed -i -e 's|^MDDS_VER.*|MDDS_VER=\"2.1\"|g' \
  /var/git/meta-repo/kits/text-kit/app-text/libetonyek/libetonyek-0.1.10.ebuild

# Add patch for net-vpn/networkmanager-vpnc
cp -vf patches/networkmanager-vpnc/networkmanager-vpnc-1.2.6.ebuild \
  /var/git/meta-repo/kits/net-kit/net-vpn/networkmanager-vpnc/

# Add patch for dev-libs/redlang
cp -vf patches/redland/redland-1.0.17-r2.ebuild /var/git/meta-repo/kits/dev-kit/dev-libs/redland/

# Add patch (no more available on funtoo)
cp -vf patches/spice-gtk/spice-gtk-0.42.ebuild /var/git/meta-repo/kits/net-kit/net-misc/spice-gtk/ 
cd /var/git/meta-repo/kits/net-kit/net-misc/spice-gtk/ && \
ebuild spice-gtk-0.42.ebuild digest && \
cd -

# ephoto needs a patch on autogen template. nls use flags is no more available.

# dev-util/ostree to upgrade at release 2023.5 (fix compilation issues) or must be replaced
# by libostree package.

# patch for networkmanager-fortisslvpn

# patch libmemcached to avoid installation of autoconf:1.13

# patch espeak-ng

# patch media-libs/quirc (needed for opencv)

# patch dev-libs/flatbuffers

# Avoid dep cycle - FL-11821
sed -i -e '/^DISTUTILS_USE_PEP517.*/d' \
/var/git/meta-repo/kits/python-modules-kit/dev-python/packaging/packaging-*.ebuild

