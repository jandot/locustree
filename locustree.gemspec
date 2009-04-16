Gem::Specification.new do |s|
  s.name = 'locustree'
  s.version = "1.0"

  s.author = "Jan Aerts"
  s.email = "jan.aerts@gmail.com"
  s.homepage = "http://github.com/jandot/locustree"
  s.summary = "Ruby library to search genomic loci using R-Tree"
  s.description = "LocusTree provides a method for indexing genomic loci for fast searching"

  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,samples,test}/**/*")
  s.files.concat ["README.textile"]

  # s.rdoc_options << '--exclude' << '.'
  s.has_rdoc = false

  s.add_dependency('dm-core', '>=0.9.11')
  s.add_dependency('dm-aggregates', '>=0.9.11')
  s.add_dependency('do_sqlite3', '>=0.9.11')

  s.require_path = 'lib'
  s.autorequire = 'locus_tree'
end
