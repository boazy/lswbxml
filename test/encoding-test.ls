require! fs
require! stream
require! \stream-to-buffer

wbxml = require \../lib

as-files-dir = 'test/assets/wbxml/ActiveSync'
as-files = fs.readdir-sync as-files-dir

# Mock buffer along with function to test the resulting obj
mock-wbxml = Buffer [0x03 0x01 0x6a 0x00 0x00 0x07 0x56 0x52 0x03 0x30 0x00 0x01 0x01]
expect-mock-obj = !(obj)->
  obj .should.exist
  obj.full-name .should.equal \FolderHierarchy:FolderSync
  obj.children .should.have.length 1
  obj.children.0.full-name .should.equal \FolderHierarchy:SyncKey
  obj.children.0.children .should.eql ['0']
  obj.children.0.content .should.equal '0'

mock-tree = do
  'FolderHierarchy:FolderSync':
    SyncKey: '0'

# Mock readable stream that demonstrates piping to the encoder
class PiedPiper
  (@buf)->
  pipe: (dest)!->
    for i from 0 til (@buf.length - 5) by 3
      dest.write @buf.slice(i, i + 3)
    dest.end @buf.slice i + 3, @buf.length

# Mock writable stream that accumulates everything to a buffer
class MouseHole extends stream.Writable
  (options)->
    super options
    @bufs = []

  _write: !(chunk, encoding, done)->
    @bufs.push chunk
    done!

  read-buffer: ->
    if @bufs.length == 0
      Buffer 0
    else 
      @bufs = [Buffer.concat @bufs] if @bufs.length > 1
      @bufs.0
      

decode = !(src, options, cb)->
  obj = null
  decoder = new wbxml.Decoder(options)
    ..on \error, !(err)->
      throw err
    ..on \readable, !->
      obj := decoder.read!
    ..on \end, !->
      throw Error("Incomplete WBXML stream") if not obj?
      cb obj

  if src.pipe?
    src.pipe decoder
  else
    decoder.end src

encode = !(obj, options, cb)->
  encoder = new wbxml.Encoder(options)
    ..on \error, !(err)->
      throw err
  
  stream-to-buffer encoder, !(err, buffer)->
    throw err if err
    cb buffer

  encoder.end obj

describe \Decoder !->
  Decoder = wbxml.Decoder

  it 'should throw on unspecified language' !->
    (-> new Decoder) .should.throw Error, 'Language must be specified'

  it 'should throw on unknown language' !->
    (-> new Decoder language: 'Silly language') .should.throw Error, 
      'Built-in language not found: Silly language'

  it 'should support ad-hoc decoding of buffers with static method' !(done)->
    wbxml.decode .should.equal Decoder.decode
    wbxml.decode mock-wbxml, language: \ActiveSync, !(err, obj)->
      throw err if err
      expect-mock-obj obj
      done!

  it 'should support ad-hoc decoding of streams with static method' !(done)->
    stream = new PiedPiper mock-wbxml
    wbxml.decode .should.equal Decoder.decode
    wbxml.decode stream, language: \ActiveSync, !(err, obj)->
      throw err if err
      expect-mock-obj obj
      done!

  it 'should support synchronous ad-hoc decoding of buffers with static method' !->
    wbxml.decode-sync .should.equal Decoder.decode-sync
    obj = wbxml.decode-sync mock-wbxml, language: \ActiveSync
    expect-mock-obj obj

describe \Encoder !->
  Encoder = wbxml.Encoder

  it 'should throw on unspecified language' !->
    (-> new Encoder) .should.throw Error, 'Language must be specified'

  it 'should throw on unknown language' !->
    (-> new Encoder language: 'Silly language') .should.throw Error, 
      'Built-in language not found: Silly language'

  it 'should support ad-hoc encoding to buffers with static method' !(done)->
    mock-obj = wbxml.create-tree mock-tree
    dest = new MouseHole
      ..on \finish ->
        result-wbxml = dest.read-buffer!
        result-wbxml .should.be.eql mock-wbxml
        done!
    wbxml.encode .should.equal Encoder.encode
    wbxml.encode mock-obj, dest, language: \ActiveSync

  it 'should support synchronous ad-hoc decoding of buffers with static method' !->
    mock-obj = wbxml.create-tree mock-tree
    wbxml.encode-sync .should.equal Encoder.encode-sync
    result-wbxml = wbxml.encode-sync mock-obj, language: \ActiveSync
    result-wbxml .should.be.eql mock-wbxml

describe 'Round-trip encoding' !->
  for filename in as-files
    full-path = "#as-files-dir/#filename"
    base-filename = filename - /\.[^.]*$/
    it "should decode '#base-filename' correctly" !(done)->
      fstream = fs.create-read-stream full-path
      <-! fstream.on \open
      obj <-! decode fstream, language: \ActiveSync
      buf <-! encode obj, language: \ActiveSync
      err, orig-buf <-! fs.read-file full-path
      throw err if err
      buf .should.eql orig-buf
      done!

  # TODO: decoding tests