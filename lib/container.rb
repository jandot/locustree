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

#    # == Description
#    #
#    # Loads LocusTree::Container data from an existing index fil
#    #
#    # == Usage
#    #
#    #   container = LocusTree::Container.open('index_file.sqlite3')
#    #
#    # ---
#    # *Arguments*:
#    # * _filename_ (optional): name of index file (default = locus_tree.sqlite3)
#    # *Returns*:: LocusTree::Container object
#    def self.open(filename = 'locus_tree.sqlite3')
#      DataMapper.setup(:default, 'sqlite3:' + filename)
#      return LocusTree::Container.first(:id => 1)
#    end

    # == Description
    #
    # Attaches a predefined structure to the container.
    #
    # ---
    # *Arguments*:
    # * _filename_ (required): filename of sqlite database
    # *Returns*:: container
    def self.load_structure(filename)
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
        STDERR.puts chr_number
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
        node.chromosome = tree.chromosome
        node.start = 1
        node.stop = CHROMOSOME_LENGTHS[chr_number]
        node.save
        node_id = node.id

        # Build the structure
        node_id = node.id
        while level.resolution > bin_size
          puts "\tlevel resolution: " + level.resolution.to_s
          parent_level = level
          level = LocusTree::Level.new
          level.tree_id = tree.id
          level.number = parent_level.number + 1
          level.resolution = ((parent_level.resolution.to_f/bin_size).floor + 1)
          level.save

          import_file = File.new('/tmp/sqlite_import.copy', 'w')
          parent_level.nodes.each do |parent_node|
#            puts "\t\tparent node: " + [parent_node.start, parent_node.stop].join('-')
            parent_node.child_ids = ''
            start = parent_node.start
            while start < parent_node.stop
              node_id += 1
#              node = LocusTree::Node.new
#              node.chromosome = tree.chromosome
#              node.start = start
#              node.stop = [start + level.resolution - 1, parent_node.stop].min
#              node.level_id = level.id
#              node.save
              stop = [start + level.resolution - 1, parent_node.stop].min
              import_file.puts [node_id, level.id, tree.chromosome, start, stop, nil, nil].join('|')
              parent_node.child_ids += node_id.to_s + ','
              start = stop + 1
            end
            parent_node.child_ids.sub!(/,$/, '')
            parent_node.save
          end
          import_file.close
          system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/sqlite_import.copy locus_tree_nodes'"
          File.delete('/tmp/sqlite_import.copy')
        end
        STDERR.puts "levels: " + level.number.to_s

      end
    end

    def query(chromosome, start, stop, resolution = 5)
      search_range = Range.new(start, stop)
      tree = self.trees.select{|t| t.chromosome == chromosome}[0]
      max_resolution = tree.levels.sort_by{|l| l.resolution}[0].resolution
      target_level = nil
      if resolution < max_resolution
        target_level = tree.levels.sort_by{|l| l.resolution}[0]
      else
        target_level = tree.levels.select{|l| l.resolution >= resolution}.sort_by{|l| l.resolution}[-1]
      end
      
      level = tree.top_level
      nodes_to_check = LocusTree::Node.all(:level_id => level.id)
      until level == target_level
        positive_nodes_at_level = Array.new
        nodes_to_check.each do |node|
          child_ids = node.child_ids.split(/,/)
          child_nodes = Array.new
          child_ids.each do |id|
            child_nodes.push(LocusTree::Node.get!(id))
          end
          child_nodes.each do |child_node|
            if Range.new(child_node.start, child_node.stop).overlaps?(search_range)
              positive_nodes_at_level.push(child_node)
            end
          end
        end
        level = tree.levels.select{|l| l.number == level.number + 1}[0]
        nodes_to_check = positive_nodes_at_level
      end

      return positive_nodes_at_level
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