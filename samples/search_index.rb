#!/usr/bin/ruby
require '../lib/locus_tree.rb'

bin_size = 4000
nr_children = 2

@container = LocusTree::Container.load_structure('locus_tree_' + bin_size.to_s + '.sqlite3')

positive_nodes = @container.query('2', 143570450, 143571890, bin_size.div(10))
positive_nodes.each do |node|
  puts node.to_s + "\t" + node.value.to_s
end

positive_nodes = @container.query('2', 143570450, 143671890, bin_size + 1)
positive_nodes.each do |node|
  puts node.to_s + "\t" + node.value.to_s
end

positive_nodes = @container.query('2', 143570450, 143671890, nr_children*bin_size + 1)
positive_nodes.each do |node|
  puts node.to_s + "\t" + node.value.to_s
end

puts @container.query_single_bin('24', 500, 50_000).to_s
puts @container.query_single_bin('24', 49_050, 49_500).to_s
puts @container.query_single_bin('24', 999_999, 1_000_002).to_s