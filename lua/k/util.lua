-- TODO make this better
--   currently lua's gsub expression '%b⟨⟩'
--   or any noon ascii character for that matter is not working
is_balanced = function(s)
  return not s:match('^(%w+)(%b[])%s+(%w+)$')
     and not s:match('^(%w+)(%b{})%s+(%w+)$')
     and not s:match('^(%w+)(%b())%s+(%w+)$')
     and     math.fmod(count_quote(s), 2) == 0
end

function count_quote(s)
  return select(2, s:gsub('"', ''))
end

util = {}

util.get_port_number = function()
  local exec = assert(io.popen([[netstat -aln | awk '
    $6 == "LISTEN" {
      if ($4 ~ "[.:][0-9]+$") {
        split($4, a, /[:.]/);
        port = a[length(a)];
        p[port] = 1
      }
    }
    END {
      for (i = 3000; i < 65000 && p[i]; i++){};
      if (i == 65000) {exit 1};
      print i
    }
  ']]))
  return tonumber(exec:read('*all'))
end

util.get_buffer_name = function()
  return vim.fn.expand('%:p'):gsub("^/", ""):gsub("/", ".")
end

util.is_empty = function(s) return s == nil or s == '' end

util.between = function(start, stop, line)
  return (start >= line.start and stop <= line.stop + 1)
end

util.trim = function(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

util.parse = function(data)
  local i = 0;
  local index = 0;
  return table.reduce(data, function(acc, line, k)
    if (not util.is_empty(util.trim(line:gsub("%s*%/[^\n\r]*", "") or line))) then
      if (acc[#acc] == nil 
          or util.is_empty(acc[#acc].data) 
          or is_balanced(acc[#acc].data)) then
        table.insert(acc, {
          index = index,
          start = i,
          stop = i,
          data = line:match("%s*%/[^\n\r]*") or line
        })
        index = index + 1
      else
        acc[#acc].stop = i
        acc[#acc].data = acc[#acc].data .. '\n' .. (line:match("%s*%/[^\n\r]*") or line)
      end
    end
    i = i + 1
    return acc
  end, {})
end

return util
