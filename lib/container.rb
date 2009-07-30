module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :base_size, Integer
    property :nr_children, Integer
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
    # Options: 'density' or 'average'. (default = 'density')
    # * _filename_ (optional): name of index file (default = locus_tree.sqlite3)
    # *Returns*:: LocusTree::Container object
    def initialize(base_size = 1000, nr_children = 2, filename = 'locus_tree.sqlite3', feature_file = nil)
      DataMapper.setup(:default, 'sqlite3:' + filename)

      LocusTree::Container.auto_migrate!
      LocusTree::Tree.auto_migrate!
      LocusTree::Level.auto_migrate!
      LocusTree::Node.auto_migrate!
      LocusTree::Feature.auto_migrate!

      self.base_size = base_size
      self.nr_children = nr_children
      self.database_file = filename
      self.save

      if feature_file.nil?
        self.create_structure(nr_children)
      else
        self.create_structure_based_on_features(feature_file)
      end
    end

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

#    # == Description
#    #
#    # Creates the empty structure which will hold the features: it will
#    # create all tree, level and node objects.
#    #
#    # This method is called automatically when the user creates a new Container
#    # object.
#    #
#    # ---
#    # *Arguments*:
#    # * _bin_size_ (required): number of children for each node
#    # *Returns*:: nothing
#    def create_structure(bin_size)
#      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
#        # Create the tree
#        tree = LocusTree::Tree.new
#        tree.container_id = self.id
#        tree.chromosome = chr_number
#        tree.save
#
#        # Create the bottom level
#        node_id = 0
#        level = LocusTree::Level.new
#        level.tree_id = tree.id
#        level.resolution = bin_size
#        level.number = 1
#        level.save
#
##        node_ids_in_level = Array.new
#        # Create the bottom nodes
#        nr_nodes, rest = CHROMOSOME_LENGTHS[chr_number].divmod(bin_size)
#        import_file = File.new('/tmp/locus_tree_' + chr_number + '_' + level.number.to_s + '.copy', 'w')
#        pbar = ProgressBar.new([chr_number, level.number].join('.'), nr_nodes)
#        nr_nodes.times do |nr|
#          pbar.inc
#          node_id += 1
##          node_ids_in_level.push([chr_number, level.number, node_id].join('.'))
#          import_file.puts [[chr_number, level.number, node_id].join('.'), level.id, nr*bin_size + 1, nr*bin_size + bin_size, '', ''].join('|')
#        end
#        pbar.finish
#        unless rest == 0
#          node_id += 1
##          node_ids_in_level.push([chr_number, level.number, node_id].join('.'))
#          import_file.puts [[chr_number, level.number, node_id].join('.'), level.id, nr_nodes*bin_size + 1, CHROMOSOME_LENGTHS[chr_number], '', ''].join('|')
#        end
##        level.node_ids = [node_ids_in_level[0].sub(/\d+\.\d+\./, ''), node_ids_in_level[-1].sub(/\d+\.\d+\./, '')].join('-')
##        level.save
#        import_file.close
#        system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_#{chr_number}_#{level.number.to_s}.copy locus_tree_nodes'"
#
#        # How many levels will we have
#        max_level_nr = (Math.log(CHROMOSOME_LENGTHS[chr_number]).to_f/Math.log(bin_size)).floor + 1
#        previous_level = level
#
#        while previous_level.number < max_level_nr - 1
#          node_id = 0
#          this_level = LocusTree::Level.new
#          this_level.tree_id = tree.id
#          this_level.number = previous_level.number + 1
#          this_level.resolution = bin_size**this_level.number
#          this_level.save
#
#          import_file = File.new('/tmp/locus_tree_' + chr_number + '_' + this_level.number.to_s + '.copy', 'w')
#
##          node_ids_in_level = Array.new
#          nr_nodes, rest = LocusTree::Node.count(:level_id => previous_level.id).divmod(bin_size)
#          prev_stop = 0
#          pbar = ProgressBar.new([chr_number, this_level.number].join('.'), nr_nodes)
#          nr_nodes.times do |nr|
#            pbar.inc
#            node_id += 1
##            node_ids_in_level.push([chr_number, this_level.number, node_id].join('.'))
#            child_id_array = Array.new
#            bin_size.times do |n|
#              child_id = bin_size*(node_id-1) + n + 1
#              child_id_array.push(chr_number + '.' + previous_level.number.to_s + '.' + child_id.to_s)
#            end
#            child_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
#            import_file.puts [[chr_number, this_level.number, node_id].join('.'), this_level.id, prev_stop + 1, [prev_stop + 1 + (bin_size**this_level.number), CHROMOSOME_LENGTHS[chr_number]].min, '', child_ids].join('|')
#            prev_stop = [prev_stop + 1 + (bin_size**this_level.number) - 1, CHROMOSOME_LENGTHS[chr_number]].min
#          end
#          pbar.finish
#          unless rest == 0
#            node_id += 1
##            node_ids_in_level.push([chr_number, this_level.number, node_id].join('.'))
#            child_id_array = Array.new
#            rest.times do |n|
#              child_id = bin_size*(node_id-1) + n + 1
#              child_id_array.push(chr_number + '.' + previous_level.number.to_s + '.' + child_id.to_s)
#            end
#            child_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
#            import_file.puts [[chr_number, this_level.number, node_id].join('.'), this_level.id, prev_stop + 1, CHROMOSOME_LENGTHS[chr_number], '', child_ids].join('|')
#          end
##          this_level.node_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
##          this_level.save
#          import_file.close
#          system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_#{chr_number}_#{this_level.number.to_s}.copy locus_tree_nodes'"
#
#          previous_level = this_level
#        end
#
#        # Wrap up in top level
#        this_level = LocusTree::Level.new
#        this_level.tree_id = tree.id
#        this_level.number = previous_level.number + 1
#        this_level.resolution = CHROMOSOME_LENGTHS[chr_number]
#        this_level.save
#
#        import_file = File.new('/tmp/locus_tree_' + chr_number + '_' + this_level.number.to_s + '.copy', 'w')
#
#        node_id = 1
##        node_ids_in_level = Array.new
#        nr_nodes, rest = LocusTree::Node.count(:level_id => previous_level.id).divmod(bin_size)
#        child_id_array = Array.new
#        rest.times do |n|
#          child_id = bin_size*(node_id-1) + n + 1
##          node_ids_in_level.push([chr_number, this_level.number, node_id].join('.'))
#          child_id_array.push(chr_number + '.' + previous_level.number.to_s + '.' + child_id.to_s)
#        end
##        this_level.node_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
##        this_level.save
#        child_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
#        import_file.puts [[chr_number, this_level.number, node_id].join('.'), this_level.id, 1, CHROMOSOME_LENGTHS[chr_number], '', child_ids].join('|')
#        import_file.close
#        system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_#{chr_number}_#{this_level.number.to_s}.copy locus_tree_nodes'"
#      end
#    end

    def create_structure_based_on_features(feature_file)
      tree_cache = Hash.new #key = chr name; value = tree object
      level_cache = Hash.new #key = chr.level_nr; value = level object
      node_cache = Hash.new #key = node id; value = node object
      CHROMOSOME_LENGTHS.keys.each do |chr_number|
        tree = LocusTree::Tree.new
        tree.container_id = self.id
        tree.chromosome = chr_number
        tree.max_level = (Math.log(CHROMOSOME_LENGTHS[chr_number]).to_f/Math.log(self.nr_children)).floor + 1
        tree.save
        tree_cache[chr_number] = tree
      end

      pbar = ProgressBar.new('creating', `wc -l #{feature_file}`.split[0].to_i)
      File.open(feature_file).each do |line|
        pbar.inc
        name, chr, start, stop = line.chomp.split(/\t/)
        start = start.to_i
        stop = stop.to_i
        level_nr = 0
        until start.node_number(self.base_size, self.nr_children, level_nr) == stop.node_number(self.base_size, self.nr_children, level_nr)
          level_nr += 1
        end
        start_node_nr = start.node_number(self.base_size, self.nr_children, level_nr)
        node_id = [chr, level_nr, start_node_nr].join('.')
        level = level_cache[chr + '.' + level_nr.to_s]
        if level.nil?
          level = LocusTree::Level.new
          level.tree_id = tree_cache[chr].id
          level.resolution = self.nr_children**level_nr
          level.number = level_nr
          level.save
          level_cache[chr + '.' + level_nr.to_s] = level
        end
        node = node_cache[node_id]
        if node.nil?
          node = LocusTree::Node.new
          node.id = node_id
          node.level_id = level.id
          node.start = (start_node_nr - 1) * (self.nr_children**level_nr) * self.base_size + 1
          node.stop = [start_node_nr * (self.nr_children**level_nr) * self.base_size, CHROMOSOME_LENGTHS[chr]].min
