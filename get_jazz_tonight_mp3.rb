require 'puppeteer'

launch_options = {
  executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  args: ['--no-sandbox']
}

def get_inner_html(page, url)
  page.goto(url)
  page.Seval('html', 'html => html.innerHTML')
end

Puppeteer.launch(**launch_options) do |browser|
  page = browser.pages.first || browser.new_page
  await html = get_inner_html(page, 'https://www.nhk.or.jp/radio/ondemand/detail.html?p=0449_01')
  match = html&.match(/\d{4}_\d{2}_\d{7}/)[0]

  await next_html = get_inner_html(page, "https://www.nhk.or.jp/radio/player/ondemand.html?p=#{match}")

  url = next_html.match(%r{https://vod-stream.nhk.jp/radioondemand[^"]*})[0]
  date = next_html.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)[0]

  exec_command = "ffmpeg -http_seekable 0 -i #{url} -write_xing 0 -metadata title=\"jazz_tonight_#{date}\" -metadata artist=\"大友良英\" -metadata album=\"ジャズ・トゥナイト\" jazz_tonight_#{date}.mp3"
  `#{exec_command}`
end
