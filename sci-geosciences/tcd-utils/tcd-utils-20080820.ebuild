# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="Utiliies for working with Tidal Constituent Databases."
HOMEPAGE="http://www.flaterco.com/xtide/"
SRC_URI="ftp://ftp.flaterco.com/xtide/${P}.tar.bz2"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=">=sci-geosciences/libtcd-2.2.4"
RDEPEND="${DEPEND}"


src_install() {
	emake install DESTDIR="${D}" || die "emake install failed"
}
