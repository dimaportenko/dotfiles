return {
  -- Use the rust-analyzer that ships with the active rustup toolchain instead of
  -- the Mason-managed copy. The rustup binary is always version-locked to `rustc`,
  -- so the proc-macro server ABI can never drift out of sync after a `rustup update`.
  -- (Fixes: "proc-macro server's api version (N) is newer than rust-analyzer's (M)".)
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        cmd = { "rustup", "run", "stable", "rust-analyzer" },
      },
    },
  },
}
