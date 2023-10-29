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

    in {
      packages = eachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ ];
          };

          buildCoursierApp =
            pkgs.callPackage my-nix-utils.lib.mkBuildCoursierApp { };

        in {
          smithy-language-server = buildCoursierApp {
            groupId = "software.amazon.smithy";
            artifactId = "smithy-language-server";
            version = "0.2.3";
            depsHash = "sha256-yvBkxcUqAU4A2YlzFfUKYuKasNDZmkRZWRiEUTUphKc=";
            javaOpts = [
              "-XX:+UseG1GC"
              "-XX:+UseStringDeduplication"
              "-Xss4m"
              "-Xms100m"
            ];
          };

          smithy-cli = buildCoursierApp {
            groupId = "software.amazon.smithy";
            artifactId = "smithy-cli";
            version = "1.39.1";
            depsHash = "sha256-/8HW7ZhDBOXf6B/dDuqeMRjuE+mRa5hHkb524oqXLO0=";
          };

          smithy4s-cli = buildCoursierApp {
            groupId = "com.disneystreaming.smithy4s";
            artifactId = "smithy4s-codegen-cli_2.13";
            version = "0.18.2";
            pname = "smith4s-cli";
            depsHash = "sha256-k5940JgN+RQTZLvPfAGwOmGn/9/KGUnq9WUKsGAoiPY=";
          };

          metals = buildCoursierApp {
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

        });

      overlays.default = final: prev: {
        inherit (self.packages.${prev.system})
          smithy-language-server smithy-cli smith4s-cli metals;
      };

      checks = self.packages;

    };

}
