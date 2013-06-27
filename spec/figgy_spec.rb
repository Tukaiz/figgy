require 'spec_helper'

describe Figgy do
  it "reads YAML config files" do
    write_config 'values', <<-YML
    foo: 1
    bar: 2
    YML

    test_config.values.should == { "foo" => 1, "bar" => 2 }
  end

  it "raises an exception if the file can't be found" do
    expect { test_config.values }.to raise_error(Figgy::FileNotFound)
  end

  it "has a useful #inspect method" do
    write_config 'values', 'foo: 1'
    write_config 'wtf', 'bar: 2'

    config = test_config
    config.inspect.should == "#<Figgy (empty)>"

    config.values
    config.inspect.should == "#<Figgy (1 keys): values>"

    config.wtf
    config.inspect.should == "#<Figgy (2 keys): values wtf>"
  end

  context "multiple extensions" do
    it "supports .yaml" do
      write_config 'values.yaml', 'foo: 1'
      test_config.values.foo.should == 1
    end

    it "supports .yml.erb and .yaml.erb" do
      write_config 'values.yml.erb', '<%= "foo" %>: <%= 1 %>'
      write_config 'values.yaml.erb', '<%= "foo" %>: <%= 2 %>'
      test_config.values.foo.should == 2
    end

    it "supports .json" do
      write_config "values.json", '{ "json": true }'
      test_config.values.json.should be_true
    end

    it "loads in the order named" do
      write_config 'values.yml', 'foo: 1'
      write_config 'values.yaml', 'foo: 2'

      config = test_config do |config|
        config.define_handler('yml', 'yaml') { |body| YAML.load(body) }
      end
      config.values.foo.should == 2
    end
  end

  context "multiple roots" do
    it "can be told to read from multiple directories" do
      write_config 'root1/values', 'foo: 1'
      write_config 'root2/values', 'bar: 2'

      config = test_config do |config|
        config.root = File.join(current_dir, 'root1')
        config.add_root File.join(current_dir, 'root2')
      end

      config.values.foo.should == 1
      config.values.bar.should == 2
    end

    it "supports overlays in each root" do
      write_config 'root1/values',      'foo: 1'
      write_config 'root1/prod/values', 'foo: 2'
      write_config 'root2/values',      'bar: 1'
      write_config 'root2/prod/values', 'bar: 2'

      config = test_config do |config|
        config.root = File.join(current_dir, 'root1')
        config.add_root File.join(current_dir, 'root2')
        config.define_overlay :environment, 'prod'
      end

      config.values.foo.should == 2
      config.values.bar.should == 2
    end

    it "reads from roots in *reverse* order of definition" do
      write_config 'root1/values', 'foo: 1'
      write_config 'root1/prod/values', 'foo: 2'
      write_config 'root2/prod/values', 'foo: 3'

      config = test_config do |config|
        config.root = File.join(current_dir, 'root1')
        config.add_root File.join(current_dir, 'root2')
        config.define_overlay :environment, 'prod'
      end

      config.values.foo.should == 2
    end
  end

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

  context "combined overlays" do
    it "allows new overlays to be defined from the values of others" do
      write_config 'keys', "foo: 1"
      write_config 'prod/keys', "foo: 2"
      write_config 'prod_US/keys', "foo: 3"

      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
        config.define_overlay :country, 'US'
        config.define_combined_overlay :environment, :country
      end

      config.keys.should == { "foo" => 3 }
    end
  end
end

describe Figgy do
  describe 'CnuConfig drop-in compatibility' do
    it "should maybe support path_formatter = some_proc.call(config_name, overlays)"
    it "should support preload's all_key_names when using path_formatter"
    it "should support preload's all_key_names when using path_formatter"
  end
end
