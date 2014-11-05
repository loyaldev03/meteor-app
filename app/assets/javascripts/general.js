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
        endAjaxLoader();
        if (jqXHR.status == 0) {
          alert('The operation is taking more than expected. Please wait a moment while we finish processing this request and check if it was done.');
        }else
          alert(global_ajax_error_messages(jqXHR));
      },
      timeout: 200000
    });
  });
});

function global_ajax_error_messages(jqXHR){
  if (jqXHR.status == 401)
    return 'Agent is not authorized to make this request.';
  else if (jqXHR.status == 500)
    return 'Unexpected error, a ticket has been submitted.';
  else
    return 'Something went wrong.'
}

function startAjaxLoader(){
  var opts = {
    lines: 9, // The number of lines to draw
    length: 4, // The length of each line
    width: 3, // The line thickness
    radius: 7, // The radius of the inner circle
    corners: 1, // Corner roundness (0..1)
    rotate: 0, // The rotation offset
    direction: 1, // 1: clockwise, -1: counterclockwise
    color: '#000', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 35, // Afterglow percentage
    shadow: false, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: 'auto', // Top position relative to parent in px
    left: 'auto' // Left position relative to parent in px
  };
  var spinner = new Spinner(opts).spin();
  $("#ajax_loader").append(spinner.el);
  $("#ajax_loader").slideDown("slow");
};

function endAjaxLoader(){
  $("#ajax_loader").slideUp();
  $('.spinner').remove();
};

