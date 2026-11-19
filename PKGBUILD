# Maintainer: sukkergris
pkgname=hk-tui-git
pkgver=r0
pkgrel=1
pkgdesc='Terminal client for Chromecast speakers, e.g. Harman Kardon Citation (unofficial)'
arch=(any)
url='https://github.com/sukkergris/hk-tui'
license=(MIT)
depends=(bash fzf curl iproute2 python python-pychromecast)
makedepends=(git)
provides=(hk-tui)
conflicts=(hk-tui)
source=("git+$url.git")
sha256sums=(SKIP)

pkgver() {
    cd hk-tui
    printf 'r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd hk-tui
    install -Dm755 bin/hk "$pkgdir/usr/bin/hk"
    install -Dm755 bin/hk-cast "$pkgdir/usr/bin/hk-cast"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
