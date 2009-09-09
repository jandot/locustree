module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    attr_accessor :magic
    attr_accessor :source_file, :index_file
    attr_accessor :aggregate_flag
    attr_accessor :base_size, :nr_children
    attr_accessor :trees, :tree_offsets
    attr_accessor :total_nr_nodes

    def self.create_structure(base_size = 1000, nr_children = 2, feature_file = 'features.bed', aggregate_flag = 1, filename = feature_file + '.idx')
      # Approach: I'll use a mapreduce-like approach:
      #   * map: output a line for each feature for the enclosing level and parent
      #     levels, with count 1 and e.g. value just the value of that feature
      #   * sort
      #   * reduce
      # The feature_name is only added to the node that is the smallest
      # enclosing node.
      #
      # So if the datafile would be (chr, start, stop, value, name)
      #    1   3   4   7   feat_1
      #    1   7   8   3   feat_2
      #    1   12  16  5   feat_3
      #    1   19  21  1   feat_4
      #    1   23  24  9   feat_5
      #
      # Suppose that chromosome length is 27 bp. With a bin-size of 5 and
      # nr_children of 2, the output from the map-step would be
      # (chr:level:number, chr, start, stop, count, sum, features):
      #    1:0:0   1   1   5   1   7   feat_1
      #    1:1:0   1   1   10  1   7
      #    1:2:0   1   1   20  1   7
      #    1:3:0   1   1   27  1   7
      #    1:0:1   1   6   10  1   3   feat_2
      #    1:1:0   1   1   10  1   3
      #    1:2:0   1   1   20  1   3
      #    1:3:0   1   1   27  1   3
      #    1:1:1   1   11  20  1   5   feat_3
      #    1:2:0   1   1   20  1   5
      #    1:3:0   1   1   27  1   5
      #    1:3:0   1   1   27  1   1   feat_4
      #    1:0:4   1   21  25  1   9   feat_5
      #    1:1:2   1   21  27  1   9
      #    1:2:1   1   21  27  1   9
      #    1:3:0   1   1   27  1   9
      #
      # Sorting this gives:
      #    1:0:0   1   1   5   1   7   feat_1
      #    1:0:1   1   6   10  1   3   feat_2
      #    1:0:4   1   21  25  1   9   feat_5
      #    1:1:0   1   1   10  1   3
      #    1:1:0   1   1   10  1   7
      #    1:1:1   1   11  20  1   5   feat_3
      #    1:1:2   1   21  27  1   9
      #    1:2:0   1   1   20  1   3
      #    1:2:0   1   1   20  1   5
      #    1:2:0   1   1   20  1   7
      #    1:2:1   1   21  27  1   9
      #    1:3:0   1   1   27  1   1   feat_4
      #    1:3:0   1   1   27  1   3
      #    1:3:0   1   1   27  1   5
      #    1:3:0   1   1   27  1   7
      #    1:3:0   1   1   27  1   9
      #
      # Reducing:
      #    1:0:0   1   1   5   1   7   feat_1
      #    1:0:1   1   6   10  1   3   feat_2
      #    1:0:4   1   21  25  1   9   feat_5
      #    1:1:0   1   1   10  2   10
      #    1:1:1   1   11  20  1   5   feat_3
      #    1:1:2   1   21  27  1   9
      #    1:2:0   1   1   20  3   15
      #    1:2:1   1   21  27  1   9
      #    1:3:0   1   1   27  5   25  feat_4
      #
      # ... which is the datapart of the binary file...

      container = self.new
      container.index_file = File.open(filename, 'wb')
      container.base_size = base_size
      container.nr_children = nr_children
      container.aggregate_flag = aggregate_flag
      container.trees = Hash.new

      # Create the tree objects
      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        nr_levels = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/base_size).to_f/Math.log(nr_children)).floor + 2
        container.trees[chr_number] = Tree.new(container, chr_number, CHROMOSOME_LENGTHS[chr_number], nr_levels)
      end

      # Create the index using map/reduce approach
      # A. map
      map_file = File.new('locustree.map','w')
      f = File.open(feature_file)
      nr_of_features = `wc -l #{feature_file}`.split[0].to_i
      pbar = ProgressBar.new('mapping', nr_of_features)
      f.each do |line|
        pbar.inc
        next if line =~ /^#/

        feature_offset = f.pos - line.length
        chr, start, stop, value, name = line.chomp.split("\t")

        container.map_feature(map_file, chr.to_i, start.to_i, stop.to_i, value, feature_offset)
      end
      pbar.finish
      map_file.close

      # B. sort
      STDERR.puts "Sorting"
      system("sort locustree.map > locustree.map.sorted")

      # C. reduce
      STDERR.puts "Reducing"
      prev_node = ''
      running_total_count = nil
      running_sum = nil
      running_features = []
      running_chromosome = nil
      running_start = nil
      running_stop = nil

      header_a = Array.new
      header_b = Hash.new
      header_c = Array.new
      # For each chromosome in header_b: create a hash for each level with
      # all the references to header_c
      CHROMOSOME_LENGTHS.keys.each do |chr_number|
        header_b[chr_number] = Hash.new
      end

      nr_of_features = `wc -l locustree.map.sorted`.split[0].to_i
      reduced_file = File.new('locustree.reduced','wb')
      pbar = ProgressBar.new('reducing', nr_of_features)
      lines = File.open('locustree.map.sorted').readlines
      lines.push('')
      lines.each do |line|
        pbar.inc
        node, chr, start, stop, count, sum, feature = line.chomp.split(/\t/)
        if node == prev_node
          running_total_count += count.to_i
          running_sum += sum.to_i
          running_features.push(feature.to_i) unless feature.nil?
        else
          unless prev_node == ''
            chr, level, node_nr = prev_node.split(/:/)
            level = level.to_i
            if header_b[chr][level].nil?
              header_b[chr][level] = Array.new
            end
            header_b[chr][level].push(header_c.length*8)
            header_c.push(reduced_file.pos)
            reduced_file << [running_start, running_stop, running_total_count].pack("I*")
            reduced_file << [running_features.length, running_sum].pack("I*")
            reduced_file << running_features.pack("Q*") unless running_features.length == 0
          end
          prev_node = node
          running_start = start.to_i
          running_stop = stop.to_i
          running_total_count = count.to_i
          running_sum = sum.to_i
          running_features = ( feature.nil? ) ? [] : [feature.to_i]
        end
      end
      pbar.finish
      reduced_file.close

      header_a << "LocusTree_v1"
      header_a << feature_file.length
      header_a << feature_file
      header_a << 0 # will become byteoffset datapart later on
      header_a << aggregate_flag
      header_a << base_size
      header_a << nr_children
      header_a << CHROMOSOME_LENGTHS.keys.length
      header_a_template = "A12IA#{feature_file.length}QIIII"
      header_a_byte_size = 12 + 4 + feature_file.length + 8 + 4 + 4 + 4 + 4 #magic + length filename + filename + byteoffset datapart + aggregate_flag + base_size + nr_children + nr chromosomes

      # Calculate byte_size of header_b
      header_b_byte_size = 0
      header_b.keys.sort.each do |chr|
        max_level = container.trees[chr].nr_levels - 1
        header_b_byte_size += 12
        (0..max_level).each do |level|
          header_b_byte_size += 4
          unless header_b[chr][level].nil?
            header_b_byte_size += 8
          end
        end
      end

      # Create header_b
      header_b_array = Array.new
      header_b_template = ''
      header_b.keys.sort.each do |chr|
        max_level = container.trees[chr].nr_levels - 1
        header_b_array << chr.to_i
        header_b_array << CHROMOSOME_LENGTHS[chr]
        header_b_array << max_level + 1
        header_b_template += 'I3'

        (0..max_level).each do |level|
          header_b_array << ( ( header_b[chr][level].nil? ) ? 0 : header_b[chr][level].length )
          header_b_template += 'I'
          unless header_b[chr][level].nil?
            header_b_array << header_b[chr][level].sort[0] + header_a_byte_size + header_b_byte_size
            header_b_template += "Q"
          end
        end
      end
      header_c_byte_size = header_c.length * 8

      STDERR.puts [header_a_byte_size, header_b_byte_size, header_c_byte_size].join("\t")
      STDERR.puts header_c.length

      container.index_file << header_a.pack(header_a_template)
      container.index_file << header_b_array.flatten.pack(header_b_template)
      container.index_file << header_c.map{|value| value + header_a_byte_size + header_b_byte_size + header_c_byte_size}.pack("Q*")

      # Correct byte offset in header_a
      container.index_file.pos = 12 + 4 + feature_file.length
      container.index_file << [header_a_byte_size + header_b_byte_size + header_c_byte_size].pack("Q")

      container.index_file.close
      system("cat locustree.reduced >> #{filename}")
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
#            STDERR.puts "node offset = " + node_offset.to_s
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

    def map_feature(outfile, chr_number, start, stop, value, name)
      return @trees[chr_number.to_s].map_feature(outfile, start, stop, value, name)
    end
    
    def get_enclosing_node(chr_number, start, stop)
      return @trees[chr_number.to_s].enclosing_node(start, stop)
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
