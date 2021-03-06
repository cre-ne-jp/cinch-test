require 'cinch'
require 'pathname'
require 'thread'

module Cinch
  # Module to allow near network I/O free testing of cinch plugins.
  module Test
    # Mock Class to handle faux IRC networks
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

    # Mock Class to avoid spinning up a real version of the chinch bot.
    class MockBot < Cinch::Bot
      attr_accessor :mask

      def initialize(*)
        super
        @irc = MockIRC.new(self)

        # Don't bother initing plugins if we didn't pass any.
        #   (This is for testing any non-plugin cinch extensions)
        unless @config.plugins.plugins.empty?
          # auugh why
          # this sets up instances of the plugins provided.
          # by default this is done in #start, which also
          # overrides @irc and calls @irc.start, which does
          # network i/o. :(
          @plugins.register_plugins(@config.plugins.plugins)
        end

        # set the bot's hostmask
        @mask = 'foo!bar@baz'
      end
    end

    # Mock class to present Message objects in a more simple fashion
    class MockMessage < Cinch::Message
      def initialize(msg, bot, opts = {})
        # override the message-parsing stuff
        super(nil, bot)
        @message = msg
        @user = Cinch::User.new(opts.delete(:nick) { 'test' }, bot)
        if opts.key?(:channel)
          @channel = Cinch::Channel.new(opts.delete(:channel), bot)
          @target = @channel
        else
          @target = @user
        end

        @bot.user_list.find_ensured(nil, @user.nick, nil)
      end
    end

    Reply = Struct.new(:text, :event, :time)

    def make_bot(plugin = nil, opts = {}, &b)
      MockBot.new do
        configure do |c|
          c.nick = 'testbot'
          c.server = nil
          c.channels = ['#test']
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

    def catch_replies(message, mutex, replies)
      (class << message; self; end).class_eval do
        [:reply, :safe_reply, :action_reply, :safe_action_reply].each do |name|
          define_method name do |msg, prefix = false|
            msg = [user.nick, msg].join(': ') if prefix
            if name == :safe_reply || name == :safe_action_reply
              msg = Cinch::Utilities::String.filter_string(msg)
            end
            reply = Reply.new(msg, name.match(/action/) ? :action : :message,
                              Time.now)
            mutex.synchronize { replies << reply }
          end
        end
      end
    end

    def catch_direct_messages(message, mutex, replies)
      (class << message.user; self; end).class_eval do
        [:send, :msg, :privmsg].each do |method|
          define_method method do |msg, notice = false|
            reply = Reply.new(msg, (notice ? :notice : :private), Time.now)
            mutex.synchronize { replies << reply }
          end
        end
      end
    end

    def catch_channel_messages(message, mutex, replies)
      return unless message.channel
      (class << message.channel; self; end).class_eval do
        [[:send, :channel], [:action, :action]].each do |method, event|
          define_method method do |msg|
            reply = Reply.new(msg, event, Time.now)
            mutex.synchronize { replies << reply }
          end
        end
      end
    end

    # Process message and return all replies.
    # @parmam [Cinch::Test::MockMessage] message A MockMessage object.
    # @param [Symbol] event The event type of the message.
    def get_replies(message, event = :message)
      mutex = Mutex.new
      replies = []

      # Catch all m.reply
      catch_replies(message, mutex, replies)

      # Catch all user.(msg|send|privmsg)
      catch_direct_messages(message, mutex, replies)

      # Catch all channel.send and action
      catch_channel_messages(message, mutex, replies)

      process_message(message, event)

      replies
    end

    # Process message by dispatching it to the handlers
    # @param [Cinch::Test::MockMessage] message A MockMessage object.
    # @param [Symbol] event The event type of the message.
    def process_message(message, event)
      handlers = message.bot.handlers

      # Get a list of applicable event types.
      events = get_events(message, event)

      # Dispatch each of the events to the handlers
      events.each { |e| handlers.dispatch(e, message) }

      # join all of the freaking threads, like seriously
      # why is there no option to dispatch synchronously
      handlers.each do |handler|
        handler.thread_group.list.each(&:join)
      end
    end

    def get_events(message, event)
      # Deal with secondary event types
      # See http://rubydoc.info/github/cinchrb/cinch/file/docs/events.md
      events = event.is_a?(Array) ? [:catchall] + event : [:catchall, event]

      # If the message has a channel add the :channel event otherwise
      #   add :private
      events << (message.channel.nil? ? :private : :channel)

      # If the message is :private also trigger :message
      events << :message if events.include?(:private)

      events.uniq
    end
  end
end
