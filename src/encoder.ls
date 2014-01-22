require! stream.Transform

{ WbxmlElement } = require \./tree
{ charsets, tokens } = require \./defs
{ print } = require \./utils

if process.env.NODE_DEBUG is /\bwbxml\b/
  debug = !(msg)->
    print "WBXML: #msg"
else
  debug = !->

Number.prototype.to-hex = ->
  "0x#{@to-string(16)}"

to-mbuint32 = (intval)->
  throw "Multibyte value should fit in a uint32" if intval >= 0xFFFFFFFF
  result = Buffer 5
  for i from 4 to 0
    result[i] = intval .&. 0x7f
    intval = intval .>>. 7
    if intval == 0
      break

  result.slice i, 5

languages = require \./builtin-languages

export class Encoder extends Transform
  (options={})->
    super options
    # Use object mode just on the readable state
    @_writable-state.object-mode = true

    @language = options.language
    if not @language?
      throw Error "Language must be specified"
    if typeof @language is 'string'
      lang-name = @language
      if not @language = languages[lang-name]
        throw Error "Built-in language not found: #lang-name"
    @_pages = @language.codepages
    @_page = @_pages.0

  _write_header: !->
    # Push WBXML header
    @push Buffer Array do
      3 # Version 1.3
      1 # Public ID: Unknown
      charsets.utf8
      0 # No string table

  _switch_page: !(namespace)->
    if @_page.Namespace != namespace
      cpid = @_pages[namespace]
      throw "Unknown namespace: #namespace" if not cpid?
      @_page = @_pages[cpid]
      @push Buffer [tokens.SWITCH_PAGE, cpid]

  _write_child: !(child)->
    if child instanceof WbxmlElement
      @_write_obj child
    else if child instanceof Buffer
      @push Buffer [tokens.OPAQUE]
      child.length |> to-mbuint32 |> @push
      @push child
    else
      @push Buffer [tokens.STR_I]
      @push Buffer child.to-string!
      @push Buffer [0]

  _write_obj: !(obj)->
    @_switch_page obj.namespace
    tag-code = @_page[obj.name]
    if not tag-code?
      throw "Unknown tag '#{obj.name}' in namespace '#{obj.namespace}'"
    if obj.children.length == 0
      @push Buffer [ tag-code ]
    else
      # Has children
      @push Buffer [ tag-code .|. 0x040 ]
      for child in obj.children
        @_write_child child
      @push Buffer [ tokens.END ]

  _transform: !(obj, encoding, done)->
    @_write_header!
    @_write_obj obj

    done!

module.exports = Encoder