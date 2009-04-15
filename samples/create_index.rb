#!/usr/bin/ruby
require '../lib/locus_tree.rb'

container = LocusTree::Container.new(5, 50)
container.bulk_load('first_mio.gff')
