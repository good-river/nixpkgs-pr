{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

let
  # These names are how they are designated in https://xanmod.org.

  # NOTE: When updating these, please also take a look at the changes done to
  # kernel config in the xanmod version commit
  ltsVariant = {
    version = "6.1.66";
    hash = "sha256-H3RTbBctvbKdsD1+G7zXVcTFb2NRON6nOzUgUW+zGxs=";
    variant = "lts";
  };

  mainVariant = {
    version = "6.6.5";
    hash = "sha256-lmJ5Gix+CEqIu+cyBeqBq6xLZ94PjhU+6SbzAE0D8SY=";
    variant = "main";
  };

  xanmodKernelFor = { version, suffix ? "xanmod1", hash, variant }: buildLinux (args // rec {
    inherit version;
    modDirVersion = lib.versions.pad 3 "${version}-${suffix}";

    src = fetchFromGitHub {
      owner = "xanmod";
      repo = "linux";
      rev = modDirVersion;
      inherit hash;
    };

    structuredExtraConfig = with lib.kernel; {
      # Google's BBRv3 TCP congestion Control
      TCP_CONG_BBR = yes;
      DEFAULT_BBR = yes;

      # WineSync driver for fast kernel-backed Wine
      WINESYNC = module;

      # Preemptive Full Tickless Kernel at 250Hz
      HZ = freeform "250";
      HZ_250 = yes;
      HZ_1000 = no;
    };

    extraMeta = {
      branch = lib.versions.majorMinor version;
      maintainers = with lib.maintainers; [ moni lovesegfault atemu shawn8901 zzzsy ];
      description = "Built with custom settings and new features built to provide a stable, responsive and smooth desktop experience";
      broken = stdenv.isAarch64;
    };
  } // (args.argsOverride or { }));
in
{
  lts = xanmodKernelFor ltsVariant;
  main = xanmodKernelFor mainVariant;
}
