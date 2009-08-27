module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    attr_accessor :magic
    attr_accessor :source_file, :index_file
    attr_accessor :header_byte_size, :data_part_offset, :initial_node_byte_size
    attr_accessor :aggregate_order
    attr_accessor :base_size, :nr_children
    attr_accessor :trees, :tree_offsets
    attr_accessor :total_nr_nodes
    
    def self.create_structure(base_size = 1000, nr_children = 2, feature_file = 'features.bed', aggregate_flag = 3, filename = feature_file + '.idx')
      initial_byte_size_features_per_node = 120 #Will allow for storing the feature offsets

      container = self.new
      container.index_file = File.open(filename, 'wb')
      container.base_size = base_size
      container.nr_children = nr_children

      header_a_byte_size = 0
      header_b_byte_size = 0
      header_c_byte_size = 0
      data_part_offset = 0
      
      # Create header
      header_a = Array.new
      header_b = Array.new
      header_b_hash = Hash.new
      header_c = Array.new
      # 1. General information: part A
      header_a << "LocusTree_v1"
      header_a << feature_file.length
      header_a << feature_file
      header_a << 0 # will become byteoffset datapart
      header_a << base_size
      header_a << nr_children
      header_a << CHROMOSOME_LENGTHS.keys.length

      header_a_byte_size = 12 + 4 + feature_file.length + 8 + 4 + 4 + 4 #magic + length filename + filename + byteoffset datapart + base_size + nr_children + nr chromosomes
      STDERR.puts "header_a_byte_size = " + header_a_byte_size.to_s
      running_offset_header_b = 0
      running_offset_header_c = 0
      running_offset_data = 0
      CHROMOSOME_LENGTHS.keys.each do |chr_number|
        header_b_hash[chr_number] = Hash.new
        header_b_hash[chr_number][:chr_length] = CHROMOSOME_LENGTHS[chr_number]
        nr_levels = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/base_size).to_f/Math.log(nr_children)).floor + 2
        header_b_hash[chr_number][:nr_levels] = nr_levels
        running_offset_header_b += 12
        running_offset_header_b += nr_levels*8
        header_b_hash[chr_number][:node_offsets] = Array.new
        nr_levels.times do |level_number|
          header_b_hash[chr_number][:node_offsets] << running_offset_header_c
          nr_nodes = (CHROMOSOME_LENGTHS[chr_number]/(base_size*(nr_children**level_number))).ceil + 1
          running_offset_header_c += nr_nodes*8
          STDERR.puts "Nr nodes: " + nr_nodes.to_s
          nr_nodes.times do
            header_c << running_offset_data; running_offset_data += initial_byte_size_features_per_node
          end
        end
      end

      header_b_byte_size = running_offset_header_b
      header_c_byte_size = running_offset_header_c
      STDERR.puts "header_b_byte_size = " + header_b_byte_size.to_s
      STDERR.puts "header_c_byte_size = " + header_c_byte_size.to_s

      container.index_file << header_a.pack("a12Ia#{feature_file.length}QI3")

      header_b_hash.keys.each do |chr_number|
        STDERR.puts "Going through chr " + chr_number.to_s
        container.index_file << [chr_number].pack("I")
        container.index_file << [CHROMOSOME_LENGTHS[chr_number]].pack("I")
        container.index_file << [header_b_hash[chr_number][:nr_levels]].pack("I")
        header_b_hash[chr_number][:node_offsets].each do |node_offset|
          STDERR.puts [node_offset, header_b_byte_size, node_offset + header_a_byte_size + header_b_byte_size].join("\t")
          container.index_file << [node_offset + header_a_byte_size + header_b_byte_size].pack("Q")
        end
      end

      header_c.each do |node_offset|
        container.index_file << [node_offset + header_a_byte_size + header_b_byte_size + header_c_byte_size].pack("Q")
      end
      
      container.index_file.pos = 12 + 4 + feature_file.length
      container.index_file << [header_a_byte_size + header_b_byte_size + header_c_byte_size].pack("Q")
      container.index_file.close

      exit

      container.total_nr_nodes = 0
      nr_levels_per_chromosome = Hash.new
      CHROMOSOME_LENGTHS.keys.each do |chr_number|
        max_level_nr = ((Math.log(CHROMOSOME_LENGTHS[chr_number]) - Math.log(base_size)).to_f/Math.log(nr_children)).floor + 1
        (max_level_nr + 1).times do |l|
          container.total_nr_nodes += (CHROMOSOME_LENGTHS[chr_number].to_f/(base_size*(nr_children**l))).ceil
        end
        nr_levels = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/base_size).to_f/Math.log(nr_children)).floor + 2
        nr_levels_per_chromosome[chr_number] = nr_levels
        container.header_b_byte_size += 4 + 4 + nr_levels*4 #chr_number + nr_levels + level_offsets
      end
      header_a << container.total_nr_nodes
      container.header_c_byte_size = container.total_nr_nodes * 8 # have to use q instead of i

      # 2. Level offsets: part B
      container.trees = Hash.new
      byte_counter_level_offset = container.header_a_byte_size
      byte_counter_node_offset = container.header_a_byte_size + container.header_b_byte_size
      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        container.tree_offsets[chr_number] = byte_counter_level_offset
        header_b << chr_number.to_i
        container.trees[chr_number] = LocusTree::Tree.new(container, chr_number, nr_levels_per_chromosome[chr_number])
        header_b << nr_levels_per_chromosome[chr_number]
        byte_counter_level_offset += 8 + nr_levels_per_chromosome[chr_number]*4
        nr_levels_per_chromosome[chr_number].times do |n|
          # Add level_offset to header
          level = LocusTree::Level.new(container.trees[chr_number], n, byte_counter_node_offset)
          level.first_node_offset = 
          container.trees[chr_number].levels[n] = level
          container.trees[chr_number].level_offsets[n] = byte_counter_node_offset
          header_b << byte_counter_node_offset
          byte_counter_node_offset += 4
