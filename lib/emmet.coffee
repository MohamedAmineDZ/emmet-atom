CSON = require 'season'
path = require 'path'

emmet = require 'emmet'
abbreviationParser = require 'emmet/lib/parser/abbreviation'
editorProxy = require './editor-proxy'
LiveUpdatePanelView = require './live-update-panel'

module.exports =
  editorSubscription: null

  activate: (@state) ->
    unless @actionTranslation
      @actionTranslation = {}
      for selector, bindings of CSON.readFileSync(path.join(__dirname, "../keymaps/emmet.cson"))
        for key, action of bindings
          # Atom likes -, but Emmet expects _
          emmet_action = action.split(":")[1].replace(/\-/g, "_")
          @actionTranslation[action] = emmet_action

    @editorViewSubscription = atom.workspaceView.eachEditorView (editorView) =>
      if editorView.attached and not editorView.mini
        for action, emmetAction of @actionTranslation
          do (action) =>
              editorView.command action, (e) =>
                editorProxy.setupContext(editorView)
                syntax = editorProxy.getSyntax() or 'html'

                if emmetAction is 'show_panel'
                  @showPanel(editorView)
                  return

                # a better way to do this might be to manage the editorProxies
                # right now we are setting up the proxy each time
                if syntax
                  emmetAction = @actionTranslation[action]
                  if emmetAction == "expand_abbreviation_with_tab" && !editorView.getEditor().getSelection().isEmpty()
                    e.abortKeyBinding()
                    return
                  else
                    emmet.run(emmetAction, editorProxy)
                else
                  e.abortKeyBinding()
                  return
  deactivate: ->
    @editorViewSubscription?.off()
    @editorViewSubscription = null

  showPanel: (editorView) ->
    editor = editorView.getEditor()
    panel = new LiveUpdatePanelView editorView, 
      onupdate: (text) ->
        expanded = abbreviationParser.expand(text)
        console.log expanded
        sel = editorProxy.getSelectionRange()
        editorProxy.replaceContent(expanded, sel.start, sel.end)

