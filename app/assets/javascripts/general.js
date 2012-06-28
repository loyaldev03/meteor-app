

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

});

  function agent_index_functions(column_count){
    $('#agents_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
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
  
  function club_index_functions(column_count){
    $('#clubs_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#clubs_table').data('source'),
    });
  }

  function domain_index_functions(column_count){
    $('#domains_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#domains_table').data('source'),
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
    today = new Date()
    $('#setter_cc_blank').click(function(){
      if ($('#setter_cc_blank').attr('checked')) {
        $('#credit_card_number').val('0000000000');
        $('#credit_card_expire_month').val(today.getMonth() + 1);
        $('#credit_card_expire_year').val(today.getFullYear());
        $('#credit_card_number').attr('readonly', true);
        $('#credit_card_expire_month').attr('readonly', true);
        $('#credit_card_expire_year').attr('readonly', true);
      }else{
        $('#credit_card_number').val('');
        $('#credit_card_expire_month').val('');
        $('#credit_card_expire_year').val('');
        $('#credit_card_number').attr('readonly', false);
        $('#credit_card_expire_month').attr('readonly', false);
        $('#credit_card_expire_year').attr('readonly', false);
      }
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

  function club_cash_functions(){
    $('form').submit( function(event) {
      event.preventDefault()
      if ($("#club_cash_transaction_amount").val().match(/^[0-9]+?([?:\.][0-9]{0,2})?$/)){
        $.ajax({
          type: 'POST',
          url: "/api/v1/add_club_cash/"+visible_id+"/"+club_id,
          data: $("form").serialize(),
          success: function(data) {
            alert (data.message);
            if (data.code == 000)
              window.location.replace('../'+visible_id);
          },
        });
      }else{
        alert("Incorrect club cash value.")
      };
    });
  }

  function operation_member_functions(column_count){
    oTable = $('#operations_table').dataTable({
      "sPaginationType": "full_numbers",
      "oLanguage": {"sSearch": "Filtered by:"},
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#operations_table').data('source'),
      });

    $('#dataTableSelect').insertAfter('#operations_table_info')

    $('.dataTables_filter').hide();
    $(".dataselect").change( function () {
        oTable.fnFilter( $(this).val() );
    });
  };

  function transactions_member_functions(column_count){
    $('#transactions_table').dataTable({
      "sPaginationType": "full_numbers",
      "bJQueryUI": true,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
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

  function refund_member_functions(){
    $('form').submit( function(event) {
      if ($("#refunded_amount").val().match(/^[0-9 .]+$/)){

      }else{
      alert("Incorrect refund value.")
      event.preventDefault(); 
      };
    })
  };


