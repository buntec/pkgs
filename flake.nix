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

      in {

        packages = {

          smithy-language-server = pkgs.stdenv.mkDerivation rec {
            pname = "smithy-language-server";
            version = "0.2.3";

            deps = pkgs.stdenv.mkDerivation {
              name = "${pname}-deps-${version}";
              src = ./src;

              nativeBuildInputs = [ pkgs.coursier ];

              SCALA_CLI_HOME = "./scala-cli-home";
              COURSIER_CACHE = "./coursier-cache/v1";
              COURSIER_ARCHIVE_CACHE = "./coursier-cache/arc";
              COURSIER_JVM_CACHE = "./coursier-cache/jvm";

              # run the same build as our main derivation
              # to populate the cache with the correct set of dependencies
              buildPhase = ''
                cs bootstrap software.amazon.smithy:smithy-language-server:${version} \
                  --standalone -o smithy-language-server
              '';

              installPhase = ''
                cp smithy-language-server $out
              '';

              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash =
                "sha256-hagKQcBvFdrTwSOgrDp78lkgj73iybe9dmynGmjynKI=";
            };

            buildInputs = [ deps ];
            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              mkdir -p $out/bin
              makeWrapper ${deps}/smithy-language-server $out/bin/smithy-language-server --set JAVA_HOME ${jdk}
            '';

          };

        };

      });

}
