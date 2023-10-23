{
  description = "Some packages I find useful";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, flake-utils, devshell, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };

        jdk = pkgs.jdk;
        coursier = pkgs.coursier.override { jre = jdk; };
        lib = pkgs.lib;

        buildCoursierBootstrappedApp = { groupId, artifactId, version
          , pname ? artifactId, depsHash ? "", javaOpts ? [ ] }:
          let
            deps = pkgs.stdenv.mkDerivation {
              name = "${pname}-deps-${version}";

              dontUnpack = true;
              nativeBuildInputs = [ jdk coursier ];

              JAVA_HOME = "${jdk}";
              COURSIER_CACHE = "./coursier-cache/v1";
              COURSIER_ARCHIVE_CACHE = "./coursier-cache/arc";
              COURSIER_JVM_CACHE = "./coursier-cache/jvm";

              buildPhase = ''
                mkdir -p coursier-cache/v1
                cs fetch ${groupId}:${artifactId}:${version} \
                  -r bintray:scalacenter/releases \
                  -r sonatype:snapshots
              '';

              installPhase = ''
                mkdir -p $out/coursier-cache
                cp -R ./coursier-cache $out
              '';

              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash = "${depsHash}";
            };

          in pkgs.stdenv.mkDerivation rec {
            inherit pname version;

            dontUnpack = true;

            buildInputs = [ jdk ];
            nativeBuildInputs = [ pkgs.makeWrapper pkgs.coursier deps ];

            JAVA_HOME = "${jdk}";
            COURSIER_CACHE = "${deps}/coursier-cache/v1";
            COURSIER_ARCHIVE_CACHE = "${deps}/coursier-cache/arc";
            COURSIER_JVM_CACHE = "${deps}/coursier-cache/jvm";

            launcher = "${pname}-launcher";

            buildPhase = ''
              mkdir -p coursier-cache/v1
              cs bootstrap ${groupId}:${artifactId}:${version} --standalone -o ${launcher}
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp ${launcher} $out
              makeWrapper $out/${launcher} $out/bin/${pname} \
                --set JAVA_HOME ${jdk} \
                --add-flags "${
                  lib.strings.concatStringsSep " "
                  (builtins.map (s: "-J" + s) javaOpts)
                }"
            '';

          };

      in {

        packages = {

          smithy-language-server = buildCoursierBootstrappedApp {
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

          smithy-cli = buildCoursierBootstrappedApp {
            groupId = "software.amazon.smithy";
            artifactId = "smithy-cli";
            version = "1.39.1";
            depsHash = "sha256-/8HW7ZhDBOXf6B/dDuqeMRjuE+mRa5hHkb524oqXLO0=";
          };

          smithy4s-cli = buildCoursierBootstrappedApp {
            groupId = "com.disneystreaming.smithy4s";
            artifactId = "smithy4s-codegen-cli_2.13";
            version = "0.18.2";
            pname = "smith4s-cli";
            depsHash = "sha256-k5940JgN+RQTZLvPfAGwOmGn/9/KGUnq9WUKsGAoiPY=";
          };

          metals = buildCoursierBootstrappedApp {
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

      }) // {
        overlays.default = final: prev: {
          inherit (self.packages.${prev.system})
            smithy-language-server smithy-cli metals;
        };
      };

}
