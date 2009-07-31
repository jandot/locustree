#!/usr/bin/ruby
require '../lib/locus_tree.rb'

bin_size = 4000
nr_children = 2

@container = LocusTree::Container.new(bin_size, nr_children, 'locus_tree_' + bin_size.to_s + '.sqlite3', 'genes.txt')