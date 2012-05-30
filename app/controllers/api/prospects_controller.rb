class Api::ProspectsController < ApplicationController


  def enroll
  	response = {}
  	prospect = Prospect.new(params[:prospect])

  	respond_to do |format|
      if prospect.save!
  	  response = "Prospect was successfuly saved."
  	    format.html { redirect_to members_path, notice: response}	
        format.json { render json: response }
  	  else
	  	format.html { redirect_to members_path, notice: response}	
	    format.json { render json: response }
 	  end
    end   

  end


end