function agent_index_functions(column_count){
  $('#agents_table').dataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "bootstrap",
  "sDom": '<"top"fp>rt<"bottom"il>',
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
  "sDom": '<"top"fp>rt<"bottom"il>',
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
  "sDom": '<"top"fp>rt<"bottom"il>',
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

function delay_jobs_index_functions(column_count){
  $('#delayed_jobs_table').dataTable({
    "sPaginationType": "bootstrap",
  "sDom": '<"top"fp>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "aaSorting": [[ 0, "asc" ]],
    "aoColumnDefs": [ { "sWidth": "100px", "aTargets": [ 1 ] },
                      { "sWidth": "130px", "aTargets": [ 4,5,column_count ] },
                      { "bSortable": false, "aTargets": [ column_count ] }],
    "sAjaxSource": $('#delayed_jobs_table').data('source'),
  });
}

function disposition_types_index_functions(column_count){
  $('#disposition_types_table').dataTable({
    "sPaginationType": "bootstrap",
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "aaSorting": [[ 0, "asc" ]],
    "aoColumnDefs": [ { "bSortable": false, "aTargets": [ column_count ] }],
    "sAjaxSource": $('#disposition_types_table').data('source'),
  });
}

function my_club_index_functions(column_count){
  $('#my_clubs_table').dataTable({
    "sPaginationType": "bootstrap",
    "sDom": '<"top"fp>rt<"bottom"il>',
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
  "sDom": '<"top"fp>rt<"bottom"il>',
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
  "sDom": '<"top"fp>rt<"bottom"il>',
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

function terms_of_memberships_table_index_functions(column_count) {
  $('#terms_of_memberships_table').dataTable({
    "sPaginationType": "bootstrap",
    "sDom": '<"top"fp>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "aaSorting": [[ 0, "asc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
    "sAjaxSource": $('#terms_of_memberships_table').data('source'),
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

function user_index_functions(){
  $('#user_id').keyup(function(event) {
    if (this.value.match(/[^0-9]/g)) {
      this.value = this.value.replace(/[^0-9]/g, '');
    }
  });

  $('#index_search_form').submit(function (event){
    var atLeastOneFilled = false;
    $('form :text, form select').each( function(){
      if($(this).val() != "")
        atLeastOneFilled = true;
    });
    if(atLeastOneFilled == false){
      alert("No filters selected.");
      event.preventDefault(); 
    }else{
      startAjaxLoader();
      $('#submit_button').attr('disabled', 'disabled');
      update_select_only = false;

    $.ajax({
        type: "GET",
        url: "users/search_result",
        dataType: 'script',
        contentType: 'application/javascript',
        data: $(this).serialize(),
        success: function(data){
          endAjaxLoader();
          $('#submit_button').removeAttr('disabled');
        },
        error: function(jqXHR, exception){
          endAjaxLoader();
          if (jqXHR.status == 0) {
            alert('The search is talking more than expected. Please, try again in a moment.');
            $('#submit_button').removeAttr('disabled');
          }else
            global_ajax_error_messages(jqXHR);
        }
      });
      return false;
    }
  });

  $(".datepicker_for_search_nbd").datepicker({ constrainInput: true, minDate: 0, dateFormat: "yy-mm-dd", 
                                           showOn: "both", buttonImage: "/icon-calendar.png", 
                                           buttonImageOnly: true});
  $(".datepicker_for_search_billed_date").datepicker({ constrainInput: true, dateFormat: "yy-mm-dd", 
                                           showOn: "both", buttonImage: "/icon-calendar.png", 
                                           buttonImageOnly: true});
  $('#users .pagination a').on('click', function () {  
    update_select_only = false;
    $.getScript(this.href);  
    return false;  
  }); 

  $("#clear_form").click( function() {
    $("#index_search_form input[type=text]").each(function() { $(this).val(''); }); 
  });

  $('#user_country').on('change',  function(){
    country = $('#user_country').val();
    update_select_only = true;
    $.get(this.action, { country_code:country, only_select:update_select_only }, null, 'script'); 
  })

};

function fetch_maketing_client_form(){
  if ($("#club_marketing_tool_client").val().length != 0) {
    $.ajax({
      type: 'GET',
      data: {id:club_id},
      url: '/partner/'+partner_prefix+'/clubs/'+$("#club_marketing_tool_client").val()+'/marketing_tool_attributes',
      success: function(data){
        $("#div_mkt_tool_attributes").empty();
        $("#div_mkt_tool_attributes").append(data);

        if(mkt_tool_errors.length != 0){
          mkt_tool_errors = mkt_tool_errors.split(",");
          for(index=0; index < mkt_tool_errors.length; index++){
            array = mkt_tool_errors[index].split(";");
            $('#div_marketing_tool_attributes_'+array[1]).append('<div id="error_inline" style="display:inline-block;"> '+ array[2].substring(0, array[2].length - 5) +' </div>');
          }
        }
      }
    });
  }
};

function clubs_form_functions(){
  $("#club_marketing_tool_client").change(function(){
    if($(this).val()!= ''){
      fetch_maketing_client_form(club_id, $(this).val());
    }else
      $("#div_mkt_tool_attributes").empty();
  })
};

function retrieve_information(){
  var skus = [];
  if ($('#kit_card_product_sku').is(':checked')) {
    skus.push("KIT-CARD");
  }
  if ($('#product_sku option:selected').text().length > 0) {
    skus.push($('#product_sku option:selected').text());
  }
  $('#user_product_sku').val(skus.join(','));

  data = {
    member:{  
      first_name: $("#user_first_name").val(),
      gender: $("#user_gender").val()=="" ? null : $("#user_gender").val(),
      address: $("#user_address").val(),
      country: $("#user_country").val(),
      state: $("#user_state").val(),
      last_name: $("#user_last_name").val(),
      city: $("#user_city").val(),
      zip: $("#user_zip").val(),
      birth_date: $("#user_birth_date").val(),
      phone_country_code: $("#user_phone_country_code").val(),
      phone_area_code: $("#user_phone_area_code").val(),
      phone_local_number: $("#user_phone_local_number").val(),
      type_of_phone_number: $("#user_type_of_phone_number").val(),
      terms_of_membership_id: $("#user_terms_of_membership_id").val(),
      manual_payment: $("#user_manual_payment").is(":checked") ? 1 : 0,
      email: $("#user_email").val(),
      external_id: $("#user_external_id").val()=="" ? null : $("#user_external_id").val(),
      product_sku: $('#user_product_sku').val(),
      enrollment_amount: $("#user_enrollment_amount").val(),
      mega_channel: $("#user_mega_channel").val(),
      campaign_medium: $("#user_campaign_medium").val(),
      landing_url: $("#user_landing_url").val(),
      referral_path: $("#user_referral_path").val(),
      ip_address: $("#user_ip_address").val(),
      campaign_description: $("#user_campaign_description").val(),
      member_group_type_id: $("#user_member_group_type_id").val()
    }
  }
  if( $("#user_credit_card_number").length > 0 ){
    var credit_card_params = {}
    credit_card_params["number"] = $("#user_credit_card_number").val(),
    credit_card_params["expire_month"] = $("#user_credit_card_expire_month").val(),
    credit_card_params["expire_year"] = $("#user_credit_card_expire_year").val(),
    data["member"]["credit_card"] = credit_card_params;
  }
  if( $("#setter_cc_blank").length > 0 )
    data["setter"] = { "cc_blank": $("#setter_cc_blank").is(":checked") ? 1 : 0 }
    
  if( $("#setter_wrong_phone_number").length > 0 )
    data["setter"] = { "wrong_phone_number": $("#setter_wrong_phone_number").is(":checked") ? 1 : 0 }

  return data
}

function payment_gateway_configuration_functions(){
  $('.help').popover({offset: 10});
}

function new_payment_gateway_configuration_functions(){
  if($('#payment_gateway_configuration_gateway').val() != 'litle'){
    $('#div_report_group').hide('fast');
    $('#div_descriptor_name').hide('fast');
    $('#div_descriptor_phone').hide('fast');
  };
  if($('#payment_gateway_configuration_gateway').val() != 'litle' && $('#payment_gateway_configuration_gateway').val() != 'mes'){
    $('#div_merchant_key').hide('fast');
  };
  
  $('#payment_gateway_configuration_gateway').change(function(){
    if($(this).val()!='litle'){
      $('#div_report_group').hide('fast');
      $('#div_descriptor_name').hide('fast');
      $('#div_descriptor_phone').hide('fast');
    }else{
      $('#div_report_group').show('fast');
      $('#div_descriptor_name').show('fast');
      $('#div_descriptor_phone').show('fast');
    }
    if($('#payment_gateway_configuration_gateway').val() != 'litle' && $('#payment_gateway_configuration_gateway').val() != 'mes'){
      $('#div_merchant_key').hide('fast');
    }else{
      $('#div_merchant_key').show('fast');
    };
  });

  $('form').submit( function(event) { 
    if(confirm(confirmationText)){
      if(!confirm(reConfirmationText)){
        event.preventDefault();
      }
    }else
      event.preventDefault();
  });
}

function new_user_functions(){
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
  $('#new_user').submit( function(event) {
    startAjaxLoader();
    $('#error_explanation').hide();
    $('#submit_button').attr('disabled', 'disabled');
    $('#cancel_button').hide();
    event.preventDefault();

    $.ajax({
      type: 'POST',
      dataType: 'json',
      contentType: 'application/json',
      url: "/api/v1/members",
      data: JSON.stringify(retrieve_information()),
      success: function(data) {
        endAjaxLoader();
        $('input').parent().parent().removeClass("error");
        if (data.code == 000) {
          alert (data.message);
          window.location.replace('../user/'+data.member_id);
        }else{
          $('#error_explanation').show();
          $('#error_explanation ul').empty();
          $('#submit_button').removeAttr('disabled');
          $('#cancel_button').show();
          $('#error_explanation ul').append("<b>"+data.message+"</b>");
          for (var key in data.errors){
            if (data.errors.hasOwnProperty(key)) {
              if (key != 'credit_card'){
                $('#user_'+key).parent().parent().addClass("error");
                $('#error_explanation ul').append("<li>"+key+': '+data.errors[key]+"</li>");
              }
              else{
                for (var key2 in data.errors[key]){
                  if (data.errors[key].hasOwnProperty(key2)){
                    if (key2 != 0){
                      $('#user_credit_card_'+key2).parent().parent().addClass("error");
                      $('#error_explanation ul').append("<li>"+key2+': '+data.errors[key][key2]+"</li>");                  
                    }
                  }
                } 
              }
            }
          }
        }
      },
      error: function(jqXHR, exception){
        endAjaxLoader();
        alert(global_ajax_error_messages(jqXHR));
        $('#submit_button').removeAttr('disabled');
        $('#cancel_button').show();
      }
    });
  });
  today = new Date()
  $('#setter_cc_blank').click(function(){
    if ($('#setter_cc_blank').attr('checked')) {
      $('#user_credit_card_number').val('0000000000');
      $('#user_credit_card_expire_month').val(today.getMonth() + 1);
      $('#user_credit_card_expire_year').val(today.getFullYear());
      $('#user_credit_card_number').attr('readonly', true);
      $('#user_credit_card_expire_month').attr('readonly', true);
      $('#user_credit_card_expire_year').attr('readonly', true);
    }else{
      $('#user_credit_card_number').val('');
      $('#user_credit_card_expire_month').val('');
      $('#user_credit_card_expire_year').val('');
      $('#user_credit_card_number').attr('readonly', false);
      $('#user_credit_card_expire_month').attr('readonly', false);
      $('#user_credit_card_expire_year').attr('readonly', false);
    }
  });  

  $('#zip_help').popover({offset: 10});
  $('.help').popover({offset: 10});
  
  $('#user_country').on('change',  function(){
    country = $('#user_country').val();
    $.get(this.action, { country_code:country }, null, 'script'); 
  });

  $("#user_terms_of_membership_id").change(function(){
    $.ajax({
      type: 'GET',
      url: "../subscription_plans/"+$(this).val()+"/resumed_information",
      success: function(data){
        $("#th_terms_of_memberships .help").attr("data-content", data);
      }
    });
  });
};

function edit_user_functions(){
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
    startAjaxLoader();
    $('#submit_button').attr('disabled', 'disabled');
    $('#cancel_button').hide();
    event.preventDefault();

    $.ajax({
      type: 'PUT',
      dataType: 'json',
      contentType: "application/json",
      url: "/api/v1/members/"+id,
      data: JSON.stringify(retrieve_information()),
      success: function(data) {
        endAjaxLoader();
        alert(data.message);
        $('input').parent().parent().removeClass("error");
        if (data.code == 000)
          window.location.replace('../'+id);
        else{
          $('#submit_button').removeAttr('disabled');
          $('#cancel_button').show();
          $('#error_explanation').show();
          $('#error_explanation ul').empty();
          $('#error_explanation ul').append("<b>"+data.message+"</b>");
          for (var key in data.errors){
            if (data.errors.hasOwnProperty(key)) {
              $('#user_'+key).parent().parent().addClass("error");
              $('#error_explanation ul').append("<li>"+key+': '+data.errors[key]+"</li>");
            }     
          }       
        }
      }
    });
  });

  $('.help').popover({offset: 10});

  $('#user_country').on('change',  function(){
    country = $('#user_country').val();
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
    startAjaxLoader();
    $('#submit_button').attr('disabled', 'disabled');
    $('#cancel_button').hide();
    event.preventDefault(); 
    $.ajax({
      type: 'POST',
      url: "/api/v1/members/"+id+"/club_cash_transaction",
      data: $("form").serialize(),
      success: function(data) {
        endAjaxLoader();
        if (data.code == 000){
          alert(data.message);
          window.location.replace('../'+id);
        }else{
          $('#submit_button').removeAttr("disabled");
          $('#cancel_button').show();
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

function sync_status_user_functions(column_count){
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

function operation_user_functions(column_count){
  oTable2 = $('#operations_table').dataTable({
    "oLanguage": {"sSearch": "Filtered by:"},
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "bootstrap",
  "sDom": '<"top"flp>rt<"bottom"i>',
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

function transactions_user_functions(column_count){
  $('#transactions_table').dataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": false,
    "sPaginationType": "bootstrap",
  "sDom": '<"top"flp>rt<"bottom"i>',
    "bServerSide": true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 1,2,3,4,5,6 ] }],
    "sAjaxSource": $('#transactions_table').data('source'),
  });
}

function memberships_user_functions(column_count){
  $('#memberships_table').dataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": false,
    "sPaginationType": "bootstrap",
  "sDom": '<"top"flp>rt<"bottom"i>',
    "bServerSide": true,
    "bLengthChange": false,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2,column_count-1 ] }],
    "sAjaxSource": $('#memberships_table').data('source')
  });
}

function fulfillment_files_functions() {
  $('#fulfillment_files_table').dataTable({
    "sPaginationType": "bootstrap",
    "sDom": '<"top"fp>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bSort": false,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "sAjaxSource": $('#fulfillment_files_table').data('source')
  });
  $('#fulfillment_files_table_filter').find('input').bind('input', function(event){
    if ( $(this).val() != $(this).val().replace(/[^\d]/,'')){
      $(this).val( $(this).val().replace(/[^\d]/,'') );
      event.preventDefault();
    }
  });
  $(".dataTables_paginate").css({ float: "left" });

  $("#mark_as_sent").live("click", function(event){
    if($(this).attr('disabled') == 'disabled'){
      event.preventDefault();
    }else{
    if(confirm("Are you sure you want to mark all the fulfillments that are in progress as sent?")){
        $(this).attr('disabled', 'disabled');
      }else{
        event.preventDefault();
      }
    }
  });
}  

function club_cash_transactions_functions(column_count){
  $('#club_cash_transactions_table').dataTable({
    "oLanguage": {"sSearch": "Filtered by:"},
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "bootstrap",
    "sDom": '<"top"flp>rt<"bottom"i>',
    "bServerSide": true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2 ] }],
    "sAjaxSource": $('#club_cash_transactions_table').data('source')
  });
}

function show_user_functions(){

  var objectsFetch = {transactions:true, notes:false, fulfillments:false, communications:false, operations:false, credit_cards:false, club_cash_transactions:false, memberships:false }

  $(".btn").on('click',function(event){
    if($(this).attr('disabled') == 'disabled')
      event.preventDefault(); 
  })

  $('.help').popover();
  mark_as_sent_fulfillment("../fulfillments/");
  resend_fulfillment("../fulfillments/");

  $.ajax({
    url: user_prefix+"/transactions_content",
      success: function(html){
        $(".tab-content #transactions .tab_body_padding div").remove();
        $(".tab-content #transactions .tab_body_padding").append(html);
      }
  })

  $(".nav-tabs li a").click(function(){
    var objects_to_search = $(this).attr("name");
    for(var key in objectsFetch){ 
      if(key == objects_to_search){
        if(!objectsFetch[objects_to_search]){
          startAjaxLoader();
          $.ajax({
            url: user_prefix+"/"+objects_to_search+"_content",
            success: function(html){
              $(".tab-content #"+objects_to_search+" .tab_body_padding").children().remove();
              $(".tab-content #"+objects_to_search+" .tab_body_padding").append(html);
              objectsFetch[objects_to_search] = true
            }
          });
          endAjaxLoader();
        }
      }
    }
    $(".tab-content .active").removeClass("active");
    $(".tab-content #"+objects_to_search+"").addClass("active");
  });
};

function user_cancellation_functions(){
  $("#user_cancelation_form").validate({
     submitHandler: function(form) {
      if (confirm('This user will be canceled. Are you really sure?')) {
        form.submit();            
      }else
      return false;
     }
  })
  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
};

function blacklist_user_functions(){
  $("form").validate({
     submitHandler: function(form) {
      if (confirm('This user will be blacklisted. Are you really sure?')) {
        form.submit();            
      } else {
        return false;
      }
    }
  })
}

function user_note_functions(){
  $('#new_user_note').validate();
};

function user_change_next_bill_date(){
  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd", showOn: "both", buttonImage: "/icon-calendar.png", buttonImageOnly: true});
};

function refund_user_functions(){
  $('form').submit( function(event) {
    $('input:submit').attr("disabled", true);
    if ($("#refunded_amount").val().match(/^[0-9 .]+$/)){
      
    }else{
      $('input:submit').attr("disabled", false);
      alert("Incorrect refund value.");
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
  $("#report_results").tablesorter({
    headers: { 
      0: { sorter: false }, 
      7: { sorter: false }, 
      8: { sorter: false } 
    } 
  }); 

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

function show_terms_of_membership_functions(){
  $('#return_btn').click( function(event){
    event.preventDefault();
    window.history.back();
  });
}

function save_the_sale_functions(){
  $('form').submit( function(event) {
  $('#save_the_sale_button').attr('disabled', 'disabled');
  $('#full_save_button').hide();
  $('#cancel_button').hide();
    startAjaxLoader();
  });
}

function recover_user_functions(){
  $('form').submit( function(event) {
  $('#recover_button').attr('disabled', 'disabled');
  $('#cancel_button').hide();
    startAjaxLoader();
  }); 
}

function admin_form_functions(){
  var count = 0;

  $('#add_new_club_role').live("click", function(event){
    var role_list = roles.split(",");
    var club_list = clubs.split(";");
    event.preventDefault();
    
    $("*[id$='_club_id'] option:selected").each( function(){
      index = club_list.indexOf($(this).text()+","+$(this).val());
      if(index >= 0)
        club_list.splice(index,1);
    });
    if(club_list.length == 0 || club_list == ""){
      alert("Cannot add more club roles. No more clubs available.")
    }else{
      count++;
      var options_for_role = "<option value=''> </option>"
      for (var i in role_list){
        options_for_role = options_for_role+"<option value='"+role_list[i]+"'>"+role_list[i]+"</option>" 
      };
      var options_for_club_id = ""
      for (var i in club_list){  
        club = club_list[i].split(',');
        options_for_club_id = options_for_club_id+"<option value='"+club[1]+"'>"+club[0]+"</option>"
      };
      $('#club_role_table').append("<tr id='tr_new_club_rol_["+count+"]'><td><select id='select_club_role_"+count+"' name='[club_roles_attributes]["+count+"][role]'>"+options_for_role+"</select></td><td><select id='select_club_role_"+count+"_club_id' name='[club_roles_attributes]["+count+"][club_id]'>"+options_for_club_id+"</select></td><td><input type='button' id='new_club_role_delete' name='"+count+"' class='btn btn-mini' value='Delete'></td></tr>")
    };

    $("*[id$='_club_id']").each(function() {
      $(this).data('lastValue', $(this).val());
    });
  });

  $("*[id^='agent_roles']").live("click", function(){
    $("#clear_global_role").show();
  });

  $("#clear_global_role").click(function(event){
    $("*[id^='agent_roles']").each(function(){
      $(this).attr('checked', false);
      event.preventDefault();
      $("#clear_global_role").hide();
    });
  });

  $("*[id$='_club_id']:not[:last]").live("change", function() {
    var name = $(this).attr("name");
    var lastRole = $(this).data('lastValue');
    var newRole = $(this).val();
    var success = true;

    $("*[id$='_club_id']").each( function(){
      if(newRole == $(this).val() && name != $(this).attr("name")){ 
        success = false;
      };
    });

    if(success){
      $(this).data('lastValue',newRole);
    }else{
      $(this).val(lastRole);
      alert("It has already been taken.")
    }
  });

  $("#new_club_role_delete").live("click", function(){
    if (confirm("Are you sure you want to delete this club role?")) {
      $("#club_role_table tr[id='tr_new_club_rol_["+$(this).attr('name')+"]']").remove();
      club_list = clubs.split(";");
    }
  });

  $("#club_role_edit").live("click", function(event){
    event.preventDefault();
    var role_list = roles.split(",");
    club_role_id = $(this).attr('name');
    var previous_role = $.trim($("#club_role_table tr td[id='td_club_role_role_"+club_role_id+"']").text());
    var options_for_role = "<option value='"+previous_role+"' selected>"+previous_role+"</option>"
    $("#club_role_table tr td[id='td_club_role_role_"+club_role_id+"']").empty();
    $("#club_role_table tr td[id='td_club_role_buttons_"+club_role_id+"'] #club_role_edit").remove();
    for (var i in role_list){
      if(role_list[i] != previous_role)
        options_for_role = options_for_role+"<option value='"+role_list[i]+"'>"+role_list[i]+"</option>"
    };
    $("#club_role_table tr td[id='td_club_role_role_"+club_role_id+"']").append("<select id='select_club_role_"+club_role_id+"' name='[club_roles_attributes]["+count+"][role]'>"+options_for_role+"</select>");
    $("#club_role_table tr td[id='td_club_role_buttons_"+club_role_id+"']").prepend("<input type='button' id='club_role_update' name='"+club_role_id+"' class='btn-primary btn-mini' value='Update'></td>");
  });   

  $("#club_role_update").live("click", function(event){
    event.preventDefault();
    if (confirm("Are you sure you want to update this club role?")) {
      var new_role = $("#select_club_role_"+$(this).attr('name')).val();
      var club_role_id = $(this).attr('name');
      $.ajax({
        type: "PUT",
        url: "/admin/agents/"+agent_id+"/update_club_role",
        data: { id:$(this).attr("name"), role:new_role },
        success: function(data){
          if(data.code == "000"){
            $("#club_role_table tr td[id='td_club_role_role_"+club_role_id+"']").empty();
            $("#club_role_table tr td[id='td_club_role_role_"+club_role_id+"']").append(new_role);
            $("#club_role_table tr td[id='td_club_role_buttons_"+club_role_id+"'] #club_role_update").remove();
            $("#club_role_table tr td[id='td_club_role_buttons_"+club_role_id+"']").prepend("<input type='button' id='club_role_edit' name='"+club_role_id+"' class='btn btn-mini' value='Edit'></td>");
            $("#td_notice").children().remove();
            $("#td_notice").append("<div class='alert-info alert'>"+data.message+"</div>");
          }else{
            $("#td_notice").children().remove();
            $("#td_notice").append("<div class='error-info alert'>"+data.message+"</div>");
          }
        },
      });
    } 
  });

  $("#club_role_delete").live("click", function(event){
    event.preventDefault();
    if (confirm("Are you sure you want to delete this club role?")) {
      array = $(this).attr('name').split(";");
      club_role_id = array[0]
      $.ajax({
        type: "PUT",
        url: "/admin/agents/"+agent_id+"/delete_club_role",
        data: { id:$(this).attr("name") },
        success: function(data){
          if(data.code == "000"){
            $("#club_role_table tr[id='tr_club_role_"+club_role_id+"']").remove();
            if(clubs.length == 0)
              clubs = array[2]+","+array[1];  
            else
              clubs = clubs+";"+array[2]+","+array[1];
            $("#td_notice").children().remove();
            $("#td_notice").append("<div class='alert-info alert'>"+data.message+"</div>");
          }else{
            $("#td_notice").children().remove();
            $("#td_notice").append("<div class='error-info alert'>"+data.message+"</div>");
          }
        },
      });
    }
  });

  $("input[name='commit']").click(function(event){
    if($("#club_role_update").length > 0){
      if(!confirm("You have unsaved roles, are you sure you want to proceed? Role's changes will be lost."))
        event.preventDefault();
    }
  })
};


// TOM Wizard functions
// Creates the wizard
function new_tom_functions() {
  $('.help').popover({offset: 10});
  tom_create_wizard();
}

function tom_create_wizard() {
  $("#tom_wizard_form").formwizard({ 
    formPluginEnabled: false,
    validationEnabled: true,
    validationOptions:{
      errorPlacement: function(error, element) {
        $("label[for="+error.attr("for")+"][generated=true]").each(function(){
          if($(this).text() == error.text() || $(this).text() != error.text()){
            $(this).remove();
          }
        })
        error.removeClass("error");
        error.appendTo($("#"+$(element).attr("id")).parent());
      },
      success: function(error){
        $("label[for="+error.attr("for")+"][generated=true]").each(function(){
          $(this).remove();
        })
      }
    },
    focusFirstInput : true,
    disableUIStyles: true,
    textNext: '',
    textSubmit: ''
  });
}

// // Communications
function switch_days_after_join_date() {
  if ($("#email_template_template_type").val() == 'pillar') {
    $("#control_group_days_after_join_date").show(100);
  }
  else {
   $("#control_group_days_after_join_date").hide(100); 
   $("#email_template_days_after_join_date").val(1);
  }
}

function email_templates_functions() {
  $('.help').popover({offset: 10});

  $("#email_template_template_type").change(function() {
    switch_days_after_join_date();
  });

  $("#et_form").submit(function(event) {
    var isValid = true;
    $('form input[type="text"], form select').each(function() {
      if($(this).hasClass('manual_validation')) {
        $('#control_'+$(this).attr('id')+' div[id="error_inline"]').remove();
        if ($.trim($(this).val()) == '') {
          isValid = false;
          $('#control_'+$(this).attr('id')).append('<div id="error_inline" style="display:inline-block;"> can\'t be blank </div>');
        }
      }
    });
    if (isValid == false) event.preventDefault();
  });
}

function email_templates_table_index_functions(column_count) {
  $('#email_templates_table').dataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": true,
    "sPaginationType": "bootstrap",
    "sDom": '<"top"lf>rt<"bottom"pi>',
    "bServerSide": true,
    "bLengthChange": false,
    'bSortable':true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count ] }],
    "sAjaxSource": $('#email_templates_table').data('source')
  });
}

function test_communications_functions() {
  $('#test_communication').submit(function(event){ event.preventDefault() });
  $("#communications_table a").live("click", function(event){
    if($("#test_communication").valid()){
      event.preventDefault();
      is_processing = false;
      $("#communications_table a").each( function(){
        if($(this).attr('disabled') == 'disabled')
          is_processing = true;
      });
      if(is_processing == false){
        button = $(this)
        user_id = $("#user_id").val();
        template_id = button.attr('name');
        button.attr('disabled', 'disabled');
        startAjaxLoader();
        $.ajax({
          type: "POST",
          url: "",
          data: { email_template_id:template_id, user_id:user_id },
          success: function(data){
            button.parent().next().empty();
            if (data.code == "000"){
              button.parent().next().append("<div class='alert-info alert'>Successfully send</div>");
            }else{
              button.parent().next().append("<div class='error-info alert'>"+data.message+"</div>");
            };
            endAjaxLoader();
            button.removeAttr("disabled");
          },
        })
      }
    }
  });
}
