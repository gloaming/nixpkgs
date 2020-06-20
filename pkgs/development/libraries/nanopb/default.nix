{ callPackage
, cmake
, fetchFromGitHub
, lib
, protobuf
, python3
, stdenv
}:

let
  pythonRuntime = python3.withPackages(ps: [ ps.protobuf ]);
in stdenv.mkDerivation rec {
  pname = "nanopb";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = version;
    sha256 = "16zxk42wzn519bpxf4578qn97k0h1cnbkvqqkqvka9sl0n3lz2dp";
  };

  nativeBuildInputs = [ cmake python3 ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON" # generate $out/lib/libprotobuf-nanopb.so{.0,}
    "-DBUILD_STATIC_LIBS=ON" # generate $out/lib/libprotobuf-nanopb.a
    "-Dnanopb_PROTOC_PATH=${protobuf}/bin/protoc"
  ];

  # On a case-insensitive filesystem (such as on Darwin), CMake fails to create
  # the build directory because of the existence of the BUILD file.
  # TODO: This can be removed once https://github.com/nanopb/nanopb/pull/537 is merged.
  preConfigure = "rm BUILD";

  # install the generator which requires Python3 with the protobuf package. It
  # also requires the nanopb module that's generated by CMake to be in a
  # relative location to the generator itself so we move it out of the
  # python.sitePackages into the shared generator folder.
  postInstall = ''
    mkdir -p $out/share/nanopb/generator/proto
    cp ../generator/nanopb_generator.py $out/share/nanopb/generator/nanopb_generator.py
    cp ../generator/proto/_utils.py $out/share/nanopb/generator/proto/_utils.py
    cp ../generator/proto/nanopb.proto $out/share/nanopb/generator/proto/nanopb.proto
    mv $out/${python3.sitePackages}/nanopb_pb2.py $out/share/nanopb/generator/proto
    rm -rf $out/${python3.sitePackages}

    mkdir $out/bin
    substitute ${./protoc-gen-nanopb} $out/bin/protoc-gen-nanopb \
      --subst-var-by python ${pythonRuntime}/bin/python \
      --subst-var-by out $out
    chmod +x $out/bin/protoc-gen-nanopb
  '';

  passthru.tests = {
    simple-proto2 = callPackage ./test-simple-proto2 {};
    simple-proto3 = callPackage ./test-simple-proto3 {};
    message-with-annotations = callPackage ./test-message-with-annotations {};
    message-with-options = callPackage ./test-message-with-options {};
  };

  meta = with lib; {
    inherit (protobuf.meta) platforms;

    description = "Protocol Buffers with small code size";
    homepage = "https://jpa.kapsi.fi/nanopb/";
    license = licenses.zlib;
    maintainers = with maintainers; [ kalbasit ];

    longDescription = ''
      Nanopb is a small code-size Protocol Buffers implementation in ansi C. It
      is especially suitable for use in microcontrollers, but fits any memory
      restricted system.

      - Homepage: jpa.kapsi.fi/nanopb
      - Documentation: jpa.kapsi.fi/nanopb/docs
      - Downloads: jpa.kapsi.fi/nanopb/download
      - Forum: groups.google.com/forum/#!forum/nanopb

      In order to use the nanopb options in your proto files, you'll need to
      tell protoc where to find the nanopb.proto file.
      You can do so with the --proto_path (-I) option to add the directory
      ''${nanopb}/share/nanopb/generator/proto like so:

      protoc --proto_path=. --proto_path=''${nanopb}/share/nanopb/generator/proto --plugin=protoc-gen-nanopb=''${nanopb}/bin/protoc-gen-nanopb --nanopb_out=out file.proto
    '';
  };
}
