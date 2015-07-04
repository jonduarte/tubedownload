require 'net/http'
require 'cgi'
require 'open-uri'
require 'progressbar'

STREAM = 'url_encoded_fmt_stream_map'
URL    = 'url'
BASE   = 'https://www.youtube.com/get_video_info?video_id=%s'

def url_for(video_id)
  BASE % [video_id]
end

def get_stream(parsed)
  CGI.parse(parsed[STREAM][0])[URL][0].split(',').first
end

def extract(parsed)
  title = parsed['title'][0]
  dest  = "%s.mp4" % [title.gsub(/\s/, '-')]
  {
    title: title,
    dest: dest,
    download: get_stream(parsed)
  }
end

def download(data)
  dest = data[:dest]
  url  = data[:download]
  video = data[:title]

  pbar = nil

  content_length_proc = lambda { |t|
    if t && 0 < t
      pbar = ProgressBar.new("Downloading", t)
      pbar.file_transfer_mode
    end
  }

  progress_proc = lambda { |size|
    pbar.set size if size
  }

  File.open(dest, "wb") do |saved|
    open(url, "rb", content_length_proc: content_length_proc, progress_proc: progress_proc) { |stream| saved.write(stream.read) }
  end

  pbar.finish if pbar
end

if ARGV.count != 1
  puts "You must provide <video_id> as argument"
  exit(1)
end

uri       = URI(url_for(ARGV[0]))
response  = Net::HTTP.get(uri)
parsed    = CGI.parse(response)
data      = extract(parsed)

puts data[:title]
download(data)
