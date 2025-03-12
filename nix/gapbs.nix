{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
}:

stdenv.mkDerivation rec {
  pname = "gapbs";
  version = "v1.5";

  src = fetchFromGitHub {
    owner = "sbeamer";
    repo = "gapbs";
    rev = version;
    sha256 = "sha256-E1s9E+vOsQfBBOdTyNbtLdOV6LIrF19wzMR3V67L7w0=";
  };

  doCheck = true;
  checkPhase = "make test";

  installPhase = ''
    mkdir -p $out
    cp -r ./* $out
  '';

  meta = {
    description = "Graph processing benchmark suite";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ hakan-demirli ];
  };
}
