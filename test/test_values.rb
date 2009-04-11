require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class ValuesTest < Test::Unit::TestCase
  def setup
    @locus_tree = LocusTree.new(2,3)
    @locus_tree.bulk_load(File.dirname(__FILE__) + '/data/loci_with_values.tsv')
    @small_search_results_level_1 = @locus_tree.search(Locus.new('1',41,89), 1)
    @small_search_results_level_2 = @locus_tree.search(Locus.new('1',41,89), 2)
    @big_search_results_level_0 = @locus_tree.search(Locus.new('1',41,153))
    @big_search_results_level_1 = @locus_tree.search(Locus.new('1',41,153), 1)
    @big_search_results_level_2 = @locus_tree.search(Locus.new('1',41,153), 2)
    @big_search_results_level_3 = @locus_tree.search(Locus.new('1',41,153), 3)
  end

  def test_averages
    assert_equal([5,8], @small_search_results_level_1.collect{|n| n.value}.sort)
    assert_equal([5], @small_search_results_level_2.collect{|n| n.value}.sort)
    assert_equal([4,5,6,7,8,9,10,11,12,13,14,15], @big_search_results_level_0.collect{|n| n.value}.sort)
    assert_equal([5,8,11,14], @big_search_results_level_1.collect{|n| n.value}.sort)
    assert_equal([5,14], @big_search_results_level_2.collect{|n| n.value}.sort)
    assert_equal([10.5], @big_search_results_level_3.collect{|n| n.value}.sort)
  end
end