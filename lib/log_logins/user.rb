# frozen_string_literal: true

module LogLogins
  module User

    def self.included(base)
      base.has_many :login_events, :class_name => 'LogLogins::Event', :as => :user, :dependent => :delete_all
    end

  end
end
