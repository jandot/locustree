require 'yaml'

class Range
  def overlaps?(other_range)
    self.include?(other_range.begin) or other_range.include?(self.begin)
  end

  def self.merge(ranges)
    return Range.new(ranges.collect{|r| r.begin}.min, ranges.collect{|r| r.end}.max)
  end
end

class RecTree
  attr_accessor :root, :min_children, :max_children
  attr_accessor :nodes
  attr_accessor :positive_nodes

  def initialize(min_children, max_children)
    @min_children, @max_children = min_children, max_children
    @nodes = Hash.new(Array.new) #key = level
  end

  def bulk_load(filename)
    #create all leaf nodes and first index nodes
    File.open(filename).sort_by{|v| v.to_i}.each do |line|
      position = line.chomp.to_i
      leaf_node = RecTree::Node.new(self, Range.new(position, position), :leaf)
      leaf_node.level = 0
      self.nodes[0].push(leaf_node)
    end

    this_level = 0
    while self.nodes[this_level].length > 1
      new_level = Array.new
      self.nodes[this_level].sort_by{|n| n.range.begin}.each_slice(@max_children) do |node_group|
        min_pos = node_group.collect{|n| n.range.begin}.min
        max_pos = node_group.collect{|n| n.range.end}.max
        new_node = RecTree::Node.new(self, Range.new(min_pos, max_pos), :index)
        new_node.level = this_level + 1
        new_node.children = node_group.to_a
        new_level.push(new_node)
      end
      self.nodes[this_level + 1] = new_level
      this_level += 1
    end
    
    
  end

  class Node
    attr_accessor :rectree
    attr_accessor :type #is :root, :index or :leaf
    attr_accessor :level
    attr_accessor :parent, :children
    attr_accessor :range

    def initialize(rectree, range, type = :index, parent = nil)
      @rectree = rectree
      @type = type
      @range = range
      @parent = parent
      @children = Array.new
      if @type == :root
        @rectree.root = self
      elsif ! @parent.nil?
        @parent.children.push(self)
        if @parent.children.length > @rectree.max_children
          @parent.split
        end
      end
    end

    def overlaps?(range)
      @range.overlaps?(range)
    end

    def split

    end
  end

  def search(range, start_node = RecTree.root)
    if start_node == RecTree.root
      RecTree.positive_nodes = Array.new
    end

    start_node.children.each do |child|
      if child.overlaps?(range)
        if child.type == :index or child.type == :root
          child.children.each do |grandchild|
            RecTree.search(range, grandchild)
          end
        else
          RecTree.positive_nodes.push(child)
        end
      end
    end
  end
end

if __FILE__ == $0
  rtree = RecTree.new(2,10)

  #Build from the top
  root = RecTree::Node.new(rtree, Range.new(1,100), :root, nil)
  child1 = RecTree::Node.new(rtree, Range.new(1,70), :index, root)
  child2 = RecTree::Node.new(rtree, Range.new(71,100), :index, root)
  child3 = RecTree::Node.new(rtree, Range.new(35,43), :index, child1)
  puts root.children.collect{|c| c.range.to_s}.join("\t")
  puts child3.range.to_s + "\t" + child3.parent.range.to_s
  puts rtree.root.range.to_s
  puts rtree.min_children.to_s + "\t" + rtree.max_children.to_s

  #Build from the bottom (using packed method from http://donar.umiacs.umd.edu/quadtree/docs/rtree_split_rules.html#packed)
  rectree = RecTree.new(2, 10)
  rectree.bulk_load(File.dirname(__FILE__) + '/../test/data/test_data.txt')
  puts rectree.nodes.to_yaml
end
