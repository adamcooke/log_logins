# frozen_string_literal: true

module LogLogins
  class Error < StandardError
  end

  class InvalidLogEventError < Error
  end

  class LoginBlocked < Error
    attr_accessor :event

    def initialize(event)
      @event = event
    end

  end
end
