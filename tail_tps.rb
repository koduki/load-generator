#! ruby

require 'json'

interval = 5
path = ARGV[0]

def parse(logs)
  logs.map{|x| [x["test_id"], x["end_time"], x["response"]/1000, x["http_status"]] }.
      map{|x|x[1] = x[1].sub(/\..*/,""); x }.
      group_by{|x| x[1] }.
      map{|k, v| 
        ok = v.find_all{|xs| xs[3] == "http_ok"}
        error = v.find_all{|xs| xs[3] != "http_ok"}

        [k, ok.size, (ok.map{|xs|xs[2]}.inject(:+) / ok.length), error.size] 
      }.map{|xs| {"time": xs[0], "tps": xs[1], "response_avg(ms)": xs[2], "error": xs[3]} }
end

def read(interval, path)
  f = open(path)
  begin
    f.sysseek(-32, IO::SEEK_END)
  rescue
    f.sysseek(0, IO::SEEK_SET)
  end

  logs = []
  text = ""
  is_head = true
  s = Time.now.to_i 
  while true
    str = f.sysread(10) rescue ""
    text += str

    xs = text.split(/\n/)
    if xs.size >= 2 then
      line = xs[0]
      text = xs[1]

      if is_head then
        is_head = false
        next
      end
      
      begin
        log = JSON.parse(line.sub(/.*{/,"{"))
      rescue
        STDERR.puts "Parse Error: #{line}"
        next
      end
      
      if log["type"] == "request" then
          logs << log
          e = Time.now.to_i 
          if (e - s) > interval then
            parse(logs).
              map{|xs| xs.map{|k,v|"#{k}:#{v}"}.join("\t") }.
              each{|l| puts l}

            logs = []
            s = Time.now.to_i 
          end
      end
    end
  end
end

read(interval, path)