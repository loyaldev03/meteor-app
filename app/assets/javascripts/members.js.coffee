# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});

  $('#member_cancelation_form').validate();  

  $('#at_least_one_required').submit ->
  	result = false
  	$('#at_least_one_required').find(':text').each -> 
  		if $(this).val() != ''  
  		  result = true
  	if (!result) 
      alert ('Compleate at least one field')
      return result
