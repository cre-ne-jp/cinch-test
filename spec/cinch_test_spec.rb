require 'spec_helper'

describe Cinch::Test do
  include Cinch::Test

  before(:each) do
    @bot = make_bot(MyPlugin, foo: 'foo_value')
  end

  describe 'Cinch::Test' do
    it 'should add the :channel event to messages with a channel set' do
      message = make_message(@bot, 'blah', channel: '#test')
      expect(get_events(message, []))
        .to include(:channel)
    end
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

  describe 'Messages' do
    it 'sent directly to a test bot get a logged reply' do
      message = make_message(@bot, '!bar')
      replies = get_replies(message)
      expect(replies.first.text).to eq('bar reply')
    end

    it 'sent directly to bot get correct number of replies' do
      message = make_message(@bot, '!bar')
      replies = get_replies(message)
      expect(replies.size).to eq(1)
    end

    it 'sent directly to a test bot and can receive a prefixed reply' do
      replies = get_replies(make_message(@bot, '!baz'))
      expect(replies.first.text).to eq('test: baz reply')
    end

    it 'sent to users are logged' do
      r = get_replies(make_message(@bot, '!message', channel: '#test')).first
      expect(r.text).to eq('a message!')
      expect(r.event).to eq(:private)
    end

    it 'sent to a bot can be responded to with a logged action' do
      replies = get_replies(make_message(@bot, '!scallops'))
      expect(replies.first.text).to eq('loves shellfish')
    end

    it 'sent to a channel get correct number of replies' do
      message = make_message(@bot, '!bar', channel: '#test')
      replies = get_replies(message)
      expect(replies.size).to eq(1)
    end

    it 'should trigger listeners' do
      message = make_message(@bot, 'blah', channel: '#test')
      expect(get_replies(message)).to_not be_empty
    end

    it 'should trigger listeners and log the output text' do
      message = make_message(@bot, 'blah', channel: '#test')
      replies = get_replies(message)
      expect(replies.first.text).to eq('I listen')
    end

    it 'should trigger in channels properly' do
      r = get_replies(make_message(@bot, '!ping', channel: '#test')).first
      expect(r.text).to eq('Pong?')
      expect(r.event).to eq(:channel)
    end

    it 'that are events should trigger properly' do
      r = get_replies(make_message(@bot, '!dance', channel: '#test')).first
      expect(r.text).to eq('DANCES')
      expect(r.event).to eq(:action)
    end
  end
end
