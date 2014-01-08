require 'sinatra'
# std
require 'fileutils'
require 'open3'


# config
CMD='./run' # what to run
TIME=true # show start, end and elapsed time
DELAY_BETWEEN_UPDATES=5*60 # 5 minutes
OUTPUT='tmp/output.txt'
OUTPUT_TMP=OUTPUT+$$.to_s
# config


DAYS_PER_YEAR = 365.242199
DAYS_PER_MONTH = DAYS_PER_YEAR / 12
SECONDS_PER_DAY = 86400.0

def seconds_to_english(sec, sep=' ')
  def plural(x, word)
    "#{x} #{(x >= 1.0 && x < 2.0) ? word : word+'s'}"
  end
  ({
    'year'   => DAYS_PER_YEAR*SECONDS_PER_DAY,
    'month'  => DAYS_PER_MONTH*SECONDS_PER_DAY,
    'week'   => 7*SECONDS_PER_DAY,
    'day'    => SECONDS_PER_DAY,
    'hour'   => 3600.0,
    'minute' => 60.0 }.map { |unit, unit_divisor|
      if (x = (sec / unit_divisor).floor) >= 1.0
        sec -= x * unit_divisor
        plural(x, unit)
      end
  }.compact << plural(sec, 'second')).join(sep)
end

def run(f) 
  if TIME
    start_date = Time.now
    f << "# started: #{start_date}\n"
  end

  exit_status = -1
  Open3.popen2e(CMD) { |stdin, stdout_and_stderr, wait_thr| 
    stdout_and_stderr.each {|line|
      f << line
      $stderr.puts("read line: #{line}")
    }
    exit_status = wait_thr.value.to_i
  }
  last = "exit code: #{exit_status}"
  if TIME
    end_date = Time.now
    elapsed_seconds = end_date - start_date
    last = "finished: #{end_date}   elapsed: #{seconds_to_english(elapsed_seconds)}  " + last
  end
  f << "# #{last}\n"
end

Thread.new do
  loop do 
    sleep(DELAY_BETWEEN_UPDATES)
    File.open(OUTPUT_TMP, 'w') {|f| run(f) }
    FileUtils.mv OUTPUT_TMP, OUTPUT, :force => true
  end
end

before do
  content_type 'text/plain'
end

get '/live' do
  stream do |f|
    run(f)
  end
end 

get '/' do
  result = ''
  File.open(OUTPUT, 'r') { |f|
    while line = f.gets
      result += (line =~ /\n$/) ? (line.chop + "\r\n") : line
    end
  } if File.exist? OUTPUT
  result
end
