EAPI=8

DESCRIPTION="Namecheap Dynamic DNS Client"
HOMEPAGE="https://github.com/dmitrodem/namecheap-client.git"

inherit git-r3 meson vala
EGIT_REPO_URI="https://github.com/dmitrodem/namecheap-client.git"

LICENSE="GPL"
SLOT="0"
KEYWORDS=""

BDEPEND="dev-util/meson
		$(vala_depend)"

DEPEND="dev-libs/glib:2
		net-libs/libsoup:2.4
		dev-libs/libxml2:2"

RDEPEND="${DEPEND}"

src_prepare() {
	vala_setup
	default
}
