class MerchantFee < ActiveRecord::Base

  serialize :transaction_types, Array

end