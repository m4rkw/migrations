Gem::Specification.new do |s|
  s.name        = 'migrations'
  s.version     = '1.0.4'
  s.date        = '2015-09-04'
  s.summary     = "Migrations"
  s.description = "Ruby database migration library"
  s.authors     = ["m4rkw"]
  s.email       = 'm@rkw.io'
  s.files       = ["lib/migrations.rb","lib/migrations/migration.rb","bin/migrate"]
  s.homepage    = 'https://github.com/m4rkw/migrations'
  s.license     = 'MIT'
  s.executables << 'migrate'
  s.add_runtime_dependency "sequel", ["~> 4.25"]
end
