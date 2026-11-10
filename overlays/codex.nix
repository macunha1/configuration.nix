_final: prev: {
  # Codex still bundles native libraries that the new Rust setup hook
  # requires from the system (including AWS-LC, zstd, and SQLite).
  codex = prev.codex.overrideAttrs (_previousAttrs: {
    dontCargoUseSystemLibs = true;
  });
}
