TOM_ID = 43
CLIENT = 'exact_target'

email_templates = [
  ["Youth Protection", 50, 712, "pillar"],
  ["Gym Ranking", 35, 709, "pillar"],
  ["Deals & Discounts", 45, 708, "pillar"],
  ["Member Content", 40, 706, "pillar"],
  ["Cancellation Email", 0, 705, "cancellation"],
  ["Prebill Email", 0, 707, "prebill"],
  ["Refund Email", 0, 711, "refund"],
  ["Hard Decline Email", 0, 710, "hard_decline"]
]

log_filename = "/tmp/#{$$}.log"
logger = File.open(log_filename, 'w+')

email_templates.each do |et|
  new_et = EmailTemplate.new
    new_et.name = et[0]
    new_et.client = CLIENT
    new_et.external_attributes = {:customer_key => et[2]}
    new_et.template_type = et[3]
    new_et.terms_of_membership_id = TOM_ID
    new_et.days = et[1]
  result = new_et.save

  logger << "Adding '#{et[0]}' - to TOM: ##{TOM_ID} - [#{result}]\n"
end

logger.close

puts "See the log file at: #{logger.path}"