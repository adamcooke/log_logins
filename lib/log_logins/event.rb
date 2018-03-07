# frozen_string_literal: true

require 'active_record'
require 'log_logins/config'
require 'log_logins/error'

module LogLogins
  class Event < ActiveRecord::Base

    self.table_name = LogLogins.config.events_table_name

    ACTIONS = ['Success', 'Failed', 'Blocked', 'Unblocked']

    belongs_to :user, :polymorphic => true

    validates :action, :inclusion => {:in => ACTIONS}

    # Events that have failed in the last hour (or whatever the block time might be)
    scope :failed_in_block_time, -> { where(:action => 'Failed').where("created_at > ?", Time.now - LogLogins.config.block_time )}
    scope :success, -> { where(:action => 'Success') }
    scope :success_or_unblock, -> { where(:action => ['Success', 'Unblocked']) }
    scope :failed, -> { where(:action => 'Failed') }
    scope :blocked, -> { where(:action => 'Blocked') }

    # Is this the first block in a series?
    #
    # @return [Boolean]
    def first_block_in_series?
      !!(self.action == 'Blocked' && (previous.nil? ||previous.action != 'Blocked'))
    end

    # Return the login event that preceeded this one for the given scope
    #
    # @return [LogLogins::Event, nil]
    def previous
      similar.order(:id => :desc).where("id < ?", self.id).first
    end

    # Return a scope of similar events
    def similar
      if self.user
        self.class.where(:user => user)
      elsif self.ip
        self.class.where(:user => nil, :ip => ip)
      else
        none
      end
    end

    # Log a new login event
    #
    # @param action [String] the action
    # @param username [String] the username that was provided with the login attempt
    # @param user [ActiveRecord::Base, nil] the user to login against or a string
    # @option options [String] :ip
    # @option options [String] :scope
    # @option options [String] :user_agent
    # @return [LogLogins::Event]
    def self.log(action, username, user, ip, options = {})
      event = self.new
      event.user = user
      event.action = action
      event.username = username
      event.ip = ip
      event.interface = options[:interface]
      event.user_agent = options[:user_agent]
      if event.save
        event
      else
        raise LogLogins::InvalidLogEventError, event.errors.full_messages.to_sentence
      end
    end

    # Is the given user currently blocked from logging in?
    #
    # @param user [ActiveRecord::Base]
    # @return [Boolean]
    def self.user_blocked?(user)
      return false unless user.is_a?(ActiveRecord::Base)
      last_success = self.where(:user => user).success_or_unblock.order(:id => :desc).select(:id).first.try(:id) || 0
      self.failed_in_block_time.where(:user => user).where("id > ?", last_success).count >= LogLogins.config.attempts_before_block
    end

    # Is the given IP address currently blocked from logging in?
    #
    # @param ip [String]
    # @return [Boolean]
    def self.ip_blocked?(ip)
      return false if ip.nil?
      last_success = self.where(:user => nil, :ip => ip.to_s).success_or_unblock.order(:id => :desc).select(:id).first.try(:id) || 0
      self.failed_in_block_time.where(:user => nil, :ip => ip.to_s).where("id > ?", last_success).count >= LogLogins.config.attempts_before_block_on_ip
    end

    # Delete old login data
    #
    # @return [Integer] the number of removed items
    def self.prune(max_age = 6.months)
      if last_to_keep = self.where("created_at <= ?", max_age.ago).order(:created_at => :desc).first.try(:id)
        self.where("id <= ?", last_to_keep).delete_all
      else
        0
      end
    end

  end
end
