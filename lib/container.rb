module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :nr_children, Integer
    property :aggregation, String
    property :database_file, String
    has n, :trees

    # == Description
    #
    # Create a new LocusTree::Container
    #
    # == Usage
    #
    #   container = LocusTree::Container.new(2,5,'average','index_file.sqlite3')
    #
    # ---
    # *Arguments*:
    # * _nr_children_ (required): number of children for each node
    # * _aggregation_ (optional): how to aggregate data in higher-level nodes.
    # Options: 'density' or 'average'. (default = 'density')
    # * _filename_ (optional): name of index file (default = locus_tree.sqlite3)
    # *Returns*:: LocusTree::Container object
    def initialize(nr_children, aggregation = 'density', filename = 'locus_tree.sqlite3')
      DataMapper.setup(:default, 'sqlite3:' + filename)

      LocusTree::Container.auto_migrate!
      LocusTree::Tree.auto_migrate!
      LocusTree::Level.auto_migrate!
      LocusTree::Node.auto_migrate!

      self.nr_children = nr_children
      self.aggregation = aggregation
      self.database_file = filename
      self.save

      self.create_structure(nr_children)
    end

    # == Description
    #
    # Loads LocusTree::Container data from an existing index fil
    #
    # == Usage
    #
    #   container = LocusTree::Container.open('index_file.sqlite3')
    #
    # ---
    # *Arguments*:
    # * _filename_ (optional): name of index file (default = locus_tree.sqlite3)
    # *Returns*:: LocusTree::Container object
    def self.open(filename = 'locus_tree.sqlite3')
      DataMapper.setup(:default, 'sqlite3:' + filename)
      return LocusTree::Container.first(:id => 1)
    end

    # == Description
    #
    # Creates the empty structure which will hold the features: it will
    # create all tree, level and node objects.
    #
    # This method is called automatically when the user creates a new Container
    # object.
    #
    # ---
    # *Arguments*:
    # * _bin_size_ (required): number of children for each node
    # *Returns*:: nothing
    def create_structure(bin_size)
      CHROMOSOME_LENGTHS.each_key do |chr_number|
        # Create the tree
        tree = LocusTree::Tree.new
        tree.container_id = self.id
        tree.chromosome = chr_number
        tree.save

        # Create the top level
        level = LocusTree::Level.new
        level.tree_id = tree.id
        level.resolution = CHROMOSOME_LENGTHS[chr_number]
        level.number = 0
        level.save

        # Create the top node
        node = LocusTree::Node.new
        node.level_id = level.id
        node.start = 1
        node.stop = CHROMOSOME_LENGTHS[chr_number]
        node.save

        # Build the structure
        while level.resolution > bin_size
          parent_level = level
          level = LocusTree::Level.new
          level.tree_id = tree.id
          level.number = parent_level.number + 1
          level.resolution = ((parent_level.resolution.to_f/bin_size).floor + 1)
          level.save

          parent_level.nodes.each do |parent_node|
            start = parent_node.start
            while start < parent_node.stop
              node = LocusTree::Node.new
              node.start = start
              node.stop = [start + level.resolution - 1, parent_node.stop].min
              node.level_id = level.id
              node.save
              start = node.stop + 1
            end
            
          end
        end


      end
    end

    # == Description
    #
    # Prints out the container
    #
    # == Usage
    #
    #   puts container.to_s
    #
    # ---
    # *Arguments*:: none
    # *Returns*:: String
    def to_s
      output = Array.new
      self.trees.each do |tree|
        output.push("Container for chromosome " + tree.chromosome.to_s)
        output.push tree.to_s
      end
      return output.join("\n")
    end

    # == Description
    #
    # Searches the container for a locus
    #
    # == Usage
    #
    #   container.search(Locus.new('1', 1, 5000), 1)
    #
    # ---
    # *Arguments*:
    # * _locus_ (required):: locus to search for. E.g. Locus.new('1', 1, 5000)
    # * _search_level_ (optional):: level to collect nodes from (default = 0)
    # * _start_node_ (optional):: node to start search from (default = root node of that chromosome)
    # *Returns*:: Array of Node objects
    def search(locus, search_level = 0, start_node = self.trees.first(:chromosome => locus.chromosome).root)
      return self.trees.first(:chromosome => locus.chromosome).search(locus, search_level, start_node)
    end
  end
end