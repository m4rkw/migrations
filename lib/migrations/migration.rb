
class Migration
  def initialize(db)
    @db = db
  end

  def method_missing(method, *args, &block)
    @db.send method, *args, &block
  end
end
