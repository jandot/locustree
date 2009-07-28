module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    include DataMapper::Resource

    property :id, Integer, :serial => true
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
    def initialize(nr_children, filename = 'locus_tree.sqlite3')
      DataMapper.setup(:default, 'sqlite3:' + filename)

      LocusTree::Container.auto_migrate!
      LocusTree::Tree.auto_migrate!
      LocusTree::Level.auto_migrate!
      LocusTree::Node.auto_migrate!
      LocusTree::Feature.auto_migrate!

      self.nr_children = nr_children
      self.database_file = filename
      self.save

      self.create_structure(nr_children)
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
      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        # Create the tree
        tree = LocusTree::Tree.new
        tree.container_id = self.id
        tree.chromosome = chr_number
        tree.save

        # Create the bottom level
        node_id = 0
        level = LocusTree::Level.new
        level.tree_id = tree.id
        level.resolution = bin_size
        level.number = 1
        level.save

        node_ids_in_level = Array.new
        # Create the bottom nodes
        nr_nodes, rest = CHROMOSOME_LENGTHS[chr_number].divmod(bin_size)
        import_file = File.new('/tmp/locus_tree_' + chr_number + '_' + level.number.to_s + '.copy', 'w')
        pbar = ProgressBar.new([chr_number, level.number].join('.'), nr_nodes)
        nr_nodes.times do |nr|
          pbar.inc
          node_id += 1
          node_ids_in_level.push([chr_number, level.number, node_id].join('.'))
          import_file.puts [[chr_number, level.number, node_id].join('.'), level.id, nr*bin_size + 1, nr*bin_size + bin_size, '', ''].join('|')
        end
        pbar.finish
        unless rest == 0
          node_id += 1
          node_ids_in_level.push([chr_number, level.number, node_id].join('.'))
          import_file.puts [[chr_number, level.number, node_id].join('.'), level.id, nr_nodes*bin_size + 1, CHROMOSOME_LENGTHS[chr_number], '', ''].join('|')
        end
        level.node_ids = [node_ids_in_level[0].sub(/\d+\.\d+\./, ''), node_ids_in_level[-1].sub(/\d+\.\d+\./, '')].join('-')
        level.save
        import_file.close
        system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_#{chr_number}_#{level.number.to_s}.copy locus_tree_nodes'"
        
        # How many levels will we have
        max_level_nr = (Math.log(CHROMOSOME_LENGTHS[chr_number]).to_f/Math.log(bin_size)).floor + 1
        previous_level = level

        while previous_level.number < max_level_nr - 1
          node_id = 0
          this_level = LocusTree::Level.new
          this_level.tree_id = tree.id
          this_level.number = previous_level.number + 1
          this_level.resolution = bin_size**this_level.number
          this_level.save

          import_file = File.new('/tmp/locus_tree_' + chr_number + '_' + this_level.number.to_s + '.copy', 'w')

          node_ids_in_level = Array.new
          nr_nodes, rest = LocusTree::Node.count(:level_id => previous_level.id).divmod(bin_size)
          prev_stop = 0
          pbar = ProgressBar.new([chr_number, this_level.number].join('.'), nr_nodes)
          nr_nodes.times do |nr|
            pbar.inc
            node_id += 1
            node_ids_in_level.push([chr_number, this_level.number, node_id].join('.'))
            child_id_array = Array.new
            bin_size.times do |n|
              child_id = bin_size*(node_id-1) + n + 1
              child_id_array.push(chr_number + '.' + previous_level.number.to_s + '.' + child_id.to_s)
            end
            child_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
            import_file.puts [[chr_number, this_level.number, node_id].join('.'), this_level.id, prev_stop + 1, [prev_stop + 1 + (bin_size**this_level.number), CHROMOSOME_LENGTHS[chr_number]].min, '', child_ids].join('|')
            prev_stop = [prev_stop + 1 + (bin_size**this_level.number) - 1, CHROMOSOME_LENGTHS[chr_number]].min
          end
          pbar.finish
          unless rest == 0
            node_id += 1
            node_ids_in_level.push([chr_number, this_level.number, node_id].join('.'))
            child_id_array = Array.new
            rest.times do |n|
              child_id = bin_size*(node_id-1) + n + 1
              child_id_array.push(chr_number + '.' + previous_level.number.to_s + '.' + child_id.to_s)
            end
            child_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
            import_file.puts [[chr_number, this_level.number, node_id].join('.'), this_level.id, prev_stop + 1, CHROMOSOME_LENGTHS[chr_number], '', child_ids].join('|')
          end
          this_level.node_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
          this_level.save
          import_file.close
          system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_#{chr_number}_#{this_level.number.to_s}.copy locus_tree_nodes'"

          previous_level = this_level
        end

        # Wrap up in top level
        this_level = LocusTree::Level.new
        this_level.tree_id = tree.id
        this_level.number = previous_level.number + 1
        this_level.resolution = CHROMOSOME_LENGTHS[chr_number]
        this_level.save

        import_file = File.new('/tmp/locus_tree_' + chr_number + '_' + this_level.number.to_s + '.copy', 'w')

        node_id = 1
        node_ids_in_level = Array.new
        nr_nodes, rest = LocusTree::Node.count(:level_id => previous_level.id).divmod(bin_size)
        child_id_array = Array.new
        rest.times do |n|
          child_id = bin_size*(node_id-1) + n + 1
          node_ids_in_level.push([chr_number, this_level.number, node_id].join('.'))
          child_id_array.push(chr_number + '.' + previous_level.number.to_s + '.' + child_id.to_s)
        end
        this_level.node_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
        this_level.save
        child_ids = [child_id_array[0].sub(/\d+\.\d+\./, ''), child_id_array[-1].sub(/\d+\.\d+\./, '')].join('-')
        import_file.puts [[chr_number, this_level.number, node_id].join('.'), this_level.id, 1, CHROMOSOME_LENGTHS[chr_number], '', child_ids].join('|')
        import_file.close
        system "sqlite3 -separator '|' #{self.database_file} '.import /tmp/locus_tree_#{chr_number}_#{this_level.number.to_s}.copy locus_tree_nodes'"
      end
    end
    
    def query(chromosome, start, stop, resolution)
      level_number = (Math.log(resolution).to_f/Math.log(self.nr_children)).floor
      search_range = Range.new(start, stop)
      tree = self.trees.select{|t| t.chromosome == chromosome}[0]
      max_level = tree.levels.sort_by{|l| l.number}[-1].number
      target_level = nil
      if level_number > max_level
        target_level = tree.levels.sort_by{|l| l.number}[-1]
        warn "Level_number bigger than max_level. Target_level now " + target_level.number.to_s
      else
        target_level = tree.levels.select{|l| l.number >= level_number}.sort_by{|l| l.number}[0]
      end
      
      level = tree.top_level
      nodes_to_check = LocusTree::Node.all(:level_id => level.id)
      until level.number == target_level.number
        positive_nodes_at_level = Array.new
        nodes_to_check.each do |node|
