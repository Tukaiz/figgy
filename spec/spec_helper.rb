require 'simplecov'

SimpleCov.start

require 'rspec'
require 'figgy'
require 'aruba/api'
require 'heredoc_unindent'

module Figgy::SpecHelpers
  def test_config
    Figgy.build do |config|
      config.root = current_dir
      yield config if block_given?
    end
  end

  def write_config(filename, contents)
    filename = "#{filename}.yml" unless filename =~ /\./
    write_file(filename, contents.unindent)
  end
end

RSpec.configure do |c|
  c.filter_run_excluding :exclude_ruby => lambda {|version|
    !(RUBY_VERSION.to_s =~ /^ruby-#{version.to_s}/)
  }
  c.include Aruba::Api
  c.include Figgy::SpecHelpers
  c.after { FileUtils.rm_rf(current_dir) }
end
