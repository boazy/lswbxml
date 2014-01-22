Language = require \./language

builtin-lang = (lang-name)->
  lang-data = require "./lang/#{lang-name}"
  new Language lang-name, lang-data

module.exports = do
  ActiveSync: builtin-lang \ActiveSync
