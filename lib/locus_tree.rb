require 'enumerator'
require 'dm-core'
require 'dm-aggregates'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'
require File.dirname(__FILE__) + '/string.rb'
require File.dirname(__FILE__) + '/container.rb'
require File.dirname(__FILE__) + '/tree.rb'
require File.dirname(__FILE__) + '/level.rb'
require File.dirname(__FILE__) + '/node.rb'

CHROMOSOME_LENGTHS = {'1' => 105,
                      '2' => 90
                     }

#CHROMOSOME_LENGTHS = {'1' => 247249719,
#                      '2' => 242951149,
#                      '3' => 199501827,
#                      '4' => 191273063,
#                      '5' => 180857866,
#                      '6' => 170899992,
#                      '7' => 158821424,
#                      '8' => 146274826,
#                      '9' => 140273252,
#                      '10' => 135374737,
#                      '11' => 134452384,
#                      '12' => 132349534,
#                      '13' => 114142980,
#                      '14' => 106368585,
#                      '15' => 100338915,
#                      '16' => 88827254,
#                      '17' => 78774742,
#                      '18' => 76117153,
#                      '19' => 63811651,
#                      '20' => 62435964,
#                      '21' => 46944323,
#                      '22' => 49691432,
#                      '23' => 154913754,
#                      '24' => 57772954
#                     }

if __FILE__ == $0
  @container = LocusTree::Container.new(5)
  puts @container.to_s
#  @container.bulk_load('../test/data/loci_with_values.gff')
#  puts @container.to_s
end