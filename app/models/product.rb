class Product < ActiveRecord::Base
  belongs_to :club
  has_many :fulfillments
  has_many :campaigns, through: :campaign_products
  has_many :campaign_products

  validates :sku, presence: true, format: /\A[0-9a-zA-Z\-_]+\z/, length: { maximum: 30 }, uniqueness: { scope: [:club_id, :deleted_at] }
  validates :name, presence: true
  validates :stock, numericality: { only_integer: true, less_than: 1999999, greater_than: -1999999 }

  scope :with_stock, -> { where('(allow_backorder = true) OR (allow_backorder = false and stock > 0)') }

  before_save :apply_upcase_to_sku
  before_update :validate_sku_update
  before_destroy :no_fulfillment_related?

  acts_as_paranoid

  def self.datatable_columns
    ['id', 'name', 'sku', 'stock', 'allow_backorder']
  end

  def store_variant_url
    club.store_url + "/admin/products/#{store_slug}/variants/#{store_id}/edit"
  end

  def can_be_assigned_to_campaign?
    image_url.present?
  end

  def apply_upcase_to_sku
    self.sku = self.sku.upcase
  end

  def no_fulfillment_related?
    fulfillments.first.nil?
  end

  def validate_sku_update
    fulfillments.update_all(product_sku: sku) if sku_changed?
  end

  def decrease_stock(quantity=1)
    if self.reload.has_stock?
      Product.where(id: self.id).update_all "stock = stock - #{quantity}"
      logger.info "Product ID: #{self.id} Stock decreased to: #{stock-quantity}"
      {:message => "Stock reduced with success", :code => Settings.error_codes.success}
    else
      {:message => I18n.t('error_messages.product_out_of_stock'), :code => Settings.error_codes.product_out_of_stock}
    end
  end

  def replenish_stock(quantity=1)
    Product.where(id: self.id).update_all "stock = stock + #{quantity}"
    logger.info "Product ID: #{self.id} Stock replenished to: #{stock+quantity}"
  end

  def has_stock?
    allow_backorder? ? true : stock>0
  end

  def sanitized_name
    # It is in two different expresions to clean product names without the
    # driver's number too
    name.sub(/.*\s-\s/, '').sub(/#\d+/, '').strip
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
          fulfillments_data = product.fulfillments.group(:status).count
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
