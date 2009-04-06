require 'test/unit'
require 'enumerator'

require '../lib/rectree.rb'

class BulkLoad < Test::Unit::TestCase
  def setup
    @rtree = RecTree.new(2,3)
    @rtree.bulk_load(File.dirname(__FILE__) + '/data/bulk_load.tsv')
  end

  def test_levels
    assert_equal(20, @rtree.nodes[0].length)
    assert_equal(7, @rtree.nodes[1].length)
    assert_equal(3, @rtree.nodes[2].length)
    assert_equal(1, @rtree.nodes[3].length)
  end

  def test_depth
    assert_equal(4, @rtree.depth)
  end
end