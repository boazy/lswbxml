{Obj} = require \prelude-ls
{bidi-map, bidi-map-with} = require \./utils

class Language
  (lang-name, lang-data)->
    @name = lang-name
    @codepages = prepare-cps lang-data

function bidi-map-cps(cps)
  for cpid, cp of cps
    # Make a bidi mapping only of the numbers inside the code-page
    for k, v of cp
      if typeof k == 'number'
        cp[v] = k
    cp.CodepageID = parseInt(cpid)
  cps |> Obj.map bidi-map

function dict-len(dict)
  (dict |> Object.keys) .length

# Convert sparse dictionary (with only integer keys) to array
function spread-to-array(dict)
  arr = new Array(dict |> dict-len)
  for k of dict
    v = dict[k]
    arr[k] = v
  arr

function prepare-cps(cps_with_ns)
  cps_with_ns |> bidi-map-cps |> bidi-map-with (.Namespace), (x)-> parseInt x

module.exports = Language
