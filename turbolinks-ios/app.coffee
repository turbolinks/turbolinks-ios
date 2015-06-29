@AppBridge =
  messageHandler:
    window.webkit.messageHandlers.bridgeMessage

  log: (message) ->
    @postNativeMessage "log", message

  postNativeMessage: (name, data) ->
    @messageHandler.postMessage {name, data}


document.addEventListener "page:before-change", (event) ->
  AppBridge.postNativeMessage "page:before-change", event.data.url
  event.preventDefault()
