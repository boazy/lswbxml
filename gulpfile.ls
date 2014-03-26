require! {
  gulp
  \gulp-clean
  \gulp-util
  \gulp-livescript
  \gulp-mocha
  \gulp-filter
  \gulp-bump
  through: through2
  through-map: \through2-map
  conventional-changelog: \gulp-conventional-changelog
  git: \gulp-git
}

paths =
  src: <[src/**/*.ls]>
  tests-src: <[test/**/*.ls]>
  tests-js: <[testjs/common.js testjs/**/*-test.js]>

gulp-env = gulp-util.env

watching = false
skip-errors-when-watching = (stream)->
  if watching
    stream.on \error (err)->
      console.log err.to-string!
      gulp-util.beep!
      @emit \end
  else
    stream

pipe = (dest)->
  (src)-> src.pipe dest

const BDD_WRAPPER_HEADER = new Buffer '''var _describe;
  _describe = function(s, cb){
    describe(s, function(){
      cb(it);
    });
  };

  (function(describe){

'''

const BDD_WRAPPER_FOOTER = new Buffer '\n})(_describe);\n'  

postprocess-tests = ->
  through-map {object-mode: true}, (file)->
    is-stream = typeof file?.contents?.on is \function and typeof file?.contents?.pipe is 'function'
    is-buffer= file?.contents instanceof Buffer
    if is-stream
      file.contents = through do
        # Per-chunk
        (chunk, enc, done)->
          if not @_header_written
            @_header_written = true
            @push BDD_WRAPPER_HEADER
          @push chunk
          done!

        # At end
        (done)->
          # We only need to write the footer if header was written (i.e. file is not empty)
          @push BDD_WRAPPER_FOOTER if @_header_written
          done!
    else if is-buffer
      file.contents = Buffer.concat [BDD_WRAPPER_HEADER, file.contents, BDD_WRAPPER_FOOTER]
    file

gulp.task \default <[test]>

gulp.task \build ->
  gulp.src paths.src
    .pipe gulp-livescript bare: true
    .pipe gulp.dest 'lib'
    |> skip-errors-when-watching

tests-filter = gulp-filter \**/*-test.js

gulp.task \build-tests ->
  gulp.src paths.tests-src
    |> pipe gulp-livescript bare: true
    |> skip-errors-when-watching
    |> pipe tests-filter
    |> pipe postprocess-tests!
    |> pipe tests-filter.restore!
    |> pipe gulp.dest 'testjs'

gulp.task \test <[build build-tests]> ->
  gulp.src paths.tests-js
    |> pipe gulp-mocha {reporter: \spec}
    |> skip-errors-when-watching

gulp.task \watch ->
  watching := true
  if gulp-env.build-only
    gulp.watch paths.src,   <[build]>
  else
    gulp.watch paths.src,       <[test]>
    gulp.watch paths.tests-src, <[test]>

gulp.task \bump ->
  gulp.src \package.json
    .pipe gulp-bump gulp-env{type or gulp-env.t or \patch}
    .pipe gulp.dest '.'
    .pipe git.add!

gulp.task \changelog <[bump]> ->
  gulp.src <[ package.json CHANGELOG.md ]>
    .pipe conventional-changelog!
    .pipe gulp.dest '.'
    .pipe git.add!

gulp.task \tag <[changelog]>, ->
  pkg = require \./package.json
  v = "v#{pkg.version}"
  message = "chore(release): #v"
  gulp.src './'
    .pipe git.commit message
    .pipe git.tag v, message
    .pipe git.push \origin \master
    .pipe git.push \origin \master \--tags
    .pipe gulp.dest './'

gulp.task \clean ->
  gulp.src <[lib testjs]>
    .pipe gulp-clean!
