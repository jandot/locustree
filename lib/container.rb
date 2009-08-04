module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    attr_accessor :index_file
    attr_accessor :header_size
    attr_accessor :aggregate_order
    attr_accessor :base_size, :nr_children, :aggregates
    attr_accessor :trees
    
    def self.create_structure(base_size = 1000, nr_children = 2, feature_file = 'features.bed', filename = feature_file + '.idx')
      container = self.new
      container.index_file = File.open(filename, 'wb')
      container.base_size = base_size
      container.nr_children = nr_children
      container.aggregate_order = 'count,avg,min,max'

      # Create header
      header_information = Array.new
      header_information << base_size
      header_information << nr_children
      header_information << 'count,avg,min,max'

      header_size = 12 + 17
      level_data_byte_offset = 0
      nr_levels_per_chromosome = Hash.new
      container.trees = Hash.new
      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        container.trees[chr_number] = LocusTree::Tree.new(chr_number, nr_levels_per_chromosome[chr_number])
        header_information << chr_number.to_i
        header_size += 4
        nr_levels = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/base_size).to_f/Math.log(nr_children)).floor + 1
        nr_levels_per_chromosome[chr_number] = nr_levels
        header_information << nr_levels
        header_size += 4
        nr_levels.times do |n|
          header_information << level_data_byte_offset
          header_size += 4
          # Each node needs 32 bytes
          nr_nodes_in_level = (CHROMOSOME_LENGTHS[chr_number].to_f/(base_size*(nr_children**n))).ceil
          bytes_needed_for_level = nr_nodes_in_level * 20
          container.trees[chr_number].levels[n] = LocusTree::Level.new(n, level_data_byte_offset)
          level_data_byte_offset += bytes_needed_for_level
        end
      end
      header_information.unshift(header_size)
      container.header_size = header_size
      container.index_file << header_information.pack("i3a17i*")

      container.trees.values.each do |tree|
        tree.levels.values.each do |level|
          level.byte_offset += header_size
        end
      end

      # Create structure
      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        STDERR.puts chr_number
        nr_levels_per_chromosome[chr_number].times do |level_number|
          STDERR.puts "\t" + level_number.to_s
          bin_size = base_size*(nr_children**level_number)
          start = 1
          stop = start + bin_size - 1
          while stop < CHROMOSOME_LENGTHS[chr_number]
            container.index_file << [start,stop,0,0,0].pack("i*")
            start = stop + 1
            stop = start + bin_size - 1
          end
          container.index_file << [start, CHROMOSOME_LENGTHS[chr_number],0,0,0].pack("i*")
        end
      end
      container.index_file.close
      container.index_file = File.open(filename, 'rb+')
      container.fill(feature_file)
      container.index_file.close
      container.index_file = File.open(filename, 'rb')
      return container
    end

    def fill(feature_file)
      # Add the feature to the smallest node that encloses it
      pbar = ProgressBar.new('filling', 36653)
      File.open(feature_file).each do |line|
        pbar.inc
        name, chr, start, stop = line.chomp.split("\t")

        enclosing_node = self.get_enclosing_node(chr.to_i, start.to_i, stop.to_i)
        @index_file.pos = enclosing_node.byte_offset
        @index_file.pos += 4*3
        count = @index_file.read(4).unpack("i")[0] + 1
        @index_file.pos -= 4
        @index_file.write([count].pack("i"))
      end

      # Add the feature to the end of the file
      @index_file.seek(-1, File::SEEK_END)
      line_counter = 0
      File.open(feature_file).each do |line|
        line_counter += 1
        name, chr, start, stop = line.chomp.split("\t")
        @index_file << [[chr.rjust(2,'0'), start.rjust(9,'0'), stop.rjust(9,'0')].join('_')].pack("a22")
        @index_file << [line_counter].pack("i")
      end
      pbar.finish
    end

    def self.open(filename)
      STDERR.puts filename
      container = self.new
      container.index_file = File.open(filename, 'rb')
      container.header_size, container.base_size, container.nr_children = container.index_file.read(12).unpack("i*")
      container.aggregate_order = container.index_file.read(17).unpack("a*")
      container.trees = Hash.new
      while container.index_file.pos < container.header_size
        chr_number, nr_levels = container.index_file.read(8).unpack("i*")
        container.trees[chr_number] = LocusTree::Tree.new(chr_number, nr_levels)
        nr_levels.times do |level|
          byte_offset = container.index_file.read(4).unpack("i")[0] + container.header_size
          container.trees[chr_number].levels[level] = LocusTree::Level.new(level, byte_offset)
        end
      end
      return container
    end

    def get_node(chr_number, pos, level_number)
      STDERR.puts '----'
      tree = @trees[chr_number]
      level = tree.levels[level_number]
      resolution_at_level = @base_size*(@nr_children**level_number)
      STDERR.puts "query: " + pos.to_s
      STDERR.puts "resolution: " + resolution_at_level.to_s
      bin = (pos-1).div(resolution_at_level)
      @index_file.pos = level.byte_offset + bin*20
      data = @index_file.read(20).unpack("i*")
      return LocusTree::Node.new(data[0], data[1], data[3], data[4])
    end

    def get_nodes(chr_number, start, stop, level_number)
      STDERR.puts '----'
      tree = @trees[chr_number]
      level = tree.levels[level_number]
      answer = Array.new
      resolution_at_level = @base_size*(@nr_children**level_number)
      STDERR.puts "query: " + [start, stop].join("\t")
      STDERR.puts "resolution: " + resolution_at_level.to_s
      start_bin = (start-1).div(resolution_at_level)
      stop_bin = (stop-1).div(resolution_at_level)
      @index_file.pos = level.byte_offset + start_bin*20
      (stop_bin - start_bin + 1).times do
        data = @index_file.read(20).unpack("i*")
        answer.push LocusTree::Node.new(data[0], data[1], data[3], data[4])
      end
      return answer
    end

    def get_enclosing_node(chr_number, start, stop)
      tree = @trees[chr_number]
      level_number = tree.levels.keys.max
      resolution_at_level = @base_size*(@nr_children**level_number)
      previous_start_bin = 0
      start_bin = (start-1).div(resolution_at_level)
      stop_bin = (stop-1).div(resolution_at_level)
      while start_bin == stop_bin and level_number > 0
        previous_start_bin = start_bin
        level_number -= 1
        resolution_at_level = @base_size*(@nr_children**level_number)
        start_bin = (start-1).div(resolution_at_level)
        stop_bin = (stop-1).div(resolution_at_level)
      end
      node_byte_offset = tree.levels[level_number].byte_offset + previous_start_bin*20
      @index_file.pos = node_byte_offset
      data = @index_file.read(20).unpack("i*")
      node = LocusTree::Node.new(data[0], data[1], data[3], data[4])
      node.byte_offset = node_byte_offset
      return node
    end

  end
end
