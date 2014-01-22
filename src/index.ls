exports = module.exports =
  Decoder: require \./decoder
  Encoder: require \./encoder
  Language: require \./language
  languages: require \./builtin-languages

exports.decode = exports.Decoder.decode
exports.encode = exports.Encoder.encode
exports.decode-sync = exports.Decoder.decode-sync
exports.encode-sync = exports.Encoder.encode-sync

require! \./tree
for k, v of tree
  k -= /^Wbxml/
  exports[k] = v
