module LocusTree
  # == Description
  #
  # The LocusTree::Level class describes a level in the tree. Level 0 corresponds
  # to the level of the leaf nodes.
  #
  class Level
    attr_accessor :number, :resolution, :byte_offset

    def initialize(number, byte_offset)
      @number, @byte_offset = number, byte_offset
    end
  end
end
