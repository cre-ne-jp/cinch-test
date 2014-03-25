require 'cinch'
require 'pathname'
require 'thread'

module Cinch
  module Test
    class MockIRC < Cinch::IRC
      def initialize(*args)
        super
        # the #setup method adds the @network property among
        # other things
        setup
      end

      # @override
      # never try to actually connect to a network
      def connect
        @bot.loggers.info('mock irc: not connecting')
      end
    end

    class MockBot < Cinch::Bot
      def initialize(*args)
        super
        @irc = MockIRC.new(self)

        # auugh why
        # this sets up instances of the plugins provided.
        # by default this is done in #start, which also
        # overrides @irc and calls @irc.start, which does
        # network i/o. :(
        unless @config.plugins.plugins.empty?
          @plugins.register_plugins(@config.plugins.plugins)
        end
      end
    end

    class MockMessage < Cinch::Message
      def initialize(msg, bot, opts = {})
        # override the message-parsing stuff
        super(nil, bot)
        @message = msg
        @user = Cinch::User.new(opts.delete(:nick) { 'test' }, bot)
        @channel = Cinch::Channel.new(opts.delete(:channel), bot) if opts.key?(:channel)

        @bot.user_list.find_ensured(nil, @user.nick, nil)
      end
    end

    Reply = Struct.new(:text, :event, :time)

    def make_bot(plugin = nil, opts = {}, &b)
      MockBot.new do
        configure do |c|
          c.nick = 'testbot'
          c.server = nil
          c.plugins.plugins = [plugin] unless plugin.nil?
          c.plugins.options[plugin] = opts
          c.reconnect = false
        end

        instance_eval(&b) if b
      end
    end

    def make_message(bot, text, opts = {})
      MockMessage.new(text, bot, opts)
    end

    # Process message and return all replies.
    # @parmam [Cinch::Test::MockMessage] message A MockMessage object.
    # @param [Symbol] event The event type of the message.
    def get_replies(message, event = :message)
      mutex = Mutex.new
      replies = []

      # Catch all m.reply
      (class << message; self; end).class_eval do
        define_method :reply do |msg, prefix = false|
          msg = [self.user.nick, msg].join(': ') if prefix
          r = Reply.new(msg, :message, Time.now)
          mutex.synchronize { replies << r }
        end
      end

      # Catch all user.(msg|send|privmsg)
      (class << message.user; self; end).class_eval do
        [:send, :msg, :privmsg].each do |method|
          define_method method do |msg, notice = false|
            r = Reply.new(msg, (notice ? :notice : :private), Time.now)
            mutex.synchronize { replies << r }
          end
        end
      end

      # Catch all channel.send and action
      if message.channel
        (class << message.channel; self; end).class_eval do
          define_method :send do |msg, notice = false|
            r = Reply.new(msg, :channel, Time.now)
            mutex.synchronize { replies << r }
          end

          define_method :action do |msg, notice = false|
            r = Reply.new(msg, :action, Time.now)
            mutex.synchronize { replies << r }
          end
        end
      end

      process_message(message, event)

      replies
    end

    private

    # Process message by dispatching it to the handlers
    # @param [Cinch::Test::MockMessage] message A MockMessage object.
    # @param [Symbol] event The event type of the message.
    def process_message(message, event)
      handlers = message.bot.handlers

      # Deal with secondary event types
      # See http://rubydoc.info/github/cinchrb/cinch/file/docs/events.md
      events = [:catchall, event]

      # If the message has a channel add the :channel event otherwise add private
      events << message.channel.nil? ? :private : :channel

      # If the message is :private also trigger :message
      events << :message if events.include?(:private)

      # Dispatch each of the events to the handlers
      events.each { |e| handlers.dispatch(e, message) }

      # join all of the freaking threads, like seriously
      # why is there no option to dispatch synchronously
      handlers.each do |handler|
        handler.thread_group.list.each(&:join)
      end
    end
  end
end
