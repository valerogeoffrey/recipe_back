# config/initializers/chaos_database.rb
if Rails.env.development? && ENV['CHAOS_DB'] == '1'
  module ChaosDB
    def self.maybe_boom!
      raise ActiveRecord::ConnectionNotEstablished if rand < (ENV.fetch('CHAOS_PROB', 0.1).to_f)
    end
  end

  ActiveRecord::Base.singleton_class.prepend(Module.new do
    def connection
      ChaosDB.maybe_boom!
      super
    end
  end)
end
