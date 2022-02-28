
require_relative 'lib/couch_party/version'

Gem::Specification.new do |s|
  s.name        = 'couchparty'
  s.version     = CouchParty::VERSION
  #s.date        = '2022-02-01'
  s.date = File.mtime('lib/couch_party/version.rb')

  s.summary     = "couchparty : thin and modern couchdb driver for ruby"
  s.description = "couchparty is a couchdb driver that target couchdb 3+ and ruby 3+"
  s.authors     = ["Christophe Vigny"]
  s.homepage = %q{http://github.com/tophe/couchparty}
  s.homepage    =   'https://github.com/tophe/couchparty'
  s.license = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths=["lib"]


  #s.required_ruby_version = '>= 1.9.3'
  # s.test_files = Dir.glob('spec/*.*')
  s.extra_rdoc_files = ['readme.md']

  s.add_runtime_dependency "httpx"
  s.add_runtime_dependency "mime-types"

  s.add_development_dependency "bundler", "~> 2.2"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake", "< 11.0"
  s.add_development_dependency "webmock"
end


