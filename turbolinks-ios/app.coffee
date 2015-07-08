class Turbolinks.NativeAdapter
  constructor: (@delegate) ->
    @messageHandler = webkit.messageHandlers.turbolinks

  visitLocation: (url) ->
    @postMessage("visit", url)

  locationChanged: (url) ->
    @postMessage("locationChanged", url)

  # Private

  postMessage: (name, data) ->
    @messageHandler.postMessage({name, data})


Turbolinks.controller.adapter = new Turbolinks.NativeAdapter Turbolinks.controller
