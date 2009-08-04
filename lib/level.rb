module LocusTree
  # == Description
  #
  # The LocusTree::Level class describes a level in the tree. Level 0 corresponds
  # to the level of the leaf nodes.
  #
  class Level
    attr_accessor :tree, :number, :resolution, :byte_offset

    def initialize(tree, number, byte_offset)
      @tree, @number, @byte_offset = tree, number, byte_offset
    end
  end
end
