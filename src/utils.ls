try
  require! prettyjson

export print = (!(x) -> console.log x)
pj = (!(x)-> print prettyjson.render x) if prettyjson
export pj

export bidi-map = (obj)->
  {[[k, v], [v, k]] for k, v of obj}

export bidi-map-with = (fn-v, fn-k, obj)-->
  {[[k, (fn-v v)], [v, (fn-k k)]] for k, v of obj}
