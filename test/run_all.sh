#!/usr/bin/ruby
Dir.glob("test_*rb").each do |fn|
  system("ruby #{fn}")
end
