#!/usr/bin/ruby

Dir['../src/com/**/*.as'].each do |file|
  data = IO.read(file)
  data.gsub!(/\/\/\/\s@\w*cond\n/m, "")
  data.gsub!(/package\s*([\w\.]+)\n\{\n/m, "/// @cond\npackage \\1\n{\n/// @endcond\n")
  open(file, "w") do |io|
    io.write(data)
  end
end

