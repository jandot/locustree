require 'yaml'
require 'enumerator'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'

class LocusTree
  attr_accessor :root, :min_children, :max_children
  attr_accessor :nodes
  attr_accessor :positive_nodes
  attr_accessor :depth

  def initialize(min_children, max_children)
    @min_children, @max_children = min_children, max_children
    @nodes = Hash.new(Array.new) #key = level
  end

  #File must have 2 columns: position and value
  def bulk_load(filename)
    #create all leaf nodes and first index nodes
    File.open(filename).sort_by{|v| v.to_i}.each do |line|
      position, value = line.chomp.split("\t")
      leaf_node = LocusTree::Node.new(self, Range.new(position.to_i, position.to_i), :leaf)
      leaf_node.value = value.to_f
      leaf_node.level = 0
      self.nodes[0].push(leaf_node)
    end

    this_level = 0
    while self.nodes[this_level].length > 1
      new_level_members = Array.new
      self.nodes[this_level].sort_by{|n| n.range.begin}.each_slice(@max_children) do |node_group|
        min_pos = node_group.collect{|n| n.range.begin}.min
        max_pos = node_group.collect{|n| n.range.end}.max
        new_node = LocusTree::Node.new(self, Range.new(min_pos, max_pos), :index)
        new_node.value = node_group.inject(0){|sum, n| sum += n.value}/node_group.length
        new_node.level = this_level + 1
        new_node.children = node_group.to_a
        new_level_members.push(new_node)
      end
      self.nodes[this_level + 1] = new_level_members
      this_level += 1
    end
    @depth = this_level
    @root = self.nodes[@depth][0]
    
  end

  def search(range, search_level = 0, start_node = @root)
    if start_node == @root
      @positive_nodes = Array.new
    end

    if search_level == @depth
      @positive_nodes = [@root]
      return @positive_nodes
    end

    start_node.children.each do |child|
      if child.overlaps?(range)
        if child.level > search_level
          self.search(range, search_level, child)
        else
          @positive_nodes.push(child)
        end
      else
      end
    end
    return @positive_nodes
  end

  def to_s
    output = Array.new
    output.push @depth.to_s + "\t" + @root.range.to_s
    @root.children.each do |node|
      output.push "\t" + node.level.to_s + "\t" + node.range.to_s
      node.children.each do |subnode|
        output.push "\t\t" + subnode.level.to_s + "\t" + subnode.range.to_s
        subnode.children.each do |subsubnode|
          output.push "\t\t\t" + subsubnode.level.to_s + "\t" + subsubnode.range.to_s
        end
      end
    end
    return output.join("\n")
  end

  class Node
    attr_accessor :rectree
    attr_accessor :type #is :root, :index or :leaf
    attr_accessor :level
    attr_accessor :parent, :children
    attr_accessor :range
    attr_accessor :value

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
end

if __FILE__ == $0
#  locus_tree = LocusTree.new(2,10)
#
#  #Build from the top
#  root = LocusTree::Node.new(locus_tree, Range.new(1,100), :root, nil)
#  child1 = LocusTree::Node.new(locus_tree, Range.new(1,70), :index, root)
#  child2 = LocusTree::Node.new(locus_tree, Range.new(71,100), :index, root)
#  child3 = LocusTree::Node.new(locus_tree, Range.new(35,43), :index, child1)
#  puts root.children.collect{|c| c.range.to_s}.join("\t")
#  puts child3.range.to_s + "\t" + child3.parent.range.to_s
#  puts locus_tree.root.range.to_s
#  puts locus_tree.min_children.to_s + "\t" + locus_tree.max_children.to_s

  #Build from the bottom (using packed method from http://donar.umiacs.umd.edu/quadtree/docs/locus_tree_split_rules.html#packed)
  rectree = LocusTree.new(2, 3)
  rectree.bulk_load(File.dirname(__FILE__) + '/../test/data/data_with_values.tsv')
#  puts rectree.nodes.to_yaml

  #Search
  puts rectree.to_s
  results = rectree.search(Range.new(69,112), 2)
  puts results.collect{|r| r.range.to_s}.join("\t")
end
