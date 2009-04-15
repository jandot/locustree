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
    @locus_tree = LocusTree::Container.open(File.dirname(__FILE__) + '/rtree.sqlite3')
    @results_level_0 = @locus_tree.search(Locus.new('1',69,112))
    @results_level_1 = @locus_tree.search(Locus.new('1',69,112), 1)
    @results_level_2 = @locus_tree.search(Locus.new('1',69,112), 2)
    @results_level_3 = @locus_tree.search(Locus.new('1',69,112), 3)
  end

  def test_results
    assert_equal("70..75;80..85;90..95;100..105;110..115", @results_level_0.collect{|n| n.locus.range.to_s}.join(';'))
    assert_equal("70..95;100..125",                        @results_level_1.collect{|n| n.locus.range.to_s}.join(';'))
    assert_equal("10..95;100..185",                        @results_level_2.collect{|n| n.locus.range.to_s}.join(';'))
    assert_equal("10..205",                                @results_level_3.collect{|n| n.locus.range.to_s}.join(';'))
  end
end