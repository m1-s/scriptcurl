{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  # TODO improve upstream instead
  inputs.shellnium.url = "github:m1-s/shellnium?ref=addChromiumLogging";
  inputs.shellnium.flake = false;

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, shellnium }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };

        apps.default =
          let
            binPath = pkgs.lib.makeBinPath (
              with pkgs;[ chromedriver chromium curl jq coreutils gnused gnugrep ]
            );
            script = pkgs.writeShellScriptBin "scriptcurl" ''
              export PATH=${binPath}
              set -e

              TARGET_URL="$1"
              SCRIPT="$2"
              USER_DIR=$(mktemp -d)
              # override $@ with arguments for shellnium
              set -- --headless --user-data-dir="$USER_DIR"

              function onExit(){
                set +e
                kill -9 $PID
              }

              trap onExit EXIT
              ${pkgs.chromedriver}/bin/chromedriver >/dev/null &
              PID=$!

              cd ${shellnium}
              source ./lib/selenium.sh

              navigate_to "$TARGET_URL"
              exec_script "$SCRIPT" "" > /dev/null
              cat "$USER_DIR/Default/chrome_debug.log" | grep "CONSOLE"
            '';
          in

          flake-utils.lib.mkApp { drv = script; };

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
            };
          };
        };
      });
}
