local has_dap, dap = pcall(require, 'dap')

local util = require 'blender.util'

---@class BlenderDap
---@field session? table
local M = {
  session = nil,
}

---@class BlenderDapAttachArgs
---@field host string
---@field port number
---@field python_exe string
---@field path_mappings List<unknown>
---@field cwd string

---@param args BlenderDapAttachArgs
M.attach = function(args)
  if not has_dap then
    return false
  end
  local adapter = {
    host = args.host,
    port = args.port,
  }
  local config = {
    type = 'python',
    request = 'attach',
    mode = 'remote',
    name = 'Blender Debugger',
    cwd = args.cwd,
    pathMappings = args.path_mappings,
  }
  local session = dap.attach(adapter, config)
  if session == nil then
    util.notify('Failed to attach to debugger', 'ERROR')
    return false
  end
  M.session = session
  util.notify('Attached to Blender debugger', 'INFO')
  return true
end

local default_buf

local get_default_buf = function()
  local buf = default_buf
  if not default_buf or not vim.api.nvim_buf_is_valid(default_buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      has_dap and 'No active debug session' or 'nvim-dap not installed',
    })
  end
  default_buf = buf
  return buf
end

M.get_buf = function()
  if not has_dap then
    return get_default_buf()
  end
  local buf = vim.fn.bufnr 'dap-repl'
  if buf == -1 and M.session and M.session.initialized and not M.session.closed then
    local all_wins = vim.api.nvim_list_wins()
    local open_wins = {}
    for _, win in pairs(all_wins) do
      open_wins[win] = true
    end
    pcall(dap.repl.open, {})
    buf = vim.fn.bufnr 'dap-repl'
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if not open_wins[win] then
        pcall(vim.api.nvim_win_close, win, true)
        break
      end
    end
  end
  if not buf or buf == -1 then
    return get_default_buf()
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd 'normal! i'
  end)
  return buf
end

return M
