require! buffertools
require! stream.Transform
require! string_decoder.StringDecoder
require! util.inspect
require! Enum: \simple-enum

{ map } = require \prelude-ls

languages = require \./builtin-languages
{ WbxmlElement } = require \./tree
{ charsets, tokens } = require \./defs
{ print } = require \./utils

states = Enum <[header str_i opaque_size opaque switch_page token past_end]>
null-terminator = new Buffer [0]

if process.env.NODE_DEBUG is /\bwbxml\b/
  debug = !(msg)->
    print "WBXML: #msg"
else
  debug = !->

Number.prototype.to-hex = ->
  "0x#{@to-string(16)}"

class Decoder extends Transform
  (options={})->
    super options
    # Use object mode just on the readable state
    @_readable-state.object-mode = true

    @language = options.language
    if not @language?
      throw Error "Language must be specified"
    if typeof @language is 'string'
      lang-name = @language
      if not @language = languages[lang-name]
        throw Error "Built-in language not found: #lang-name"
    @_pages = @language.codepages
    @_page = @_pages.0
    @_header  = {}
    @_stack   = []   # Stack of incomplete parent nodes
    @_element = null # Current WBXML node
    @_state = states.header
    @_is_mb = false
    @_buffers = []
    @_buffers_len = 0

  @decode = !(src, options, cb)->
    decoder = new Decoder options
    obj = null
    if src.pipe?
      decoder
        ..on \error, !(err)->
          cb err, null
        ..on \readable, !->
          obj := decoder.read!
        ..on \end, !->
          if obj? then cb null, obj
          else cb Error("Incomplete WBXML stream"), null
      src.pipe decoder
    else
      # src is chunk, so we call _transform() directly
      # Monkey-patch decoder object to simplify processing
      err = null
      decoder.push = !(pushed-obj)->
        obj := pushed-obj
      decoder.emit = !(event, data)->
        err := data if event is 'error'
      <-! decoder._transform src, null
      if err? then cb err, null
      else if not obj? then cb Error("Incomplete WBXML stream"), null
      else cb null, obj

  @decode-sync = (src, options)->
    throw Error("Stream decoding must be asynchronous!") if src.pipe?
    result = null
    @decode src, options, !(err, obj)->
      throw err if err
      result := obj
    throw Error("Unexpected condition") if not result?
    result

  _flush_buffers: (last-chunk, binary)->
    if @_buffers.length > 0
      @_buffers.push last-chunk
      consolidated = Buffer.concat @_buffers, @_buffers_len + last-chunk.length
    else
      consolidated = last-chunk

    @_buffers = []
    @_buffers_len = 0

    if binary
      consolidated
    else
      # Decode to string using chosen codepage
      @_decoder.write consolidated

  _start_mb: !->
    @_mb_val = 0
    @_is_mb = true

  _transform: !(chunk, encoding, done)->
    clen = chunk.length
    if clen == 0
      return done!

    try
      i = 0
      while i < clen
        if @_is_mb
          b = chunk[i]
          @_mb_val .<<.= 7
          @_mb_val = b .&. 0x7f
          throw "mb_u_int32 overflow (could be invalid or malicious WBXML)!" if @_mb_val > 0xFFFFFFFF
          @_is_mb = b .&. 0x80
          continue if @_is_mb

        switch @_state
        case states.header
          # WBXML Header
          if not @_header.version?
            @_header.version = chunk[i]
            @_start_mb!
          else if not @_header.public-id?
            # TODO: support string talbe indexes
            @_header.public-id = @_mb_val
            @_start_mb!
          else if not @_header.charset?
            charset = @_mb_val
            charset-name = charsets[charset]
            @_header.charset = charset
            if charset-name
              @_decoder = new StringDecoder charset-name
            else
              throw "Unsupported charset: #charset"
            @_start_mb!
          else if not @_header.strtbl?
            # todo skip, later parse
            @_header.strtbl = chunk[i]
            throw "WBXML String Table is not supported" if @_header.strtbl != 0
            @_state = states.token
        case states.str_i
          term = buffertools.index-of chunk, null-terminator, i
          if term >= 0
            last-chunk = chunk.slice i, term
            entire-str = @_flush_buffers last-chunk
            throw "An element must be open!" if not @_element
            @_element.add-content entire-str
            i := term
            @_state = states.token
            #debug "STR-I #entire-str"
          else
            @_buffers.push (chunk.slice i, clen)
            @_buffers_len += clen - i
            return done! # chunk exhausted
        case states.opaque_size
          @_state = states.opaque
        case states.opaque
          opaque-left = @_mb_val - @_buffers_len
          if opaque-left <= (clen - i)
            opaque-end = i + opaque-left
            last-chunk = chunk.slice i, opaque-end
            opaque-data = @_flush_buffers last-chunk, true
            throw "An element must be open!" if not @_element
            @_element.add-content opaque-data
            i := opaque-end - 1
            @_state = states.token
            #debug "OPAQUE: #{opaque-data.inspect!}"
          else
            @_buffers.push (chunk.slice i, clen)
            @_buffers_len += clen - i
            return done! # chunk exhausted
        case states.switch_page
          page-num = chunk[i]
          if not @_page = @_pages[page-num]
            throw "Codepage not found: #{page-num.to-hex!}"
          #debug "Switch page to #{@_page.Namespace} (#{page-num.to-hex!})"
          @_state = states.token
        case states.token
          token = chunk[i]
          #debug "TOKEN: #{token.to-hex!}"
          switch token
          case tokens.SWITCH_PAGE
            @_state = states.switch_page
          case tokens.STR_I
            @_state = states.str_i
          case tokens.STR_T
            throw "WBXML String Table is not supported"
          case tokens.OPAQUE
            @_state = states.opaque_size
            @_start_mb!
          case tokens.END
            #debug "END Current: #{@_element.$name}, Stack: #{@_stack |> map (.$name)}"
            if @_stack.length == 0
              # Closing the root element
              throw "No root element found in WBXML document!" if not @_element
              @push @_element
              @_state = states.past_end
            else
              @_element = @_stack.pop!
              @_state = states.token
          default
            tag-code = token .&. 0x3f
            if tag-code < 0x05
              # When literals are supported this should be '< 0x04'
              token-name = "UNKNOWN" if not token-name = tokens[token]
              throw "Unsupported special WBXML token: #token-name (#{token.to-hex!}))"

            if token .&. 0x80
              throw "Attributes are not supported! Token: #{token.to-hex!}"
            has-children = token .&. 0x40
            if not tag = @_page[tag-code]
              throw "Unknown tag #{tag-code.to-hex!} in #{@_page.Namespace}"
            
            new-element = new WbxmlElement(tag, @_element)
            new-element.namespace = @_page.Namespace
            if @_element
              # Non-root element, add to parent and push parent to the stack
              @_element.add-child(new-element)
              if has-children
                @_stack.push @_element if @_element
                @_element = new-element
              #else debug "Childless #tag"
            else
              # Root element
              if has-children
                @_element = new-element
              else
                # Root element is childless - output it directly
                @push new-element
            
        case states.past_end
          throw "Data past end: #{chunk.slice(i, chunk.length-i)}"
        default
          throw "Unexpected state: #{@_state}"
        i++

    catch er
      @emit "error", er

    done!

module.exports = Decoder