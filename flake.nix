{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = false;
      };

      gapbs = pkgs.callPackage ./nix/gapbs.nix { };

      wiki-Vote = fetchTarball {
        url = "https://suitesparse-collection-website.herokuapp.com/MM/SNAP/wiki-Vote.tar.gz";
        sha256 = "sha256:03v5pj07fjj2xrnlhqsgwj6s3k5wjzi3b433acpci8yhvmnx05za";
      };

      cage3 = fetchTarball {
        url = "https://suitesparse-collection-website.herokuapp.com/MM/vanHeukelum/cage3.tar.gz";
        sha256 = "sha256:1dzy2wxrip89ah0ws4q8cb0npryyk4i2jrf7wxzwvzqxz0zwxwms";
      };

      pin = pkgs.callPackage ./nix/pin.nix { };
      sde = pkgs.callPackage ./nix/sde.nix { };

      dynamorio = pkgs.fetchFromGitHub {
        owner = "DynamoRIO";
        repo = "dynamorio";
        rev = "246ddb28e7848b2d09d2b9909f99a6da9b2ce35e";
        sha256 = "sha256-bYUW8BjMRyOS2AdsKbLnnrOYKIjofOqk+mHqYzjGr1E=";
        fetchSubmodules = true;
      };

      capstone = pkgs.fetchFromGitHub {
        owner = "aquynh";
        repo = "capstone";
        rev = "f9c6a90489be7b3637ff1c7298e45efafe7cf1b9";
        sha256 = "sha256-Ri1OP+3DBHnZYUXfHvfLS69FpPtA8O5D+inbcGbvXEY=";
        fetchSubmodules = true;
      };

      mbuild = pkgs.fetchFromGitHub {
        owner = "intelxed";
        repo = "mbuild";
        rev = "f32bc9b31f9fc5a0be3dc88cd2086b70270295ab";
        sha256 = "sha256-IZhJMe+FFvRpRm0dsajmxa4Y3loIFg7RFPxlPQBviFY=";
        fetchSubmodules = true;
      };

      xed = pkgs.fetchFromGitHub {
        owner = "intelxed";
        repo = "xed";
        rev = "b86dd5014463d954bc8898d2376b14852d26facd";
        sha256 = "sha256-X8Tarkl9gEw3nW6UaHA+Rc0YIr7RWyossRNTolGPmB0=";
        fetchSubmodules = true;
      };

      mcpat = fetchTarball {
        url = "https://snipersim.org/packages/mcpat-1.0.tgz";
        sha256 = "sha256:1ynx1h554bwpw1cmbnpf7xv0dglid0nmg0hxf90kr610zib46ing";
      };

      libtorch = fetchTarball {
        url = "https://snipersim.org/packages/libtorch-shared-with-deps-2.5.0-cpu.tar.gz";
        sha256 = "sha256:1q0bw3y1hkwb9iazlshgnyrcb167ag7v1vsncpm8bipvih1ih0a5";
      };

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        shellHook = ''
          copy_if_missing() {
            local target_dir="$1"
            local src_dir="$2"
            echo "src_dir: $src_dir"
            echo "target_dir: $target_dir"

            if [ ! -d "$target_dir" ] || [ -z "$(ls -A "$target_dir" 2>/dev/null)" ]; then
              mkdir -p "$target_dir"
              cp -r "$src_dir"/* "$target_dir"
              chmod -R u+w "$target_dir"
            else
              echo -e "\033[1;33mWarning: $target_dir already exists. Skipping copy.\033[0m"
            fi
          }

          copy_if_missing "./gapbs"   ${gapbs}

          copy_if_missing "./pin_kit"   ${pin}
          copy_if_missing "./sde_kit"   ${sde}
          copy_if_missing "./dynamorio" ${dynamorio}
          copy_if_missing "./capstone"  ${capstone}
          copy_if_missing "./mbuild"    ${mbuild}
          copy_if_missing "./xed"       ${xed}
          copy_if_missing "./mcpat"     ${mcpat}
          copy_if_missing "./libtorch"  ${libtorch}

          copy_if_missing "./dataset/wiki-Vote"  ${wiki-Vote}
          copy_if_missing "./dataset/cage3"      ${cage3}
	  
	  export KMP_AFFINITY=disabled
          export SIM_ROOT=$(realpath ./)
          export SNIPER_ROOT=$(realpath $SIM_ROOT)
          export SDE_HOME=$(realpath $SIM_ROOT/sde_kit)
          # export SDE_BUILD_KIT=$(realpath $SIM_ROOT/sde_kit)
          export PIN_ROOT=$(realpath $SIM_ROOT/pin_kit)
          export PIN_HOME=$(realpath $SIM_ROOT/pin_kit)
          export MBUILD_HOME=$(realpath $SIM_ROOT/mbuild)

          export PIN_INCLUDE=$(realpath $SIM_ROOT/pin_kit/extras/components/include)
          export XED_INCLUDE=$(realpath $SIM_ROOT/xed/include/xed)

          export OPT_CFLAGS="-O3 -march=native -flto"
          export OPT_CXXFLAGS="-O3 -march=native -flto"

          export CXXFLAGS="$CXXFLAGS -D_GLIBCXX_USE_CXX11_ABI=0 -I$PIN_INCLUDE -I$XED_INCLUDE"

          export BUILD_KIT_FOR_PYTHON=$(realpath $SIM_ROOT/sde_kit/pinkit/sde-example)
          export PYTHONPATH="$PYTHONPATH:$MBUILD_HOME:$BUILD_KIT_FOR_PYTHON"

          export TOOLS_ROOT=$(realpath $PIN_ROOT/source/tools)

          # dumb as duck
          mkdir -p $SIM_ROOT/lib

          # dumb as duck x2
          rm -r $SDE_HOME/pinkit/source/tools/InstLib
        '';

        packages = [
          pkgs.gcc
          pkgs.gdb
          pkgs.cmake

          pkgs.python3
          pkgs.sift
          pkgs.sqlite
          pkgs.boost
          pkgs.zlib
          pkgs.binutils
          pkgs.bzip2
          pkgs.mvapich
	  pkgs.wget
	  pkgs.llvmPackages.openmp
        ];
      };
    };
}
