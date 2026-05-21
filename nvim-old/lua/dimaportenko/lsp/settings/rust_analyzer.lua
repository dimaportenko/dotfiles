return {
  settings = {
    cmd = {
      "rustup", "run", "stable", "rust-analyzer"
    },
    diagnostics = {
      enable = true,
      experimental = {
        enable = true,
      },
    },
  },
}
