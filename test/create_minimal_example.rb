#!/usr/bin/ruby
f = File.open('minimal_example.bed.idx','wb')

# Part A of the header (see Google Document to see what this means)
f << ["LocusTree_v1"].pack("a*")
f << [19].pack("I")
f << ["minimal_example.bed"].pack("a*")
f << [319].pack("Q") #size of header
f << [1].pack("I") # aggregate flag
f << [5,2,2].pack("I*")

# Part B of the header
f << [1,28,4,6,167,3,215,2,239,1,255].pack("I3IQIQIQIQ")
f << [2,19,3,4,263,2,295,1,311].pack("I3IQIQIQ")

# Part C of the header
f << [319,347,367,387,407,435,455,475,511,531,551,571,599,619,647,667,687,707,735].pack("Q*")

# Data
f << [1,5,1,1,17,22].pack("I5Q")       # 319 = byte offset of start of this line
f << [6,10,0,0,0].pack("I*")           # 347
f << [11,15,0,0,0].pack("I*")          # 367
f << [16,20,0,0,0].pack("I*")          # 387
f << [21,25,1,1,19,64].pack("I5Q")     # 407
f << [26,28,0,0,0].pack("I*")          # 435
f << [1,10,1,0,17].pack("I*")          # 455
f << [11,20,2,2,29,31,42].pack("I5Q2") # 475
f << [21,28,1,0,19].pack("I*")         # 511
f << [1,20,3,0,46].pack("I*")          # 531
f << [21,28,1,0,19].pack("I*")         # 551
f << [1,28,5,1,77,53].pack("I5Q")      # 571
f << [1,5,0,0,0].pack("I*")            # 599
f << [6,10,1,1,5,75].pack("I5Q")       # 619
f << [11,15,0,0,0].pack("I*")          # 647
f << [16,19,0,0,0].pack("I*")          # 667
f << [1,10,1,0,5].pack("I*")           # 687
f << [11,19,1,1,9,83].pack("I5Q")      # 707
f << [1,19,2,0,14].pack("I*")          # 735
f.close

