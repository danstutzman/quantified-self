import BaseHTTPServer
import os
import datetime

class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
  def do_GET(self):
    self.send_response(200)
    self.end_headers()
    self.wfile.write("<script>window.close();</script>")
    self.wfile.close()
    now = datetime.datetime.now()
    num_seconds = (5 - now.hour) * 3600 + (59 - now.minute) * 60
    if num_seconds < 0:
      num_seconds += 24 * 60 * 60
    num_seconds = 3
    os.system('sleep 1 && xset dpms force off && sleep %d && xset dpms force on' % num_seconds)


try:
  server = BaseHTTPServer.HTTPServer(('localhost', 8000), MyHandler)
  server.serve_forever()
except KeyboardInterrupt:
  server.socket.close()

