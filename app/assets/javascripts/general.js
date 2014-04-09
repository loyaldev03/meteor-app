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
        if (jqXHR.status == 0) {
          alert('The operation is taking more than expected. Please wait a moment while we finish processing this request and check if it was done.');
          endAjaxLoader();
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
  $("#blocker").show();
  $("#ajax_loader").slideDown("slow");
};

function endAjaxLoader(){
  $("#blocker").hide();
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

function member_index_functions(){
  $('#index_search_form').submit(function (event){
    var atLeastOneFilled = false;
    $('form :text, form select').each( function(){
      if($(this).val() != "")
        atLeastOneFilled = true;
    });
    $('form :checkbox').each( function(){
      if($(this).is(":checked"))
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
        url: "members/search_result",
        dataType: 'script',
        contentType: 'application/javascript',
        data: $(this).serialize(),
        success: function(data){
          endAjaxLoader();
          $('#submit_button').removeAttr('disabled');
        },
        error: function(jqXHR, exception){
          if (jqXHR.status == 0) {
            alert('The search is talking more than expected. Please, try again in a moment.');
            endAjaxLoader();
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

function retrieve_information(){
  var skus = [];
  if ($('#kit_card_product_sku').is(':checked')) {
    skus.push("KIT-CARD");
  }
  if ($('#product_sku option:selected').text().length > 0) {
    skus.push($('#product_sku option:selected').text());
  }
  $('#member_product_sku').val(skus.join(','));

  data = {
    member:{  
      first_name: $("#member_first_name").val(),
      gender: $("#member_gender").val()=="" ? null : $("#member_gender").val(),
      address: $("#member_address").val(),
      country: $("#member_country").val(),
      state: $("#member_state").val(),
      last_name: $("#member_last_name").val(),
      city: $("#member_city").val(),
      zip: $("#member_zip").val(),
      birth_date: $("#member_birth_date").val(),
      phone_country_code: $("#member_phone_country_code").val(),
      phone_area_code: $("#member_phone_area_code").val(),
      phone_local_number: $("#member_phone_local_number").val(),
      type_of_phone_number: $("#member_type_of_phone_number").val(),
      terms_of_membership_id: $("#member_terms_of_membership_id").val(),
      manual_payment: $("#member_manual_payment").is(":checked") ? 1 : 0,
      email: $("#member_email").val(),
      external_id: $("#member_external_id").val()=="" ? null : $("#member_external_id").val(),
      product_sku: $('#member_product_sku').val(),
      enrollment_amount: $("#member_enrollment_amount").val(),
      mega_channel: $("#member_mega_channel").val(),
      campaign_medium: $("#member_campaign_medium").val(),
      landing_url: $("#member_landing_url").val(),
      referral_path: $("#member_referral_path").val(),
      ip_address: $("#member_ip_address").val(),
      campaign_description: $("#member_campaign_description").val(),
      member_group_type_id: $("#member_member_group_type_id").val()
    }
  }
  if( $("#member_credit_card_number").length > 0 ){
    var credit_card_params = {}
    credit_card_params["number"] = $("#member_credit_card_number").val(),
    credit_card_params["expire_month"] = $("#member_credit_card_expire_month").val(),
    credit_card_params["expire_year"] = $("#member_credit_card_expire_year").val(),
    data["member"]["credit_card"] = credit_card_params;
  }
  if( $("#setter_cc_blank").length > 0 )
    data["setter"] = { "cc_blank": $("#setter_cc_blank").is(":checked") ? 1 : 0 }
    
  if( $("#setter_wrong_phone_number").length > 0 )
    data["setter"] = { "wrong_phone_number": $("#setter_wrong_phone_number").is(":checked") ? 1 : 0 }

  return data
}

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
          window.location.replace('../member/'+data.member_id);
        }else{
          $('#error_explanation').show();
          $('#error_explanation ul').empty();
          $('#submit_button').removeAttr('disabled');
          $('#cancel_button').show();
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
  });

  $("#member_terms_of_membership_id").change(function(){
    $.ajax({
      type: 'GET',
      url: "../subscription_plans/"+$(this).val()+"/resumed_information",
      success: function(data){
        $("#th_terms_of_memberships .help").attr("data-content", data);
      }
    });
  });
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

function transactions_member_functions(column_count){
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

function memberships_member_functions(column_count){
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

function show_member_functions(){

  var objectsFetch = {transactions:true, notes:false, fulfillments:false, communications:false, operations:false, credit_cards:false, club_cash_transactions:false, memberships:false }

  $(".btn").on('click',function(event){
    if($(this).attr('disabled') == 'disabled')
      event.preventDefault(); 
  })

  $('.help').popover();
  mark_as_sent_fulfillment("../fulfillments/");
  resend_fulfillment("../fulfillments/");

  $.ajax({
    url: member_prefix+"/transactions_content",
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
            url: member_prefix+"/"+objects_to_search+"_content",
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
      } else {
        return false;
      }
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

function fulfillments_index_functions(create_xls_file_url, make_report_url, fulfillment_file_cant_be_empty_message, settings_kit_card_product, settings_others_product, error_message){
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
    var ff_id = "";
    for (x in fuls) {
      $('<input>').attr({ type: 'hidden', name: fuls[x].name, value: fuls[x].value }).appendTo($('#fulfillment_report_form'));
    }
    if (fuls.length != 0) {
      set_product_type_at_fulfillments_index(settings_kit_card_product, settings_others_product)
      $('#fulfillment_report_form').attr("action", create_xls_file_url);
      startAjaxLoader();
      $.ajax({
        type: "POST",
        async: false,
        url: "fulfillments/generate_xls",
        data: $('#fulfillment_report_form').serialize(),
        success: function(data){
          if(data.code == "500"){
            endAjaxLoader();
            $(".container .content").prepend("<div class='alert-error alert'>"+data.message+"</div>");
          }else{
            ff_id = data.fulfillment_file_id;
            alert(data.message);
          }
        }
      });
      if(ff_id != ""){
        var counter = 0;
        var timer = $.timer(function() {
          counter++;
          $.ajax({
            type: "GET",
            url: "fulfillments/files/"+ff_id+"/check_if_is_in_process ",
            data: $('#fulfillment_report_form').serialize(),
            success: function(data){
              if(data.code == "000"){
                alert("Fulfillment File creation proccess finished successfully.");
                $("#report_results").remove();
                $(".container .content").prepend("<div class='alert-info alert'>"+data.message+"</div>");
                timer.stop();  
                endAjaxLoader();
              }
            }
          });
          if(counter == 30){
            timer.stop();  
            endAjaxLoader();
            alert("It is taking more than expected. Wait a little longer and if you do not see the fulfillment file created, contact IT crew, please.");
          }
        });
        timer.set({ time : 20000, autostart : true });
      }
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

function recover_member_functions(){
  $('form').submit( function(event) {
  $('#recover_button').attr('disabled', 'disabled');
  $('#cancel_button').hide();
    startAjaxLoader();
  }); 
}

function admin_form_functions(){
  var count = 0;
  var club_list = clubs.split(";");
  var role_list = roles.split(",");

  $('#add_new_club_role').live("click", function(event){
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
      $('#club_role_table').append("<tr id='tr_club_rol_["+count+"]'><td><select id='club_roles_attributes_"+count+"_role' name='[club_roles_attributes]["+count+"][role]'>"+options_for_role+"</select></td><td><select id='club_roles_attributes_"+count+"_club_id' name='[club_roles_attributes]["+count+"][club_id]'>"+options_for_club_id+"</select></td><td><input type='button' id='club_role_delete' name='"+count+"' class='btn btn-mini' value='Delete'></td></tr>")
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

  $("#club_role_delete").live("click", function(){
    if (confirm("Are you sure you want to delete this club role?")) {
      $("#club_role_table tr[id='tr_club_rol_["+$(this).attr('name')+"]']").remove();
      club_list = clubs.split(";");
    }
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