#          nr_nodes_in_level = (CHROMOSOME_LENGTHS[chr_number].to_f/(base_size*(nr_children**n))).ceil
#          bytes_needed_for_node_offsets_in_level = nr_nodes_in_level * 4
#          container.trees[chr_number].levels[n] = LocusTree::Level.new(container.trees[chr_number], n, level_byte_offset)
#          level_byte_offset += bytes_needed_for_node_offsets_in_level

          # Add node_offsets to header
          
        end
      end

      # 3. Node offsets: part C
      container.data_part_offset = container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size
      container.total_nr_nodes.times do |n|
        header_c << container.data_part_offset + n*container.initial_node_byte_size
      end
      
      container.header_byte_size = container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size
      header_a.unshift(container.header_byte_size)
      header_a.unshift("LocusTree_v1")
      container.index_file << header_a.pack("a12i3a17iq")
      container.index_file << header_b.pack("i*")
      container.index_file << header_c.pack("q*")

      STDERR.puts "Creating structure"
      # Create structure including the empty space
      node_counter = 0
      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        STDERR.puts "Nr of levels: " + nr_levels_per_chromosome[chr_number].to_s
        nr_levels_per_chromosome[chr_number].times do |level_number|
          STDERR.puts [chr_number, level_number].join("\t")
          bin_size = base_size*(nr_children**level_number)
          start = 1
          stop = start + bin_size - 1
          while stop < CHROMOSOME_LENGTHS[chr_number]
            container.index_file << [start,stop,0,0,0].pack("i*") #start,stop,aggregate_flag,count,sum
            container.index_file.pos += initial_byte_size_features_per_node
            start = stop + 1
            stop = start + bin_size - 1
            node_counter += 1
          end
          container.index_file << [start, CHROMOSOME_LENGTHS[chr_number],0,0,0].pack("i*") #start,stop,aggregate_flag,count,sum
          container.index_file.pos += initial_byte_size_features_per_node
          node_counter += 1
        end

      end
      container.index_file.close
      container.index_file = File.open(filename, 'rb+')
      container.fill(feature_file, container.initial_node_byte_size)
      container.cull_empty_space
      container.index_file.close
      container.index_file = File.open(filename, 'rb')
      STDERR.puts "Number of nodes: " + node_counter.to_s
      return container
    end

    def cull_empty_space
      # For each node: remove the empty space and update the nodebyteoffset in the header
    end

    def fill(feature_file, node_byte_size)
      nr_of_features = `wc -l #{feature_file}`.split[0].to_i
      STDERR.puts "Number of features in file: " + nr_of_features.to_s
      
      # Add the feature to the smallest node that encloses it
      pbar = ProgressBar.new('filling', nr_of_features)
      File.open(feature_file).each do |line|
        pbar.inc
        name, chr, start, stop = line.chomp.split("\t")

        enclosing_node = self.get_enclosing_node(chr.to_i, start.to_i, stop.to_i)
        @index_file.pos = enclosing_node.byte_offset
        node_start, node_stop, node_flag, node_count, node_sum = @index_file.read(20).unpack("i*")
        STDERR.puts [node_start, node_stop, node_flag, node_count].join("\t")
        node_feature_offsets = @index_file.read(node_count*4).unpack("i*")
        node_count += 1
        node_feature_offsets.push(start) #TODO: replace this with byte offset in GFF/BED file instead of start
        @index_file.pos = enclosing_node.byte_offset
        @index_file.write([node_start, node_stop, node_flag, node_count, node_sum, node_feature_offsets].flatten.pack("i*"))
