require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class BulkLoad < Test::Unit::TestCase
  def setup
    @locus_tree = LocusTree.new(2,3)
    @locus_tree.bulk_load(File.dirname(__FILE__) + '/data/bulk_load.tsv')
  end

  def test_levels
    assert_equal(20, @locus_tree.nodes[0].length)
    assert_equal(7, @locus_tree.nodes[1].length)
    assert_equal(3, @locus_tree.nodes[2].length)
    assert_equal(1, @locus_tree.nodes[3].length)
  end

  def test_depth
    assert_equal(4, @locus_tree.depth)
  end
end