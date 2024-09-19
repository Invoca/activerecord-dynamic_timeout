# encoding: utf-8

$:.unshift File.expand_path("../lib", __FILE__)
require "active_record/dynamic_timeout/version"

Gem::Specification.new do |s|
  s.name          = "activerecord-dynamic_timeout"
  s.version       = ActiveRecord::DynamicTimeout::VERSION
  s.authors       = ["Tristan Starck"]
  s.email         = ["tstarck@invoca.com"]
  s.homepage      = "https://github.com/ttstarck/activerecord-dynamic_timeout"
  s.licenses      = ["MIT"]
  s.summary       = "[summary]"
  s.description   = "[description]"

  s.files         = Dir.glob("{bin/*,lib/**/*,[A-Z]*}")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", ">= 6.1"
end
