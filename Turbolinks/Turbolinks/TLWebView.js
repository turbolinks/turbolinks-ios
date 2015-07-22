window.TLWebView = {
    messageHandler: webkit.messageHandlers.turbolinks,

    postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data })
    },

    pushLocation: function(location) {
        Turbolinks.controller.history.push(location)
    },

    loadResponse: function(response) {
        Turbolinks.controller.loadResponse(response)
        requestAnimationFrame(function() {
            this.postMessage("responseLoaded")
        }.bind(this))
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
    }
}

Turbolinks.controller.adapter = new Turbolinks.NativeAdapter(Turbolinks.controller)

document.documentElement.setAttribute("data-bridge-configuration", "ios")
