$:.unshift(File.expand_path('../../lib', __FILE__))
require 'log_logins'

module Helpers
  def simulate_failed_logins(number, username, user, ip, options = {})
    number.times do
      LogLogins::Event.log('Failed', username, user, ip, options)
    end
  end
end

RSpec.configure do |config|
  config.color = true
  config.include Helpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after(:each) do
    LogLogins::Event.delete_all
  end
end

require 'active_record'
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveRecord::Migrator.migrate(File.expand_path('../../db/migrate', __FILE__))
ActiveRecord::Migration.create_table :users do |t|
  t.string :username
end

class User < ActiveRecord::Base
end
