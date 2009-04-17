require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class BulkLoad < Test::Unit::TestCase
  def setup
    @locus_tree = LocusTree::Container.new(2,3,'density',File.dirname(__FILE__) + '/rtree.sqlite3')
    @locus_tree.bulk_load(File.dirname(__FILE__) + '/data/loci_with_values.gff')
    @small_search_results_level_1 = @locus_tree.search(Locus.new('1',41,89), 1)
    @small_search_results_level_2 = @locus_tree.search(Locus.new('1',41,89), 2)
    @big_search_results_level_0 = @locus_tree.search(Locus.new('1',41,153))
    @big_search_results_level_1 = @locus_tree.search(Locus.new('1',41,153), 1)
    @big_search_results_level_2 = @locus_tree.search(Locus.new('1',41,153), 2)
    @big_search_results_level_3 = @locus_tree.search(Locus.new('1',41,153), 3)
  end

  def test_averages
    assert_equal([3,3], @small_search_results_level_1.collect{|n| n.value}.sort)
    assert_equal([9], @small_search_results_level_2.collect{|n| n.value}.sort)
    assert_equal([4,5,6,7,8,9,10,11,12,13,14,15], @big_search_results_level_0.collect{|n| n.value}.sort)
    assert_equal([3,3,3,3], @big_search_results_level_1.collect{|n| n.value}.sort)
    assert_equal([9,9], @big_search_results_level_2.collect{|n| n.value}.sort)
    assert_equal([20], @big_search_results_level_3.collect{|n| n.value}.sort)
  end

  def teardown
    File.delete(File.dirname(__FILE__) + '/rtree.sqlite3')
  end
end