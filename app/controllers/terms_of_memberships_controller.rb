class TermsOfMembershipsController < ApplicationController
  layout '2-cols'
  
  # GET /terms_of_memberships
  # GET /terms_of_memberships.json
  def index
    @terms_of_memberships = TermsOfMembership.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @terms_of_memberships }
    end
  end

  # GET /terms_of_memberships/1
  # GET /terms_of_memberships/1.json
  def show
    @terms_of_membership = TermsOfMembership.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @terms_of_membership }
    end
  end

  # GET /terms_of_memberships/new
  # GET /terms_of_memberships/new.json
  def new
    @terms_of_membership = TermsOfMembership.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @terms_of_membership }
    end
  end

  # GET /terms_of_memberships/1/edit
  def edit
    @terms_of_membership = TermsOfMembership.find(params[:id])
  end

  # POST /terms_of_memberships
  # POST /terms_of_memberships.json
  def create
    @terms_of_membership = TermsOfMembership.new(params[:terms_of_membership])

    respond_to do |format|
      if @terms_of_membership.save
        format.html { redirect_to @terms_of_membership, notice: 'Terms of membership was successfully created.' }
        format.json { render json: @terms_of_membership, status: :created, location: @terms_of_membership }
      else
        format.html { render action: "new" }
        format.json { render json: @terms_of_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /terms_of_memberships/1
  # PUT /terms_of_memberships/1.json
  def update
    @terms_of_membership = TermsOfMembership.find(params[:id])

    respond_to do |format|
      if @terms_of_membership.update_attributes(params[:terms_of_membership])
        format.html { redirect_to @terms_of_membership, notice: 'Terms of membership was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @terms_of_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /terms_of_memberships/1
  # DELETE /terms_of_memberships/1.json
  def destroy
    @terms_of_membership = TermsOfMembership.find(params[:id])
    @terms_of_membership.destroy

    respond_to do |format|
      format.html { redirect_to terms_of_memberships_url }
      format.json { head :no_content }
    end
  end
end
