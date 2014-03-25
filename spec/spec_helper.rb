require 'coveralls'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'cinch/test'
require 'minitest'
require 'minitest/autorun'
require 'wrong/adapters/minitest'
require 'rr'

Wrong.config[:color] = true

