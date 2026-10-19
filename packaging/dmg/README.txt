AptReceipt
==========

A native macOS app to generate, manage and export apartment income and
expense receipts.

Publisher: Babadogan Tech and Edu
Source:    https://github.com/berkbb/aptreceipt
License:   GNU General Public License v3.0 (see LICENSE.txt)


INSTALLATION
------------

1. Drag "aptreceipt" onto the "Applications" folder in this window.
   When updating, choose "Replace".
2. Eject this disk image.
3. Open AptReceipt from Applications.


FIRST LAUNCH (GATEKEEPER)
-------------------------

AptReceipt is ad-hoc signed and not notarized by Apple, so macOS blocks
the first launch of each downloaded version. Allow it in one of these ways:

- macOS 15 or later: try to open the app once, then go to
  System Settings > Privacy & Security and click "Open Anyway".
- macOS 13-14: right-click the app in Applications, choose "Open",
  then click "Open" again.
- Terminal (any version):

    xattr -dr com.apple.quarantine /Applications/aptreceipt.app

If macOS refuses to open the disk image itself, allow it the same way
in Privacy & Security, or run:

    xattr -d com.apple.quarantine ~/Downloads/aptreceipt-*.dmg


UPDATES
-------

Use "Check for Updates..." in the app menu. AptReceipt downloads the new
disk image to your Downloads folder, verifies its SHA-256 checksum and
opens it. Then repeat the installation steps above.


------------------------------------------------------------------------

KURULUM (TÜRKÇE)
----------------

1. "aptreceipt" uygulamasını bu penceredeki "Applications" klasörüne
   sürükleyin. Güncelleme yapıyorsanız "Değiştir"i seçin.
2. Disk görüntüsünü çıkarın.
3. AptReceipt'i Uygulamalar klasöründen açın.

İLK AÇILIŞ (GATEKEEPER)

AptReceipt ad-hoc imzalıdır ve Apple tarafından notarize edilmemiştir.
Bu yüzden macOS indirilen her sürümün ilk açılışını engeller:

- macOS 15 ve sonrası: Uygulamayı bir kez açmayı deneyin, ardından
  Sistem Ayarları > Gizlilik ve Güvenlik bölümünde "Yine de Aç"a tıklayın.
- macOS 13-14: Uygulamaya sağ tıklayıp "Aç"ı seçin ve onaylayın.
- Terminal (tüm sürümler):

    xattr -dr com.apple.quarantine /Applications/aptreceipt.app

macOS disk görüntüsünün kendisini açmayı reddederse aynı şekilde
Gizlilik ve Güvenlik'ten izin verin veya şunu çalıştırın:

    xattr -d com.apple.quarantine ~/Downloads/aptreceipt-*.dmg
