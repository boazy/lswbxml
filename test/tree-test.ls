wbxml = require \../lib

describe \Tree !->
  tree-obj =
    Root:
      Main:
        Str: 'Foo'
        Buf: Buffer [0x11, 0x22, 0x33]
        Num: 42
        True: true
        False: false
      Secondary:
        Data:
          * Bar: 'Barbar'
          * Data: 'Data in Data'
            Other: 'Baz'
          * 'Direct Content'

  tree-ns =
    'Default:Root':
      Main:
        'Foo:Str': 'Foo'
        'http://ns.foo.org:999/ns:Str': 'Bar'
        'Str': 'Baz'
      'Foo:Food':
        Pasta:
          * 'Spaghettini'
          * 'Spaghettoni'

  tree-empty =
    Root:
      Empty: {}
      Null: null
      Undef: undefined
      
  describe 'Creating trees with create-tree()' !->
    it 'should throw on empty input' !->
      (-> wbxml.create-tree {}) .should.throw Error, 'Empty object'

    it 'should return a wbxml.Element' !->
      wbxml.create-tree tree-obj .should.be.an.instance-of wbxml.Element

    it 'should return a single wbxml.Element even on multiple-root input' !->
      wbxml.create-tree {a: '1', b: '2'} .should.be.an.instance-of wbxml.Element

    it 'should return an equivalent tree as output' !->
      res = wbxml.create-tree tree-obj
      res.name .should.equal 'Root'
      res.Main.Str.content .should.equal 'Foo'
      res.Main.Buf.content .should.be.eql Buffer [0x11, 0x22, 0x33]
      res.Main.Num.content .should.equal \42
      res.Main.True.content .should.be.equal \1
      res.Main.False.content .should.be.equal \0
      res.Secondary.Data .should.have.length.of 3
      res.Secondary.Data.0.Bar.content .should.equal 'Barbar'
      res.Secondary.Data.1.name .should.equal 'Data'
      res.Secondary.Data.1.Data.name .should.equal 'Data'
      res.Secondary.Data.1.Data.content  .should.equal 'Data in Data'
      res.Secondary.Data.1.Other.content  .should.equal 'Baz'
      res.Secondary.Data.2.name .should.equal 'Data'
      res.Secondary.Data.2.content  .should.equal 'Direct Content'

    it 'should work with namespaces' !->
      res = wbxml.create-tree tree-ns
      res.name .should.equal 'Root'
      res.namespace .should.equal 'Default'
      res.full-name .should.equal 'Default:Root'
      res.Main.Str .should.have.length.of 3
      res.Main.Str .should.all.have.property \name, 'Str'
      res.Main.Str.0.namespace .should.equal 'Foo'
      res.Main.Str.1.namespace .should.equal 'http://ns.foo.org:999/ns'
      res.Main.Str.2.namespace .should.equal 'Default'
      res.Main.Str.0.full-name .should.equal 'Foo:Str'
      res.Main.Str.1.full-name .should.equal 'http://ns.foo.org:999/ns:Str'
      res.Main.Str.2.full-name .should.equal 'Default:Str'
      res.Food.Pasta .should.all.have.property \fullName, 'Foo:Pasta'
      res.Food.Pasta.0.content .should.equal 'Spaghettini'
      res.Food.Pasta.1.content .should.equal 'Spaghettoni'

    it 'should work with empty nodes' !->
      res = wbxml.create-tree tree-empty
      res.name .should.equal 'Root'
      res.Empty.children .should.be.empty
      res.Null.children .should.be.empty
      res .should.not.have.property 'Undef'
  