#        @index_file.pos += 4*3
#        count = @index_file.read(4).unpack("i")[0] + 1
#        @index_file.pos -= 4
#        @index_file.write([count].pack("i"))


        parent_node = enclosing_node.parent_node
        unless parent_node.nil?
          while parent_node.level.number < parent_node.level.tree.nr_levels - 1
            @index_file.pos = parent_node.byte_offset
            @index_file.pos += 4*3
            count = @index_file.read(4).unpack("i")[0] + 1
            @index_file.pos -= 4
            @index_file.write([count].pack("i"))
            parent_node = parent_node.parent_node
          end
        end
      end
      pbar.finish
    end

    def self.open(filename)
      container = self.new
      container.index_file = File.open(filename, 'rb')
      container.magic = container.index_file.read(12).unpack("a*")[0]
      source_filename_length = container.index_file.read(4).unpack("i")[0]
      container.source_file = File.open(container.index_file.read(source_filename_length).unpack("a*")[0])
      container.header_byte_size, container.base_size, container.nr_children, nr_chromosomes = container.index_file.read(20).unpack("QI3")
      container.trees = Hash.new
      # For each chromosome: get the level offsets

      nr_chromosomes.times do
        chr_number, chr_length, nr_levels = container.index_file.read(12).unpack("I3")
        tree = LocusTree::Tree.new(container, chr_number.to_s, chr_length, nr_levels)
        container.trees[chr_number.to_s] = tree
        level_offsets = container.index_file.read(8*nr_levels).unpack("Q*")
        level_offsets.each_with_index do |level_offset, level_number|
          nr_nodes_in_level = (tree.chromosome_length/(container.base_size*(container.nr_children**level_number))).ceil + 1
          tree.levels[level_number] = Level.new(tree, level_number, level_offset, nr_nodes_in_level)
          tree.levels[level_number]
        end
#        STDERR.puts [chr_number, nr_levels, level_offsets].flatten.join("\t")
      end

      container.trees.values.each do |tree|
        tree.levels.values.each do |level|
          container.index_file.pos = level.offset
          level.nr_nodes.times do
            node_offset = container.index_file.read(8).unpack("Q")[0]
            level.node_offsets.push(node_offset)
          end
        end
      end
      return container
    end

    def get_node(chr_number, pos, level_number)
      tree = @trees[chr_number]
      level = tree.levels[level_number]
      return level.nodes(pos,pos)[0]
    end

    def get_nodes(chr_number, start, stop, level_number)
      tree = @trees[chr_number]
      level = tree.levels[level_number]
      return level.nodes(start,stop)
    end

    def get_enclosing_node(chr_number, start, stop)
      return @trees[chr_number].enclosing_node(start, stop)
    end

    def get_features(chr_number, start, stop)
      tree = @trees[chr_number]
      answer = Array.new
      level_number = 0
      while level_number < tree.nr_levels
        level = tree.levels[level_number]
        level.nodes(start, stop).each do |node|
          node.feature_byte_offsets.each do |feature_byte_offset|
            @source_file.pos = feature_byte_offset
            feat_chr, feat_start, feat_stop, feat_value = @source_file.readline.chomp.split(/\t/)
            if feat_start.to_i.between?(start, stop) and feat_stop.to_i.between?(start, stop)
              answer.push(Feature.new(feat_chr, feat_start.to_i, feat_stop.to_i, feat_value.to_i))
            end
          end
        end
        level_number += 1
      end
      return answer
    end
  end
end
