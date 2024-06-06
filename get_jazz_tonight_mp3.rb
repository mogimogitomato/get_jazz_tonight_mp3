require 'puppeteer'
require 'date'

launch_options = {
  executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  args: ['--no-sandbox']
}

NHK_FM_JAZZ_TONIGHT_URL = 'https://www.nhk.or.jp/radio/ondemand/detail.html?p=0449_01'.freeze

def convert_date_string(date_str)
  # 正規表現を使って月と日を抽出
  match_data = /(\d+)月(\d+)日/.match(date_str)
  return nil unless match_data

  month = match_data[1].to_i
  day = match_data[2].to_i

  # 現在年を取得して、Date.newで日付を作成(放送年がページから取れない為暫定対処. 年跨ぎ時は手で補正要)
  current_year = Date.today.year
  date = Date.new(current_year, month, day)

  # yyyymmdd形式に変換して返す
  date.strftime('%Y-%m-%d')
end

def get_inner_html(page, url)
  page.goto(url, wait_until: 'domcontentloaded')
  page.Seval('html', 'html => html.innerHTML')
end

def get_url(page)
  url_item = page.query_selector('div[data-hlsurl]')
  url_item.evaluate('node => node.dataset.hlsurl')
end

def get_title(page)
  title_item = page.query_selector('.program-archive-link')
  title_item.eval_on_selector('h2', 'h2 => h2.innerText')
end

def get_summary(page)
  summary_item = page.query_selector('.program-archive-link')
  summary_item.eval_on_selector_all('p', 'nodes => nodes[1]?.innerText')
end

def get_date(page)
  summary_item = page.query_selector('.program-archive-link')
  summar_raw_text = summary_item.eval_on_selector_all('p', 'nodes => nodes[0]?.innerText')
  convert_date_string(summar_raw_text)
end

def exec_command(url, date, title, comment)
  return if [url, date, title].any?(&:empty?)

  file_name = "jazz_tonight_#{date}_#{title}"
  get_mp3_exec_command = %(ffmpeg -http_seekable 0 -i #{url} \
    -write_xing 0 -metadata title="#{date} #{title}" \
    -metadata artist="大友良英" -metadata album="ジャズ・トゥナイト" \
    #{file_name}.mp3)
  `#{get_mp3_exec_command}`
  return if comment.empty?

  # ffmpegのバグで,commentのメタデータは上手く編集できないらしいのでeyeD3で代替(https://stackoverflow.com/a/61991841)
  add_comment_command = %(eyeD3 --comment "#{comment}" #{file_name}.mp3)
  `#{add_comment_command}`
end

Puppeteer.launch(**launch_options) do |browser|
  page = browser.pages.first || browser.new_page
  await html = get_inner_html(page, NHK_FM_JAZZ_TONIGHT_URL)
  url = get_url(page)
  title = get_title(page).gsub(/ジャズ・トゥナイト/, '')
                         .gsub(/[[:space:]]/, '')
                         .gsub(/[Ａ-Ｚａ-ｚ０-９]/) { |s| s.tr('Ａ-Ｚａ-ｚ０-９ ', 'A-Za-z0-9') }
                         .gsub(/\/|\\|\?|\*|<|>|\|/, '_')
  date = get_date(page)
  summary = get_summary(page)
  comment = "#{title}: #{summary}"
  exec_command(url, date, title, comment)
end