#          child_nodes = node.children
          child_nodes = node.children_in_range(start, stop)
          if node.start >= start and node.stop <= stop
            positive_nodes_at_level.push(child_nodes)
          else
            child_nodes.sort_by{|n| n.start}.each do |child_node|
              next if child_node.stop < start
              if Range.new(child_node.start, child_node.stop).overlaps?(search_range)
                positive_nodes_at_level.push(child_node)
              end
              break if child_node.start > stop
            end
          end
        end
        level = tree.levels.select{|l| l.number == level.number - 1}[0]
        nodes_to_check = positive_nodes_at_level
      end

      return positive_nodes_at_level
    end

    def query_single_bin(chromosome, start, stop)
      tree = self.trees.select{|t| t.chromosome == chromosome}[0]
      
      level = tree.top_level
      nodes_to_check = LocusTree::Node.all(:id => [chromosome, level.number, 1].join('.'))
      answer = Array.new
      while nodes_to_check.length == 1 and level.number >= 2
        answer = nodes_to_check
        positive_nodes_at_level = Array.new
        nodes_to_check.each do |node|
#          child_nodes = node.children
          child_nodes = node.children_in_range(start, stop)
          child_nodes.sort_by{|n| n.start}.each do |child_node|
            next if child_node.stop < start
            if child_node.start <= start and child_node.stop >= stop #Range.new(child_node.start, child_node.stop).overlaps?(search_range)
              positive_nodes_at_level.push(child_node)
            end
            break if child_node.start > stop
          end
        end
        level = tree.levels.select{|l| l.number == level.number - 1}[0]
        nodes_to_check = positive_nodes_at_level
      end
      return answer[0]
    end

    def aggregate(method = [:count])
      self.trees.each do |tree|
        tree.aggregate
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
