@AppBridge =
  messageHandler:
    window.webkit.messageHandlers.bridgeMessage

  log: (message) ->
    @postNativeMessage "log", message

  postNativeMessage: (name, data) ->
    @messageHandler.postMessage {name, data}


document.addEventListener 'DOMContentLoaded', ->
  for key, event of Turbolinks.EVENTS
    $(document).on event, (event) -> AppBridge.log(event.type)
