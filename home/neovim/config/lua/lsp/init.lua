local M = {}

local registry

local function load_registry()
  if registry then
    return registry
  end

  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "lsp-registry.json")
  registry = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  return registry
end

local function ordered_server_names()
  local names = vim.tbl_keys(load_registry())
  table.sort(names)
  return names
end

local function base_config(server)
  local config = {}

  if server.cmd then
    config.cmd = server.cmd
  end

  if server.filetypes then
    config.filetypes = server.filetypes
  end

  if server.root_markers then
    config.root_markers = server.root_markers
  end

  return config
end

local function merged_config(name, server)
  local config = base_config(server)

  if server.override then
    config = vim.tbl_deep_extend("force", config, require("lsp.overrides." .. server.override))
  end

  return config
end

function M.server_names()
  return ordered_server_names()
end

function M.setup(capabilities)
  vim.lsp.config("*", { capabilities = capabilities })

  local loaded_registry = load_registry()
  local names = ordered_server_names()

  for _, name in ipairs(names) do
    vim.lsp.config(name, merged_config(name, loaded_registry[name]))
  end

  vim.lsp.enable(names)
end

return M
