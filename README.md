em_postgresql
---------------

An EventMachine-aware driver for using Postgresql with ActiveRecord.

Requirements
==============

* Ruby 1.9
* EventMachine 0.12.10
* postgres-pr 0.6.1
* Rails 2.3.5

Tested with these version, other versions might work.  YMMV.

You CANNOT have the **pg** gem installed.  ActiveRecord prefers the **pg** gem but this code requires
the **postgres-pr** gem to be loaded.  I'm not sure if there is a way to make them live together in harmony.

You'll need to ensure your code is running within an active Fiber using the FiberPool defined in fiber_pool.rb.  If you are running Rails in Thin, the following code is a good place to start to figure out how to do this:

<http://github.com/espace/neverblock/blob/master/lib/never_block/servers/thin.rb>

Usage
=======

List this gem in your `config/environment.rb`:

    config.gem 'postgres-pr', :lib => false
    config.gem 'em_postgresql', :lib => false

and update your `config/database.yml` to contain the proper adapter attribute:

    adapter: em_postgresql


Author
=========

Mike Perham, mperham AT gmail.com,
[Github](http://github.com/mperham), 
[Twitter](http://twitter.com/mperham),
[Blog](http://mikeperham.com)

