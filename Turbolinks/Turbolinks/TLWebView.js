window.TLWebView = {
    messageHandler: webkit.messageHandlers.turbolinks,

    postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data })
    },

    postMessageAfterNextRepaint: function(name, data) {
        requestAnimationFrame(function() {
            this.postMessage(name, data)
        }.bind(this))
    },

    pushLocation: function(location) {
        Turbolinks.controller.history.push(location)
    },

    loadResponse: function(response) {
        Turbolinks.controller.loadResponse(response)
        this.postMessageAfterNextRepaint("responseLoaded")
    }
}

Turbolinks.NativeAdapter = function(delegate) {
    this.delegate = delegate
}

Turbolinks.NativeAdapter.prototype = {
    visitLocation: function(url) {
        TLWebView.postMessage("visitRequested", url)
    },

    locationChanged: function(url) {
        TLWebView.postMessage("locationChanged", url)
    },

    snapshotRestored: function(url) {
        TLWebView.postMessageAfterNextRepaint("snapshotRestored")
    }
}

Turbolinks.controller.adapter = new Turbolinks.NativeAdapter(Turbolinks.controller)

document.documentElement.setAttribute("data-bridge-configuration", "ios")
