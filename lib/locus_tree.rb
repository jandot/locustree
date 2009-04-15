require 'yaml'
require 'enumerator'
require 'progressbar'
require 'dm-core'

require File.dirname(__FILE__) + '/range.rb'
require File.dirname(__FILE__) + '/locus.rb'
require File.dirname(__FILE__) + '/string.rb'

DataMapper.setup(:default, 'sqlite3:' + File.dirname(__FILE__) + '/rtree.sqlite3')

module LocusTree
  class Container
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :min_children, Integer
    property :max_children, Integer
    property :database_file, String
    has n, :trees

    def initialize(min_children, max_children, filename = File.dirname(__FILE__) + '/rtree.sqlite3')
      DataMapper.setup(:default, 'sqlite3:' + filename)

      LocusTree::Container.auto_migrate!
      LocusTree::Tree.auto_migrate!
      LocusTree::Level.auto_migrate!
      LocusTree::Node.auto_migrate!

      self.min_children = min_children
      self.max_children = max_children
      self.database_file = filename
      self.save
    end

    def self.open(filename = File.dirname(__FILE__) + '/rtree.sqlite3')
      DataMapper.setup(:default, 'sqlite3:' + filename)
      return LocusTree::Container.first(:id => 1)
    end

#    def initialize(min_children, max_children)
#      container = LocusTree::Container.new
#      container.min_children = min_children
#      container.max_children = max_children
#      container.save
#    end

    # File must be in GFF format, the 4th column ("score") containing the value
    # For example:
    #   chr1	hg18	readdepth	1	    500   8433	.	.	.
    #   chr1	hg18	readdepth	501  	1000	146 	.	.	.
    #   chr1	hg18	readdepth	1001	1500	400 	.	.	.
    #   chr1	hg18	readdepth	1501	2000	716 	.	.	.
    #   chr1	hg18	readdepth	2001	2500	466 	.	.	.
    # CAUTION: File has to be sorted beforehand!!
    def bulk_load(filename)
      `cut -f 1 #{filename} | sort | uniq`.each do |chr|
        tree = LocusTree::Tree.new
        tree.container_id = self.id
        tree.chromosome = chr.chomp
        tree.save
      end

      tree_hash = Hash.new
      self.trees.each do |t|
        tree_hash[t.chromosome] = t
      end

      # Create all leaf nodes
      level_hash = Hash.new
      self.trees.each do |tree|
        level_zero = LocusTree::Level.new
        level_zero.tree_id = tree.id
        level_zero.number = 0
        level_zero.save
        level_hash[tree.chromosome] = level_zero
      end

      import_file = File.new('/tmp/sqlite_import.copy', 'w')
      pbar = ProgressBar.new('leaf', 6045280)
      id = 0
      File.open(filename).each do |line|
        pbar.inc
        fields = line.chomp.split(/\t/)
        chr, start, stop, value = fields[0], fields[3], fields[4], fields[5]
        id += 1
        import_file.puts [id, tree_hash[chr].id, level_hash[chr].id, chr, start.to_i, stop.to_i, value.to_f, 1, 'leaf', ''].join('|')
      end
      pbar.finish
      import_file.close
      system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/sqlite_import.copy locus_tree_nodes'"
      File.delete('/tmp/sqlite_import.copy')

      # Create the tree on top of those leaf nodes
      self.trees.each do |tree|
        STDERR.puts "DEBUG: chromosome " + tree.chromosome.to_s
        this_level = level_hash[tree.chromosome]
        while this_level.nodes.length > 1
          next_level = LocusTree::Level.new
          next_level.tree_id = tree.id
          next_level.number = this_level.number + 1
          next_level.save
          this_level.nodes.sort_by{|n| n.start}.each_slice(self.max_children) do |node_group|
            min_pos = node_group.collect{|n| n.start}.min
            max_pos = node_group.collect{|n| n.stop}.max
            new_node = LocusTree::Node.new
            new_node.tree_id = tree.id
            new_node.chromosome = node_group[0].chromosome
            new_node.start = min_pos
            new_node.stop = max_pos
            new_node.type = 'index'
            new_node.nr_leaf_nodes = node_group.inject(0){|sum, n| sum += n.nr_leaf_nodes}
            new_node.value = node_group.inject(0){|sum, n| sum += n.nr_leaf_nodes*n.value}.to_f/new_node.nr_leaf_nodes
            new_node.level_id = next_level.id
            new_node.child_ids = node_group.collect{|n| n.id}.join(',')
            new_node.save
          end
          this_level = next_level
        end
        tree.depth = this_level.number
        root_node = Node.all(:tree_id => tree.id).sort_by{|n| n.level.number}[-1]
        tree.root_id = root_node.id
        root_node.type = 'root'
        root_node.save
        tree.save
      end
    end

    def to_s
      output = Array.new
      self.trees.each do |tree|
        output.push("Container for chromosome " + tree.chromosome.to_s)
        output.push tree.to_s
      end
      return output.join("\n")
    end

    def search(locus, search_level = 0, start_node = self.trees.first(:chromosome => locus.chromosome).root)
      return self.trees.first(:chromosome => locus.chromosome).search(locus, search_level, start_node)
    end

