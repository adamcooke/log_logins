# frozen_string_literal: true

require 'log_logins/config'
require 'log_logins/event'
require 'log_logins/user'

if defined?(Rails)
  require 'log_logins/engine'
end

module LogLogins

  def self.success(*args)
    event = touch('Success', *args)
    dispatch(:success, event)
    event
  end

  def self.fail(*args)
    event = touch('Failed', *args)
    dispatch(:fail, event)
    event
  end

  def self.dispatch(callback_name, event)
    if callbacks = config.callbacks[callback_name.to_sym]
      callbacks.each { |c| c.call(event) }
    end
  end

  def self.unblock_user(user)
    Event.log('Unblocked', nil, user, nil)
  end

  def self.unblock_ip(ip)
    Event.log('Unblocked', nil, nil, ip)
  end

  private

  def self.blocked!(username, user, ip, options = {})
    event = Event.log('Blocked', username, user, ip, options)
    dispatch(:blocked, event)
    raise LogLogins::LoginBlocked.new(event), "Login has been blocked due to too many failed logins."
  end

  def self.touch(action, username, user, ip, options = {})
    if Event.user_blocked?(user)
      blocked!(username, user, ip, options)
    end

    if Event.ip_blocked?(ip)
      blocked!(username, user, ip, options)
    end

    Event.log(action, username, user, ip, options)
  end

end
