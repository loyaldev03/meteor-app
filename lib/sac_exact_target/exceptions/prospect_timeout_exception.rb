class ProspectTimeoutException < Exception
  def initialize(data)
    @data = data
  end
end
