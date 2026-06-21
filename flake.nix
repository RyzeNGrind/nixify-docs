{
  description = "nixify-docs — public documentation surface for the (private) nixify std+hive monorepo";

  # Single input by design: this is a docs flake, not infra. `nix develop`
  # generates flake.lock on first use.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAll = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # Phase B: `nix build .#docs` renders the mdBook site into ./result.
      packages = forAll (system:
        let pkgs = pkgsFor system; in {
          docs = pkgs.stdenv.mkDerivation {
            pname = "nixify-docs";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [ pkgs.mdbook ];
            buildPhase = "mdbook build -d $out";
            dontInstall = true;
          };
          default = self.packages.${system}.docs;
        });

      devShells = forAll (system:
        let pkgs = pkgsFor system; in {
          default = pkgs.mkShell {
            packages = [ pkgs.mdbook pkgs.git ];
            shellHook = ''
              echo "nixify-docs devshell"
              echo "  mdbook serve docs   # live preview at http://localhost:3000"
              echo "  scripts/leak-scan.sh  # MUST pass before pushing main"
            '';
          };
        });

      # `nix flake check` runs the secret/topology leak gate.
      checks = forAll (system:
        let pkgs = pkgsFor system; in {
          leak-scan = pkgs.runCommand "leak-scan" { } ''
            cp -r ${./.} src && cd src
            ${pkgs.bash}/bin/bash scripts/leak-scan.sh
            touch $out
          '';
        });
    };
}
