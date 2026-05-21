P = function(v)
  print(vim.inspect(v))
  return v
end

RELOAD = function(...)
  return require("plenary.reload").reload_module(...)
end

RR = function(name)
  RELOAD(name)
  return require(name)
end

R = function(name)
  package.loaded[name] = nil
  return require(name)
end
