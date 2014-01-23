require! _: lodash

_.extend exports, do
  Decoder: require \./decoder
  Encoder: require \./encoder
  Language: require \./language
  languages: require \./builtin-languages

_.extend exports, do
  decode: exports.Decoder.decode
  encode: exports.Encoder.encode
  decode-sync: exports.Decoder.decode-sync
  encode-sync: exports.Encoder.encode-sync

require! \./tree
for k, v of tree
  k -= /^Wbxml/
  exports[k] = v
