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
    attr_accessor :level, :start, :stop, :count, :flag, :sum, :min, :max
    attr_accessor :feature_byte_offsets
    attr_accessor :byte_offset

    def initialize(level, start, stop, count = 0, flag = 0, sum = nil, min = nil, max = nil, feature_byte_offsets = Array.new)
      @level, @start, @stop, @count, @flag, @sum, @min, @max, @feature_byte_offsets = level, start, stop, count, flag, sum, min, max, feature_byte_offsets
    end

    def to_s
      return [@level.tree.chromosome, @level.number, @start, @stop, @count, @flag, @sum, @min, @max, @feature_byte_offsets].join("\t")
    end

    def parent_node
      return nil if @level.tree.nr_levels == @level.number + 1

      parent_level_number = @level.number + 1
      parent_node = @level.tree.container.get_node(@level.tree.chromosome, @start + @level.tree.container.base_size.div(2), parent_level_number)
      return parent_node
    end

    def child_nodes
      return [] if @level.number == 0

      child_level_number = @level.number - 1
      return @level.tree.container.get_nodes(@level.tree.chromosome, @start, @stop, child_level_number)
    end
  end
end
