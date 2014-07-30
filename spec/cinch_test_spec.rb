require 'spec_helper'

describe Cinch::Test do
  include Cinch::Test

  before(:each) do
    @bot = make_bot(MyPlugin, foo: 'foo_value')
  end

  describe 'Mock bot' do
    it 'makes a test bot without a config' do
      bot = make_bot(MyPlugin)
      expect(bot).to be_instance_of(Cinch::Test::MockBot)
    end

    it 'makes a test bot with a config' do
      expect(@bot).to be_instance_of(Cinch::Test::MockBot)
    end

    it 'makes a bot with config values available to the plugin' do
      message = make_message(@bot, '!foo')
      replies = get_replies(message)
      expect(replies.first.text).to eq('foo: foo_value')
    end
  end

  describe 'message events' do
    it 'messages a test bot and gets a reply' do
      message = make_message(@bot, '!bar')
      replies = get_replies(message)
      expect(replies.first.text).to eq('bar reply')
    end

    it 'messages a test bot and gets a prefixed reply' do
      replies = get_replies(make_message(@bot, '!baz'))
      expect(replies.first.text).to eq('test: baz reply')
    end
  end

  describe 'user events' do
    it 'captures messages sent to users' do
      r = get_replies(make_message(@bot, '!message', channel: '#test')).first
      expect(r.text).to eq('a message!')
      expect(r.event).to eq(:private)
    end
  end

  describe '#make_message with action_reply' do
    it 'messages a test bot and gets an action' do
      replies = get_replies(make_message(@bot, '!scallops'))
      expect(replies.first.text).to eq('loves shellfish')
    end
  end

  describe 'channel events' do
    # This will be fixed next rev, I hope.
    it 'get triggered by channel events' do
      message = make_message(@bot, 'blah', channel: '#test')
      replies = get_replies(message)
      expect(replies.first.text).to eq('I listen')
    end

    it 'captures channel messages' do
    r = get_replies(make_message(@bot, '!ping', channel: '#test')).first
      expect(r.text).to eq('Pong?')
      expect(r.event).to eq(:channel)
    end

    it 'captures a channel action' do
      r = get_replies(make_message(@bot, '!dance', channel: '#test')).first
      expect(r.text).to eq('DANCES')
      expect(r.event).to eq(:action)
    end
  end
end
