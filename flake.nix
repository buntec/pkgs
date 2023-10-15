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
      in {

        packages = {

          smithy-language-server = let
            version = "0.2.3";
            pname = "smithy-language-server";

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
                mkdir -p coursier-cache/arc
                mkdir -p coursier-cache/jvm
                cs fetch software.amazon.smithy:smithy-language-server:${version}
              '';

              installPhase = ''
                mkdir -p $out/coursier-cache
                cp -R ./coursier-cache $out
              '';

              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash =
                "sha256-Vat5YIV/cuciUM6anuhMxwFLiQHvofcBszQc0qUlf+A=";
            };

          in pkgs.stdenv.mkDerivation rec {
            inherit pname version;

            dontUnpack = true;

            buildInputs = [ jdk ];
            nativeBuildInputs = [ pkgs.makeWrapper pkgs.coursier deps ];

            JAVA_HOME = "${jdk}";
            COURSIER_CACHE = "./coursier-cache/v1";
            COURSIER_ARCHIVE_CACHE = "./coursier-cache/arc";
            COURSIER_JVM_CACHE = "./coursier-cache/jvm";

            buildPhase = ''
              mkdir -p coursier-cache/v1
              mkdir -p coursier-cache/arc
              mkdir -p coursier-cache/jvm
              cs bootstrap software.amazon.smithy:smithy-language-server:${version} \
                --standalone -o launcher
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp launcher $out
              makeWrapper $out/launcher $out/bin/smithy-language-server --set JAVA_HOME ${jdk}
            '';

          };

        };

      });

}
