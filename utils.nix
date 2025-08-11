{
  callPiaWithDeps =
    pkgs:
    import ./package.nix {
      inherit (pkgs)
        stdenv
        lib
        qt6
        makeWrapper
        xterm
        openssl
        libnl
        libnsl
        libatomic_ops
        fetchurl
        autoPatchelfHook
        libcap_ng
        bash
        libxkbcommon
        psmisc
        makeDesktopItem
        iptables
        iproute2
        gawk
        mount
        systemd
        openresolv
        util-linux
        coreutils
        ;
      wrapQtAppsHook = pkgs.qt6.wrapQtAppsHook;
    };
}
