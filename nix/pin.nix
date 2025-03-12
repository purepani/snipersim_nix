{
  pkgs,
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  makeWrapper,
  patchelf,
  ...
}:
stdenv.mkDerivation {
  pname = "pin";
  version = "3.31";

  src = fetchurl {
    url = "https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-3.31-98869-gfa6f126a8-gcc-linux.tar.gz";
    sha256 = "sha256-giFhROPfdo8CA7Zx/0hgUxTxMmaQPrQtrAG5ExDrqVY=";
  };

  buildInputs = [ stdenv.cc.cc.lib ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    patchelf
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r ./* $out
    ln -s $out/pin $out/intel64/bin/* $out/bin

    # Remove bundled extlib libraries from XED so system ones are used.
    rm -rf $out/extras/xed-intel64/extlib

    # Remove bundled cpplibs so the system's libstdc++ is used.
    rm -rf $out/intel64/runtime/cpplibs

    # Too generic. There are exceptions.
    # find $out -type f -exec sed -i 's|/usr/bin/\([^/]\+\)|/usr/bin/env \1|g' {} +
     
    sed -i 's/\/usr\/bin\/ar/\/usr\/bin\/env ar/' $out/source/tools/Config/unix.vars

    # 2) Python shebangs
    sed -i '1 s|^#!.*/usr/bin/python|#!${pkgs.python3}/bin/python|' \
      $out/source/tools/ImageTests/region_compare.py \
      $out/source/tools/RtnTests/is_ifunc_supported.py

    # 3) /usr/bin/env python -> /usr/bin/env python3
    sed -i '1 s|^#! */usr/bin/env python|#! /usr/bin/env python3|' \
      $out/source/tools/SimpleExamples/callgraph.py \
      $out/source/tools/SimpleExamples/flowgraph.py \
      $out/source/tools/Utils/testReleaseVersionPython.py \
      $out/source/tools/Utils/printWindowsVersion.py \
      $out/source/tools/Utils/printFunctionSize.py \
      $out/source/tools/Utils/printFilteredTests.py \
      $out/source/tools/Mix/summarize.py \
      $out/source/tools/AttachDetach/attach_read_stdin.py
  '';

  postInstall = ''
    for exe in $out/bin/*; do
      # Patch the interpreter to use the older glibc dynamic linker.
      patchelf --set-interpreter ${pkgs.glibc.out}/lib/ld-linux-x86-64.so.2 "$exe"
      wrapProgram "$exe" \
        --prefix LD_LIBRARY_PATH ":$out/intel64/runtime/pincrt:$out/extras/xed-intel64/lib:${pkgs.glibc.out}/lib"
    done
  '';

  meta = {
    homepage = "https://software.intel.com/content/www/us/en/develop/articles/pin-a-dynamic-binary-instrumentation-tool.html";
    description = "A tool for the dynamic instrumentation of programs";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers.hakan-demirli ];
  };
}
