

$(document).ready( function() {

  $('.confirm').click( function(event){
    var answer = confirm('Are you sure?');
    return answer 
  });

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

  $('#MyModal').modal({
    show: false,
    backdrop: true
  });

  $('#MyModal modal-footer .primary').click(function(){
    alert("da")
  });

});

  function agent_index_functions(){
    $('#agents_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 5 ] }],
      "sAjaxSource": $('#agents_table').data('source'),
    });

  }

  function partner_index_functions(column_count){
    $('#partners_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#partners_table').data('source'),
    });
  }

  function member_index_functions(){
    $('#at_least_one_required').submit(function (){
      result = false;
      $('#at_least_one_required').find(':text').each(function (){
        if ($(this).val() != '')
          result = true;
      });
      if (!result){ 
        alert ('Compleate at least one field');
        return result;
      };
    });
    $(".datepicker_for_search").datepicker({ constrainInput: true, minDate: 0, dateFormat: "yy-mm-dd", 
                                             showOn: "both", buttonImage: "/icon-calendar.png", 
                                             buttonImageOnly: true});
    $("#clear_form").click( function() {
      $("#at_least_one_required input[type=text]").each(function() { $(this).val(''); }); 
    });
  };

  function new_member_functions(){
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

    $('#zip_help').popover({offset: 10});
    $('#phone_number_help').popover({offset: 10});   
    $('.help').popover({offset: 10});
  };

  function edit_member_functions(){
    $('form').submit( function(event) {
      event.preventDefault();
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
    $('.help').popover({offset: 10});
  };


  function operation_member_functions(){
    $('#'+filter).toggleClass("btn-info");
    $('#operations_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 3 ] }],
      "sAjaxSource": $('#operations_table').data('source'),
      });
  };

  function transactions_member_functions(){
    $('#transactions_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 1,2,3,4,5 ] }],
      "sAjaxSource": $('#transactions_table').data('source'),
    });
  }

  function show_member_functions(){
    $('.help').popover();
  };

  function member_cancellation_functions(){
    $('#member_cancelation_form').validate();
    $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
  };

  function member_note_functions(){
    $('#new_member_note').validate();
  };

  function member_change_next_bill_date(){
    $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
  };

  function refound_member_functions(){
    $('form').submit( function(event) {
      if ($("#refunded_amount").val().match(/^[0-9 .]+$/)){

      }else{
      alert("Incorrect refound value.")
      event.preventDefault(); 
      };
    })
  };

  function club_cash_transaction_functions(){
    $('form').submit( function(event) {
      if ($("#club_cash_transaction_amount").val().match(/^[0-9]+?([?:\.][0-9]{0,2})?$/)){

      }else{
      alert("Incorrect club cash value.")
      event.preventDefault(); 
      };
    })
  }

