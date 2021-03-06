export class WbxmlNode

safe-add-child = !(obj, name, child)->
  # If multiple children with the same name exist, make an array of them
  if obj[name]?
    cur-child = obj[name]
    if Array.is-array cur-child
      cur-child.push child
    else
      obj[name] = [cur-child, child]
  else
    obj[name] = child

export class WbxmlElement extends WbxmlNode
  (@name, @parent)->
    @children = []
    @$$ = @children

  full-name:~ ->
    if @namespace?
      @namespace + ':' + @name
    else
      @name

  # Ensure child is return as multiple array items, 
  # even if there are zero one children with this name
  # Usage: arr = node.multi (.child)
  multi: (accessor)->
    child = accessor @
    if child?
      if Array.is-array child
        child
      else
        [child]
    else
      return []

  # Returns content as integer, NaN if content not exists or not an integer
  int:~ ->
    parse-int @content

  maybe-int:~ ->
    i = parse-int @content
    if Number.is-NaN i then @content else i

  add-child: !(child)->
    # Add new child to ordered list of children
    @children.push child
    safe-add-child @, child.name, child

  add-content: !(new-content)->
    @children.push new-content
    if @content?
      if @content instanceof Buffer and new-content instanceof Buffer
        @content = Buffer.concat [@content, new-content]
      else
        @content += new-content
    else
      @content = new-content

  to-xml: ->
    if @children.length == 0
      "<#{@name} />"
    else
      result = "<#{@name}>"
      for child in @children
        if child instanceof WbxmlNode
          result += child.to-xml!
        else
          result += child # as string
      result += "</#{@name}>"

  to-json-bare: ({namespaces=true}={})->
    if @children.length == 0
      null
    else if @content?
      if @content instanceof Buffer
        return @content.to-string!
      else
        return @content
    else
      result = {}
      for child in @children
        if child instanceof WbxmlElement
          if (namespaces and @namespace != child.namespace) or (namespaces == 'always')
            name = @full-name
          else
            name = child.name

          safe-add-child result, name, child.to-json-bare!
      result

  to-json: (options={namespaces=true}={})->
    if namespaces
      name = @full-name
    else
      name = @name

    { "#name": @to-json-bare options }

export function create-tree(obj)
  make-tree = (name, obj, parent)->
    if Array.is-array obj
      [make-tree(name, v, parent) for v in obj]
    else if typeof obj is \undefined
      []
    else
      name-parts = name.split ':'
      namespace = name-parts[til -1].join ':'
      name = name-parts[*-1]
      me = new WbxmlElement(name, parent)
      if namespace
        me.namespace = namespace
      else
        me.namespace = parent?.namespace

      switch typeof obj
      | \number  => obj = obj.to-string!
      | \boolean => obj = if obj then \1 else \0

      if typeof obj is \string or obj instanceof Buffer
        me.add-content obj
      else
        for k, v of obj
          children = make-tree k, v, me
          if Array.is-array children
            children.for-each -> me.add-child it
          else
            me.add-child children
      me

  for k, v of obj
    # Use just the first property of obj as the root node
    return make-tree k, v, null
  else
    throw Error "Empty object"
