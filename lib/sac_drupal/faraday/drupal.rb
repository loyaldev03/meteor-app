# module Faraday
#   class Drupal
#     # logger.info "  * registering Faraday middleware: DrupalAuthentication"
#     # logger.info "  * registering Faraday middleware: FixNonJsonBody"
#     register_middleware :request, :drupal_auth => lambda { ::Drupal::FaradayMiddleware::DrupalAuthentication }
#     register_middleware :response, :fix_non_json_body => lambda { ::Drupal::FaradayMiddleware::FixNonJsonBody }
#   end
# end