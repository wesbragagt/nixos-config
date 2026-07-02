-- Keep tofu-ls scoped to the Terraform/OpenTofu module being edited.
-- Using the enclosing .git directory as the root makes tofu-ls recursively
-- discover large monorepos and can make Neovim appear to hang on .tf files.
local function buffer_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end

  return vim.fs.dirname(vim.fs.normalize(name))
end

return {
  root_dir = function(bufnr, on_dir)
    local dir = buffer_dir(bufnr)
    if not dir then
      return
    end

    on_dir(dir)
  end,

  on_init = function(client)
    -- tofu-ls can return very large/invalid semantic-token payloads for big
    -- Terraform modules, causing Neovim itself to spin at 100% CPU on open.
    client.server_capabilities.semanticTokensProvider = nil
  end,
}
