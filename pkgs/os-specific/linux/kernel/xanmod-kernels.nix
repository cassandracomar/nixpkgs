{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

let
  # These names are how they are designated in https://xanmod.org.
  ltsVariant = {
    version = "5.15.75";
    hash = "sha256-tgm5nmguEfRFq3OhmZgRgFLIW7E798Rv1basxnfdqLI=";
    variant = "lts";
  };

  ttVariant = {
    version = "6.0.6";
    suffix = "xanmod1-tt";
    hash = "sha256-FUkQB6eIi9FHSMeUGQYJUxlVjpl/bIIoR6pBtKr5WbQ=";
    variant = "tt";
  };

  mainVariant = {
    version = "6.0.6";
    hash = "sha256-JMfAtiPDgoVF+ypeFXev06PL39ZM2H7m07IxpasjAoM=";
    variant = "main";
  };

  rtVariant = {
    version = "6.0.2";
    hash = "sha256-bJWMHBBXpsOHASYwaCU4flfgzoUlDRFjBudDqKCk3Ac=";
    variant = "rt";
  };

  xanmodKernelFor = { version, suffix ? "xanmod1", hash, variant }: buildLinux (args // rec {
    inherit version;
    modDirVersion = "${version}-${suffix}";

    src = fetchFromGitHub {
      owner = "xanmod";
      repo = "linux";
      rev = modDirVersion;
      inherit hash;
    };

    structuredExtraConfig = with lib.kernel; {
      # AMD P-state driver
      X86_AMD_PSTATE = lib.mkForce yes;

      # Google's BBRv2 TCP congestion Control
      TCP_CONG_BBR2 = yes;
      DEFAULT_BBR2 = yes;

      # Google's Multigenerational LRU framework
      LRU_GEN = yes;
      LRU_GEN_ENABLED = yes;

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
      rev = "6.0.6-xanmod1-tt";
      hash = "sha256-FUkQB6eIi9FHSMeUGQYJUxlVjpl/bIIoR6pBtKr5WbQ=";
    };
  };
  rt = xanmodKernelFor rtVariant;
  main = xanmodKernelFor mainVariant;
}
