require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class SearchTest < Test::Unit::TestCase
  # input data looks like this:
  #
  # LEVEL 0              LEVEL 1      LEVEL 2     LEVEL 3 (=root)
  # 10 (value: 1)    -+
  # 20 (value: 2)     |- 10..30   -+
  # 30 (value: 3)    -+            |
  # 40 (value: 4)    -+            |
  # 50 (value: 5)     |- 40..60    |- 10..90   -+
  # 60 (value: 6)    -+            |            |
  # 70 (value: 7)    -+            |            |
  # 80 (value: 8)     |- 70..90   -+            |
  # 90 (value: 9)    -+                         |
  # 100 (value: 10)  -+                         |
  # 110 (value: 11)   |- 100..120 -+            |
  # 120 (value: 12)  -+            |            |- 10..200
  # 130 (value: 13)  -+            |            |
  # 140 (value: 14)   |- 130..150  |- 100..180  |
  # 150 (value: 15)  -+            |            |
  # 160 (value: 16)  -+            |            |
  # 170 (value: 17)   |- 160..180 -+            |
  # 180 (value: 18)  -+                         |
  # 190 (value: 19)  -+                         |
  # 200 (value: 20)  -+- 190..200 --- 190..200 -+
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