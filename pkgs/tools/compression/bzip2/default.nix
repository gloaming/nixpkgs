{ stdenv, fetchurl
}:

stdenv.mkDerivation rec {
  name = "bzip2-${version}";
  version = "1.0.8";

  src = fetchurl {
    url = "https://sourceware.org/pub/bzip2/${name}.tar.gz";
    sha256 = "0s92986cv0p692icqlw1j42y9nld8zd83qwhzbqd61p1dqbh6nmb";
  };

  outputs = [ "bin" "dev" "out" "man" ];

  buildFlags = [ "-f Makefile-libbz2_so" ];

  installFlags = [ "PREFIX=$(out)" ];

  postInstall = ''
    moveToOutput bin $bin
    ln -s libbz2.so.1.0 libbz2.so.1
    ln -s libbz2.so.1   libbz2.so
    mv libbz2.so* $out/lib
    rm $out/lib/libbz2.a
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "High-quality data compression program";
    license = licenses.bsdOriginal;
    platforms = platforms.all;
    maintainers = [];
  };
}
