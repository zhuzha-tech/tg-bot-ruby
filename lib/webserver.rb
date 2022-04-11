require 'webrick'

Thread.report_on_exception = true

server = WEBrick::HTTPServer.new :Port => 8080
# Logger: WEBrick::Log.new(log_path.to_s, WEBrick::Log::INFO),
#   AccessLog: [
#     [log_path.open('w'), WEBrick::AccessLog::COMBINED_LOG_FORMAT],
#   ]
server.mount_proc '/' do |req, res|
  res.body = 'Hello, world!'
end
trap('INT') { server.shutdown }  
Thread.new { server.start }
