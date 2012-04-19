class DomainsController < ApplicationController
  layout '2-cols'

  # GET /domains
  # GET /domains.json
  def index
    @domains = Domain.where(:partner_id => @current_partner)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @domains }
    end
  end

  # GET /domains/1
  # GET /domains/1.json
  def show
    @domain = Domain.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @domain }
    end
  end

  # GET /domains/new
  # GET /domains/new.json
  def new
    @domain = Domain.new :partner => @current_partner
    @clubs = Club.where(:partner_id => @current_partner)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @domain }
    end
  end

  # GET /domains/1/edit
  def edit
    @domain = Domain.find(params[:id])
    @clubs = Club.where(:partner_id => @current_partner)
  end

  # POST /domains
  # POST /domains.json
  def create
    @domain = Domain.new(params[:domain])
    @domain.partner = @current_partner

    respond_to do |format|
      if @domain.save
        format.html { redirect_to domain_path(:id => @domain), notice: "The domain #{@domain.url} was successfully created." }
        format.json { render json: @domain, status: :created, location: @domain }
      else
        format.html { render action: "new" }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /domains/1
  # PUT /domains/1.json
  def update
    @domain = Domain.find(params[:id])

    respond_to do |format|
      if @domain.update_attributes(params[:domain])
        format.html { redirect_to domain_path(:id => @domain), notice: "The domain #{@domain.url} was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /domains/1
  # DELETE /domains/1.json
  def destroy
    @domain = Domain.find(params[:id])
    @partner = Partner.find(@domain.partner_id)

    if @domain.destroy
      respond_to do |format|
        format.html { redirect_to domains_url }
        format.json { head :no_content }
      end
    else
      redirect_to domains_path(:id => @domain), :flash => { error: "The domain #{@domain.url} cannot be destroyed. You must have at least one domain."}
    end
  end
end