#    def store(filename = 'locustree.store')
#      ObjectStash.store(self, filename)
#    end
#
#    def self.load(filename = 'locustree.store')
#      return ObjectStash.load(filename)
#    end
  end

  class Tree
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :container_id, Integer
    property :root_id, Integer
    property :chromosome, String
    property :depth, Integer
    belongs_to :container
    has n, :levels
    has n, :nodes

  #  attr_accessor :root, :min_children, :max_children
  #  attr_accessor :nodes
    attr_accessor :positive_nodes
  #  attr_accessor :depth


#    def initialize
#      @nodes = Hash.new(Array.new) #key = level
#    end

    def root
      return Node.first(:id => self.root_id)
    end

    def search(locus, search_level = 0, start_node = self.root)
      if start_node == self.root
        @positive_nodes = Array.new
      end

      if search_level == self.depth
        @positive_nodes = [self.root]
        return @positive_nodes
      end

      start_node.children.each do |child_node|
        if child_node.locus.overlaps?(locus)
          if child_node.level.number > search_level
            self.search(locus, search_level, child_node)
          else
            @positive_nodes.push(child_node)
          end
        else
        end
      end
      return @positive_nodes
    end

    def to_s
      output = Array.new
      output.push self.depth.to_s + "\t" + self.root.locus.to_s + "\t" + self.root.value.to_s
      self.root.children.each do |node|
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
  end

  class Level
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :tree_id, Integer
    property :number, Integer

    belongs_to :tree
    has n, :nodes
  end

  class Node
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :tree_id, Integer
    property :level_id, Integer
    property :chromosome, String
    property :start, Integer
    property :stop, Integer
    property :value, Float
    property :nr_leaf_nodes, Integer
    property :type, String #is root, index or leaf
    property :child_ids, String #1,2,3,4,5
    belongs_to :tree
    belongs_to :level

    attr_accessor :locus
    attr_accessor :children

    def locus
      if @locus.nil?
        @locus = Locus.new(self.chromosome, self.start, self.stop)
      end
      return @locus
    end

    def children
      if @children.nil?
        @children = Array.new
        self.child_ids.split(/,/).each do |child_id|
          @children.push(self.class.first(:id => child_id))
        end
      end
      return @children
    end

#    def parent
#      return self.first(:id => self.parent_id)
#    end

#    attr_accessor :rectree
#    attr_accessor :type #is :root, :index or :leaf
#    attr_accessor :level
#    attr_accessor :parent, :children
#    attr_accessor :locus
#    attr_accessor :value
#    attr_accessor :nr_leaf_nodes


#    def initialize(tree, locus, type = :index, parent = nil)
#      @rectree = tree
#      @type = type
#      @locus = locus
#      @parent = parent
#      @children = Array.new
#      if @type == :root
#        @rectree.root = self
#      elsif ! @parent.nil?
#        @parent.children.push(self)
#        if @parent.children.length > @rectree.max_children
#          @parent.split
#        end
#      end
#    end

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
#  rectree = LocusTree.new(2, 3)
#  rectree.bulk_load(File.dirname(__FILE__) + '/../test/data/bindepth-500_chr1.gff')
#  rectree.store(File.dirname(__FILE__) + '/data.store')
#  puts rectree.nodes.to_yaml

  #Search
#  puts rectree.to_s
#  rectree = LocusTree.load(File.dirname(__FILE__) + '/data.store')
#
#  results = rectree.search(Locus.new('1',1000,50000), 2)
#  puts results.collect{|r| r.locus.to_s}.join("\n")


  tree_container = LocusTree::Container.new(50,250)
  tree_container.bulk_load(File.dirname(__FILE__) + '/../test/data/bindepth-500.gff')

#  tree_container = LocusTree::Container.open
#  puts tree_container.min_children.to_s + "\t" + tree_container.max_children.to_s
#  results = tree_container.search(Locus.new('1',1000,490000), 1)
#  puts results.collect{|n| n.locus.range.to_s}.join("\n")

#  tree_container.store(File.dirname(__FILE__) + '/data.store')
#  puts tree_container.to_s

#  puts "Started loading"
#  tree_container = LocusContainer.load(File.dirname(__FILE__) + '/data.store')
#  puts tree_container.trees['3'].to_s
end
