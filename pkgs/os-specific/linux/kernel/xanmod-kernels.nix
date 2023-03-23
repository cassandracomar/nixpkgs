{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

let
  # These names are how they are designated in https://xanmod.org.
  ltsVariant = {
    version = "6.1.15";
    hash = "sha256-KQ/1C8/nCQL8y/eTHQNJDYb/BSjwzdrUKdK05bSwuSI=";
    variant = "lts";
  };

  ttVariant = {
    version = "6.2.8";
    suffix = "xanmod1-tt";
    hash = "sha256-LVx08ad5b1uzYIZIozB0DzmdwOxYWug+QM9CRLwlMLg=";
    variant = "tt";
  };

  mainVariant = {
    version = "6.2.2";
    hash = "sha256-YQSaIiGzszuOSO3rYnuBeucvhVlnue24b3ECRTH55bg=";
    variant = "main";
  };

  rtVariant = {
    version = "6.0.2";
    hash = "sha256-bJWMHBBXpsOHASYwaCU4flfgzoUlDRFjBudDqKCk3Ac=";
    variant = "rt";
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
      # AMD P-state driver
      X86_AMD_PSTATE = lib.mkOverride 60 yes;

      # Google's BBRv2 TCP congestion Control
      TCP_CONG_BBR2 = yes;
      DEFAULT_BBR2 = yes;

      # FQ-PIE Packet Scheduling
      NET_SCH_DEFAULT = yes;
      DEFAULT_FQ_PIE = yes;

      # Futex WAIT_MULTIPLE implementation for Wine / Proton Fsync.
      FUTEX = yes;
      FUTEX_PI = yes;

      # WineSync driver for fast kernel-backed Wine
      WINESYNC = module;

      # Preemptive Full Tickless Kernel at 500Hz
      HZ = freeform "500";
      HZ_500 = yes;
      HZ_1000 = no;

      CACHY = yes;
    };

    extraMeta = {
      branch = lib.versions.majorMinor version;
      maintainers = with lib.maintainers; [ fortuneteller2k lovesegfault atemu ];
      description = "Built with custom settings and new features built to provide a stable, responsive and smooth desktop experience";
      broken = stdenv.isAarch64;
    };
  } // (args.argsOverride or { }));
in
{
  lts = xanmodKernelFor ltsVariant;
  tt = (xanmodKernelFor ttVariant).override {
    src = fetchFromGitHub {
      owner = "cassandracomar";
      repo = "xanmod-linux";
      rev = "6.2.8-xanmod1-tt";
      hash = "sha256-LVx08ad5b1uzYIZIozB0DzmdwOxYWug+QM9CRLwlMLg=";
    };
  };
  rt = xanmodKernelFor rtVariant;
  main = xanmodKernelFor mainVariant;
}
