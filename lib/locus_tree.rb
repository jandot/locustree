require 'enumerator'
require 'dm-core'
require 'dm-aggregates'
require 'progressbar'
require 'logger'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'
require File.dirname(__FILE__) + '/string.rb'
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
  bin_size = 1000
#  logger = Logger.new('logger_' + bin_size.to_s + '.txt')
#  logger.level = Logger::INFO

#  logger.info "Creating structure"
#  @container = LocusTree::Container.new(bin_size, 'locus_tree_' + bin_size.to_s + '.sqlite3')
#  @container = LocusTree::Container.new(bin_size, 'locus_tree_' + bin_size.to_s + '.sqlite3', 'genes.txt')
  @container = LocusTree::Container.load_structure('locus_tree_' + bin_size.to_s + '.sqlite3')
#
#  logger.info "Creating indexes"
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_level_id ON locus_tree_levels(id)'")
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_level_tree ON locus_tree_levels(tree_id)'")
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_node_id ON locus_tree_nodes(id)'")
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_node_level ON locus_tree_nodes(level_id)'")
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_node_start ON locus_tree_nodes(start)'")
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_node_stop ON locus_tree_nodes(stop)'")
#
#  logger.info "Loading features"
#  pbar = ProgressBar.new('features', 36653)
#  File.open('genes.txt').each do |line|
#    pbar.inc
#    name, chr, start, stop = line.chomp.split(/\t/)
#    feature = LocusTree::Feature.new
#    feature.chr = chr
#    feature.start = start.to_i
#    feature.stop = stop.to_i
#    node = @container.query_single_bin(chr, start.to_i, stop.to_i)
#    feature.node_id = node.id
#    feature.save
#  end
#  pbar.finish
#
#  logger.info "Creating indexes on features"
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_feature_id ON locus_tree_features(id)'")
#  system("sqlite3 locus_tree_#{bin_size.to_s}.sqlite3 'CREATE INDEX ind_feature_node ON locus_tree_features(node_id)'")
#
#  logger.info "Aggregating features"
#  @container.aggregate(:count)
#
#  logger.info "Fetching stuff"
#  positive_nodes = @container.query('1', 500, 10000000, 999999)
#  positive_nodes.each do |node|
#    puts node.to_s + "\t" + node.value.to_s
#  end
#
  puts @container.query_single_bin('24', 500, 50_000).to_s
  puts @container.query_single_bin('24', 49_050, 49_500).to_s
  puts @container.query_single_bin('24', 999999, 1000002).to_s
end
