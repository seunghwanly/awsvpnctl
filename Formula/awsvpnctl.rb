class Awsvpnctl < Formula
  desc "macOS AWS Client VPN SAML SSO controller"
  homepage "https://github.com/seunghwanly/awsvpnctl"
  url "https://github.com/seunghwanly/awsvpnctl.git",
      tag:      "v0.1.0",
      revision: "89f89bece10c7642a566f204a9b97ffc6a759bb2"
  license :cannot_represent

  depends_on "python@3.14"
  depends_on "seunghwanly/awsvpnctl/openvpn-aws"

  def install
    libexec.install "bin", "docs", "etc", "Formula", "hammerspoon", "install.sh", "share"

    (etc/"awsvpnctl/profiles").mkpath
    (var/"run/awsvpnctl").mkpath
    (var/"log/awsvpnctl").mkpath

    env = {
      AWSVPNCTL_ROOT:        opt_libexec,
      AWSVPNCTL_BIN:         opt_bin/"awsvpnctl",
      AWSVPNCTL_CONFIG_DIR:  etc/"awsvpnctl",
      AWSVPNCTL_RUN_DIR:     var/"run/awsvpnctl",
      AWSVPNCTL_LOG_DIR:     var/"log/awsvpnctl",
      AWSVPNCTL_SUDO_RUNNER: opt_libexec/"bin/aws-vpn-sudo-runner",
      AWSVPNCTL_NO_PATH:     "1",
    }

    (bin/"awsvpnctl").write_env_script libexec/"bin/awsvpnctl", env

    install_env = env.merge(HOMEBREW_PREFIX: HOMEBREW_PREFIX)
    (bin/"awsvpnctl-install").write_env_script libexec/"install.sh", install_env
  end

  def caveats
    <<~EOS
      Finish setup after installing:
        awsvpnctl-install
        awsvpnctl setup
        awsvpnctl doctor

      Put AWS Client VPN .ovpn files in ~/Downloads, or pass one directly:
        awsvpnctl setup ~/Downloads/downloaded-client-config.ovpn

      Connect manually:
        awsvpnctl connect dev

      Or trigger auto-connect after AWS SSO login:
        aws sso login --sso-session <name>

      Local files are stored outside the Cellar:
        profiles: #{etc}/awsvpnctl/profiles
        config:   #{etc}/awsvpnctl/config.json
        logs:     #{var}/log/awsvpnctl
        state:    #{var}/run/awsvpnctl
    EOS
  end

  test do
    system bin/"awsvpnctl", "list"
  end
end
