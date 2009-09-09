module LocusTree
  # == Description
  #
  # The LocusTree::Container class represents the object containing the trees
  # for all chromosomes/contigs/...
  class Container
    attr_accessor :magic
    attr_accessor :source_file, :index_file
    attr_accessor :header_a_template, :header_b_template
    attr_accessor :header_byte_size, :data_part_offset, :initial_node_byte_size
    attr_accessor :header_a_byte_size, :header_b_byte_size, :header_c_byte_size
    attr_accessor :aggregate_flag
    attr_accessor :base_size, :nr_children
    attr_accessor :trees, :tree_offsets
    attr_accessor :total_nr_nodes

#    def self.create_structure(base_size = 1000, nr_children = 2, feature_file = 'features.bed', aggregate_flag = 1, filename = feature_file + '.idx')
#      # Suppose the file looks like this:
#      #   # HEADER A
#      #   LocusTree_v1
#      #   19  minimal_example.bed
#      #   319 # size of header
#      #   1 # aggregate flag
#      #   5  2
#      #   2
#      #   # HEADER B
#      #   1  28  4  6  167  3  215  2  239  1  255 # byte offsets: 59,63,67,71,75,83,87,85,93,97,105
#      #   2  19  3  4  263  2  295  1  311         # byte offsets: 113,117,121,125,129,137,141,149,153
#      #   # HEADER C
#      #   319  347  359  371  383  411  423  435  471  483  495  507  535  547  575  587  599  611  639
#      #   # DATA PART
#      #   1  5  1  1  17  22 # 319 = byte offset of start of this line
#      #   6  10 0            # 347
#      #   11 15 0            # 359
#      #   16 20 0            # 371
#      #   ...
#      #
#      # The fact that there are multiple references to byte offsets get quite confusing. The offsets in header B
#      # (167, 215, 239 and 255) are the byte offsets of the node byte offsets in header C.
#      # Variable naming convention:
#      #   * The actual byte offsets (i.e. the values) get a variable name *_offset.
#      #     For example: 137, 215, 239 and 255 are level_offsets for chromosome 1
#      #     and 319, 347, 359, .. are the node_offsets for level 0 in chromosome 1.
#      #   * The byte offsets that contain this information get a variable name *_pointer_offset.
#      #     For example: 75, 87, 93 and 105 are the node_pointer_offsets for each level in chromosome 1
#
#      initial_nr_dummy_features_per_node = 10 #Will allow for storing the feature offsets. Will put NULL bytes there at first.
#
#      container = self.new
#      container.index_file = File.open(filename, 'wb')
#      container.base_size = base_size
#      container.nr_children = nr_children
#      container.aggregate_flag = aggregate_flag
#      container.trees = Hash.new
#
#      container.header_a_byte_size = 0
#      container.header_b_byte_size = 0
#      container.header_c_byte_size = 0
#
#      # Create header
#      header_a = Array.new
#      header_b_hash = Hash.new
#      header_b = Array.new
#      header_c = Array.new
#
#      header_a << "LocusTree_v1"
#      header_a << feature_file.length
#      header_a << feature_file
#      header_a << 0 # will become byteoffset datapart
#      header_a << aggregate_flag
#      header_a << base_size
#      header_a << nr_children
#      header_a << CHROMOSOME_LENGTHS.keys.length
#      container.header_a_byte_size = 12 + 4 + feature_file.length + 8 + 4 + 4 + 4 + 4 #magic + length filename + filename + byteoffset datapart + aggregate_flag + base_size + nr_children + nr chromosomes
#      running_offset_header_b = 0
#      running_offset_header_c = 0
#      running_offset_data = 0
#
#      container.header_a_template = "a12Ia#{feature_file.length}QI4"
#      container.header_b_template = ""
#
#      STDERR.puts "A"
#      #
#      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
#        header_b_hash[chr_number] = Hash.new
#        header_b_hash[chr_number][:chr_length] = CHROMOSOME_LENGTHS[chr_number]
#        nr_levels = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/base_size).to_f/Math.log(nr_children)).floor + 2
#        header_b_hash[chr_number][:nr_levels] = nr_levels
#        running_offset_header_b += 12
#        running_offset_header_b += nr_levels*(4 + 8) # bytesize for level_number + byte_size for offset
#        header_b_hash[chr_number][:node_offsets] = Hash.new #key = levelnumber
#
#        tree = Tree.new(container, chr_number, CHROMOSOME_LENGTHS[chr_number], nr_levels)
#        nr_levels.times do |level_number|
#          header_b_hash[chr_number][:node_offsets][level_number] = running_offset_header_c
#          nr_nodes = (CHROMOSOME_LENGTHS[chr_number]/(base_size*(nr_children**level_number))).ceil + 1
##          STDERR.puts "running offset C " + running_offset_header_c.to_s
#          tree.levels[level_number] = Level.new(tree, level_number, nr_nodes)#, running_offset_header_c) # ATTENTION: running node offset is relative to start of header part C => adding length of part A and B later
#          running_offset_header_c += nr_nodes*8
#          nr_nodes.times do
#            header_c << running_offset_data; running_offset_data += (20 + 8*initial_nr_dummy_features_per_node)
#          end
#        end
#        container.trees[chr_number] = tree
#      end
#
#      container.header_b_byte_size = running_offset_header_b
#      container.header_c_byte_size = running_offset_header_c
#      container.header_byte_size = container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size
#
#      container.index_file << header_a.pack(container.header_a_template)
#
#      STDERR.puts "B"
#      # For each level first_node_offset we still need to add the byte size of headers A and B
#      all_node_offsets = header_c.clone
#      header_b_hash.keys.each do |chr_number|
#        tree = container.trees[chr_number]
#        tree.levels.keys.each do |level_number|
#          level = tree.levels[level_number]
#          level.node_offsets = Array.new
#          level.nr_nodes.times do
#            level.node_offsets.push(all_node_offsets.shift + container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size)
#          end
#        end
#      end
#
#      STDERR.puts "C"
#      # Writing header B to file
#      header_b_hash.keys.sort.each do |chr_number|
#        header_b << chr_number.to_i
#        header_b << CHROMOSOME_LENGTHS[chr_number]
#        header_b << header_b_hash[chr_number][:nr_levels]
#        container.header_b_template << "I3"
#        header_b_hash[chr_number][:node_offsets].keys.sort.each do |level_number|
#          node_offset = header_b_hash[chr_number][:node_offsets][level_number]
#          nr_nodes = (CHROMOSOME_LENGTHS[chr_number]/(base_size*(nr_children**level_number))).ceil + 1
#          header_b << [nr_nodes, node_offset + container.header_a_byte_size + container.header_b_byte_size]
#          container.header_b_template << "IQ"
#        end
#
#      end
#      header_b.flatten!
#      container.index_file << header_b.pack(container.header_b_template)
#
#      STDERR.puts "DEBUG: " + container.header_a_template
#      STDERR.puts "DEBUG: " + container.header_b_template
#
#      # Writing header C to the file
#      header_c.each do |node_offset|
#        container.index_file << [node_offset + container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size].pack("Q")
#      end
#
#      STDERR.puts "D"
#      # Adding correct header byte size to header A
#      header_a[3] = container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size
#      container.index_file.pos = 12 + 4 + feature_file.length
#      container.index_file << [container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size].pack("Q")
#      container.index_file.pos = container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size
#
#      container.header_byte_size = container.header_a_byte_size + container.header_b_byte_size + container.header_c_byte_size
#
#      # Create structure including the empty space
#      node_counter = 0
#      header_b_hash.keys.sort.each do |chr_number|
#        header_b_hash[chr_number][:nr_levels].times do |level_number|
#          bin_size = base_size*(nr_children**level_number)
#          start = 1
#          stop = start + bin_size - 1
#          while stop < CHROMOSOME_LENGTHS[chr_number]
#            container.index_file << [start,stop,0,0,0].pack("I*") #start,stop,total_count,count,sum
##            initial_nr_dummy_features_per_node.times do
##              container.index_file << [0].pack("Q")
##            end
#            container.index_file.pos += 8*initial_nr_dummy_features_per_node
#            start = stop + 1
#            stop = start + bin_size - 1
#            node_counter += 1
#          end
#          container.index_file << [start, CHROMOSOME_LENGTHS[chr_number],0,0,0].pack("I*") #start,stop,total_count,count,sum
##          initial_nr_dummy_features_per_node.times do
##            container.index_file << [0].pack("Q")
##          end
#          container.index_file.pos += 8*initial_nr_dummy_features_per_node
#          STDERR.puts "position: " + container.index_file.pos.to_s
#          node_counter += 1
#        end
#
#      end
#
#      STDERR.puts "------ total number of nodes: " + node_counter.to_s
#
##      container.trees.values.sort_by{|v| v.chromosome}.each do |tree|
##        STDERR.puts '------'
##        STDERR.puts tree.chromosome
##        tree.levels.values.sort_by{|v| v.number}.each do |level|
##          STDERR.puts level.number.to_s + "\t" + level.node_offsets.join(';')
##        end
##      end
##
##      exit
#      STDERR.puts "E"
#      STDERR.puts "Index file at position " + container.index_file.pos.to_s
#      container.index_file.close
#      container.index_file = File.open(filename, 'rb+')
#      container.fill(feature_file, container.initial_node_byte_size)
#      container.cull_empty_space(header_a, header_b, header_c)
#      container.index_file.close
#      system("mv locustree.tmp #{filename}")
#      container.index_file = File.open(filename, 'rb')
#      return container
#    end


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
#      container.index_file = File.open(filename, 'wb')
      container.base_size = base_size
      container.nr_children = nr_children
      container.aggregate_flag = aggregate_flag
      container.trees = Hash.new

      CHROMOSOME_LENGTHS.keys.sort.each do |chr_number|
        nr_levels = (Math.log(CHROMOSOME_LENGTHS[chr_number].to_f/base_size).to_f/Math.log(nr_children)).floor + 2
        container.trees[chr_number] = Tree.new(container, chr_number, CHROMOSOME_LENGTHS[chr_number], nr_levels)
      end

      map_file = File.new('locustree.map','w')
      f = File.open(feature_file)
      pbar = ProgressBar.new('mapping', 500000)
      f.each do |line|
        pbar.inc
        next if line =~ /^#/

        feature_offset = f.pos - line.length
        name, chr, start, stop = line.chomp.split("\t")
        value = 1

        container.map_feature(map_file, chr.to_i, start.to_i, stop.to_i, value, name)
      end
      pbar.finish
      map_file.close

      STDERR.puts "Sorting"
      system("sort locustree.map > locustree.map.sorted")

      STDERR.puts "Reducing"
      nr_of_features = `wc -l locustree.map.sorted`.split[0].to_i
      reduced_file = File.new('locustree.reduced','w')
      prev_node = ''
      running_count = nil
      running_sum = nil
      running_features = nil
      running_chromosome = nil
      running_start = nil
      running_stop = nil
      pbar = ProgressBar.new('reducing', nr_of_features)
      File.open('locustree.map.sorted').each do |line|
        pbar.inc
        node, chr, start, stop, count, sum, feature = line.chomp.split(/\t/)
        if node == prev_node
          running_count += count.to_i
          running_sum += sum.to_i
          running_features.push(feature) unless feature.nil?
        else
          reduced_file.puts [running_chromosome, running_start, running_stop, running_count, running_sum, running_features.join(',')].join("\t") unless prev_node == ''
          prev_node = node
          running_chromosome = chr
          running_start = start.to_i
          running_stop = stop.to_i
          running_count = count.to_i
          running_sum = sum.to_i
          running_features = ( feature.nil? ) ? [] : [feature]
        end
      end
      pbar.finish
      reduced_file.close

    end

    def cull_empty_space(header_a, header_b, header_c)
      culled_index_file = File.open('locustree.tmp','wb')
      STDERR.puts "header_a: " + header_a.join(" ")
      STDERR.puts "size: " + @header_byte_size.to_s
      culled_index_file << header_a.pack(@header_a_template)
      culled_index_file << header_b.pack(@header_b_template)

      # For each node: remove the empty space and update the nodebyteoffset in the header
      corrected_header_c = Array.new
      @index_file.pos = @header_byte_size
      culled_index_file.pos = @header_byte_size
      corrected_header_c << @header_byte_size
      header_c.each do |node_offset|
        node_offset += @header_byte_size
        @index_file.pos = node_offset
        start, stop, total_count, count, sum = @index_file.read(20).unpack("I*")
        culled_index_file << [start, stop, total_count, count, sum].pack("I*")
        STDERR.puts "start, stop, total_count, count, sum = " + [start, stop, total_count, count, sum].join("\t")
        STDERR.puts "position culled index file BEFORE: " + culled_index_file.pos.to_s
        culled_index_file << @index_file.read(8*count)
        STDERR.puts "position culled index file AFTER: " + culled_index_file.pos.to_s
        STDERR.puts "Corrected: " + node_offset.to_s + " --> " + corrected_header_c[-1].to_s
        corrected_header_c << culled_index_file.pos
      end
      corrected_header_c.pop

      culled_index_file.pos = @header_a_byte_size + @header_b_byte_size
      corrected_header_c.each do |node_offset|
        culled_index_file << [node_offset].pack("Q")
      end
    end

    def fill(feature_file, node_byte_size)
      nr_of_features = `wc -l #{feature_file}`.split[0].to_i
      
      # Add the feature to the smallest node that encloses it
#      pbar = ProgressBar.new('filling', nr_of_features)
      f = File.open(feature_file)
      f.each do |line|
        next if line =~ /^#/

        feature_offset = f.pos - line.length
#        pbar.inc
        chr, start, stop, value = line.chomp.split("\t")
#        STDERR.puts "Feature: " + [chr, start, stop].join("\t")

        enclosing_node = self.get_enclosing_node(chr.to_i, start.to_i, stop.to_i)
        enclosing_node.add_feature(feature_offset, value.to_i)

        parent_node = enclosing_node.parent_node
        until parent_node.nil?
          parent_node.add_feature(nil, value.to_i)
          parent_node = parent_node.parent_node
        end
      end
#      pbar.finish
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
