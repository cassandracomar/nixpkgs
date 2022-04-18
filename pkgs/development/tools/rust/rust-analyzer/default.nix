{ lib, stdenv, fetchFromGitHub, rustPlatform, CoreServices, cmake, libiconv
, useMimalloc ? false, doCheck ? true }:

rustPlatform.buildRustPackage rec {
  pname = "rust-analyzer-unwrapped";
  version = "2022-04-18";
  cargoSha256 = "sha256-m3HnV2pUEy8HUDkQ7TB9e8V68gUdduyBF+1Nat92W2E=";

  src = fetchFromGitHub {
    owner = "rust-analyzer";
    repo = "rust-analyzer";
    rev = version;
    sha256 = "sha256-jJO6/IMGbd1kOzLXP28L16B7RtxjQuhYkkeSsVkGGM4=";
  };

  patches = [
    # Code format and git history check require more dependencies but don't really matter for packaging.
    # So just ignore them.
    ./ignore-git-and-rustfmt-tests.patch
  ];

  buildAndTestSubdir = "crates/rust-analyzer";

  nativeBuildInputs = lib.optional useMimalloc cmake;

  buildInputs = lib.optionals stdenv.isDarwin [ CoreServices libiconv ];

  buildFeatures = lib.optional useMimalloc "mimalloc";

  RUST_ANALYZER_REV = version;

  inherit doCheck;
  preCheck = lib.optionalString doCheck ''
    export RUST_SRC_PATH=${rustPlatform.rustLibSrc}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    versionOutput="$($out/bin/rust-analyzer --version)"
    echo "'rust-analyzer --version' returns: $versionOutput"
    [[ "$versionOutput" == "rust-analyzer ${version}" ]]
    runHook postInstallCheck
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "A modular compiler frontend for the Rust language";
    homepage = "https://rust-analyzer.github.io";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ oxalica ];
  };
}
