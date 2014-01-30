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
      for v in obj
        child = make-tree name, v, parent
        parent.add-child child
    else
      name-parts = name.split ':'
      namespace = name-parts[til -1].join ':'
      name = name-parts[*-1]
      me = new WbxmlElement(name, parent)
      if namespace
        me.namespace = namespace
      else
        me.namespace = parent?.namespace

      obj = obj.to-string! if typeof obj is \number
      if typeof obj is 'string' or obj instanceof Buffer
        me.add-content obj
      else
        for k, v of obj
          child = make-tree k, v, me
          me.add-child child
      me

  for k, v of obj
    # Use just the first property of obj as the root node
    return make-tree k, v, null
  else
    throw Error "Empty object"

export function create-treex(obj)
  make-tree = (name, obj, parent)->
    if Array.is-array obj
      for v in obj
        child = make-tree name, v, parent
        parent.add-child child
    else
      name-parts = name.split ':'
      namespace = name-parts[til -1].join ':'
      name = name-parts[*-1]
      me = new WbxmlElement(name, parent)
      if namespace
        me.namespace = namespace
      else
        me.namespace = parent?.namespace

      obj = obj.to-string! if typeof obj is \number
      if typeof obj is 'string' or obj instanceof Buffer
        me.add-content obj
      else
        for k, v of obj
          child = make-tree k, v, me
          me.add-child child
      me

  for k, v of obj
    # Use just the first property of obj as the root node
    return make-tree k, v, null
  else
    throw Error "Empty object"
