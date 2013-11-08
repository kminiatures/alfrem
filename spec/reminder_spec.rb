#encoding=utf-8
require './reminder.rb'

describe Reminder do
  def format_time(time)
    time.strftime '%Y/%m/%d %H:%M'
  end

  before do
    Time.stub(:now).and_return(Time.parse('2011/10/10 10:10:00')) # monday
    @now = Time.now
  end

  describe "日付を解析できる" do
    YAML.load_file('./spec/pattern.yml').each do|str,time|
      it "#{str}" do
        r = Reminder.new str.dup
        r.parse
        format_time(r.time).should eq(time)
        r.str.should eq('地下鉄にのる')
      end
    end
  end
end
