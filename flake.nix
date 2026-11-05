{
  description = "nix-regedit: a registry-editor style GUI for Nix flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      crane,
      ...
    }:
    let
      binaryInfo =
        if builtins.pathExists ./binary-url.json then
          builtins.fromJSON (builtins.readFile ./binary-url.json)
        else
          null;

      desktopPostInstall =
        if builtins.pathExists ./nix-regedit.desktop then
          ''
            install -Dm644 ${./nix-regedit.desktop} "$out/share/applications/nix-regedit.desktop"
          ''
        else
          "";

      mkBinary =
        {
          system,
          tag ? (
            if binaryInfo == null then throw "nix-regedit: binary-url.json is missing" else binaryInfo.latest
          ),
          package ? "nix-regedit",
        }:
        let
          release =
            if binaryInfo == null then
              throw "nix-regedit: binary-url.json is missing"
            else
              binaryInfo.releases.${tag}
                or (throw "nix-regedit: release '${tag}' is not recorded in binary-url.json");
          packageInfo =
            release.packages.${package}
              or (throw "nix-regedit: package '${package}' is not recorded in release '${tag}'");
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.callPackage ./nix/binary.nix {
          name = package;
          inherit (packageInfo) file;
          info = {
            inherit (binaryInfo) repo system;
            inherit (release) tag version;
            inherit (packageInfo) url hash;
          };
          postInstall = desktopPostInstall;
        };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        craneLib = crane.mkLib pkgs;

        runtimePath = lib.makeBinPath (
          with pkgs;
          [
            nix
            nixd
            nixfmt
          ]
        );

        nativeBuildInputs = with pkgs; [
          pkg-config
          wrapGAppsHook4
        ];

        buildInputs = with pkgs; [
          gtk4
          libadwaita
          glib
        ];

        commonArgs = {
          pname = "nix-regedit";
          version = "0.1.0";
          src = lib.cleanSource ./.;
          inherit nativeBuildInputs buildInputs;
          doCheck = false;
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        nix-regedit = craneLib.buildPackage (
          commonArgs
          // {
            inherit cargoArtifacts;

            preFixup = ''
              gappsWrapperArgs+=(--prefix PATH : "${runtimePath}")
            '';

            postInstall = ''
              install -Dm644 ${./nix-regedit.desktop} \
                "$out/share/applications/nix-regedit.desktop"
            '';

            meta = with lib; {
              description = "A registry-editor style GUI for Nix flakes";
              mainProgram = "nix-regedit";
              license = licenses.gpl3Plus;
              platforms = platforms.linux;
            };
          }
        );
      in
      {
        packages = {
          inherit nix-regedit;
          default = nix-regedit;
        }
        // lib.optionalAttrs (binaryInfo != null && binaryInfo.system == system) {
          nix-regedit-binary = mkBinary { inherit system; };
        };

        apps.default = {
          type = "app";
          program = "${nix-regedit}/bin/nix-regedit";
        };

        checks.default = nix-regedit;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs =
            nativeBuildInputs
            ++ (with pkgs; [
              cargo
              rustc
              rustfmt
              clippy
              rust-analyzer
              mold
            ]);

          buildInputs =
            buildInputs
            ++ (with pkgs; [
              nix
              nixd
              nixfmt
            ]);

          RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
          RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
        };
      }
    )
    // {
      lib.mkBinary = mkBinary;
      nixosModules.default = import ./modules/nixos.nix self;
      nixosModules.nix-regedit = import ./modules/nixos.nix self;
    };
}
