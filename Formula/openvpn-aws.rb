# OpenVPN 2.6.12 with AWS Client VPN's auth-federate (SAML) patch.
# Builds against system openssl@3 (samm-git's openssl@1.1 path is dead since
# Homebrew dropped that formula).
class OpenvpnAws < Formula
  desc "OpenVPN with AWS Client VPN SAML federated auth (auth-federate)"
  homepage "https://github.com/samm-git/aws-vpn-client"
  url "https://swupdate.openvpn.org/community/releases/openvpn-2.6.12.tar.gz"
  sha256 "1c610fddeb686e34f1367c347e027e418e07523a10f4d8ce4a2c2af2f61a1929"
  version "2.6.12-aws"
  revision 1
  license "GPL-2.0-only" => { with: "openvpn-openssl-exception" }

  patch do
    url "https://raw.githubusercontent.com/samm-git/aws-vpn-client/master/openvpn-v2.6.12-aws.patch"
    sha256 "561f0887a7043452cff55f3140539f18c7a63e914343047c98f82a121f356457"
  end

  depends_on "docutils"      => :build  # provides rst2man for man pages
  depends_on "pkg-config"    => :build
  depends_on "lz4"
  depends_on "lzo"
  depends_on "openssl@3"
  depends_on "pkcs11-helper"

  def install
    # The AWS SAML patch expands USER_PASS_LEN only for non-PKCS11 builds.
    # Homebrew's build enables PKCS11, so keep the management command buffer
    # large enough for SAMLResponse payloads there as well.
    inreplace "src/openvpn/misc.h" do |s|
      s.gsub! "#define USER_PASS_LEN 4096", "#define USER_PASS_LEN (1 << 17)"
      s.gsub! "#define USER_PASS_LEN 1 << 17", "#define USER_PASS_LEN (1 << 17)"
    end

    system "./configure",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--with-crypto-library=openssl",
      "--enable-pkcs11",
      "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system sbin/"openvpn", "--show-ciphers"
  end

  def caveats
    <<~EOS
      This installs only the AWS Client VPN-compatible OpenVPN binary.

      For the awsvpnctl CLI, install:
        brew install awsvpnctl
        awsvpnctl setup
        awsvpnctl doctor
    EOS
  end
end
