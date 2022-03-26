local str = debug.getinfo(2, "S").source:sub(2)
print(str)
print(string.match(str, "^(.*[\\/])") or ".")
str = arg[0]
print(str)
print(string.match(str, "^(.*[\\/])") or ".")