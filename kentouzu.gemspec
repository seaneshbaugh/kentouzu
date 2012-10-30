# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'kentouzu/version'

Gem::Specification.new do |s|
  s.name        = 'kentouzu'
  s.version     = Kentouzu::VERSION
  s.authors     = ['Sean Eshbaugh']
  s.email       = ['seaneshbaugh@gmail.com']
  s.homepage    = 'http://seaneshbaugh.com/'
  s.summary     = 'Add drafts to ActiveRecord models.'
  s.description = 'Add drafts to ActiveRecord models.'

  s.rubyforge_project = 'kentouzu'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'railties', '~> 3.0'
  s.add_dependency 'activerecord', '~> 3.0'

  s.add_development_dependency 'rspec'
end
