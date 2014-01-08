require 'sinatra'
# std
require 'fileutils'
require 'open3'

def var(env_name, default=nil)
  ENV.include?(env_name) ? ENV[env_name] : default
end

def str_to_bool(str)
  str == true || str =~ /^(true|1|yes|y|on|si|aye)$/i
end

# config (ugly, cleanup todo)
SHELL2WEB_CMD=var('SHELL2WEB_CMD', './run') # what to run
SHELL2WEB_CONTENT_TYPE=var('SHELL2WEB_CONTENT_TYPE', 'text/html')
SHELL2WEB_LIVE=str_to_bool(var('SHELL2WEB_LIVE', 'true')) # allow /live
SHELL2WEB_TIME=str_to_bool(var('SHELL2WEB_TIME', 'true')) # show start, end and elapsed time
SHELL2WEB_DELAY=Integer(var('SHELL2WEB_DELAY', 5*60))  # 5 minutes
SHELL2WEB_AVG_RUN_TIME=Integer(var('SHELL2WEB_AVG_RUN_TIME', 4*60))
# config

OUTPUT='tmp/output.txt'
OUTPUT_TMP=$$.to_s+OUTPUT

DAYS_PER_YEAR = 365.2425
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

def run(f, args, format) 
  # header
  if SHELL2WEB_TIME && format == 'txt'
    start_date = Time.now
    f << "# started: #{start_date}\n"
  end

  # body
  exit_status = -1
  Open3.popen2e(SHELL2WEB_CMD, *args) { |stdin, stdout_and_stderr, wait_thr|
    stdout_and_stderr.each {|line| f << line }
    exit_status = wait_thr.value.to_i
  }

  # footer
  if format == 'txt'
    last = "exit code: #{exit_status}" 
    if SHELL2WEB_TIME
      end_date = Time.now
      elapsed_seconds = end_date - start_date
      last = "finished: #{end_date}   elapsed: #{seconds_to_english(elapsed_seconds)}  " + last
    end
    f << "# #{last}\n"
  end
end

# background worker to update cached copy for /
Thread.new do
  loop do 
    FileUtils.mkdir_p('tmp')
    FORMATS.zip(FORMAT_ARGS).each { |format, args|
      tmp_filename = OUTPUT_TMP+'.'+format
      File.open(tmp_filename, 'w') {|f| run(f, args, format) }
      filename = OUTPUT+'.'+format
      FileUtils.mv tmp_filename, filename, :force => true
    }
    sleep(SHELL2WEB_DELAY)
  end
end

before do
  content_type SHELL2WEB_CONTENT_TYPE
end

get %r{^/live(/(|txt|text|html|yaml|xml|toml|json))?$} do |_, format|
  format ||= 'html'
  format = 'txt' if format == 'text'
  which = FORMATS.index(format)
  content_type FORMAT_CONTENT_TYPES[which]
  stream do |f|
    run(f, FORMAT_ARGS[which], format)
  end
end if SHELL2WEB_LIVE

FORMATS=%w[html json toml txt xml yaml]
FORMAT_ARGS=[['-H'], ['-j'], ['-t'], [], ['-x'], ['-y']]
FORMAT_CONTENT_TYPES=%w[text/html application/json text/x-toml text/plain application/xml text/x-yaml]

get %r{^/(|txt|text|html|yaml|xml|toml|json)$} do |format|
  format ||= 'html'
  format = 'txt' if format == 'text'

  file="#{OUTPUT}.#{format}"

  if ! File.exist?(file)
    up_to_estimate = SHELL2WEB_AVG_RUN_TIME + SHELL2WEB_DELAY
    return [404, {}, "No output right now.   Takes up to #{seconds_to_english(up_to_estimate)} have results."]
  end

  content_type FORMAT_CONTENT_TYPES[FORMATS.index(format)]

  result = ''
  File.open(file, 'r') { |f|
    while line = f.gets
      result += (line =~ /\n$/) ? (line.chop + "\r\n") : line
    end
  }
  result
end
