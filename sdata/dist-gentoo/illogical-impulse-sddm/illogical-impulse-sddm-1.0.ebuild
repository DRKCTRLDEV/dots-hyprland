# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse SDDM Display Manager and Sugar Candy Theme"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	x11-misc/sddm
	dev-qt/qtgraphicaleffects:5
	dev-qt/qtquickcontrols2:5
	dev-qt/qtsvg:5
"
