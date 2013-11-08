#encoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup
require 'active_support/time'

class Reminder
  attr_accessor :input, :str, :time 
  def initialize(input)
    @input = input
    @now = Time.now
    @time = Time.now
    @str = input

  end

  def days_of_week
    %w{日 月 火 水 木 金 土}
  end

  def today
    ['今日']
  end

  def tomorrow
    ['明日', 'あした']
  end

  def dat
    ['明後日', 'あさって'] # day after tomorrow
  end
  alias :day_after_tomorrow :dat 

  def format(time)
    time.strftime '%Y/%m/%d %H:%M'
  end

  def match?(regex)
    if @input =~ regex
      yield $~.to_a
    else
      nil
    end
  end

  def _match?(regex)
    if @input =~ regex
      $~.to_a
    else
      nil
    end
  end

  def set_time_result(remove, hour, min)
    remove_time_word remove
    hour = hour.to_i
    if hour > 24
      @time += (hour.div(24)).day 
      hour = hour % 24
    end
    @time = @time.change(hour: hour, min: min)
  end

  def remove_time_word(key)
    @str.sub!(%r{#{key}[のにで]?}, '')
    @str.sub!(%r{^[ 　]|[ 　]$}, '')
  end

  def next_dow_days(str)
    now = @now.wday
    target = days_of_week.index(str).to_i
    target += 7 if target <= now
    (target - now)
  end

  def set_time
    num = '([0-9]{1,2})'
    space = '[ 　]?'
    match?(/#{num}([:：])#{num}/){|x| set_time_result x[0], x[1], x[2]; return}
    match?(/#{num+space}時半/){|x|    set_time_result x[0], x[1], 30;   return}
    match?(/#{num+space}時/){|x|      set_time_result x[0], x[1], 0}
    match?(/#{num+space}分/){|x|      set_time_result x[0], @time.hour, x[1]}
  end

  def add_unit_time(num, unit)
    num = num.to_i
    case unit
    when '分';         @time += num.minute
    when '時間';       @time += num.hour
    when '日';         @time += num.day
    when '週間', '週'; @time += num.week
    when 'ヶ月', '月'; @time += num.month 
    end
  end

  def set_day
    units = '(分|時間|日|週間?|ヶ?月)'

    [
      /([0-9]{1,2})#{units}後/,
      /あと([0-9]{1,2})#{units}/,
    ].each do |regex|
      match?(regex)do |x|
        str, num, unit = x
        add_unit_time num, unit
        remove_time_word str
        return 
      end
    end

    num2 = '([0-9]{1,2})'
    match?(%r{(([0-9]{2,4})[年/-])?#{num2}[月/-]#{num2}日?})do |x|
      all, y_with_suffix, y, m, d = x
      remove_time_word all
      y = @now.year unless y
      @time = @now.change(year: y.to_i, month: m.to_i, day: d.to_i)
      @time += 1.year if @time < @now
      return 
    end

    match?(%r{(次の)?(#{days_of_week.join("|")})曜}) do |r|
      remove, dummy, dow_str = r
      remove_time_word remove
      @time += next_dow_days(dow_str).day
      return 
    end 

    
    match?(/#{(today + tomorrow + dat).join('|')}/) do |r|
      case r.first
      when *today;    add = 0
      when *tomorrow; add = 1
      when *dat;      add = 2
      end
      remove_time_word r.first
      @time += add.day
      return 
    end
  end

  def parse
    set_day
    set_time
  end

  def publish
  end

  def dump
    puts "day:#{format @time} #{@str}"
  end
end
