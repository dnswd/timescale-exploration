{
  description = "Flake to run stress test on timescale";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    command-utils.url = "github:expede/nix-command-utils";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, command-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };

          libExt = {
            getExe' = derivation: binaryName:
              let
                binPath = "${derivation}/bin/${binaryName}";
              in
              if pkgs.lib.pathExists binPath
              then binPath
              else throw "Binary '${binaryName}' not found in '${derivation}/bin/'";
          };

          lib = pkgs.lib // libExt;

          # Cargo just for example
          pgbench = lib.getExe' pkgs.postgresql_jit "pgbench";

          cmd = command-utils.cmd.${system};
          command_menu = command-utils.commands.${system} {
            "stress:basic" = cmd "Run basic stresstets with pgbench default tables" # sh
              ''
                ${pgbench} -h localhost -p 5432 -U timescaledb -i -s 625 example
                ${pgbench} -h localhost -p 5432 -U timescaledb -c 10 -j 2 -t 10000 example
              '';
          };
        in
        {
          devShells.default = pkgs.mkShell
            {
              nativeBuildInputs = with pkgs; [
                command_menu
                postgresql_jit
              ];
            };
        }
      );
}
