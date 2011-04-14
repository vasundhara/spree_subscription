class AddOptionTypesAndValues < ActiveRecord::Migration
  def self.up
    duration = OptionType.create(:name => 'subscription-duration', :presentation => 'Duration')
    interval = OptionType.create(:name => 'subscription-interval', :presentation => 'Interval')
    
    OptionValue.create(:name => '1', :presentation => '1', :position => 1, :option_type => duration)
    OptionValue.create(:name => '2', :presentation => '2', :position => 2, :option_type => duration)
    OptionValue.create(:name => '3', :presentation => '3', :position => 3, :option_type => duration)
    OptionValue.create(:name => '4', :presentation => '4', :position => 4, :option_type => duration)
    
    OptionValue.create(:name => 'month', :presentation => 'Month', :position => 1, :option_type => interval)
    OptionValue.create(:name => 'year',  :presentation => 'Year',  :position => 2, :option_type => interval)
    OptionValue.create(:name => 'week',  :presentation => 'Week',  :position => 3, :option_type => interval)
  end

  def self.down
  end
end
