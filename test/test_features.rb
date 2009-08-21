require 'test/unit'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class TestFeatures < Test::Unit::TestCase
  def setup
    @container = LocusTree::Container.open(File.dirname(__FILE__) + '/minimal_example.bed.idx')
  end

  def test_get_features_single_node
    features = @container.get_features('1', 10, 20)
    assert_equal(2, features.length)
  end

  def test_get_features_multiple_nodes
    features = @container.get_features('1', 10, 27)
    assert_equal(4, features.length)
  end

  def test_feature_values
    features = @container.get_features('1', 10, 27)
    assert_equal([11,12,18,19], features.collect{|f| f.value}.sort)
  end
end
