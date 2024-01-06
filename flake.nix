{
  description = "Some packages I find useful";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.my-nix-utils.url = "github:buntec/nix-utils";

  outputs = { self, nixpkgs, my-nix-utils, ... }:

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

      buildCoursierApp = pkgs:
        pkgs.callPackage my-nix-utils.lib.mkBuildCoursierApp { };

      mkPackages = pkgs: {

        smithy-language-server = buildCoursierApp pkgs {
          groupId = "software.amazon.smithy";
          artifactId = "smithy-language-server";
          version = "0.2.3";
          depsHash = "sha256-BmCWWR7OWAPtLjS5cwFQdFJylT3CvQXASbQPWRPloIs=";
          javaOpts = [
            "-XX:+UseG1GC"
            "-XX:+UseStringDeduplication"
            "-Xss4m"
            "-Xms100m"
          ];
        };

        smithy-cli = buildCoursierApp pkgs {
          groupId = "software.amazon.smithy";
          artifactId = "smithy-cli";
          version = "1.39.1";
          depsHash = "sha256-/8HW7ZhDBOXf6B/dDuqeMRjuE+mRa5hHkb524oqXLO0=";
        };

        smithy4s-codegen-cli = buildCoursierApp pkgs {
          groupId = "com.disneystreaming.smithy4s";
          artifactId = "smithy4s-codegen-cli_2.13";
          version = "0.18.2";
          pname = "smithy4s-codegen-cli";
          depsHash = "sha256-k5940JgN+RQTZLvPfAGwOmGn/9/KGUnq9WUKsGAoiPY=";
        };

        metals = buildCoursierApp pkgs {
          groupId = "org.scalameta";
          artifactId = "metals_2.13";
          version = "1.0.1";
          pname = "metals";
          depsHash = "sha256-WAQbkBcYxGjWKdC2NZHHYPha9i+b7f+xWO1LVsLkJeI=";
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
        let pkgs = import nixpkgs { inherit system; };
        in mkPackages pkgs);

      apps = eachSystem (system:
        let pkgs = import nixpkgs { inherit system; };
        in builtins.mapAttrs (_: value: mkApp { drv = value; })
        (mkPackages pkgs));

      overlays.default = final: _: mkPackages final;

      checks = self.packages;

    };

}
