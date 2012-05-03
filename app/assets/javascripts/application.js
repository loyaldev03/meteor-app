// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require_tree .
//= require dataTables/jquery.dataTables
//= require dataTables/jquery.dataTables.bootstrap


$('document').ready( function() {
  $('#new_member').submit( function(event) {
    event.preventDefault()
    $.ajax({
      type: 'POST',
      url: "/api/v1/enroll",
      data: $("#new_member").serialize(),
      success: function(data) {
        alert (data.message);
      	if (data.code == 000)
      		window.location.replace('../members/'+data.v_id);
      },
      });
  });


  $('form[id^="edit_member"]').submit( function(event) {
    event.preventDefault()
    $.ajax({
      type: 'PUT',
      url: "/api/v1/update_profile/"+visible_id+"/"+club_id,
      data: $('form[id^="edit_member"]').serialize(),
      success: function(data) {
        alert (data.message);
        if (data.code == 000)
          window.location.replace('../'+data.v_id);
      },
    });
  });

  $('.confirm').click( function(event){
    var answer = confirm('Are you sure?');
    return answer
  });

  $('#myTab a:last').tab('show');

  $('.datatable').dataTable({
    "sDom": "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
    "sPaginationType": "bootstrap"
  });

  $('.datatable_only_sorting').dataTable({
    "sDom": "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
    "sPaginationType": "bootstrap",
    "bLengthChange": false,
    "bFilter": false,
    "bSort": true,
    "bInfo": false,
    "bAutoWidth": false,
  });




});