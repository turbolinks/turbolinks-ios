function TLWebView(controller, messageHandler) {
    this.controller = controller
    this.messageHandler = messageHandler
    controller.adapter = this
}

TLWebView.prototype = {
    pushLocation: function(location) {
        this.controller.pushHistory(location)
    },

    hasSnapshotForLocation: function(location) {
        return this.controller.hasSnapshotForLocation(location)
    },

    restoreSnapshotByScrollingToSavedPosition: function(scrollToSavedPosition) {
        if (this.controller.restoreSnapshotByScrollingToSavedPosition(scrollToSavedPosition)) {
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

    locationChangedByActor: function(location, actor) {
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

window.webView = new TLWebView(Turbolinks.controller, webkit.messageHandlers.turbolinks)
document.documentElement.setAttribute("data-bridge-configuration", "ios")
