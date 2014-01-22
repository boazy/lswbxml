module.exports =
  Decoder: require \./decoder
  Encoder: require \./encoder
  Language: require \./language
  languages: require \./builtin-languages

require! \./tree
for k, v of tree
  k -= /^Wbxml/
  module.exports[k] = v
