em_postgresql
---------------

An EventMachine-aware driver for using Postgresql with ActiveRecord.

Requirements
==============

* Ruby 1.9! (or Ruby 1.8 with the Fiber extension)
* EventMachine 0.10.12
* postgres-pr 0.6.1
* Rails 2.3.5

Tested with these version, other versions might work.  YMMV.

You CANNOT have the **pg** gem installed.  ActiveRecord prefers the **pg** gem but this code requires
the **postgres-pr** gem to be loaded.  I'm not sure if there is a way to make them live together in harmony.

Usage
=======

List this gem in your `config/environment.rb`:

    config.gem 'em_postgresql', :lib => false

and update your `config/database.yml` to contain the proper adapter attribute:

    adapter: em_postgresql


Author
=========

Mike Perham, mperham AT gmail.com,
[Github](http://github.com/mperham), 
[Twitter](http://twitter.com/mperham),
[Blog](http://mikeperham.com)

