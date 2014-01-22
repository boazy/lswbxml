require! fs
require! \stream-to-buffer

wbxml = require \../lib

as-files-dir = 'test/assets/wbxml/ActiveSync'
as-files = fs.readdir-sync as-files-dir

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

describe \Encoder !->
  Encoder = wbxml.Encoder
  it 'should throw on unspecified language' !->
    (-> new Encoder) .should.throw Error, 'Language must be specified'

  it 'should throw on unknown language' !->
    (-> new Encoder language: 'Silly language') .should.throw Error, 
      'Built-in language not found: Silly language'

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