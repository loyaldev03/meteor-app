=begin
Script to create new Decline Strategy, this script generate a file
that includes the sql to insert the decline_strategy into the database and 
another file with the yaml objects, to add to the /db/decline_strategies.yml file.

issues:
- https://www.pivotaltracker.com/s/projects/840771/stories/52309955
- http://www.pivotaltracker.com/story/show/54434484
- https://www.pivotaltracker.com/story/show/54679906
=end


@yaml_file = File.open("/tmp/yaml_file.yml", 'w+')
@sql_file = File.open("/tmp/sql_file.yml", 'w+')

def create_strategy(attributes)
  ds = DeclineStrategy.new(attributes)
  ds.save
  return ds.id
end

def strategy_to_yaml(dsid)
  data = DeclineStrategy.find(dsid).to_yaml.gsub("--- !ruby/ActiveRecord:DeclineStrategy", "- !ruby/object:DeclineStrategy")
  data += "\n\n"
  puts "\n"
  puts data

  @yaml_file << data
end

def strategy_to_sql(dsid)
  ds = DeclineStrategy.find(dsid)
  data = "insert into decline_strategies set\n"
  data += "`gateway` = '#{ds.gateway}',\n"
  data += "`installment_type` = '#{ds.installment_type}',\n"
  data += "`credit_card_type` = '#{ds.credit_card_type}',\n"
  data += "`response_code` = '#{ds.response_code}',\n"
  data += "`max_retries` = #{ds.max_retries},\n"
  data += "`days` = #{ds.days},\n"
  data += "`decline_type` = '#{ds.decline_type}',\n"
  data += "`created_at` = NOW(),\n"
  data += "`updated_at` = NOW(),\n"
  data += "`id` = #{ds.id};\n\n"

  puts "\n"
  puts data

  @sql_file << data
end

strategies= []

strategies << {
  :gateway => "mes",
  :installment_type => "1.month",
  :credit_card_type => "all",
  :response_code => "005",
  :max_retries => 6,
  :days => 6,
  :decline_type => "soft"
}

strategies.each do |strategy|
  dsid = create_strategy(strategy)
  strategy_to_yaml(dsid)
  strategy_to_sql(dsid)
end

@yaml_file.close
@sql_file.close


# getting the last strategy
# 
# select id from decline_strategies order by id desc max_retries 1;

# 
# the inserts for Carla
# 
# insert into decline_strategies set
# gateway = "mes",
# installment_type = "1.month",
# credit_card_type = "all",
# response_code = "061",
# `max_retries` = 4,
# days = 9,
# decline_type = "soft";
# 
# insert into decline_strategies set
# gateway = "mes",
# installment_type = "1.year",
# credit_card_type = "all",
# response_code = "061",
# `max_retries` = 4,
# days = 9,
# decline_type = "soft";

