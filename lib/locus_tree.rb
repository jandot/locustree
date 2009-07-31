require 'enumerator'
require 'dm-core'
require 'dm-aggregates'
require 'progressbar'
require 'logger'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'
require File.dirname(__FILE__) + '/fixnum.rb'
#require File.dirname(__FILE__) + '/string.rb'
require File.dirname(__FILE__) + '/container.rb'
require File.dirname(__FILE__) + '/tree.rb'
require File.dirname(__FILE__) + '/level.rb'
require File.dirname(__FILE__) + '/node.rb'
require File.dirname(__FILE__) + '/feature.rb'

CHROMOSOME_LENGTHS = {'1' => 247249719,
                      '2' => 242951149,
                      '3' => 199501827,
                      '4' => 191273063,
                      '5' => 180857866,
                      '6' => 170899992,
                      '7' => 158821424,
                      '8' => 146274826,
                      '9' => 140273252,
                      '10' => 135374737,
                      '11' => 134452384,
                      '12' => 132349534,
                      '13' => 114142980,
                      '14' => 106368585,
                      '15' => 100338915,
                      '16' => 88827254,
                      '17' => 78774742,
                      '18' => 76117153,
                      '19' => 63811651,
                      '20' => 62435964,
                      '21' => 46944323,
                      '22' => 49691432,
                      '23' => 154913754,
                      '24' => 57772954
                     }

if __FILE__ == $0
  bin_size = 4000
  nr_children = 2

#  @container = LocusTree::Container.new(bin_size, nr_children, 'locus_tree_' + bin_size.to_s + '.sqlite3', 'genes.txt')
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
end
