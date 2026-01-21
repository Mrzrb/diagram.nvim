---@class SvgOptions
---@field width? number
---@field height? number
---@field dpi? number
---@field background? string
---@field cli_args? string[]

---@class Renderer<SvgOptions>
local M = {
  id = "svg",
}

-- fs cache
local cache_dir = vim.fn.resolve(vim.fn.stdpath("cache") .. "/diagram-cache/svg")
vim.fn.mkdir(cache_dir, "p")

---@param source string
---@param options SvgOptions
---@return table|nil
M.render = function(source, options)
  local hash = vim.fn.sha256(M.id .. ":" .. source)
  local path = vim.fn.resolve(cache_dir .. "/" .. hash .. ".png")
  if vim.fn.filereadable(path) == 1 then return { file_path = path } end

  if not vim.fn.executable("rsvg-convert") then
    vim.notify("rsvg-convert not found in PATH. Please install librsvg to use SVG diagrams.", vim.log.levels.ERROR, { title = "Diagram.nvim" })
    return nil
  end

  local tmpsource = vim.fn.tempname() .. ".svg"
  vim.fn.writefile(vim.split(source, "\n"), tmpsource)

  local command_parts = {
    "rsvg-convert",
  }

  -- Add custom CLI arguments if provided
  if options.cli_args and #options.cli_args > 0 then vim.list_extend(command_parts, options.cli_args) end

  -- Add standard arguments
  if options.width then
    table.insert(command_parts, "--width")
    table.insert(command_parts, tostring(options.width))
  end
  if options.height then
    table.insert(command_parts, "--height")
    table.insert(command_parts, tostring(options.height))
  end
  if options.dpi then
    table.insert(command_parts, "--dpi-x")
    table.insert(command_parts, tostring(options.dpi))
    table.insert(command_parts, "--dpi-y")
    table.insert(command_parts, tostring(options.dpi))
  end
  if options.background then
    table.insert(command_parts, "--background-color")
    table.insert(command_parts, options.background)
  end

  vim.list_extend(command_parts, {
    "-o",
    path,
    tmpsource,
  })

  local command = table.concat(command_parts, " ")

  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(job_id, data, event) end,
    on_stderr = function(job_id, data, event)
      local error_msg = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
      if error_msg ~= "" then
        vim.notify("Failed to render SVG diagram:\n" .. error_msg, vim.log.levels.ERROR, { title = "Diagram.nvim" })
      end
    end,
    on_exit = function(job_id, exit_code, event)
      -- Clean up temp file
      vim.fn.delete(tmpsource)
    end,
  })
  return { file_path = path, job_id = job_id }
end

return M
