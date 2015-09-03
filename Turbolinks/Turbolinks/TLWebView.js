function TLWebView(controller, messageHandler) {
    this.controller = controller
    this.messageHandler = messageHandler
    controller.adapter = this
}

TLWebView.prototype = {
    visitLocationWithAction: (location, action) {
        this.controller.startVisit(location, action, false)
    },

    startProposedVisit: function() {
        this.proposedVisit.start()
        this.proposedVisit = null
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
    }

    // Adapter interface
   
    visitProposed: function(visit) {
        this.proposedVisit = visit
        this.postMessage("visitProposed", { location: visit.location.absoluteURL })
    },

    visitStarted: function(visit) {
        this.currentVisit = visit
        var location = visit.location.absoluteURL
        var hasSnapshot = visit.hasSnapshot()
        this.postMessage("visitStarted", { location: location, hasSnapshot: hasSnapshot })
    },

    visitRequestStarted: function(visit) {
        this.postMessage("visitRequestStarted")
    },

    visitRequestCompleted: function(visit) {
        this.postMessage("visitRequestCompleted")
    },

    visitRequestFailedWithStatusCode: function(visit, statusCode) {
        this.postMessage("visitRequestFailed", { statusCode: statusCode })
    },

    visitRequestFinished: function(visit) {
        this.postMessage("visitRequestFinished")
    },

    visitSnapshotRestored: function(visit) {
        this.postMessageAfterNextRepaint("visitSnapshotRestored")
    },

    visitResponseLoaded: function(visit) {
        this.postMessageAfterNextRepaint("visitResponseLoaded")
    },

    pageInvalidated: function() {
        this.postMessage("pageInvalidated")
    },

    // Private

    postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data || {} })
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
    var message = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
    webView.postMessage("error", { message: message })
}, false)
