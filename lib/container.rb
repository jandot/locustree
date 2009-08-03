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

    def create_structure_based_on_features(feature_file)
      tree_cache = Hash.new #key = chr name; value = tree object
      level_cache = Hash.new #key = chr.level_nr; value = level object
      node_cache = Hash.new #key = node id; value = node object
      CHROMOSOME_LENGTHS.keys.each do |chr_number|
        STDERR.puts "chr: " + chr_number.to_s
        tree = LocusTree::Tree.new
        tree.container_id = self.id
        tree.chromosome = chr_number
        tree.max_level = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/self.base_size).to_f/Math.log(self.nr_children)).floor + 1
        STDERR.puts "tree max_level: " + tree.max_level.to_s
        tree.save
        tree_cache[chr_number] = tree
      end

      import_file = File.new('/tmp/locus_tree_features.copy', 'w')
      pbar = ProgressBar.new('creating', `wc -l #{feature_file}`.split[0].to_i)
      feature_id = 0
      File.open(feature_file).each do |line|
        pbar.inc
        feature_id += 1
        name, chr, start, stop = line.chomp.split(/\t/)
        start = start.to_i
        stop = stop.to_i
        level_nr = 0
        until start.node_number(self.base_size, self.nr_children, level_nr) == stop.node_number(self.base_size, self.nr_children, level_nr)
          level_nr += 1
        end
#        STDERR.puts "level: " + level_nr.to_s
        start_node_nr = start.node_number(self.base_size, self.nr_children, level_nr)
#        STDERR.puts "node_nr: " + start_node_nr.to_s
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

#        feature = LocusTree::Feature.new
#        feature.chr = chr
#        feature.start = start.to_i
#        feature.stop = stop.to_i
#        feature.node_id = node_id
#        feature.save
        import_file.puts [feature_id, node_id, chr, start, stop, ''].join('|')

        tree = tree_cache[chr]
        while level_nr <= tree.max_level
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
      import_file.close
      system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_features.copy locus_tree_features'"

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
      level_number = (Math.log(resolution.to_f/self.base_size).to_f/Math.log(self.nr_children)).floor
      level_number = 0 if level_number < 0
      start_id = start.node_number(self.base_size, self.nr_children, level_number)
      stop_id = stop.node_number(self.base_size, self.nr_children, level_number)
      answer = Array.new
      (start_id..stop_id).each do |id|
        node_id = [chromosome, level_number, id].join('.')
        node = LocusTree::Node.first(:id => node_id)
        if node.nil?
          node = LocusTree::Node.new
          node.id = node_id
          level = LocusTree::Level.first(:tree_id => tree.id, :number => level_number)
          if level.nil?
            level = LocusTree::Level.new
            level.tree_id = tree.id
            level.number = level_number
          end
          node.level = level
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
      STDERR.puts "Query start level_nr: " + level_number.to_s
      start_id = (start-1).div(self.nr_children**level_number)
      stop_id = (stop-1).div(self.nr_children**level_number)
      previous_start_id = 0
      previous_level_number = level_number
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
        level = LocusTree::Level.first(:tree_id => tree.id, :number => previous_level_number)
        if level.nil?
          level = LocusTree::Level.new
          level.tree_id = tree.id
          level.number = previous_level_number
        end
        node.level = level
        node.start = previous_start_id*(self.nr_children**previous_level_number) + 1
        node.stop = [node.start + (self.nr_children**previous_level_number) - 1, CHROMOSOME_LENGTHS[chromosome]].min
        node.value = 0
      end
      return node
    end
  end
end
