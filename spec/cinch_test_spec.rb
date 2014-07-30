require 'spec_helper'

describe Cinch::Test do
  class MyPlugin
    include Cinch::Plugin

    attr_reader :foo
    def initialize(*)
      super
      @foo = config[:foo]
    end

    match /foo/, method: :foo
    def foo(m)
      m.reply "foo: #{@foo}"
    end

    match /bar/, method: :bar
    def bar(m)
      m.reply 'bar reply'
    end

    match /baz/, method: :baz
    def baz(m)
      m.reply 'baz reply', true
    end

    listen_to :channel
    def listen(m)
      m.reply 'I listen' if m.message == 'blah'
    end

    match /trout/, method: :action, react_on: :action
    def action(m)
      m.reply 'I hate fish'
    end

    match /ping/, method: :ping
    def ping(m)
      m.channel.send 'Pong?'
    end

    match /dance/, method: :dance
    def dance(m)
      m.channel.action 'DANCES'
    end

    match /message/, method: :message
    def message(m)
      m.user.send 'a message!'
    end

    match /scallops/, :method => :shellfish
    def shellfish(m)
      m.action_reply 'loves shellfish'
    end
  end

  include Cinch::Test

  it 'makes a test bot without a config' do
    bot = make_bot(MyPlugin)
    assert bot.is_a?(Cinch::Bot)
  end

  let(:bot) { make_bot(MyPlugin, :foo => 'foo_value') }

  it 'makes a test bot with a config' do
    assert bot.is_a?(Cinch::Bot)
  end

  it 'makes a bot with config values available to the plugin' do
    message = make_message(bot, '!foo')
    replies = get_replies(message)
    assert replies.first.text == 'foo: foo_value'
  end

  describe 'message events' do
    it 'messages a test bot and gets a reply' do
      message = make_message(bot, '!bar')
      replies = get_replies(message)
      assert replies.first.text == 'bar reply'
    end

    it 'messages a test bot and gets a prefixed reply' do
      replies = get_replies(make_message(bot, '!baz'))
      assert replies.first.text == 'test: baz reply'
    end
  end

  describe 'user events' do
    it 'captures messages sent to users' do
      r = get_replies(make_message(bot, '!message', channel: '#test')).first
      assert r.text == 'a message!'
      assert r.event == :private
    end
  end

  describe '#make_message with action_reply' do
    it 'messages a test bot and gets an action' do
      replies = get_replies(make_message(bot, '!scallops'))
      assert replies.first.text == 'loves shellfish'
    end
  end

  describe 'channel events' do
    # This will be fixed next rev, I hope.
    # it 'get triggered by channel events' do
    #   message = make_message(bot, 'blah', channel: '#test')
    #   replies = get_replies(message)
    #   assert replies.first.text == 'I listen'
    # end

    it 'captures channel messages' do
      r = get_replies(make_message(bot, '!ping', channel: '#test')).first
      assert r.text == 'Pong?'
      assert r.event == :channel
    end

    it 'captures a channel action' do
      r = get_replies(make_message(bot, '!dance', channel: '#test')).first
      assert r.text == 'DANCES'
      assert r.event == :action
    end
  end
end
