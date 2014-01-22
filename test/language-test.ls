wbxml = require \../lib

Object.values = (obj)-> Object.keys obj .map (k)-> obj[k]

describe \Language !->
  describe 'Built-in languages' !->
    it 'should include ActiveSync' !->
      wbxml.languages .should.include.keys \ActiveSync
      wbxml.languages.ActiveSync.name .should.equal 'ActiveSync'

    it 'should only contain wbxml.Language objects' !->
      Object.values wbxml.languages .should.all.be.instance-of wbxml.Language

  # TODO: Test custom language parsing
