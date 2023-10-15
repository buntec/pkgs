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

          smithy-language-server = let
            version = "0.2.3";

            deps = pkgs.stdenv.mkDerivation {
              #name = "${pname}-deps-${version}";
              name = "deps";

              dontUnpack = true;
              buildInputs = [ pkgs.jdk pkgs.bash pkgs.coursier ];
              nativeBuildInputs = [ pkgs.coursier pkgs.bash ];

              JAVA_HOME = "${jdk}";
              COURSIER_CACHE = "./coursier-cache/v1";
              COURSIER_ARCHIVE_CACHE = "./coursier-cache/arc";
              COURSIER_JVM_CACHE = "./coursier-cache/jvm";

              buildPhase = ''
                mkdir -p coursier-cache/v1
                mkdir -p coursier-cache/arc
                mkdir -p coursier-cache/jvm
                cs bootstrap software.amazon.smithy:smithy-language-server:${version} -o smithy-language-server
              '';

              installPhase = ''
                mkdir -p $out/bin
                cp smithy-language-server $out/bin
              '';

              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash = "";
            };

          in pkgs.stdenv.mkDerivation rec {
            pname = "smithy-language-server";
            version = "0.2.3";

            dontUnpack = true;

            buildInputs = [ deps ];
            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              mkdir -p $out/bin
              makeWrapper ${deps}/bin/smithy-language-server $out/bin/smithy-language-server --set JAVA_HOME ${jdk}
            '';

          };

        };

      });

}
