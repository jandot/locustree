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
    attr_accessor :start, :stop, :count, :avg, :min, :max
    attr_accessor :byte_offset

    def initialize(start, stop, count, avg)
      @start, @stop, @count, @avg = start, stop, count, avg
    end

    def to_s
      return [@start, @stop, @count, @avg].join("\t")
    end
  end
end
