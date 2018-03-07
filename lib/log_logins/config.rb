# frozen_string_literal: true

module LogLogins

  def self.config
    @config ||= Config.new
  end

  def self.configure(&block)
    block.call(config)
    config
  end

  class Config

    attr_reader :callbacks

    def initialize
      @callbacks = {}
    end

    def on(event, &block)
      @callbacks[event.to_sym] ||= []
      @callbacks[event.to_sym] << block
    end

    def remove_callback(event, block)
      @callbacks[event.to_sym] && @callbacks[event.to_sym].delete(block)
    end

    def events_table_name
      @events_table_name || 'login_events'
    end
    attr_writer :events_table_name

    def block_time
      @block_time || 3600
    end
    attr_writer :block_time

    def attempts_before_block
      @attempts_before_block || 10
    end
    attr_writer :attempts_before_block

    def attempts_before_block_on_ip
      @attempts_before_block_on_ip || attempts_before_block
    end
    attr_writer :attempts_before_block_on_ip

  end
end
