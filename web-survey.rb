#!/usr/bin/ruby
require 'webrick'

class Servlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    response.status = 200
    response['Content-Type'] = 'text/html'
    response.body = File.read(SURVEY_PATH)
  end
  def do_POST(request, response)
    path = File.expand_path('../web-survey.log', __FILE__)
    date = Time.now.strftime('%Y-%m-%d')
    File.open(path, 'a') { |file|
      request.query.each { |field, value|
        file.write "#{date},#{field},#{value}\n"
      }
    }

    response.status = 200
    response['Content-Type'] = 'text/html'
    response.body = "<html><body>
      Responses received; closing window...
      <script>
        setTimeout(function() {
          window.open('', '_self', ''); 
          window.close();
        }, 1000);
      </script>
    </body></html>"

    sleep 1
    `kill #{Process.pid}`
  end
end

SURVEY_PATH = ARGV[0] or raise "First arg: path to html to show"
PORT = ARGV[1] or raise "Second arg: port (example: 2998)"
server = WEBrick::HTTPServer.new :Port => PORT.to_i
server.mount "/", Servlet, './'
trap('INT') { server.stop }
trap('TERM') { server.stop }
if fork
  server.start
else
  `open http://localhost:#{PORT}/`
end
