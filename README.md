# Cinch::Test

[![Gem Version](https://badge.fury.io/rb/cinch-test.png)](http://badge.fury.io/rb/cinch-test)
[![Dependency Status](https://gemnasium.com/bhaberer/cinch-test.png)](https://gemnasium.com/bhaberer/cinch-test)
[![Build Status](https://travis-ci.org/bhaberer/cinch-test.png?branch=master)](https://travis-ci.org/bhaberer/cinch-test)
[![Coverage Status](https://coveralls.io/repos/bhaberer/cinch-test/badge.png?branch=master)](https://coveralls.io/r/bhaberer/cinch-test?branch=master)
[![Code Climate](https://codeclimate.com/github/bhaberer/cinch-test.png)](https://codeclimate.com/github/bhaberer/cinch-test)

## Usage

1. `require 'cinch/test'` and include the module `Cinch::Test` in your test scope
2. Make a bot with `make_bot(plugin, plugin_opts)` (you can pass a block to further configure the bot)
3. Make a message with `make_message(bot, 'message text')`
4. Stub things out on the message as you like, then collect all the replies
   with `get_replies(message)`
