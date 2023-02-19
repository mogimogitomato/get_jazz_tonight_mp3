require 'puppeteer'

launch_options = {
  executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  args: ['--no-sandbox']
}

def get_inner_html(page, url)
  page.goto(url, wait_until: 'domcontentloaded')
  page.Seval('html', 'html => html.innerHTML')
end

Puppeteer.launch(**launch_options) do |browser|
  page = browser.pages.first || browser.new_page
  await html = get_inner_html(page, 'https://www.nhk.or.jp/radio/ondemand/detail.html?p=0449_01')
  match = html&.match(/\d{4}_\d{2}_\d{7}/)[0]

  await next_html = get_inner_html(page, "https://www.nhk.or.jp/radio/player/ondemand.html?p=#{match}")

  url = next_html.match(%r{https://vod-stream.nhk.jp/radioondemand[^"]*})[0]
  date = next_html.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)[0]

  title_item = page.query_selector('#ODcontents #bangumi #title')
  title = title_item.eval_on_selector('h3', 'h3 => h3.innerText')
  detail_item = page.query_selector('#ODcontents #bangumi #detail .inner')
  detail = detail_item.eval_on_selector('p', 'p => p.innerText')
  comment = "#{title}: #{detail}"

  get_mp3_exec_command = "ffmpeg -http_seekable 0 -i #{url} -write_xing 0 -metadata title=\"jazz_tonight_#{date} #{title}\" -metadata artist=\"大友良英\" -metadata album=\"ジャズ・トゥナイト\" jazz_tonight_#{date}.mp3"
  `#{get_mp3_exec_command}`
  # ffmpegのバグで,commentのメタデータは上手く編集できないらしいのでeyeD3で代替(https://stackoverflow.com/a/61991841)
  add_comment_command = "eyeD3 --comment \"#{comment}\" jazz_tonight_#{date}.mp3"
  `#{add_comment_command}`
end
