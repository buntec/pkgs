{
  description = "Some packages I find useful";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nix-utils.url = "github:buntec/nix-utils";

  outputs = { self, nixpkgs, nix-utils, ... }:

    let
      inherit (nixpkgs.lib) genAttrs;

      eachSystem = genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      mkApp = { drv, name ? drv.pname or drv.name }: {
        type = "app";
        program = "${drv}/bin/${name}";
      };

      overlays = [ nix-utils.overlays.default ];

      mkPackages = pkgs: {

        smithy-language-server = pkgs.buildCoursierApp {
          groupId = "software.amazon.smithy";
          artifactId = "smithy-language-server";
          version = "0.2.4";
          depsHash = "sha256-CwYOqKrIB1lNpcLcIbs/WrwYtJ1c8CKr3I2pYi61C/g=";
          javaOpts = [
            "-XX:+UseG1GC"
            "-XX:+UseStringDeduplication"
            "-Xss4m"
            "-Xms100m"
          ];
        };

        smithy-cli = pkgs.buildCoursierApp {
          groupId = "software.amazon.smithy";
          artifactId = "smithy-cli";
          version = "1.43.0";
          depsHash = "sha256-fF5PeiWMcuWIUdMo9H5rdSNu3b+whlJ2VKqqJJOC7lM=";
        };

        smithy4s-codegen-cli = pkgs.buildCoursierApp {
          groupId = "com.disneystreaming.smithy4s";
          artifactId = "smithy4s-codegen-cli_2.13";
          version = "0.18.6";
          pname = "smithy4s-codegen-cli";
          depsHash = "sha256-DlJDdiY6UotLUlyn1tFvP+1qNHUaacJNcFKKyQTkknM=";
        };

        metals = pkgs.buildCoursierApp {
          groupId = "org.scalameta";
          artifactId = "metals_2.13";
          version = "1.2.0";
          pname = "metals";
          depsHash = "sha256-Izm9VVFOzHDecKlNlFmmE2rSCm7mus1QT3WfB/7ZryQ=";
          javaOpts = [
            "-XX:+UseG1GC"
            "-XX:+UseStringDeduplication"
            "-Xss4m"
            "-Xms100m"
          ];
        };

      };

    in {

      packages = eachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            inherit overlays;
          };
        in mkPackages pkgs);

      apps = eachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            inherit overlays;
          };
        in builtins.mapAttrs (_: value: mkApp { drv = value; })
        (mkPackages pkgs));

      overlays.default = final: _: mkPackages final;

      checks = self.packages;

    };

}
