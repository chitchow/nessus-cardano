# Build the cardano node Docker image
#
# Several examples for pkgs.dockerTools are here
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix
#
{
  # Pinned packages with Niv
  sources ? import ../../sources.nix,
  haskellNix ? import sources.haskellNix {},
  nixpkgsSrc ? haskellNix.sources.nixpkgs-2009,
  nixpkgsArgs ? haskellNix.nixpkgsArgs,
  pkgs ? import nixpkgsSrc nixpkgsArgs,

  # Required image architecture
  imageArch,

  # Required version args
  cardanoVersion,
  nessusRevision,
  cabalVersion,
  ghcVersion,

  libsodium ? import ../../libsodium {},
  cardano ? import ../../cardano { inherit cardanoVersion nessusRevision cabalVersion ghcVersion; },
  gLiveView ? import ../../gLiveView { inherit cardanoVersion nessusRevision; },
}:

let

  imageName = "nessusio/cardano-node";

  # The configs for the given cardano-node version
  # mainnet-config = builtins.fetchurl "https://raw.githubusercontent.com/input-output-hk/cardano-node/${cardanoVersion}/configuration/cardano/mainnet-config.json";
  mainnet-topology = builtins.fetchurl "https://raw.githubusercontent.com/input-output-hk/cardano-node/${cardanoVersion}/configuration/cardano/mainnet-topology.json";
  byron-genesis = builtins.fetchurl "https://raw.githubusercontent.com/input-output-hk/cardano-node/${cardanoVersion}/configuration/cardano/mainnet-byron-genesis.json";
  shelley-genesis = builtins.fetchurl "https://raw.githubusercontent.com/input-output-hk/cardano-node/${cardanoVersion}/configuration/cardano/mainnet-shelley-genesis.json";

  # Custom mainnet-config.json
  mainnet-config = ./context/config/mainnet-config.json;

  # The Docker context with static content
  context = ./context;

  nonRootSetup = { user, uid, gid ? uid }: with pkgs; [
    (
    writeTextDir "etc/shadow" ''
      root:!x:::::::
      ${user}:!:::::::
    ''
    )
    (
    writeTextDir "etc/passwd" ''
      root:x:0:0::/root:${runtimeShell}
      ${user}:x:${toString uid}:${toString gid}::/home/${user}:
    ''
    )
    (
    writeTextDir "etc/group" ''
      root:x:0:
      ${user}:x:${toString gid}:
    ''
    )
    (
    writeTextDir "etc/gshadow" ''
      root:x::
      ${user}:x::
    ''
    )
  ];

  runAsUser = "core";
  runAsUserId = 1000;

in
  pkgs.dockerTools.buildLayeredImage {

    name = imageName;
    tag = "${cardanoVersion}-${nessusRevision}-${imageArch}";

    contents = [
<<<<<<< HEAD

      # Base packages needed by cardano
      pkgs.bashInteractive   # Provide the BASH shell
=======
      pkgs.bashInteractive   # Provide the BASH shell
      pkgs.bc                # An arbitrary precision calculator
>>>>>>> 938c84c... [#33] Run node/tools images as non-root user
      pkgs.cacert            # X.509 certificates of public CA's
      pkgs.coreutils         # Basic utilities expected in GNU OS's
      pkgs.curl              # CLI tool for transferring files via URLs
      pkgs.glibcLocales      # Locale information for the GNU C Library
      pkgs.iana-etc          # IANA protocol and port number assignments
      pkgs.iproute           # Utilities for controlling TCP/IP networking
      pkgs.iputils           # Useful utilities for Linux networking
<<<<<<< HEAD
      pkgs.socat             # Utility for bidirectional data transfer
      pkgs.utillinux         # System utilities for Linux
      libsodium

      # Packages needed on RaspberryPi
      pkgs.numactl           # Tools for non-uniform memory access

      # Packages needed by gLiveView
      pkgs.bc                # An arbitrary precision calculator
      pkgs.gawk              # GNU implementation of the Awk programming language
      pkgs.gnugrep           # GNU implementation of the Unix grep command
      pkgs.jq                # Utility for JSON processing
      pkgs.ncurses           # Free software emulation of curses
      pkgs.netcat            # Networking utility for reading from and writing to network connections
      pkgs.procps            # Utilities that give information about processes using the /proc filesystem
      pkgs.tuptime           # Total uptime & downtime statistics utility
    ];
=======
      pkgs.jq                # Utility for JSON processing
      pkgs.netcat            # Networking utility for reading from and writing to network connections
      pkgs.numactl           # Tools for non-uniform memory access (needed on RaspPi)
      pkgs.procps            # Utilities that give information about processes using the /proc filesystem
      pkgs.socat             # Utility for bidirectional data transfer
      pkgs.utillinux         # System utilities for Linux
      libsodium
    ] ++ nonRootSetup { user = runAsUser; uid = runAsUserId; };

    # Set creation date to build time. Breaks reproducibility
    created = "now";

    # Requires 'system-features = kvm' in /etc/nix/nix.conf
    # https://discourse.nixos.org/t/cannot-build-docker-image/7445
    runAsRoot = ''
      mkdir -p /usr/local/bin
      mkdir -p /opt/cardano/config
      mkdir -p /opt/cardano/data
      mkdir -p /opt/cardano/ipc
      mkdir -p /opt/cardano/logs
      chown -vR ${runAsUser}:${runAsUser} /usr/local/bin
      chown -vR ${runAsUser}:${runAsUser} /opt/cardano

      mkdir -p /tmp
      chmod 777 /tmp
    '';
>>>>>>> 938c84c... [#33] Run node/tools images as non-root user

    # Set creation date to build time. Breaks reproducibility
    created = "now";

    # Requires 'system-features = kvm' in /etc/nix/nix.conf
    # https://discourse.nixos.org/t/cannot-build-docker-image/7445
    # runAsRoot = '' do root stuff '';

    extraCommands = ''

<<<<<<< HEAD
      mkdir -p usr/local/bin
      mkdir -p opt/cardano/config
      mkdir -p opt/cardano/data
      mkdir -p opt/cardano/ipc
      mkdir -p opt/cardano/logs
      mkdir -m 0777 tmp

=======
>>>>>>> 938c84c... [#33] Run node/tools images as non-root user
      # Entrypoint and helper scripts
      cp ${context}/bin/* usr/local/bin

      # Node configurations
      cp ${mainnet-config} opt/cardano/config/mainnet-config.json
      cp ${mainnet-topology} opt/cardano/config/mainnet-topology.json
      cp ${byron-genesis} opt/cardano/config/mainnet-byron-genesis.json
      cp ${shelley-genesis} opt/cardano/config/mainnet-shelley-genesis.json

      # gLiveView scripts
      cp -r ${gLiveView}/cnode-helper-scripts cnode-helper-scripts

      # Create links for executables
      ln -s ${cardano}/bin/cardano-cli usr/local/bin/cardano-cli
      ln -s ${cardano}/bin/cardano-node usr/local/bin/cardano-node
    '';

    config = {
      Env = [
        # Export the default socket path for use by the cli
        "CARDANO_NODE_SOCKET_PATH=/opt/cardano/ipc/node.socket"
        "TMP=/tmp"
      ];
      Entrypoint = [ "entrypoint" ];
    };
  }
