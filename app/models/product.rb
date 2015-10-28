class Product < ActiveRecord::Base
  belongs_to :club

  validates :sku, presence: true, format: /\A[0-9a-zA-Z\-_]+\z/, length: { minimum: 2 }, uniqueness: { scope: [:club_id, :deleted_at] }
  validates :cost_center, format: /\A[a-zA-Z\-_]+\z/, length: { minimum: 2, maximum: 30 }, allow_nil: true

  validates :package, format: /\A[a-zA-Z\-_]+\z/, length: { maximum: 19 }
  validates :stock, numericality: { only_integer: true, less_than: 1999999 }, allow_backorder: true

  scope :with_stock, -> { where('(allow_backorder = true) OR (allow_backorder = false and stock > 0)') }
  scope :not_kit_card, -> { where('sku != "KIT-CARD" ') }

  before_save :apply_upcase_to_sku
  before_update :validate_sku_update
  before_destroy :any_fulfillment_related?

  acts_as_paranoid

  def self.datatable_columns
    ['id', 'name', 'sku', 'stock', 'allow_backorder' ]
  end

  def apply_upcase_to_sku
    self.sku = self.sku.upcase
  end

  def any_fulfillment_related?
    Fulfillment.where(club_id: self.club_id, product_sku: self.sku).limit(1).empty?
  end

  def validate_sku_update
    if sku_changed? and Fulfillment.where(club_id: self.club_id, product_sku: self.sku_was).limit(1).any?
      errors.add :sku, "Cannot change this sku. There are fulfillments related to it."
      false
    end
  end

  def update_product_data_by_params(params)
  	self.name = params[:name]
  	self.recurrent = params[:recurrent]
  	self.sku = params[:sku]
    self.package = params[:package]
  	self.stock = params[:stock]
  	self.weight = params[:weight]
    self.cost_center = params[:cost_center]
    self.allow_backorder = params[:allow_backorder]
    self.is_visible = params[:is_visible]
  end

  def decrease_stock(quantity=1)
    Product.where(id: self.id).update_all "stock = stock - #{quantity}"
  end

  def replenish_stock(quantity=1)
    self.stock = self.stock+quantity
    self.save
  end

  def has_stock?
    allow_backorder? ? true : stock>0
  end

  def self.generate_xls(clubs_id = nil)
    header = ['Name', 'Sku']
    status_list = Fulfillment.state_machines[:status].states.map(&:name)
    status_list.each {|x| header << x}

    package = Axlsx::Package.new
    club_list = Club.where(billing_enable: true)
    club_list = club_list.where(id: clubs_id) if clubs_id 
    club_list.each do |club|
      package.workbook.add_worksheet(:name => club.name) do |sheet|
        sheet.add_row header
        club.products.each do |product|
          row = [ product.name, product.sku ]
          fulfillments_data = Fulfillment.where(product_sku: product.sku, club_id: club.id).group(:status).count
          status_list.each {|status| row << (fulfillments_data[status.to_s] || 0) }
          sheet.add_row row
        end
      end
    end
    package
  end

  def self.send_product_list_email(clubs_id = nil)
    product_xls = Product.generate_xls(clubs_id)
    temp = Tempfile.new("posts.xlsx") 
    
    product_xls.serialize temp.path
    Notifier.product_list(temp).deliver_now!
    
    temp.close 
    temp.unlink
  end 
end
