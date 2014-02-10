fs = require 'fs'
async = require 'async'
jade = require 'jade'
url = require 'url'

module.exports = (env, callback) ->

  options = env.config.jade or {}
  options.pretty ?= true

  class JadePlugin extends env.plugins.Page

    constructor: (@filepath, @metadata, @tpl) ->

    getFilename: ->
      @filepath.relative.replace /jade$/, 'html'

    getLocation: (base) ->
      uri = @getUrl base
      return uri[0..uri.lastIndexOf('/')]

    resolveLink: (match, base=env.config.baseUrl) ->
        url.resolve @getLocation(base), match

    getHtml: ->
      ### render jade template using metadata as locals ###
      self = this
      html = @tpl(@metadata)
      html.replace /<img src="([^">]+)"/g, (match, src) ->
        "<img src=\"" + self.resolveLink(src) + "\""

    getView: -> 'template'

  JadePlugin.fromFile = (filepath, callback) ->
    async.waterfall [
      (callback) -> fs.readFile filepath.full, callback
      (buffer, callback) ->
        # extract metadata using wintersmiths markdown plugin's markdown parser
        env.plugins.MarkdownPage.extractMetadata buffer.toString(), callback
      (result, callback) ->
        try
          opts = {filename: filepath.full}
          env.utils.extend opts, options
          tpl = jade.compile result.markdown, opts
        catch error
          callback error
          return
        callback null, new JadePlugin(filepath, result.metadata, tpl)
    ], callback

  env.registerContentPlugin 'pages', '**/*.jade', JadePlugin
  callback() # tell the plugin manager we are done
