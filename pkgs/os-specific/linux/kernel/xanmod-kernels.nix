{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

let
  # These names are how they are designated in https://xanmod.org.
  ltsVariant = {
    version = "5.15.60";
    hash = "sha256-XSOYgrJ/uvPpEG+P3Zy1geFeF/HMZ4LejsKWtTxMUTs=";
    variant = "lts";
  };

  edgeVariant = {
    version = "6.0.1";
    hash = "sha256-zZGAlBbdx1rWOqo7BI5pr/o0Z3VKr/PDqZaOa9N2Sow=";
    variant = "edge";
  };

  ttVariant = {
    version = "5.15.54";
    suffix = "xanmod1-tt";
    hash = "sha256-4ck9PAFuIt/TxA/U+moGlVfCudJnzSuAw7ooFG3OJis=";
    variant = "tt";
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
      X86_AMD_PSTATE = yes;

      # Google's BBRv2 TCP congestion Control
      TCP_CONG_BBR2 = yes;
      DEFAULT_BBR2 = yes;

      # FQ-PIE Packet Scheduling
      NET_SCH_DEFAULT = yes;
      DEFAULT_FQ_PIE = yes;

      # Graysky's additional CPU optimizations
      CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

      # Futex WAIT_MULTIPLE implementation for Wine / Proton Fsync.
      FUTEX = yes;
      FUTEX_PI = yes;

      # WineSync driver for fast kernel-backed Wine
      WINESYNC = module;
    } // lib.optionalAttrs (variant == "tt") {
      # removed options
      CFS_BANDWIDTH = lib.mkForce (option no);
      RT_GROUP_SCHED = lib.mkForce (option no);
      SCHED_AUTOGROUP = lib.mkForce (option no);
      SCHED_CORE = lib.mkForce (option no);
    } // lib.optionalAttrs (variant == "edge") {
      # this has been removed as of 6.0; xanmod sets KCFLAGS="-O3" in its makefile.
      # see: https://github.com/xanmod/linux/blob/6cbaa601f6074e14c6d8aeb0bf163f793f314f58/arch/x86/Makefile#L70-L71
      CC_OPTIMIZE_FOR_PERFORMANCE_O3 = lib.mkForce (option no);
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
  edge = xanmodKernelFor edgeVariant;
  tt = xanmodKernelFor ttVariant;
}
