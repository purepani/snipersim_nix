{
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  llvmPackages,
}:

let
  # mbuild is a custom build system used only to build xed
  mbuild = python3Packages.buildPythonPackage {
    pname = "mbuild";
    version = "vSniper";

    src = fetchFromGitHub {
      owner = "intelxed";
      repo = "mbuild";
      rev = "f32bc9b31f9fc5a0be3dc88cd2086b70270295ab";
      sha256 = "sha256-IZhJMe+FFvRpRm0dsajmxa4Y3loIFg7RFPxlPQBviFY=";
    };
    doCheck = false;
  };

in
stdenv.mkDerivation {
  pname = "xed";
  version = "vSniper";

  src = fetchFromGitHub {
    owner = "intelxed";
    repo = "xed";
    rev = "b86dd5014463d954bc8898d2376b14852d26facd";
    sha256 = "sha256-X8Tarkl9gEw3nW6UaHA+Rc0YIr7RWyossRNTolGPmB0=";
  };

  nativeBuildInputs = [
    mbuild
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ llvmPackages.bintools ];

  buildPhase = ''
    patchShebangs mfile.py

    # this will build, test and install
    ./mfile.py test --prefix $out
    ./mfile.py examples
    ./mfile.py install
    # mkdir -p $out/bin
    # cp ./obj/wkit/examples/obj/xed $out/bin/
  '';

  dontInstall = true; # already installed during buildPhase

  meta = with lib; {
    broken = stdenv.hostPlatform.isAarch64;
    description = "Intel X86 Encoder Decoder (Intel XED)";
    homepage = "https://intelxed.github.io/";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = with maintainers; [ arturcygan ];
  };
}
