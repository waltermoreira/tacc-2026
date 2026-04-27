{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
    lean-toolchain-nix.url = "github:provables/lean-toolchain-nix";
  };
  outputs = { nixpkgs, flake-utils, shell-utils, lean-toolchain-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shell = shell-utils.myShell.${system};
        lean-toolchain = lean-toolchain-nix.packages.${system}.lean-toolchain-4_30;
        inherit (lean-toolchain-nix.lib.${system}) buildLeanDeps buildLeanPackageFromDeps;

        slidesDeps =
          let
            hashes = {
              "aarch64-darwin" = "";
              "aarch64-linux" = "";
              "x86_64-darwin" = "";
              "x86_64-linux" = "sha256-NKRDTClnkKsjxKLd8ZLviTQndRfL/VjauWNjZ+zcRgE=";
            };
          in
          buildLeanDeps {
            name = "slidesDeps";
            src = ./.;
            outputHash = hashes.${system};
            leanVersion = "4.30.0-rc2";
            buildPhase = ''
              lake build Slides
              lake build generate-slides
              lake exe generate-slides
              rm -rf .lake/packages/MD4Lean/.lake/build/lib
              find .lake -name \*.trace -delete
            '';
          };

        slides = buildLeanPackageFromDeps {
          name = "slides";
          src = ./.;
          leanVersion = "4.30.0-rc2";
          deps = slidesDeps;
          buildInputs = [ pkgs.rsync ];
          phases = [ "unpackPhase" "buildPhase" ];
          buildPhase = ''
            lake exe generate-slides 
            mkdir -p $out
            rsync -a _slides/ $out/
          '';
        };
        python = pkgs.python313.withPackages (ps: [ ps.supervisor ps.ipython ]);
        runner = pkgs.writeShellApplication {
          name = "run-slides";
          text = ''
            ${python}/bin/python -m http.server -d ${slides} 
          '';
        };
      in
      {
        packages = {
          default = slides;
          inherit slides slidesDeps runner;
        };

        apps = {
          default = {
            type = "app";
            program = "${runner}/bin/run-slides";
          };
        };
        devShells = {
          default = shell {
            name = "tacc-2026";
            buildInputs = with pkgs; [
              lean-toolchain
              elan
              go-task
              python
              uv
              findutils
              lsof
            ] ++ lib.optional stdenv.isDarwin apple-sdk_14;
          };
        };
      }
    );
}
