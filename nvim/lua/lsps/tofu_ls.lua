return {
  cmd = { "tofu-ls", "serve" },
  filetypes = { "terraform", "opentofu", "opentofu-vars", "terraform-vars" },
  root_markers = { ".terraform", ".git", "*.tf" },
}
