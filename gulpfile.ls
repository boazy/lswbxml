require! {
  gulp
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

tests-filter = gulp-filter \**/*-test.js

gulp.task \build-tests ->
  gulp.src paths.tests-src
    .pipe gulp-livescript bare: true
    .pipe tests-filter
    .pipe postprocess-tests!
    .pipe tests-filter.restore!
    .pipe gulp.dest 'testjs'

gulp.task \test <[build build-tests]> ->
  gulp.src paths.tests-js
      .pipe gulp-mocha {reporter: \spec}

gulp.task \watch ->
  if gulp-env.build-only
    gulp.watch paths.src,   <[build]>
  else
    gulp.watch paths.src,       <[test]>
    gulp.watch paths.tests-src, <[test]>

gulp.task \bump ->
  return gulp.src \package.json
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

