#!/usr/bin/ruby
require '../lib/locus_tree.rb'

container = LocusTree::Container.open('locus_tree.sqlite3')
results = container.search(Locus.new('1', 500, 700000), 1)

results.each do |r|
  puts r.locus.to_s + "\t" + r.value.to_s
end
