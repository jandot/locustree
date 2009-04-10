require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class SearchTest < Test::Unit::TestCase
  def setup
    @locus_tree = LocusTree.new(2,3)
    @locus_tree.bulk_load(File.dirname(__FILE__) + '/data/data_with_values.tsv')
    @results_level_0 = @locus_tree.search(Range.new(69,112))
    @results_level_1 = @locus_tree.search(Range.new(69,112), 1)
    @results_level_2 = @locus_tree.search(Range.new(69,112), 2)
    @results_level_3 = @locus_tree.search(Range.new(69,112), 3)
  end

  def test_results
    assert_equal("70..70;80..80;90..90;100..100;110..110", @results_level_0.collect{|n| n.range.to_s}.join(';'))
    assert_equal("70..90;100..120",                        @results_level_1.collect{|n| n.range.to_s}.join(';'))
    assert_equal("10..90;100..180",                        @results_level_2.collect{|n| n.range.to_s}.join(';'))
    assert_equal("10..200",                                @results_level_3.collect{|n| n.range.to_s}.join(';'))
  end
end