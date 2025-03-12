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
  pname = "sde";
  version = "9.44";

  src = fetchurl {
    url = "https://snipersim.org/packages/sde-external-9.44.0-2024-08-22-lin.tar.xz";
    sha256 = "sha256-xrwW/G0YVQSeoi2vIUqMADMXE7xqewxNaVXW7YQUi5s=";
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

    ln -s $out/sde $out/intel64/bin/* $out/bin

    rm -rf $out/extras/xed-intel64/extlib
    rm -rf $out/intel64/runtime/cpplibs

    # Fix references to /usr/bin/*

    # 1) In source/tools/Utils: fix reference to gcc in testToolVersion
    sed -i 's|/usr/bin/gcc|${stdenv.cc.cc}/bin/gcc|g' $out/pinkit/source/tools/Utils/testToolVersion || true

    # 2) Fix Python shebangs in several Utils scripts
    for file in \
      $out/pinkit/source/tools/Utils/printWindowsVersion.py \
      $out/pinkit/source/tools/Utils/testReleaseVersionPython.py \
      $out/pinkit/source/tools/Utils/printFunctionSize.py \
      $out/pinkit/source/tools/Utils/printFilteredTests.py; do
      sed -i '1 s|^#!.*/usr/bin/env python|#!/usr/bin/env python3|' "$file" || true
    done

    # 3) In sde-example/mbuild/mbuild: fix Python shebangs in various scripts
    for file in \
      $out/pinkit/sde-example/mbuild/mbuild/dfs.py \
      $out/pinkit/sde-example/mbuild/mbuild/dag.py \
      $out/pinkit/sde-example/mbuild/mbuild/base.py \
      $out/pinkit/sde-example/mbuild/mbuild/header_tag.py \
      $out/pinkit/sde-example/mbuild/mbuild/arar.py \
      $out/pinkit/sde-example/mbuild/mbuild/build_env.py \
      $out/pinkit/sde-example/mbuild/mbuild/env.py \
      $out/pinkit/sde-example/mbuild/mbuild/doxygen.py; do
      sed -i '1 s|^#!.*/usr/bin/env python|#!/usr/bin/env python3|' "$file" || true
    done

    # 4) In mbuild/util.py: replace /usr/bin/python or /bin/python calls with 'python3'
    sed -i "s|['\"]\\(/usr/bin/python\\|/bin/python\\)['\"]|'python3'|g" $out/pinkit/sde-example/mbuild/mbuild/util.py || true

    # 5) In source/tools/Config/win.vars: replace /usr/bin/sort
    sed -i 's|/usr/bin/sort|${pkgs.coreutils}/bin/sort|g' $out/pinkit/source/tools/Config/win.vars || true

    # 6) In source/tools/Config/makefile.debug.rules: replace /usr/bin/gdb
    sed -i 's|/usr/bin/gdb|${pkgs.gdb}/bin/gdb|g' $out/pinkit/source/tools/Config/makefile.debug.rules || true

    # 7) In mbuild/env.py: replace /usr/bin/getconf
    sed -i 's|/usr/bin/getconf|${pkgs.coreutils}/bin/getconf|g' $out/pinkit/sde-example/mbuild/mbuild/env.py || true

    # 8) In extras/libdwarf/libdwarf-0.7.0/doc/pdfbld.sh: patch TROFF and PSTOPDF
    sed -i 's|/usr/bin/groff|${pkgs.groff}/bin/groff|g' $out/pinkit/extras/libdwarf/libdwarf-0.7.0/doc/pdfbld.sh || true
    sed -i 's|/usr/bin/ps2pdf|${pkgs.ghostscript}/bin/ps2pdf|g' $out/pinkit/extras/libdwarf/libdwarf-0.7.0/doc/pdfbld.sh || true

    # 9) In extras/libdwarf: patch dwarf_debuglink.c and simplecrc.c
    sed -i 's|/usr/bin/||g' $out/pinkit/extras/libdwarf/libdwarf-0.7.0/src/lib/libdwarf/dwarf_debuglink.c || true
    sed -i 's|"/usr/bin/gdb"|"'${pkgs.gdb}/bin/gdb'"|g' $out/pinkit/extras/libdwarf/libdwarf-0.7.0/src/bin/dwarfexample/simplecrc.c || true

    # Additional patches for python references

    # In pinkit/sde-example/mbuild/mbuild/util.py
    sed -i 's|/usr/bin/python|python3|g' $out/pinkit/sde-example/mbuild/mbuild/util.py || true
    sed -i 's|/bin/python|python3|g' $out/pinkit/sde-example/mbuild/mbuild/util.py || true

    # In pinkit/source/tools/Config/unix.vars
    sed -i -e 's|/usr/bin/ar|${pkgs.binutils-unwrapped}/bin/ar|g' \
           -e 's|/usr/bin/strip|${pkgs.binutils-unwrapped}/bin/strip|g' \
           $out/pinkit/source/tools/Config/unix.vars || true

    # In pinkit/source/tools/Config/makefile.unix.config
    sed -i -e 's|-gcc-name=/usr/bin/gcc|-gcc-name=${stdenv.cc.cc}/bin/gcc|g' \
           -e 's|-gxx-name=/usr/bin/g++|-gxx-name=${stdenv.cc.cc}/bin/g++|g' \
           -e 's|/usr/bin/g++|${stdenv.cc.cc}/bin/g++|g' \
           $out/pinkit/source/tools/Config/makefile.unix.config || true

    # In pinkit/extras/libdwarf/libdwarf-0.7.0/bugxml/readbugs.py
    sed -i '1 s|^#!.*/usr/bin/python3|#!/usr/bin/env python3|' $out/pinkit/extras/libdwarf/libdwarf-0.7.0/bugxml/readbugs.py || true

    # In pinkit/extras/libdwarf/libdwarf-0.7.0/bugxml/bugrecord.py
    sed -i '1 s|^#!.*/usr/bin/python3|#!/usr/bin/env python3|' $out/pinkit/extras/libdwarf/libdwarf-0.7.0/bugxml/bugrecord.py || true
  '';

  postInstall = ''
    for exe in $out/bin/*; do
      patchelf --set-interpreter ${pkgs.glibc.out}/lib/ld-linux-x86-64.so.2 "$exe"
      wrapProgram "$exe" \
        --prefix LD_LIBRARY_PATH ":$out/intel64/runtime/pincrt:$out/extras/xed-intel64/lib:${pkgs.glibc.out}/lib"
    done
  '';

  meta = {
    homepage = "https://software.intel.com/content/www/us/en/developer/tools/software-development-emulator.html";
    description = "Intel Software Development Emulator (SDE) for dynamic binary instrumentation";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers.hakan-demirli ];
  };
}
