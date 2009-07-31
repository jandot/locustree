module LocusTree
  # == Description
  #
  # The LocusTree::Node class describes a single node of the tree. A node
  # contains a number of child-nodes (between Container.min_children and
  # Container.max_children). There are 3 types of nodes: (1) leaf-nodes are
  # at the raw data-level, (2) index nodes are nodes that contain other nodes,
  # and the (3) root node is the index node at the top of the tree, which is
  # not contained in any other node.
  #
  class Node
    include DataMapper::Resource

    property :id, String, :key => true, :index => true
    property :level_id, Integer, :index => true
    property :start, Integer, :index => true
    property :stop, Integer, :index => true
    property :value, Float, :default => 0.0
    property :child_ids, String

    belongs_to :level
    has n, :features

    def children
      return [] if self.level.number == 1

      answer = Array.new
      bin_size = self.level.tree.container.nr_children
      chr = self.level.tree.chromosome
      level_nr = self.level.number - 1
      number = self.id.sub(/^\d+\.\d+\./,'').to_i
      left_boundary = number*bin_size - (bin_size - 1)
      right_boundary = number*bin_size
      (left_boundary..right_boundary).each do |n|
        node = self.class.first(:id => [chr, level_nr, n].join('.'))
        answer.push(node) unless node.nil?
      end
      return answer
    end

    # == Description
    #
    # Returns the children of this node.
    #
    # == Usage
    #
    #   node.children
    #
    # ---
    # *Arguments*:: none
    # *Returns*:: Array of Node objects
    def children_in_range(start, stop)
      return [] if self.level.number == 1

      answer = Array.new
      bin_size = self.level.tree.container.nr_children
      chr = self.level.tree.chromosome
      level_nr = self.level.number - 1
#      number = self.id.sub(/^\d+\.\d+\./,'').to_i
      left_boundary = start.div(bin_size**(level_nr))# + 1
      right_boundary = stop.div(bin_size**(level_nr))# + 1
#      STDERR.puts "    boundaries: " + [left_boundary, right_boundary].join('-')
      (left_boundary..right_boundary).each do |n|
        node = self.class.first(:id => [chr, level_nr, n].join('.'))
        answer.push(node) unless node.nil?
      end
      return answer
    end

    def to_s
      return self.id + "\t" + self.level.tree.chromosome + ':' + self.start.to_s + '..' + self.stop.to_s
    end
  end
end
