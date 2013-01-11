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

  $(".alert").alert();



  // taken fom https://makandracards.com/makandra/1383
  $(function() {
    $('[data-remote][data-replace]')
      .data('type', 'html')
      .live('ajax:success', function(evt, data) {
        var self = $(this);
        $(self.data('replace')).html(data);
        self.trigger('ajax:replaced');
      })
      .live('ajax:beforeSend', function(evt, data) {
        var self = $(this);
        $(self.data('replace')).html("<div class='progress progress-striped active'><div class='bar' style='width: 100%;' /></div>");
      })
      .live('ajax:error', function(evt, data) {
        var self = $(this);
        $(self.data('replace')).find('> .progress').addClass('progress-danger').removeClass('active');
      });
  });

});

  function agent_index_functions(column_count){
    $('#agents_table').dataTable({
      "bJQueryUI": false,
      "bProcessing": true,
      "sPaginationType": "bootstrap",
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 4 ] }],
      "sAjaxSource": $('#agents_table').data('source'),
    });
  }

  function partner_index_functions(column_count){
    $('#partners_table').dataTable({
      "sPaginationType": "bootstrap",
      "bJQueryUI": false,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#partners_table').data('source'),
    });
  }
  
  function club_index_functions(column_count){
    $('#clubs_table').dataTable({
      "sPaginationType": "bootstrap",
      "bJQueryUI": false,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count+1, column_count ], "sWidth": "25%", "aTargets": [ 3 ] }],
      "sAjaxSource": $('#clubs_table').data('source'),
    });
  }

  function my_club_index_functions(column_count){
    $('#my_clubs_table').dataTable({
      "sPaginationType": "bootstrap",
      "bJQueryUI": false,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count, column_count+1 ], "sWidth": "20%", "aTargets": [ 3 ] }],
      "sAjaxSource": $('#my_clubs_table').data('source'),
    });
  }
  function domain_index_functions(column_count){
    $('#domains_table').dataTable({
      "sPaginationType": "bootstrap",
      "bJQueryUI": false,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#domains_table').data('source'),
    });   
  }

  function product_index_functions(column_count){
    $('#products_table').dataTable({
      "sPaginationType": "bootstrap",
      "bJQueryUI": false,
      "bProcessing": true,
      "bServerSide": true,
      "aaSorting": [[ 0, "asc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
      "sAjaxSource": $('#products_table').data('source'),
    });       
  }

  function new_partner_functions(){
    $('.help').popover({offset: 10});
  }

  function new_domain_functions(){
    $('.help').popover({offset: 10});
  }

  function new_product_functions(){
    $('.help').popover({offset: 10});
  }

  function member_index_functions(){
    $('#index_search_form').submit(function (){
      update_select_only = false;
      $.get(this.action, $(this).serialize(), null, 'script'); 
      return false;
    });

    $(".datepicker_for_search").datepicker({ constrainInput: true, minDate: 0, dateFormat: "yy-mm-dd", 
                                             showOn: "both", buttonImage: "/icon-calendar.png", 
                                             buttonImageOnly: true});
    $('#members .pagination a').live('click', function () {  
      update_select_only = false;
      $.getScript(this.href);  
      return false;  
    }); 

    $("#clear_form").click( function() {
      $("#index_search_form input[type=text]").each(function() { $(this).val(''); }); 
    });

    $('#member_country').live('change',  function(){
      country = $('#member_country').val();
      update_select_only = true;
      $.get(this.action, { country_code:country, only_select:update_select_only }, null, 'script'); 
    })

  };

  function new_member_functions(){
    $('#error_explanation').hide();
    $(".datepicker").datepicker({ constrainInput: true, 
                                  maxDate: 0, 
                                  dateFormat: "yy-mm-dd", 
                                  showOn: "both", 
                                  buttonImage: "/icon-calendar.png", 
                                  changeMonth: true,
                                  changeYear: true,
                                  yearRange: '1900',
                                  buttonImageOnly: true});
    $('#new_member').submit( function(event) {
      $('#error_explanation').hide();
      $('#submit_button').attr('disabled', 'disabled');
      event.preventDefault();
      $.ajax({
        type: 'POST',
        url: "/api/v1/members",
        data: $("#new_member").serialize(),
        success: function(data) {
          $('input').parent().parent().removeClass("error");
          if (data.code == 000) {
            alert (data.message);
            window.location.replace('../member/'+data.v_id);
          }else{
            $('#error_explanation').show();
            $('#error_explanation ul').empty();
            $('#submit_button').removeAttr('disabled');
            $('#error_explanation ul').append("<b>"+data.message+"</b>");
            for (var key in data.errors){
              if (data.errors.hasOwnProperty(key)) {
                if (key != 'credit_card'){
                  $('#member_'+key).parent().parent().addClass("error");
                  $('#error_explanation ul').append("<li>"+key+': '+data.errors[key]+"</li>");
                }
                else{
                  for (var key2 in data.errors[key]){
                    if (data.errors[key].hasOwnProperty(key2)){
                      if (key2 != 0){
                        $('#member_credit_card_'+key2).parent().parent().addClass("error");
                        $('#error_explanation ul').append("<li>"+key2+': '+data.errors[key][key2]+"</li>");                  
                      }
                    }
                  } 
                }
              }
            }
          }
        },
      });
    });
    today = new Date()
    $('#setter_cc_blank').click(function(){
      if ($('#setter_cc_blank').attr('checked')) {
        $('#member_credit_card_number').val('0000000000');
        $('#member_credit_card_expire_month').val(today.getMonth() + 1);
        $('#member_credit_card_expire_year').val(today.getFullYear());
        $('#member_credit_card_number').attr('readonly', true);
        $('#member_credit_card_expire_month').attr('readonly', true);
        $('#member_credit_card_expire_year').attr('readonly', true);
      }else{
        $('#member_credit_card_number').val('');
        $('#member_credit_card_expire_month').val('');
        $('#member_credit_card_expire_year').val('');
        $('#member_credit_card_number').attr('readonly', false);
        $('#member_credit_card_expire_month').attr('readonly', false);
        $('#member_credit_card_expire_year').attr('readonly', false);
      }
    });  

    $('#zip_help').popover({offset: 10});
    $('.help').popover({offset: 10});
    
    $('#member_country').live('change',  function(){
      country = $('#member_country').val();
      $.get(this.action, { country_code:country }, null, 'script'); 
    })

  };

  function edit_member_functions(){
    $('#error_explanation').hide();
    $(".datepicker").datepicker({ constrainInput: true, 
                                  maxDate: 0, 
                                  dateFormat: "yy-mm-dd",
                                  showOn: "both", 
                                  buttonImage: "/icon-calendar.png", 
                                  changeMonth: true,
                                  changeYear: true,
                                  yearRange: '1900',
                                  buttonImageOnly: true});
    $('form').submit( function(event) {
      $('#submit_button').attr('disabled', 'disabled');
      event.preventDefault();
      $.ajax({
        type: 'PUT',
        url: "/api/v1/members/"+id,
        data: $('form').serialize(),
        success: function(data) {
          alert(data.message);
          $('input').parent().parent().removeClass("error");
          if (data.code == 000)
            window.location.replace('../'+v_id);
          else{
            $('#submit_button').removeAttr('disabled');
            $('#error_explanation').show();
            $('#error_explanation ul').empty();
            $('#error_explanation ul').append("<b>"+data.message+"</b>");
            for (var key in data.errors){
              if (data.errors.hasOwnProperty(key)) {
                $('#member_'+key).parent().parent().addClass("error");
                $('#error_explanation ul').append("<li>"+key+': '+data.errors[key]+"</li>");
              }     
            }       
          }
        }
      });
    });
    $('body').ajaxError(function () {
      alert('An unexpected error occurred.');
    });
    $('.help').popover({offset: 10});

    $('#member_country').live('change',  function(){
      country = $('#member_country').val();
      $.get('', { country_code:country }, null, 'script'); 
    })
  };

  function club_cash_functions(){
    $('#_amount').live('change', function(){
      amount = $('#_amount').val().substring(0,15);
      var num = parseFloat(amount);
      if(num!=0)
        $('#_amount').val(Math.floor(num * 100) / 100);
    });

    $('#error_explanation').hide();
    $('form').submit( function(event) {
      $('#submit_button').attr('disabled', 'disabled');
      event.preventDefault(); 
        $.ajax({
          type: 'POST',
          url: "/api/v1/members/"+member_id+"/club_cash",
          data: $("form").serialize(),
          success: function(data) {
            if (data.code == 000)
              window.location.replace('../'+visible_id);
            else{
              $('#submit_button').removeAttr("disabled");
              $('#error_explanation').show();
              $("#error_explanation ul").empty();
              $('#error_explanation ul').append("<b>"+data.message+"</b>");
              for (var key in data.errors){
                if (data.errors.hasOwnProperty(key)){
                  if (key != 'member'){
                  $("#error_explanation ul").append("<li>"+key+": "+data.errors[key]+"</li>");
                   }
                  else{
                    for (var key2 in data.errors[key]){
                      if (data.errors[key].hasOwnProperty(key2)){
                        if (key2 != 0){
                          $('#error_explanation ul').append("<li>"+key2+': '+data.errors[key][key2]+"</li>");                       
                        }
                      }
                    } 
                  }
                }
              }
            }
          },
        });
    });
  }

  function sync_status_member_functions(column_count){
    $('.toggler').each(function() {
      var self = $(this);
      var target = $(self.data('target'));
      target.filter(':not(.default)').hide();
    });
    $('.toggler').click(function(evt){
      evt.preventDefault();
      var self = $(this);
      var target = $(self.data('target'));
      var active = target.filter('.active');
      var inactive = target.filter(':not(.active)');
      active.hide().removeClass('active');
      inactive.show().addClass('active');
    });
  }

  function operation_member_functions(column_count){
    oTable2 = $('#operations_table').dataTable({
      "oLanguage": {"sSearch": "Filtered by:"},
      "bJQueryUI": false,
      "bProcessing": true,
      "sPaginationType": "bootstrap",
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count, column_count+1 ] }],
      "sAjaxSource": $('#operations_table').data('source'),
    });

    $('#dataTableSelect').insertAfter('#operations_table_info')

    $('.dataTables_filter').hide();
    $(".dataselect").change( function () {
        oTable2.fnFilter( $(this).val() );
    });
  };

  function transactions_member_functions(column_count){
    $('#transactions_table').dataTable({
      "oLanguage": {"sSearch": "Filtered by:"},
      "bJQueryUI": false,
      "bProcessing": true,
      "sPaginationType": "bootstrap",
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 1,2,3,4,5 ] }],
      "sAjaxSource": $('#transactions_table').data('source'),
    });
  }
  
  function memberships_member_functions(column_count){
    $('#memberships_table').dataTable({
      "oLanguage": {"sSearch": "Filtered by:"},
      "bJQueryUI": false,
      "bProcessing": true,
      "bFilter": false,
      "sPaginationType": "bootstrap",
      "bServerSide": true,
      "bLengthChange": false,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2,column_count-1 ] }],
      "sAjaxSource": $('#memberships_table').data('source')
    });
  }

  
  function club_cash_transactions_functions(column_count){
    $('#club_cash_transactions_table').dataTable({
      "oLanguage": {"sSearch": "Filtered by:"},
      "bJQueryUI": false,
      "bProcessing": true,
      "sPaginationType": "bootstrap",
      "bServerSide": true,
      "aaSorting": [[ 0, "desc" ]],
      "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 1 ] }],
      "sAjaxSource": $('#club_cash_transactions_table').data('source')
    });
  }

  function show_member_functions(){
    $(".btn").live('click',function(event){
      if($(this).attr('disabled') == 'disabled')
        event.preventDefault(); 
    })

    $('.help').popover();
    mark_as_sent_fulfillment("../fulfillments/");
    resend_fulfillment("../fulfillments/");
  };

  function member_cancellation_functions(){
    $("#member_cancelation_form").validate({
       submitHandler: function(form) {
        if (confirm('This member will be canceled. Are you really sure?')) {
          form.submit();            
        }else
        return false;
       }
    })
    $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
  };

  function blacklist_member_functions(){
    $("form").validate({
       submitHandler: function(form) {
        if (confirm('This member will be blacklisted. Are you really sure?')) {
          form.submit();            
        }else
        return false;
       }
    })
  }

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

  function fulfillments_index_functions(create_xls_file_url, make_report_url){
    $(".datepicker").datepicker({ constrainInput: true, 
                                  dateFormat: "yy-mm-dd", 
                                  showOn: "both", 
                                  buttonImage: "/icon-calendar.png", 
                                  buttonImageOnly: true });
    
    $("#initial_date").datepicker( "setDate", '-1w' );
    
    $("#end_date").datepicker( "setDate", '0' );

    $("#all_times").click (function (){
      if ($("#all_times").is(':checked')) {
        $('#td_initial_date').hide();
        $('#td_end_date').hide();
      } else {
        $('#td_initial_date').show();
        $('#td_end_date').show();
      }
    });

    if ($("#all_times").is(':checked')) {
      $('#td_initial_date').hide();
      $('#td_end_date').hide();
    }


    $("#create_xls_file").click(function() {
      $('#fulfillment_report_form').attr("action", create_xls_file_url);
    });    
    $("#make_report").click(function() {
      $('#fulfillment_report_form').attr("action", make_report_url);
    });    

    resend_fulfillment("fulfillments/");
    
    mark_as_sent_fulfillment("fulfillments/");

    $('*#set_as_wrong_address').click( function(event){
      $(this).hide();
      append = $(this).parent();
      $.get(this.action, {member_prefix:$(this).attr("name")}, null, 'script'); 
      return false;
    });

    $("#set_undeliverable").live("submit", function(event){
      event.preventDefault();
      this_form = $(this);
      $.ajax({
        type: 'POST',
        url: "member/"+$(this).attr("name")+"/set_undeliverable",
        data: $(this).serialize(),
        dataType: 'json',
        success: function(data) {
          if (data.code == "000"){
            $("[id='set_as_wrong_address'][name='"+this_form.attr("name")+"']").parent().children().hide();
            $("[id='set_as_wrong_address'][name='"+this_form.attr("name")+"']").parent().append("<div class='alert-info alert'>"+data.message+"</div>")
          }else{
            alert(data.message);
          };
        },
      });  
    });

  };

  function mark_as_sent_fulfillment(url){
    $('*#mark_as_sent').click( function(event){
      button = $(this)
      button.attr('disabled', 'disabled');
      event.preventDefault();
      $.ajax({
        type: 'PUT',
        url: url+button.attr("name")+"/mark_as_sent",
        success: function(data) {
          if (data.code == "000"){
            button.parent().children().hide();
            //button.parent().append("<div class='alert-info alert'>"+data.message+"</div>");
            button.parent().parent().after("<tr><td colspan='8'><p style='text-align: center;'><div class='alert-info alert'>"+data.message+"</div></p></td></tr>");
          }else{
            button.removeAttr('disabled');
            alert(data.message);
          };
        },
      });
    });
  }

  function resend_fulfillment(url){
    $('*#resend').click( function(event){
      button = $(this)
      button.attr('disabled', 'disabled');
      event.preventDefault();
      $.ajax({
        type: 'PUT',
        url: url+button.attr("name")+"/resend",
        success: function(data) {
          if (data.code == "000"){
            button.parent().children().hide();
            button.parent().parent().after("<tr><td colspan='8'><p style='text-align: center;'><div class='alert-info alert'>"+data.message+"</div></p></td></tr>");
          }else{
            button.removeAttr('disabled');
            alert(data.message);
          };
        },
      });
    });
  }