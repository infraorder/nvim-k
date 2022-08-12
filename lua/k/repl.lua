require('k.table')
local util = require('k.util')
local uv = vim.loop
local ns = vim.api.nvim_create_namespace('kout')

local M = {}

local function enumerate(it)
  local idx, v = 0, nil
  return function()
    v, idx = it(), idx + 1
    return v, idx
  end
end

M.buffers = {}

M.store = {
  connect_timeout = 50,
  constant = false;
}

M.constant_eval = function()
  if (M.store.constant == false) then
    M.store.constant = true;
    vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"},  {command=[[lua if vim.bo.filetype == "k" then require("k").repl.eval() end]] })
  end
end

M.start_repl = function()
  local buffer_name = util.get_buffer_name()
  M.buffers[buffer_name] = {
    port            = util.get_port_number(),
    pending         = {},
    line_cache      = {}
  }

  vim.fn.jobstart({"bash", "-c", "socat TCP4-LISTEN:" .. M.buffers[buffer_name].port .. [[,reuseaddr,fork EXEC:""k,stderr""]]})
  vim.defer_fn(M.create_client, M.store.connect_timeout)
end

M.create_client = function()
  local buffer_name = util.get_buffer_name()

  if (not util.is_empty(M.buffers[buffer_name].client)) then
    uv.close(M.buffers[buffer_name].client)
  end
  local client = uv.new_tcp()

  uv.tcp_connect(client, "127.0.0.1", M.buffers[buffer_name].port, function (err)
    if(err) then
      print("connection failed")
      print(err)
      vim.defer_fn(M.create_client, M.store.connect_timeout)
      return
    end

    print("K. connected to server")

    uv.read_start(client, function (err, chunk)
      assert(not err, err)

      if(chunk == nil) then return end

      if (M.buffers[buffer_name].current ~= nil) then
        M.buffers[buffer_name].response = {
          type = "OK",
          output = chunk,
          data = M.buffers[buffer_name].current.data,
          start = M.buffers[buffer_name].current.start,
          stop = M.buffers[buffer_name].current.stop,
        }
        if (chunk == "OK") then
          M.buffers[buffer_name].pending = {}
          M.buffers[buffer_name].line_cache = table.reduce(
            M.buffers[buffer_name].line_cache,
            function(acc, item)
              if(not (item.index >= M.buffers[buffer_name].current.index)) then
                table.insert(acc, item)
              end
              return acc

            end, {})
        end
        vim.defer_fn(M.draw, 0)
        vim.defer_fn(M.schedule_first, 0)
      end
    end)

    M.buffers[buffer_name].client = client
    vim.defer_fn(M.eval, 0)
  end)
end

M.schedule_first = function()
  local buffer_name = util.get_buffer_name()

  M.buffers[buffer_name].current = table.remove(M.buffers[buffer_name].pending, 1)
  if (M.buffers[buffer_name].current == nil) then 
    if (M.buffers[buffer_name].scheduled) then
      M.eval()
    end
    return
  end
  M.send(M.buffers[buffer_name].current.data)
end

M.draw = function()
  local buffer_name = util.get_buffer_name()

  local error
  local type = M.buffers[buffer_name].response.type
  local output = M.buffers[buffer_name].response.output
  local data = M.buffers[buffer_name].response.data
  local start = M.buffers[buffer_name].response.start
  local stop = M.buffers[buffer_name].response.stop

  local hl = 'koutok'
  if type ~= "OK" then
    local message = output:match("^Error: (.-)\n")
    if message == nil then
      message = output:match("^Error: (.-)$")
    end
    hl = 'kouterr'
    error_line = stop

    local match = output:match('at (.*)\n')
    local col, end_col = 0
    if match then

      for v, k in enumerate(data:gmatch("[^\n]+")) do
        if v:find(match) then
          error_line = start + k - 1
          break
        end
      end

      local col_match = output:match('   (% +%^+)') or output:match('   (%^+)')
      if (col_match) then
        col, end_col = col_match:find('%^+')
        col = col - 1
      end
    end
    
    error = {
      message=message, 
      lnum=error_line, 
      col=col,
      end_col=end_col
    }

  end

  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
      table.insert(lines, {{' ' .. line, hl}})
  end

  M.clear(start, stop)

  -- Reset and show diagnostics
  vim.diagnostic.reset(ns, 0)
  if error ~= nil and error.lnum ~= nil then
    vim.diagnostic.set(ns, 0, {{
      message=error.message,
      lnum=error.lnum,
      col=error.col,
      end_col=error.end_col,
      severity=vim.diagnostic.severity.ERROR,
      source='K',
    }})
  end

  vim.api.nvim_buf_clear_namespace(0, ns, start, stop + 1)
  vim.api.nvim_buf_set_extmark(0, ns, stop, 0, {
    virt_lines=lines
  })

  vim.api.nvim_command("redraw!")
end

M.send = function(data)
  local buffer_name = util.get_buffer_name()
  -- command = "` 0:`k@"
  command = ""
  uv.write(M.buffers[buffer_name].client, command .. data .. "\n")
end

M.ensure_repl_exists = function()
  local buffer_name = util.get_buffer_name()
  if (M.buffers[buffer_name] == nil or M.buffers[buffer_name].client == nil) then
    M.start_repl()
    return false
  end

  return true
end

-- bug here that I don't like
--   when namespace is cleared above carret it won't move the cursor accordingly
M.clear = function(start, stop)
  vim.diagnostic.reset(ns, 0)
  vim.api.nvim_buf_clear_namespace(0, ns, start, stop)
  vim.api.nvim_command("redraw!")
end

M.eval = function(start, stop)
  local redundant_eval = false
  local empty_range = false

  if start ~= nil or start ~= nil or stop == -1 then
    redundant_eval = true
  else
    empty_range = true
  end

  if start == nil then
    start = 0
  end

  if stop == nil or stop == -1 then
    stop = vim.api.nvim_buf_line_count(0)
  end

  local buffer_name = util.get_buffer_name()  

  if not M.ensure_repl_exists() then
    return
  end

  if (M.buffers[buffer_name].pending == {}) then
    M.buffers[buffer_name].scheduled = true;
    return
  end

  M.buffers[buffer_name].pending = table.reduce(
    util.parse(vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), true)),
    function(acc, pending, k)
      if ((redundant_eval 
          or M.buffers[buffer_name].line_cache[k] == nil 
          or M.buffers[buffer_name].line_cache[k].data ~= pending.data)
          and (empty_range or util.between(start, stop, pending))) then

        -- This is to eval every line after file change
        redundant_eval = true

        M.buffers[buffer_name].line_cache[k] = pending
        table.insert(acc, pending)
      end
      -- no change
      return acc
    end, {})

  vim.defer_fn(M.schedule_first, 0)
end

return M