#          node.save
          node_cache[node_id] = node
        end
        node.value += 1

        feature = LocusTree::Feature.new
        feature.chr = chr
        feature.start = start.to_i
        feature.stop = stop.to_i
        feature.node_id = node_id
        feature.save

        tree = tree_cache[chr]
        while level_nr < tree.max_level
          level_nr += 1
          level = level_cache[chr + '.' + level_nr.to_s]
          if level.nil?
            level = LocusTree::Level.new
            level.tree_id = tree_cache[chr].id
            level.resolution = [(self.nr_children**level_nr)*self.base_size, CHROMOSOME_LENGTHS[chr]].min
            level.number = level_nr
            level.save
            level_cache[chr + '.' + level_nr.to_s] = level
          end
          start_node_nr = start.node_number(self.base_size, self.nr_children, level_nr)
          node_id = [chr, level_nr, start_node_nr].join('.')
          node = node_cache[node_id]
          if node.nil?
            node = LocusTree::Node.new
            node.id = node_id
            node.level_id = level.id
            node.start = (start_node_nr - 1) * (self.nr_children**level_nr) * self.base_size + 1
            node.stop = [start_node_nr * (self.nr_children**level_nr) * self.base_size, CHROMOSOME_LENGTHS[chr]].min
#            node.save
            node_cache[node_id] = node
          end
          node.value += 1
        end
      end
      pbar.finish

      import_file = File.new('/tmp/locus_tree_nodes.copy', 'w')
      pbar = ProgressBar.new('saving', node_cache.keys.length)
      node_cache.values.each do |node|
        pbar.inc
        import_file.puts [node.id, node.level_id, node.start, node.stop, node.value, ''].join('|')
