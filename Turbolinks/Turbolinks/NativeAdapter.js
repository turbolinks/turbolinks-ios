Turbolinks.NativeAdapter = function(delegate) {
    this.delegate = delegate
    this.messageHandler = webkit.messageHandlers.turbolinks
}

Turbolinks.NativeAdapter.prototype = {
    visitLocation: function(url) {
        this.postMessage("visit", url)
    },

    locationChanged: function(url) {
        this.postMessage("locationChanged", url)
    },

    notifyOfNextRender: function() {
        var _this = this
        requestAnimationFrame(function() {
            _this.postMessage("webViewRendered")
        })
    },

    // Private

    postMessage: function(name, data) {
        this.messageHandler.postMessage({ name: name, data: data })
    }
}

Turbolinks.controller.adapter = new Turbolinks.NativeAdapter(Turbolinks.controller)

document.documentElement.setAttribute("data-bridge-configuration", "ios")
