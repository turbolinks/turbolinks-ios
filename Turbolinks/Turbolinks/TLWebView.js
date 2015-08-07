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
            this.postMessageAfterNextRepaint("snapshotRestored", this.controller.location.absoluteURL)
        }
    },

    issueRequestForLocation: function(location) {
        this.controller.issueRequestForLocation(location)
    },

    abortCurrentRequest: function() {
        this.controller.abortCurrentRequest()
    },

    loadResponse: function(response) {
        this.controller.loadResponse(response)
        this.postMessageAfterNextRepaint("responseLoaded", this.controller.location.absoluteURL)
    },

    // Adapter interface
   
    visitLocation: function(location) {
        this.postMessage("visitRequested", location.absoluteURL)
    },

    locationChangedByActor: function(location, actor) {
        this.postMessage("locationChanged", location.absoluteURL)
    },

    requestCompletedWithResponse: function(response) {
        this.postMessage("requestCompleted", response)
    },

    requestFailedWithStatusCode: function(statusCode, response) {
        this.postMessage("requestFailed", statusCode)
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
