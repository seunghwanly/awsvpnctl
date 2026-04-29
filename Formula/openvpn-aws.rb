# OpenVPN 2.6.12 with AWS Client VPN's auth-federate (SAML) patch.
# Builds against system openssl@3 (samm-git's openssl@1.1 path is dead since
# Homebrew dropped that formula).
class OpenvpnAws < Formula
  desc "OpenVPN with AWS Client VPN SAML federated auth (auth-federate)"
  homepage "https://github.com/samm-git/aws-vpn-client"
  url "https://github.com/OpenVPN/openvpn/archive/refs/tags/v2.6.12.tar.gz"
  sha256 "cbca5e13b2b1c4de5ef0361d37c44b5e97e8654948f80d95ca249b474108d4c0"
  version "2.6.12-aws"
  license "GPL-2.0-only" => { with: "openvpn-openssl-exception" }

  patch do
    url "https://raw.githubusercontent.com/samm-git/aws-vpn-client/master/openvpn-v2.6.12-aws.patch"
    sha256 "561f0887a7043452cff55f3140539f18c7a63e914343047c98f82a121f356457"
  end

  depends_on "autoconf"      => :build
  depends_on "automake"      => :build
  depends_on "docutils"      => :build  # provides rst2man for man pages (GitHub source archive lacks prebuilt ones)
  depends_on "libtool"       => :build
  depends_on "pkg-config"    => :build
  depends_on "lz4"
  depends_on "lzo"
  depends_on "openssl@3"
  depends_on "pkcs11-helper"

  def install
    # GitHub source archive lacks a configure script; bootstrap autotools.
    system "autoreconf", "-i", "-v", "-f"
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
