table.reduce = function (list, fn, init)
  local acc = init
  for k, v in ipairs(list) do
    if 1 == k and not init then
      acc = v
    else
      acc = fn(acc, v, k)
    end
  end
  return acc
end
