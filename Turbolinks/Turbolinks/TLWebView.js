function TLWebView(controller, messageHandler) {
    this.controller = controller
    this.messageHandler = messageHandler
    controller.adapter = this
}

TLWebView.prototype = {
    visitLocationWithAction: function(location, action) {
        this.controller.startVisitToLocationWithAction(location, action)
    },

    // Current visit

    issueRequest: function() {
        this.currentVisit.issueRequest()
    },

    changeHistory: function() {
        this.currentVisit.changeHistory()
    },

    restoreSnapshot: function() {
        this.currentVisit.restoreSnapshot()
    },

    loadResponse: function() {
        this.currentVisit.loadResponse()
    },

    cancelVisit: function() {
        this.currentVisit.cancel()
    },

    // Adapter interface
   
    visitProposedToLocationWithAction: function(location, action) {
        this.postMessage("visitProposed", { location: location.absoluteURL })
    },

    visitStarted: function(visit) {
        this.currentVisit = visit
        this.postMessage("visitStarted", { identifier: visit.identifier, hasSnapshot: visit.hasSnapshot() })
    },

    visitRequestStarted: function(visit) {
        this.postMessage("visitRequestStarted", { identifier: visit.identifier })
    },

    visitRequestCompleted: function(visit) {
        this.postMessage("visitRequestCompleted", { identifier: visit.identifier })
    },

    visitRequestFailedWithStatusCode: function(visit, statusCode) {
        this.postMessage("visitRequestFailed", { identifier: visit.identifier, statusCode: statusCode })
    },

    visitRequestFinished: function(visit) {
        this.postMessage("visitRequestFinished", { identifier: visit.identifier })
    },

    visitSnapshotRestored: function(visit) {
        this.postMessageAfterNextRepaint("visitSnapshotRestored", { identifier: visit.identifier })
    },

    visitResponseLoaded: function(visit) {
        this.postMessageAfterNextRepaint("visitResponseLoaded", { identifier: visit.identifier })
    },

    visitCompleted: function(visit) {
        this.postMessageAfterNextRepaint("visitCompleted", { identifier: visit.identifier })
    },

    pageInvalidated: function() {
        this.postMessage("pageInvalidated", { identifier: visit.identifier })
    },

    // Private

    postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data })
    },

    postMessageAfterNextRepaint: function(name, data) {
        var postMessage = this.postMessage.bind(this, name, data)
        requestAnimationFrame(function() {
            requestAnimationFrame(postMessage)
        })
    }
}

window.webView = new TLWebView(Turbolinks.controller, webkit.messageHandlers.turbolinks)

addEventListener("error", function(event) {
    var error = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
    webView.postMessage("error", { error: error })
}, false)
