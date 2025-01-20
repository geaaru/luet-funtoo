# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual to select between different resolvconf providers"
SLOT="0"
KEYWORDS="*"

RDEPEND="|| ( net-dns/openresolv sys-apps/systemd )"
