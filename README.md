# figgy

Provides convenient access to configuration files in various formats, with
support for overriding the values based on environment, hostname, locale, or
any other arbitrary thing you happen to come up with.

## Travis-CI Build Status
[![Build Status](https://secure.travis-ci.org/kingmt/figgy.png)](http://travis-ci.org/kingmt/figgy)

## Documentation
[yardocs](http://rdoc.info/github/pd/figgy/master/frames)

## Installation

Just like everything else these days. In your Gemfile:

    gem 'figgy'

## Overview

Set it up (say, in a Rails initializer):

    AppConfig = Figgy.build do |config|
      config.root = Rails.root.join('etc')

      # config.foo is read from etc/foo.yml
      config.define_overlay :default, nil

      # config.foo is then updated with values from etc/production/foo.yml
      config.define_overlay(:environment) { Rails.env }

      # Maybe you need to load XML files?
      config.define_handler 'xml' do |contents|
        Hash.from_xml(contents)
      end
    end

Access it as a dottable, indifferent-access hash:

    AppConfig.foo.some_key
    AppConfig["foo"]["some_key"]
    AppConfig[:foo].some_key

Multiple root directories may be specified, so that configuration files live in
more than one place (say, in gems):

    AppConfig = Figgy.build do |config|
      config.root = Rails.root.join('etc')
      config.add_root Rails.root.join('vendor/etc')
    end

Precedence of root directories is in reverse order of definition, such that the
root directory added first (typically the one immediately within the application)
has highest precedence. In this way, defaults can be inherited from libraries,
but then overridden when necessary within the application.

## Thanks

This was written on [Enova Financial's](http://www.enovafinancial.com) dime/time.
