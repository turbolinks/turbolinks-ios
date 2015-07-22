function TLWebViewAdapter(controller, messageHandler) {
    this.controller = controller
    this.messageHandler = messageHandler
    controller.adapter = this
}

TLWebViewAdapter.prototype = {
    pushLocation: function(location) {
        this.controller.pushHistory(location)
    },

    restoreSnapshot: function() {
        if (this.controller.restoreSnapshot()) {
            this.postMessageAfterNextRepaint("snapshotRestored")
        }
    },

    loadResponse: function(response) {
        this.controller.loadResponse(response)
        this.postMessageAfterNextRepaint("responseLoaded")
    },

    // Adapter interface
   
    visitLocation: function(location) {
        this.postMessage("visitRequested", location)
    },

    locationChanged: function(location) {
        this.postMessage("locationChanged", location)
    },

    // Private

    postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data })
    },

    postMessageAfterNextRepaint: function(name, data) {
        requestAnimationFrame(function() {
            this.postMessage(name, data)
        }.bind(this))
    }
}

window.TLWebView = new TLWebViewAdapter(Turbolinks.controller, webkit.messageHandlers.turbolinks)
document.documentElement.setAttribute("data-bridge-configuration", "ios")
