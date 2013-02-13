class AllowBackorderValidator < ActiveModel::EachValidator  
  def validate(record)
  	if not record.stock.nil?
		  if record.allow_backorder == false and record.stock < 0
	  	  record.errors[:stock] << 'Stock cannot be negative. Enter positive stock, or allow backorder '
	  	end
  	end
  end
end
