require 'puppeteer'

launch_options = {
  executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  args: ['--no-sandbox']
}

NHK_FM_JAZZ_TONIGHT_URL = 'https://www.nhk.or.jp/radio/ondemand/detail.html?p=0449_01'.freeze
NHK_FM_PLAYLIST_BASE_URL = 'https://www.nhk.or.jp/radio/player/ondemand.html'.freeze
NHK_FM_STREAMING_URL = 'https://vod-stream.nhk.jp/radioondemand'.freeze

def get_inner_html(page, url)
  page.goto(url, wait_until: 'domcontentloaded')
  page.Seval('html', 'html => html.innerHTML')
end

def get_title(page)
  title_item = page.query_selector('#ODcontents #bangumi #title')
  title_item.eval_on_selector('h3', 'h3 => h3.innerText')
end

def get_detail(page)
  detail_item = page.query_selector('#ODcontents #bangumi #detail .inner')
  detail_item.eval_on_selector('p', 'p => p.innerText')
end

def exec_command(url, date, title, comment)
  return if [url, date, title].any?(&:empty?)

  file_name = "jazz_tonight_#{date}"
  get_mp3_exec_command = %(ffmpeg -http_seekable 0 -i #{url} \
    -write_xing 0 -metadata title="#{file_name} #{title}" \
    -metadata artist="大友良英" -metadata album="ジャズ・トゥナイト" \
    #{file_name}.mp3)
  `#{get_mp3_exec_command}`
  return if comment.empty?

  # ffmpegのバグで,commentのメタデータは上手く編集できないらしいのでeyeD3で代替(https://stackoverflow.com/a/61991841)
  add_comment_command = %(eyeD3 --comment #{comment} #{file_name}.mp3)
  `#{add_comment_command}`
end

Puppeteer.launch(**launch_options) do |browser|
  page = browser.pages.first || browser.new_page
  await html = get_inner_html(page, NHK_FM_JAZZ_TONIGHT_URL)
  match = html.match(/\d{4}_\d{2}_\d{7}/)[0]

  await next_html = get_inner_html(page, "#{NHK_FM_PLAYLIST_BASE_URL}?p=#{match}")

  url = next_html.match(%r(#{NHK_FM_STREAMING_URL}[^"]*))[0]
  date = next_html.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)[0]

  title = get_title(page)
  detail = get_detail(page)
  comment = "#{title}: #{detail}"
  exec_command(url, date, title, comment)
end
