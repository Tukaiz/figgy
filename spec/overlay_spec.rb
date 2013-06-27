require 'spec_helper'

describe Figgy do
  context "overlays" do
    it "defaults to no overlay, thus reading directly from the config root" do
      write_config 'values', "foo: 1"
      test_config.values.should == { "foo" => 1 }
    end

    it "interprets a nil overlay value as an indication to read from the config root" do
      write_config 'values', "foo: 1"
      config = test_config do |config|
        config.define_overlay :default, nil
      end
      config.values.should == { "foo" => 1 }
    end

    it "allows the overlay's value to be the result of a block" do
      write_config 'prod/values', "foo: 1"
      config = test_config do |config|
        config.define_overlay(:environment) { 'prod' }
      end
      config.values.should == { "foo" => 1 }
    end

    it "overwrites values if the config file does not define a hash" do
      write_config 'some_string', "foo bar baz"
      write_config 'prod/some_string', "foo bar baz quux"

      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
      end

      config.some_string.should == "foo bar baz quux"
    end

    it "deep merges hash contents from overlays" do
      write_config 'defaults/values', <<-YML
      foo:
        bar: 1
        baz: 2
      YML

      write_config 'prod/values', <<-YML
      foo:
        baz: 3
      quux: hi!
      YML

      config = test_config do |config|
        config.define_overlay :default, 'defaults'
        config.define_overlay :environment, 'prod'
      end

      config.values.should == { "foo" => { "bar" => 1, "baz" => 3 }, "quux" => "hi!" }
    end

    it "can use both a nil overlay and an overlay with a value" do
      write_config 'values', "foo: 1\nbar: 2"
      write_config 'prod/values', "foo: 2"
      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
      end
      config.values.should == { "foo" => 2, "bar" => 2 }
    end

    it "reads from overlays in order of definition" do
      write_config 'defaults/values', <<-YML
      foo: 1
      bar: 1
      baz: 1
      YML

      write_config 'prod/values', <<-YML
      bar: 2
      baz: 2
      YML

      write_config 'local/values', <<-YML
      baz: 3
      YML

      config = test_config do |config|
        config.define_overlay :default, 'defaults'
        config.define_overlay :environment, 'prod'
        config.define_overlay :local, 'local'
      end

      config.values.should == { "foo" => 1, "bar" => 2, "baz" => 3 }
    end
  end
end
