require 'coveralls'
Coveralls.wear!

require 'cinch/test'
require 'minitest'
require 'minitest/autorun'
require 'wrong/adapters/minitest'
require 'rr'

Wrong.config[:color] = true

