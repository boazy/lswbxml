{
  partition
  find
  flatten
} = require \prelude-ls

{ spawn }     = require \child_process
{ dirname }   = require \path

require! gaze
require! fs
require! LiveScript
require! mkdirp
require! dive-sync

/* Tasks */

task \build 'Compile all LiveScript from src/ to JavaScript in lib/' ->
  build!

task \test 'Build and test files' ->
  build-test!

task \watch 'Watch, compile and test files.' ->
  run = (op)->
    !->
      clearTerminal!
      op!

  gaze [\src/**/*.ls \test/**/*.ls], -> @on \all, run !->
    build-test checkError

/* Helper functions */

slobber = (filename, contents)->
  spit filename, contents
  say "* #filename"

build = !(cb)->
  clean ->
    compile cb

build-test = !(cb)->
  <- clean
  err <- compile
  cb err if err
  test cb

test = !(cb)->
  err <- compile-tests
  if err
    if cb? then cb err
    else throw err
  run-mocha 'testjs' cb

run-mocha = (test-path, cb) ->
  mocha-path = [\node_modules/.bin/mocha, \node_modules/mocha/bin/mocha]
    |> find fs.exists-sync
    |> path.normalize

  requires = [\chai \./testjs/common]
  base-args = flatten [[\--require req] for req in requires]
  base-args ++= [\--reporter \spec test-path]

  if process.platform is /^win/
    mocha-path
    args =
      \/c
      mocha-path
    args ++= base-args
    proc = spawn 'cmd', args, { stdio: \inherit }
  else
    proc = spawn mocha-path, base-args, { stdio: \inherit }
  if cb then proc.on \exit cb

clean = !(cb)->
  proc = spawn \rm [\-r \./bin \./lib \./testjs]
  if cb then proc.on \exit cb

default-post-proc = (filename, content)-> content
compile-ls = !(src-dir, {transform-path, postprocess=default-post-proc}, cb)-->
  try
    # Ensure src-dir ends with a slash
    src-dir += '/' if src-dir is not /\/$/
    src-dir-no-slash = src-dir.slice 0, -1
    in-src-dir-re = RegExp "^#{src-dir}"
    dive-sync src-dir-no-slash, (err, filename)->
      throw err if err
      if filename is /\.ls$/
        base-file = (filename.replace in-src-dir-re, '').replace /\.ls$/ '.js'
        out-file = transform-path base-file
        mkdirp.sync (out-file |> dirname)
        fs.read-file-sync filename, \utf8
        |> (LiveScript.compile _, { +bare, filename })
        |> (postprocess out-file, _)
        |> (slobber out-file, _)
  catch err
    cb err
    return
  cb null

compile = compile-ls 'src/' do
  transform-path: (base-path)->
    if base-path is /^bin\//
      base-path
    else
      "lib/#base-path"

const BDD_WRAPPER_HEADER = '''var _describe;
  _describe = function(s, cb){
    describe(s, function(){
      cb(it);
    });
  };

  (function(describe){

'''

const BDD_WRAPPER_FOOTER = '\n})(_describe);\n'  

compile-tests = compile-ls 'test/' do
  transform-path: (base-path)->
    "testjs/#base-path"
  postprocess: (filename, content)->
    if filename is /-test\.js$/
      BDD_WRAPPER_HEADER + content + BDD_WRAPPER_FOOTER
    else
      content

livescript = !(args, cb)->
  proc = spawn 'node' ['node_modules/LiveScript/bin/livescript'] ++ args
  proc.stderr.on \data say
  proc.on \error, (err) ->
    throw err
  proc.on \exit, (err) ->
    if cb then err = cb err
    if err then process.exit err

clear-terminal = -> process.stdout.write '\u001B[2J\u001B[0;0f'

check-error = (err)->
  if err
    console.log "Error: #err"
  else
    console.log "Build successful."
  false
