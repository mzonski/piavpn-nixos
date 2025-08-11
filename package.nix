{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  qt6,
  autoPatchelfHook,
  wrapQtAppsHook ? qt6.wrapQtAppsHook,
  libcap_ng,
  bash,
  libnl,
  iptables,
  xterm,
  libnsl,
  libatomic_ops,
  libxkbcommon,
  psmisc,
  makeDesktopItem,
  installOutDir ? "$out/opt/piavpn",
  iproute2,
  gawk,
  mount,
  systemd,
  openresolv,
  util-linux,
  coreutils,
  ...
}:
stdenv.mkDerivation rec {
  pname = "piavpn";
  version = "3.6.2-08398";

  src = fetchurl {
    url = "https://installers.privateinternetaccess.com/download/pia-linux-${version}.run";
    sha256 = "sha256-xRNyHkLnB6X+8DxEgKMB/VQlUco1e9UgUyOslCHfr/0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
    qt6.qt3d
    qt6.qtquicktimeline
    qt6.qtvirtualkeyboard
    qt6.qtlottie
    qt6.qtscxml
    libcap_ng

    bash

    libxkbcommon
    libnl.out
    libnsl.out
    iptables
    psmisc
    libatomic_ops
    xterm
    iproute2
  ];

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "Private Internet Access (PIA)";
      comment = "Private Internet Access VPN client";
      exec = "XDG_SESSION_TYPE=X11 ${passthru.piaOptDir}/bin/pia-client %u";
      icon = pname;
      terminal = false;
      categories = [ "Network" ];
      keywords = [
        "pia"
        "vpn"
      ];
      startupWMClass = "pia-client";
      mimeTypes = [ "x-scheme-handler/piavpn" ];
    })
  ];

  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    sh $src --target . --noexec --keep

    runHook postUnpack
  '';

  passthru = {
    groupName = pname;
    libDir = "${installOutDir}/lib";
    piaOptDir = "/opt/piavpn";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p ${installOutDir}
    cp -a ./piafiles/* ${installOutDir}
    cp -a ./installfiles/app-icon.png ${installOutDir}/lib
    mkdir -p $out/share/icons/hicolor/128x128/apps
    ln -s ${installOutDir}/lib $out/share/icons/hicolor/128x128/apps/piavpn.png

    for binary in pia-client pia-daemon pia-hnsd pia-openvpn pia-ss-local pia-support-tool pia-unbound pia-wireguard-go piactl support-tool-launcher; do
      makeWrapper ${installOutDir}/bin/$binary ${installOutDir}/bin/$binary-wrapped \
        --prefix PATH : "${
          lib.makeBinPath [
            iptables
            psmisc
            iproute2
            gawk
            mount
            systemd
            openresolv
            util-linux
            coreutils
          ]
        }" \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            installOutDir
            libxkbcommon
            libnl.out
            libnsl.out
          ]
        }"
    done


    substituteInPlace ${installOutDir}/bin/openvpn-updown.sh \
      --replace "/usr/bin/busctl" "${systemd}/bin/busctl"

    mkdir -p $out/bin

    for binary in piactl pia-client; do
      ln -s ${installOutDir}/bin/$binary-wrapped $out/bin/$binary
    done

    runHook postInstall
  '';

  meta = {
    description = "Private Internet Access (PIA) VPN client";
    homepage = "https://www.privateinternetaccess.com/";
    license = lib.licenses.unfree;
    maintainers = [ "Zonni" ];
    platforms = [ "x86_64-linux" ];
  };
}
