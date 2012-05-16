

$(document).ready( function() {
  $('#new_member').submit( function(event) {
    event.preventDefault()
    $.ajax({
      type: 'POST',
      url: "/api/v1/enroll",
      data: $("#new_member").serialize(),
      success: function(data) {
        alert (data.message);
        if (data.code == 000)
          window.location.replace('../member/'+data.v_id);
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

  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
  
  $(".datepicker_for_search").datepicker({ constrainInput: true, minDate: 0, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});

  $('#member_cancelation_form').validate();  

  $('#new_member_note').validate();

  $('#at_least_one_required').submit(function (){
    result = false
    $('#at_least_one_required').find(':text').each(function (){
      if ($(this).val() != '')  
        result = true;
    if (!result){ 
      alert ('Compleate at least one field')
      return result;
    }
    });
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
    "aaSorting": [[ 0, "desc" ]]
  });
});

  function member_index_functions(){
    //every function that we use on member#index
  };
  function search_functions(){
    $(".datepicker_for_search").datepicker({ constrainInput: true, minDate: 0, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
    
    $('#at_least_one_required').submit(function (){
      result = false
      $('#at_least_one_required').find(':text').each(function (){
        if ($(this).val() != '')  
          result = true;
      if (!result){ 
        alert ('Compleate at least one field')
        return result;
      }
      });
    });