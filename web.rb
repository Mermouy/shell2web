require 'sinatra'
# std
require 'fileutils'
require 'open3'


# config
CMD='./run' # what to run
CONTENT_TYPE='text/plain'
LIVE=true # allow /live
TIME=true # show start, end and elapsed time
DELAY_BETWEEN_UPDATES=5*60  # 5 minutes
AVERAGE_RUN_TIME=4*60
# config

OUTPUT='tmp/output.txt'
OUTPUT_TMP=OUTPUT+$$.to_s

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
  # header
  if TIME
    start_date = Time.now
    f << "# started: #{start_date}\n"
  end

  # body
  exit_status = -1
  Open3.popen2e(CMD) { |stdin, stdout_and_stderr, wait_thr| 
    stdout_and_stderr.each {|line| f << line }
    exit_status = wait_thr.value.to_i
  }

  # footer
  last = "exit code: #{exit_status}"
  if TIME
    end_date = Time.now
    elapsed_seconds = end_date - start_date
    last = "finished: #{end_date}   elapsed: #{seconds_to_english(elapsed_seconds)}  " + last
  end
  f << "# #{last}\n"
end

# background worker to update cached copy for /
Thread.new do
  loop do 
    FileUtils.mkdir_p('tmp')
    File.open(OUTPUT_TMP, 'w') {|f| run(f) }
    FileUtils.mv OUTPUT_TMP, OUTPUT, :force => true
    sleep(DELAY_BETWEEN_UPDATES)
  end
end

before do
  content_type CONTENT_TYPE
end

get '/live' do
  stream do |f|
    run(f)
  end
end if LIVE

get '/' do
  result = ''
  if File.exist? OUTPUT
    result = "No output right now.   Takes up to #{seconds_to_english(DELAY_BETWEEN_UPDATES+AVERAGE_RUN_TIME)} have results."
  else
    File.open(OUTPUT, 'r') { |f|
      while line = f.gets
        result += (line =~ /\n$/) ? (line.chop + "\r\n") : line
      end
    }
  end
  result
end