#        node.save
      end
      pbar.finish
      import_file.close

      system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_nodes.copy locus_tree_nodes'"
    end
    
    def query(chromosome, start, stop, resolution)
      tree = LocusTree::Tree.first(:chromosome => chromosome)

      # We take a conservative approach: get the level that has _at least_ the
      # resolution requested. In case the requested resolution is smaller than
      # that of the bottom level, we have to correct for that and just return
      # that bottom level.
      level_number = (Math.log(resolution).to_f/Math.log(self.nr_children)).floor
      level_number = 1 if level_number == 0
      start_id = start.node_number(self.base_size, self.nr_children, level_number)
      stop_id = stop.node_number(self.base_size, self.nr_children, level_number)
      answer = Array.new
      (start_id..stop_id).each do |id|
        node_id = [chromosome, level_number, id].join('.')
        node = LocusTree::Node.first(:id => node_id)
        if node.nil?
          node = LocusTree::Node.new
          node.id = node_id
          node.level_id = LocusTree::Level.first(:tree_id => tree.id, :number => level_number).id
          node.start = (id - 1) * (self.nr_children**level_number) * self.base_size + 1
          node.stop = [id * (self.nr_children**level_number) * self.base_size, CHROMOSOME_LENGTHS[chromosome]].min
          node.value = 0
        end
        answer.push(node)
      end
      return answer
    end

    def query_single_bin(chromosome, start, stop)
      tree = LocusTree::Tree.first(:chromosome => chromosome)

      # We take a conservative approach: get the level that has _at least_ the
      # resolution requested. In case the requested resolution is smaller than
      # that of the bottom level, we have to correct for that and just return
      # that bottom level.
      level_number = tree.top_level.number
      start_id = (start-1).div(self.nr_children**level_number)
      stop_id = (stop-1).div(self.nr_children**level_number)
      while start_id == stop_id
        previous_start_id = start_id
        previous_level_number = level_number
        level_number -= 1
        start_id = (start-1).div(self.nr_children**level_number)
        stop_id = (stop-1).div(self.nr_children**level_number)
      end
      node_id = [chromosome, previous_level_number, previous_start_id].join('.')
      node = LocusTree::Node.first(:id => previous_start_id)
      if node.nil?
        node = LocusTree::Node.new
        node.id = node_id
        node.level_id = LocusTree::Level.first(:tree_id => tree.id, :number => previous_level_number).id
        node.start = previous_start_id*(self.nr_children**previous_level_number) + 1
        node.stop = [node.start + (self.nr_children**previous_level_number) - 1, CHROMOSOME_LENGTHS[chromosome]].min
        node.value = 0
      end
      return node
    end

#    def aggregate(method = [:count])
#      self.trees.each do |tree|
#        tree.aggregate
#      end
#    end

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
