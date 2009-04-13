require 'yaml'
require 'enumerator'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'
require File.dirname(__FILE__) + '/string.rb'
require File.dirname(__FILE__) + '/object_stash.rb'

class LocusTree
  attr_accessor :root, :min_children, :max_children
  attr_accessor :nodes
  attr_accessor :positive_nodes
  attr_accessor :depth

  def initialize(min_children, max_children)
    @min_children, @max_children = min_children, max_children
    @nodes = Hash.new(Array.new) #key = level
  end

  # File must be in GFF format, the 4th column ("score") containing the value
  # For example:
  #   chr1	hg18	readdepth	1	    500   8433	.	.	.
  #   chr1	hg18	readdepth	501  	1000	146 	.	.	.
  #   chr1	hg18	readdepth	1001	1500	400 	.	.	.
  #   chr1	hg18	readdepth	1501	2000	716 	.	.	.
  #   chr1	hg18	readdepth	2001	2500	466 	.	.	.
  # CAUTION: File has to be sorted beforehand!!
  def bulk_load(filename)
    # Create all leaf nodes nodes
    File.open(filename).each do |line|
      fields = line.chomp.split(" ")
      chr, start, stop, value = fields[0], fields[3], fields[4], fields[5]
      leaf_node = LocusTree::Node.new(self, Locus.new(chr, start.to_i, stop.to_i), :leaf)
      leaf_node.value = value.to_f
      leaf_node.level = 0
      leaf_node.nr_leaf_nodes = 1
      self.nodes[0].push(leaf_node)
    end

    # Create the tree on top of those leaf nodes
    this_level = 0
    while self.nodes[this_level].length > 1
      new_level_members = Array.new
      self.nodes[this_level].sort_by{|n| n.locus.range.begin}.each_slice(@max_children) do |node_group|
        min_pos = node_group.collect{|n| n.locus.range.begin}.min
        max_pos = node_group.collect{|n| n.locus.range.end}.max
        new_node = LocusTree::Node.new(self, Locus.new(node_group[0].locus.chromosome, min_pos, max_pos), :index)
        new_node.nr_leaf_nodes = node_group.inject(0){|sum, n| sum += n.nr_leaf_nodes}
        new_node.value = node_group.inject(0){|sum, n| sum += n.nr_leaf_nodes*n.value}.to_f/new_node.nr_leaf_nodes
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

  def search(locus, search_level = 0, start_node = @root)
    if start_node == @root
      @positive_nodes = Array.new
    end

    if search_level == @depth
      @positive_nodes = [@root]
      return @positive_nodes
    end

    start_node.children.each do |child_node|
      if child_node.locus.overlaps?(locus)
        if child_node.level > search_level
          self.search(locus, search_level, child_node)
        else
          @positive_nodes.push(child_node)
        end
      else
      end
    end
    return @positive_nodes
  end

  def store(filename = 'locustree.store')
    ObjectStash.store(self, filename)
  end

  def self.load(filename = 'locustree.store')
    return ObjectStash.load(filename)
  end

  def to_s
    output = Array.new
    output.push @depth.to_s + "\t" + @root.locus.to_s + "\t" + @root.value.to_s
    @root.children.each do |node|
      output.push "\t" + node.level.to_s + "\t" + node.locus.to_s + "\t" + node.value.to_s
      node.children.each do |subnode|
        output.push "\t\t" + subnode.level.to_s + "\t" + subnode.locus.to_s + "\t" + subnode.value.to_s
        subnode.children.each do |subsubnode|
          output.push "\t\t\t" + subsubnode.level.to_s + "\t" + subsubnode.locus.to_s + "\t" + subsubnode.value.to_s
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
    attr_accessor :locus
    attr_accessor :value
    attr_accessor :nr_leaf_nodes

    def initialize(rectree, locus, type = :index, parent = nil)
      @rectree = rectree
      @type = type
      @locus = locus
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

    def overlaps?(locus)
      @locus.overlaps?(locus)
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
  rectree.bulk_load(File.dirname(__FILE__) + '/../test/data/loci_with_values.tsv')
#  puts rectree.nodes.to_yaml

  #Search
  puts rectree.to_s
  results = rectree.search(Locus.new('1',69,112), 2)
  puts results.collect{|r| r.locus.to_s}.join("\t")
end
