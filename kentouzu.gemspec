$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'kentouzu/version'

Gem::Specification.new do |s|
  s.name        = 'kentouzu'
  s.version     = Kentouzu::VERSION
  s.summary     = 'Add drafts to ActiveRecord models.'
  s.description = s.summary
  s.homepage    = 'https://github.com/seaneshbaugh/kentouzu'
  s.authors     = ['Sean Eshbaugh']
  s.email       = 'seaneshbaugh@gmail.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'railties', '>= 3.0'
  s.add_dependency 'activerecord', '>= 3.0'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'jquery-rails'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rails', '>= 3.2'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'sqlite3'
end
