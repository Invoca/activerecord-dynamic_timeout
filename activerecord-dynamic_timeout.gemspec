# encoding: utf-8

$:.unshift File.expand_path("../lib", __FILE__)
require "active_record/dynamic_timeout/version"

Gem::Specification.new do |s|
  s.name          = "activerecord-dynamic_timeout"
  s.version       = ActiveRecord::DynamicTimeout::VERSION
  s.authors       = ["Tristan Starck"]
  s.email         = ["tstarck@invoca.com", "Invoca Development"]
  s.homepage      = "https://github.com/Invoca/activerecord-dynamic_timeout"
  s.licenses      = ["MIT"]
  s.summary       = "ActiveRecord extension for dynamically setting connection timeouts"
  s.description   = s.summary
  s.metadata      = {
    "allowed_push_host" => "https://rubygems.org",
    "source_code_uri"   => s.homepage,
  }

  s.files         = Dir.glob("{bin/*,lib/**/*,[A-Z]*}")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", ">= 6.1"
end
