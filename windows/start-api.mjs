// Keep the unmodified upstream API reachable only through the local HTTPS proxy.
import http from 'node:http'

const originalListen = http.Server.prototype.listen
http.Server.prototype.listen = function (port, callback) {
  if (arguments.length !== 2 || typeof port !== 'number' || typeof callback !== 'function') {
    throw new Error('Unexpected API listener signature; refusing to expose a network listener.')
  }
  return originalListen.call(this, port, '127.0.0.1', callback)
}

await import('../api/server.js')
