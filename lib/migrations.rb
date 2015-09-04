
require 'fileutils'
require 'sequel'

class Migrations
  attr_accessor :path
  attr_accessor :verbose

  def initialize(db=nil)
    config_file = "config/config.rb"

    if db
      @db = db
    elsif File.exist? config_file
      config = {}
      instance_eval(File.read(config_file)).each do |key, value|
        config[key] = value
      end

      if !config[:db]
        raise "Database connection is not defined in config.rb"
      end

      @db = Sequel.connect("#{config[:db][:adapter]}://#{config[:db][:user]}:#{config[:db][:password]}@#{config[:db][:host]}/#{config[:db][:database]}")
    else
      raise "#{config_file} was not found and no database handle was passed to us."
    end

    @path = 'migrations'
    @verbose = true
  end

  def get_migrations
    ensure_migration_table

    filesystem = []
    database = {}
    all = []

    Dir.glob(@path + '/*.rb').map do |migration|
      class_name = migration.match(/(M[0-9]{8}_[0-9]{6}_[a-zA-Z0-9_]+)\.rb\z/)[1]

      filesystem.push class_name
      all.push class_name
    end

    @db[:migration].each do |migration|
      database[migration[:version]] = migration[:applied_at]
      if !all.include? migration[:version]
        all.push migration[:version]
      end
    end

    [filesystem,database,all]
  end

  def list
    filesystem, database, all = get_migrations

    list = []

    all.sort.each do |migration|
      list.push({
        :version => migration,
        :applied => database[migration] ? true : false,
        :applied_at => database[migration] ? database[migration] : ''
      })
    end

    list
  end

  def pending(n=nil)
    filesystem, database, all = get_migrations

    pending = []

    filesystem.sort.each do |migration|
      if !database.keys.include?(migration) and (n.nil? or pending.length < n)
        pending.push migration
      end
    end

    pending
  end

  def applied(n=nil)
    filesystem, database, all = get_migrations

    applied = []

    database.keys.sort.reverse.each do |migration|
      if (n.nil? or applied.length < n)
        applied.push migration
      end
    end

    applied
  end

  def generate(name)
    if !File.exist? @path
      FileUtils.mkdir_p @path
    end

    t = Time.now

    while 1
      t = Time.at(t.to_i + 1)
      class_name = 'M' + t.strftime('%Y%m%d_%H%M%S') + '_' + name.gsub(/[^a-zA-Z0-9_]/i, '')
      migration = "#{@path}/#{class_name}.rb"

      if !File.exist? migration
        break
      end
    end

    File.open(migration,'w') do |f|
      f.write("
require 'migrations/migration'

class #{class_name} < Migration
  def up
  end

  def down
  end
end
")
      @verbose and puts "Create new migration: #{migration}"

      true
    end
  end

  def ensure_migration_table
    begin
      table = @db[:migration].map(:version)
    rescue Sequel::DatabaseError => e
      if e.message.match /Table .*? doesn\'t exist/
        @db.create_table :migration do
          primary_key :id
          String :version, :unique => true, :null => false
          DateTime :applied_at
        end
      else
        raise Sequel::DatabaseError e
      end
    end
  end

  def up(n=nil)
    ensure_migration_table

    pending(n).each do |version|
      apply(version)
    end
  end

  def down(n=nil)
    ensure_migration_table

    applied(n).each do |version|
      revert(version)
    end
  end

  def apply(version, update_table=true)
    migration = @path + '/' + version + '.rb'

    load migration

    m = Object::const_get(version).new(@db)

    @verbose and print "Applying: #{version} ... "

    m.up

    @verbose and puts "ok"

    update_table and insert(version)
  end

  def insert(version)
    @db[:migration].insert(:version => version, :applied_at => Time.now)
  end

  def revert(version, update_table=true)
    migration = @path + '/' + version + '.rb'

    if !File.exist? migration
      raise "Migration file #{migration} not found."
    end

    load migration

    m = Object::const_get(version).new(@db)

    @verbose and print "Rolling back: #{version} ... "

    m.down

    @verbose and puts "ok"

    update_table and remove(version)
  end

  def remove(version)
    @db[:migration].where('version = ?',version).delete
  end
end
