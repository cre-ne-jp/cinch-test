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
