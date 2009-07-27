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

    property :id, String, :key => true #:serial => true
    property :level_id, Integer
    property :start, Integer
    property :stop, Integer
    property :value, Float
    property :child_ids, String

    belongs_to :level

#    # == Description
#    #
#    # Returns the locus covered by this node.
#    #
#    # == Usage
#    #
#    #   node.locus
#    #
#    # ---
#    # *Arguments*:: none
#    # *Returns*:: Locus object
#    def locus
#      if @locus.nil?
#        @locus = Locus.new(self.chromosome, self.start, self.stop)
#      end
#      return @locus
#    end

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

    def to_s
      return self.level.tree.chromosome + ':' + self.start.to_s + '..' + self.stop.to_s
    end
  end
end