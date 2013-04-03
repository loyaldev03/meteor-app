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
      .on('ajax:success', function(evt, data) {
        var self = $(this);
        $(self.data('replace')).html(data);
        self.trigger('ajax:replaced');
      })
      .on('ajax:beforeSend', function(evt, data) {
        var self = $(this);
        $(self.data('replace')).html("<div class='progress progress-striped active'><div class='bar' style='width: 100%;' /></div>");
      })
      .on('ajax:error', function(evt, data) {
        var self = $(this);
        $(self.data('replace')).find('> .progress').addClass('progress-danger').removeClass('active');
      });
  });

  $(function() {
    $.ajaxSetup({
      error: function(jqXHR, exception) {
        if (jqXHR.status == 401)
          alert('Agent is not authorized to make this request.');
        else if (jqXHR.status == 500)
          alert('Unexpected error, a ticket has been submitted.');
      }
    });
  });
});

function agent_index_functions(column_count){
  $('#agents_table').dataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "bootstrap",
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
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
    "bLengthChange": false,
    "iDisplayLength": 25,
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
    "bLengthChange": false,
    "iDisplayLength": 25,
    "aaSorting": [[ 0, "asc" ]],
    "aoColumnDefs": [{ "sWidth": "380px", "aTargets": [ column_count+1 ] },
                     { "bSortable": false, "aTargets": [ column_count+1, column_count ] }],
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
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count, column_count+1 ] },
                     { "sWidth": "360px", "aTargets": [ column_count+1 ] }],
    "sAjaxSource": $('#my_clubs_table').data('source'),
  });
}
function domain_index_functions(column_count){
  $('#domains_table').dataTable({
    "sPaginationType": "bootstrap",
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "aaSorting": [[ 0, "asc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] },
                     { "sWidth": "190px", "aTargets": [ column_count ] }],
    "sAjaxSource": $('#domains_table').data('source'),
  });   
}

function product_index_functions(column_count){
  $('#products_table').dataTable({
    "sPaginationType": "bootstrap",
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
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
  $('#members .pagination a').on('click', function () {  
    update_select_only = false;
    $.getScript(this.href);  
    return false;  
  }); 

  $("#clear_form").click( function() {
    $("#index_search_form input[type=text]").each(function() { $(this).val(''); }); 
  });

  $('#member_country').on('change',  function(){
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
          window.location.replace('../member/'+data.member_id);
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
  
  $('#member_country').on('change',  function(){
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
          window.location.replace('../'+id);
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

  $('.help').popover({offset: 10});

  $('#member_country').on('change',  function(){
    country = $('#member_country').val();
    $.get('', { country_code:country }, null, 'script'); 
  })
};

function club_cash_functions(){
  $('#_amount').on('change', function(){
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
      url: "/api/v1/members/"+id+"/club_cash_transaction",
      data: $("form").serialize(),
      success: function(data) {
        if (data.code == 000)
          window.location.replace('../'+id);
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
    "aaSorting": [[ 1, "desc" ]],
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
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": false,
    "sPaginationType": "bootstrap",
    "bServerSide": true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 1,2,3,4,5,6 ] }],
    "sAjaxSource": $('#transactions_table').data('source'),
  });
}

function memberships_member_functions(column_count){
  $('#memberships_table').dataTable({
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

function fulfillment_files_functions() {
  $('#fulfillment_files_table').dataTable({
    "oLanguage": {"sSearch": "Filtered by:"},
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "bootstrap",
    "bServerSide": true,
    "bSort": false,
    "bFilter": false,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "sAjaxSource": $('#fulfillment_files_table').data('source')
  });
  $('.dataTables_filter').hide();

}


function club_cash_transactions_functions(column_count){
  $('#club_cash_transactions_table').dataTable({
    "oLanguage": {"sSearch": "Filtered by:"},
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "bootstrap",
    "bServerSide": true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2 ] }],
    "sAjaxSource": $('#club_cash_transactions_table').data('source')
  });
}

function show_member_functions(){
  $(".btn").on('click',function(event){
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

function fulfillments_not_processed_function(){
  $('#reason').hide();
  $('#new_status').change(function (value){
    if (this.options[this.selectedIndex].value == "bad_address" || this.options[this.selectedIndex].value == "returned" )
      $('#reason').show();
    else
      $('#reason').hide();
  });
  $("#fulfillment_select_all").click(function (){
    if ($("#fulfillment_select_all").is(':checked')) {
      $('.fulfillment_selected').attr('checked', true);
    } else {
      $('.fulfillment_selected').attr('checked', false);
    }
  });
  $("#update_fulfillment_status").click(function() {
    if($('.fulfillment_selected:checked').length == 0){
      alert("Select a fulfillment to apply status.");
    } else{
      $('.fulfillment_selected:checked').each(function(index){
      $.ajax({
        type: 'PUT',
        url: $(this).data('url'),
        data: { new_status: $('#new_status').val(), reason: $('#reason').val(), file: $('#fulfillment_file').val() },
        dataType: 'json',
        success: function(data) {
          if (data.code == "000"){
            $("[name='fulfillment_selected["+data.id+"]']").parent().children().hide();
            $("[name='fulfillment_selected["+data.id+"]']").parent().append("<div class='alert-info alert'>"+data.message+"</div>")
          }else{
            alert(data.message);
            $("[name='fulfillment_selected["+data.id+"]']").parent().append("<div class='error-info error'>"+data.message+"</div>")
          };
        },
      });  
    });
    }
  });     
}

function set_product_type_at_fulfillments_index(settings_kit_card_product, settings_others_product) {
  var radio_product_type = $('[name=radio_product_type]:checked');
  if (radio_product_type.val() == settings_kit_card_product || radio_product_type.val() == settings_others_product) {
    $('#product_type').val(radio_product_type.val());
  } else {
    $('#product_type').val($('#input_product_type').val());
  }
}

function fulfillments_index_functions(create_xls_file_url, make_report_url, fulfillment_file_cant_be_empty_message, settings_kit_card_product, settings_others_product){
  $(".datepicker").datepicker({ constrainInput: true, 
                                dateFormat: "yy-mm-dd", 
                                showOn: "both", 
                                buttonImage: "/icon-calendar.png", 
                                buttonImageOnly: true });
  
  if ($("#initial_date").val() == ""){
    $("#initial_date").datepicker( "setDate", '-1w' );
  }
  if ($("#end_date").val() == ""){
    $("#end_date").datepicker( "setDate", '0' );
  }

  $("#all_times").click(function (){
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
    var fuls = $('.fulfillment_selected:checked');
    for (x in fuls) {
      $('<input>').attr({ type: 'hidden', name: fuls[x].name, value: fuls[x].value }).appendTo($('#fulfillment_report_form'));
    }
    if (fuls.length != 0) {
      set_product_type_at_fulfillments_index(settings_kit_card_product, settings_others_product)
      $('#fulfillment_report_form').attr("action", create_xls_file_url);
      $('#fulfillment_report_form').submit();
    } else {
      alert(fulfillment_file_cant_be_empty_message);
    }
  });  

  $('#input_product_type').blur(function() {
    $('#radio_product_type_'+settings_others_product+'_others').attr('checked', true);
  });

  $("#make_report").click(function() {
    set_product_type_at_fulfillments_index(settings_kit_card_product, settings_others_product);
    $('#fulfillment_report_form').attr("action", make_report_url);
  });    

  // resend_fulfillment("fulfillments/");
  
  // mark_as_sent_fulfillment("fulfillments/");

  // $('*#set_as_wrong_address').click( function(event){
  //   $(this).hide();
  //   append = $(this).parent();
  //   $.get(this.action, {member_prefix:$(this).attr("name")}, null, 'script'); 
  //   return false;
  // });

  // $("#set_undeliverable").on("submit", function(event){
  //   event.preventDefault();
  //   this_form = $(this);
  //   $.ajax({
  //     type: 'POST',
  //     url: "member/"+$(this).attr("name")+"/set_undeliverable",
  //     data: $(this).serialize(),
  //     dataType: 'json',
  //     success: function(data) {
  //       if (data.code == "000"){
  //         $("[id='set_as_wrong_address'][name='"+this_form.attr("name")+"']").parent().children().hide();
  //         $("[id='set_as_wrong_address'][name='"+this_form.attr("name")+"']").parent().append("<div class='alert-info alert'>"+data.message+"</div>")
  //       }else{
  //         alert(data.message);
  //       };
  //     },
  //   });  
  // });

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
