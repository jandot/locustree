require 'enumerator'
#require 'progressbar'
require 'logger'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'
require File.dirname(__FILE__) + '/fixnum.rb'
require File.dirname(__FILE__) + '/container.rb'
require File.dirname(__FILE__) + '/tree.rb'
require File.dirname(__FILE__) + '/level.rb'
require File.dirname(__FILE__) + '/node.rb'
require File.dirname(__FILE__) + '/feature.rb'

CHROMOSOME_LENGTHS = {1 => 28,
                      2 => 19
}
#CHROMOSOME_LENGTHS = {1 => 247249719,
#                      2 => 242951149,
#                      3 => 199501827,
#                      4 => 191273063,
#                      5 => 180857866,
#                      6 => 170899992,
#                      7 => 158821424,
#                      8 => 146274826,
#                      9 => 140273252,
#                      10 => 135374737,
#                      11 => 134452384,
#                      12 => 132349534,
#                      13 => 114142980,
#                      14 => 106368585,
#                      15 => 100338915,
#                      16 => 88827254,
#                      17 => 78774742,
#                      18 => 76117153,
#                      19 => 63811651,
#                      20 => 62435964,
#                      21 => 46944323,
#                      22 => 49691432,
#                      23 => 154913754,
#                      24 => 57772954
#                     }

if __FILE__ == $0
#  bin_size = 400
#  nr_children = 2
#
#  container = LocusTree::Container.create_structure(bin_size, nr_children, 'tmp.txt.sorted')
  container = LocusTree::Container.open(File.dirname(__FILE__) + '/../samples/minimal_example.bed.idx')
  puts container.get_node(1,1,0).to_s
  puts container.get_node(1,5,0).to_s
  puts container.get_node(1,6,0).to_s
  puts container.get_node(1,10,0).to_s
  

#  puts container.get_node(1,1,0).to_s
#  puts container.get_node(1,4000,0).to_s
#  puts container.get_node(1,4001,0).to_s
#  puts container.get_node(1,8000,0).to_s
#  puts container.get_node(1,20_000_000,3).to_s
#  puts container.get_node(1,20_000_001,3).to_s
#  puts container.get_node(1,20_000_001,14).to_s
  container.get_nodes(1,6,16,1).each do |n|
    puts n.to_s
  end
#  container.get_nodes(3,177000000,190000000,6).each do |node|
#    puts node.to_s
#  end
end
