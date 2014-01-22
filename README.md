lswbxml
=======

Fast streaming WBXML parser and generator for Node.js.

Installation
------------

With npm:

    npm install lswbxml

Parsing WBXML
-------------

### LiveScript: ###
```LiveScript
require! fs
wbxml = require \lswbxml

# With streams
file = fs.create-read-stream 'example.wbxml'
<-! file.on \open
wbxml.decode file, language: \ActiveSync, (err, obj)->
  throw err if err
  console.log 'Parsed WBXML:'
  console.log obj

# With buffers (synchronous)
buf = fs.read-file-sync 'example.wbxml'
obj = wbxml.decode-sync buf, language: \ActiveSync
console.log 'Parsed WBXML:'
console.log obj
```

### CoffeeScript: ###
```CoffeeScript
fs = require 'fs'
wbxml = require 'lswbxml'

# With streams
file = fs.createReadStream 'example.wbxml'
file.on 'open', ->
  wbxml.decode file, language: 'ActiveSync', (err, obj)->
    throw err if err
    console.log 'Parsed WBXML:'
    console.log obj

# With buffers (synchronous)
buf = fs.readFileSync 'example.wbxml'
obj = wbxml.decodeSync buf, language: 'ActiveSync'
console.log 'Parsed WBXML:'
console.log obj
```

### JavaScript ###
```js
fs = require('fs');
wbxml = require('lswbxml');

// With streams
file = fs.createReadStream('example.wbxml');
file.on('open', function() {
  wbxml.decode(file, {language: 'ActiveSync'}, function(err, obj) {
    if (err) {
      throw err;
    }
    console.log('Parsed WBXML:');
    console.log(obj);
  });
});

// With buffers (synchronous)
buf = fs.readFileSync('example.wbxml');
obj = wbxml.decodeSync(buf, {language: 'ActiveSync'});
console.log('Parsed WBXML:');
console.log(obj);
```

Parsing WBXML stream
--------------------

### LiveScript: ###
```LiveScript
require! fs
wbxml = require \lswbxml

file = fs.create-read-stream 'example.wbxml'
<-! file.on \open
obj = null
decoder = new wbxml.Decoder language: \ActiveSync
  ..on \error !->
    throw it
  ..on \readable !->
    obj := decoder.read!
  ..on \end !->
    throw Error("Incomplete WBXML stream") if not obj?
    console.log 'Parsed WBXML:'
    console.log obj
file.pipe decoder
```

### CoffeeScript: ###
```CoffeeScript
fs = require 'fs'
wbxml = require 'lswbxml'

file = fs.createReadStream 'example.wbxml'
file.on 'open', ->
  obj = null
  decoder = new wbxml.Decoder language: 'ActiveSync'
  decoder.on 'error', (err)->
      throw err
  decoder.on 'readable', ->
      obj = decoder.read()
  decoder.on 'end', ->
      throw Error("Incomplete WBXML stream") if obj is null
      console.log 'Parsed WBXML:'
      console.log obj
  file.pipe decoder
```

### JavaScript: ###
```js
fs = require('fs');
wbxml = require('lswbxml');

file = fs.createReadStream('example.wbxml');
file.on('open', function() {
  var obj = null;
  decoder = new wbxml.Decoder({language: 'ActiveSync'});
  decoder.on('error', function(err) {
    throw err;
  });
  decoder.on('readable', function() {
    obj = decoder.read();
  });
  decoder.on('end', function() {
    if (obj === null) {
      throw Error('Incomplete WBXML stream');
    }
    console.log('Parsed WBXML:');
    console.log(obj);
  });
  file.pipe(decoder);
});
```


Building from source
--------------------

    slake build

or

    slake watch

for continuous integration.

Testing
-------

    slake test
