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

    property :id, Integer, :serial => true
#    property :tree_id, Integer
    property :level_id, Integer
#    property :chromosome, String
    property :start, Integer
    property :stop, Integer
    property :value, Float
    property :parent_node_id, Integer
    property :nr_leaf_nodes, Integer
#    property :type, String #is root, index or leaf
#    property :child_ids, String #1,2,3,4,5
#    belongs_to :tree
    belongs_to :level

    attr_accessor :locus
    attr_accessor :children

    # == Description
    #
    # Returns the locus covered by this node.
    #
    # == Usage
    #
    #   node.locus
    #
    # ---
    # *Arguments*:: none
    # *Returns*:: Locus object
    def locus
      if @locus.nil?
        @locus = Locus.new(self.chromosome, self.start, self.stop)
      end
      return @locus
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
    def children
      if @children.nil?
        @children = Array.new
        self.child_ids.split(/,/).each do |child_id|
          @children.push(self.class.first(:id => child_id))
        end
      end
      return @children
    end

    # == Description
    #
    # Split a node.
    #
    # == Usage
    #
    #   new_nodes = node.split
    #
    # ---
    # *Arguments*:: none
    # *Returns*:: Array of Node objects
    def split
      raise NotImplementedError
    end

    # == Description
    #
    # Merges two nodes.
    #
    # == Usage
    #
    #   merged_node = node_a.merge(node_b)
    #
    # ---
    # *Arguments*:: Node object
    # *Returns*:: Node object
    def merge(other_node)
      raise NotImplementedError
    end
  end
end