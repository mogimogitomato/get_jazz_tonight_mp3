require 'open-uri'
require 'json'

NHK_FM_JAZZ_TONIGHT_JSON_URL = 'https://www.nhk.or.jp/radioondemand/json/0449/bangumi_0449_01.json'.freeze

def fetch_file_list
  begin
    res = URI.parse(NHK_FM_JAZZ_TONIGHT_JSON_URL).read
    json = JSON.parse(res.force_encoding('UTF-8'), { symbolize_names: true })
  rescue
    raise '番組情報取得に失敗しました'
  end
  json[:main][:detail_list][0][:file_list][0]
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
  add_comment_command = %(eyeD3 --comment "#{comment}" #{file_name}.mp3)
  `#{add_comment_command}`
end

file_list = fetch_file_list
url = file_list[:file_name]
date = file_list[:aa_vinfo3].slice(0, 8).gsub(/(\d{4})(\d{2})(\d{2})/, '\1-\2-\3')
title = file_list[:file_title]
subscription = file_list[:file_title_sub]
comment = "#{title}: #{subscription}"
exec_command(url, date, title, comment)
