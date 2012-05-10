# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "dd-mm-yy", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});

  $('#member_cancelation_form').validate();