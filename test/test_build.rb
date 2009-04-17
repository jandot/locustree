require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class BulkLoad < Test::Unit::TestCase
  def setup
    @locus_tree = LocusTree::Container.new(2,3,'average',File.dirname(__FILE__) + '/rtree.sqlite3')
    @locus_tree.bulk_load(File.dirname(__FILE__) + '/data/loci_with_values.gff')
  end

  def test_levels
    assert_equal(20, @locus_tree.trees.first(:chromosome => '1').levels.first(:number => 0).nodes.length)
    assert_equal(7, @locus_tree.trees.first(:chromosome => '1').levels.first(:number => 1).nodes.length)
    assert_equal(3, @locus_tree.trees.first(:chromosome => '1').levels.first(:number => 2).nodes.length)
    assert_equal(1, @locus_tree.trees.first(:chromosome => '1').levels.first(:number => 3).nodes.length)
  end

  def test_depth
    assert_equal(3, @locus_tree.trees.first(:chromosome => '1').depth)
  end
end