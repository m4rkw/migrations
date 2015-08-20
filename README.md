Migrations gem for ruby
=======================

This gem is a simple standalone migrations system for ruby that uses the very awesome Sequel gem for
database communication.  It's designed to be simple and powerful.


Version history
---------------

- 1.0.0 - Initial release
- 1.0.1 - Bugfix (typo :|)
- 1.0.2 - Added ability for -y to be in any part of the arguments, eg: migrate -y up  - this is so that
one can add a shell alias to always -y, eg:  alias mi="migrate -y"


Installation
------------

    sudo gem install migrations

The gem will look for config/config.rb in the current directory when the migrate binary is called.  You should
add your database connection details there.

Alternatively you can use the Migrations class directly without using the binary and simply pass a Sequel
database connection instance into its constructor, eg:

    db = Sequel.connect("connection string")
    m = Migrations.new(db)

Migrations will be placed in migrations/ in the current directory where the migrate binary is executed from.
This can be overridden if calling the Migrations class directly, eg:

    m = Migrations.new(db)
    m.path = "path/to/migrations"


Using the migrate binary
------------------------

By default the binary will prompt the user to continue with whatever action they've requested.  This can be
overridden with the -y flag.

    migrate

Returns a helpful summary of available commands and their parameters.

    migrate list

Returns a list of migrations, both in the database (and therefore applied) and on the filesystem.

    migrate add <name>

Creates a new migration class with a filename based on the current timestamp and the name value.  Only
characters a-zA-Z0-9\_ will be used in the name.

    migrate up

Runs any pending migrations.

    migrate up [n]

Runs [n] pending migrations.

    migrate down

Reverts the last applied migration.

    migrate down [n]

Reverts [n] migrations.

    migrate down all

Reverts all applied migrations.

    migrate to <version>

Migrates either up to down to a specific version.

    migrate set <version>

Sets the current version without applying or reverting any migrations.

    migrate apply <version>

Executes the up method of the specified version without changing the currently migrated version.

    migrate revert <version>

Executes the down method of the specified version without changing the currently migrated version.


Using the Migrations class directly
-----------------------------------

    db = Sequel.new("connection string")
    m = Migrations.new(db)

Note: by default the library will print text to stdout to indicate what it's doing.  This can be disabled
with:

    m.verbose = false

Get a list of all migrations:

    m.list => []

Get a list of pending migrations:

    m.pending => []

Get [n] pending migrations:

    m.pending(2) => []

Get a list of applied migrations:

    m.applied => []

Get [n] applied migrations:

    m.applied(2) => []

Generate a new migration:

    m.generate("test") => true

Apply all pending migrations:

    m.up

Apply [n] pending migrations:

    m.up(2)

Revert all applied migrations:

    m.down

Revert [n] applied migrations:

    m.down(2)

Apply a single migration and update the version:

    m.apply("M20150820_075856_test")

Apply a single migration without updating the version:

    m.apply("M20150820_075856_test",false)

Revert a single migration and update the version:

    m.revert("M20150820_075856_test")

Revert a single migration without updating the version:

    m.revert("M20150820_075856_test",false)

Mark a single version as applied:

    m.insert("M20150820_075856_test")

Mark a single version as not applied:

    m.remove("M20150820_075856_test")


Writing migrations
------------------

By default a migration class will have blank up and down methods.  When the migration is applied
the up method is executed, and when it's reverted the down method is executed.  There is a @db
handle passed to the constructor so that the Sequel database instance is available.  An example
migration that creates a user table might look like this:

    require 'migrations/migration'

    class M20150820_075856_test < Migration
      def up
        @db.create_table :user do
          primary_key :id
          String :username, :unique => true, :null => false
          String :name, :null => false
          String :email, :unique => true, :null => false
          String :password
          String :salt
          TrueClass :active
        end
      end

      def down
        @db.drop_table :user
      end
    end
