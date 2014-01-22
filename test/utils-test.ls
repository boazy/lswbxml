{
  bidi-map
} = require \../lib/utils

describe 'Utils' !->
  describe 'bidi-map' !->
    it "returns empty output for empty input" !->
      bidi-map {} .should.be.empty
    it "Reverses a map" !->
      bidi-map {a: 1, 9: 'x', 0.1: 'yyy'} .should.eql {a: 1, 9: 'x', 0.1: 'yyy', 1: 'a', x: '9', yyy: '0.1'}
