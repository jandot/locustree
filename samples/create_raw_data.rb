#!/usr/bin/ruby
outfile = File.open('first_mio.gff','w')
start = 1
600000.times do |n|
  value = rand(500)
  if rand(100) == 1
    value += rand(10000)
  end
  outfile.puts [1, 'hg18', 'readdepth', start, start+499, value, '.','.','.'].join("\t")
  start += 500
end
start = 1
300000.times do |n|
  value = rand(500)
  if rand(100) == 1
    value += rand(10000)
  end
  outfile.puts [2, 'hg18', 'readdepth', start, start+499, value, '.','.','.'].join("\t")
  start += 500
end
start = 1
100000.times do |n|
  value = rand(500)
  if rand(100) == 1
    value += rand(10000)
  end
  outfile.puts [3, 'hg18', 'readdepth', start, start+499, value, '.','.','.'].join("\t")
  start += 500
end
outfile.close