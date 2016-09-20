$(document).ready( function() {
  $('.help').popover({offset: 10, trigger: 'hover', html: true });

  dataConfirmModal.setDefaults({
    title: 'Confirm your action',
    commit: 'Confirm',
    cancel: 'Cancel'
  });

  $('.datatable').DataTable({
    "sDom": "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
    "sPaginationType": "full_numbers"
  });

  $(".readonly").keydown(function(event){
    event.preventDefault();
  });

  $('.datatable_only_sorting').DataTable({
    "sDom": "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
    "sPaginationType": "full_numbers",
    "bLengthChange": false,
    "bFilter": false,
    "bSort": true,
    "bInfo": false,
    "bAutoWidth": false,
    "aaSorting": [[ 0, "desc" ]]
  });

  $(".alert").alert();

  $(".datepicker").datepicker('option', { buttonImage: "/icon-calendar.png", showOn: "both", buttonImageOnly: true })

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
        endAjaxLoader(true);
        if (jqXHR.status == 0) {
          alert('The operation is taking more than expected. Please wait a moment while we finish processing this request and check if it was done.');
        }else
          alert(global_ajax_error_messages(jqXHR));
      },
      timeout: 200000
    });
  });
});

function disable_form_buttons_upon_submition(form_id){
  $('#'+form_id).submit(function(){
    startAjaxLoader(true);
  })  
}

function flash_message(message, error){
  message_type = error ? "alert-error" : "alert-info"
  $(".container .row:first .alert").remove();
  $(".container .row:first").prepend("<div class='alert "+message_type+"'><a class='close' data-dismiss='alert'>×</a><p>"+message+"</p></div>");
}

function global_ajax_error_messages(jqXHR){
  if (jqXHR.status == 401)
    return 'Agent is not authorized to make this request.';
  else if (jqXHR.status == 500)
    return 'Unexpected error, a ticket has been submitted.';
  else
    return 'Something went wrong.'
}

function startAjaxLoader(disableButtons){
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
  if(disableButtons) {
    $("#ajax_loader").append(spinner.el);
    $("#ajax_loader").slideDown("slow");
    $('.content :submit, .content :button, .content a').addClass('disabled');
  };
};

function endAjaxLoader(enableButtons){
  if(enableButtons){
    $("#ajax_loader").slideUp();
    $('.spinner').remove();
    $('.content :submit, .content :button, .content a').removeClass('disabled');
  };
};

function agent_index_functions(column_count){
  $('#agents_table').DataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "full_numbers",
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
  $('#partners_table').DataTable({
    "sPaginationType": "full_numbers",
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
  $('#clubs_table').DataTable({
    "sPaginationType": "full_numbers",
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
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      if(aData[4] == 'Disabled'){ $('td', nRow).closest('tr').removeClass('even odd').addClass('alert'); }
    }
  });
}

function campaign_days_functions(column_count){
  var oTable2 = $('#campaign_days_table').DataTable({
    "sPaginationType": "full_numbers",
    "sDom": '<"top"p>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "bResetDisplay": false,
    "aaSorting": [[ 1, "asc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 3,4,5,6 ] }],
    "sAjaxSource": $('#campaign_days_table').data('source')
  });

  $('#campaign_days_table_wrapper .top').prepend($("#dataTableSelect"));
  $("#search_transport").change( function () {
    oTable2.search( $(this).val() ).draw();
  });

  $('#campaign_days_table').on("click",'a[data-toggle="custom-remote-modal"]', function(event){
    event.preventDefault();

    var targetModal = '#campaignDayEditModal';
    $('#campaignDayEditModal .modal-header h3').remove();
    $('#campaignDayEditModal .modal-header').append("<h3> Update Campaign Day "+$(this).data('date')+"</h3>");
    $('#campaignDayEditModal .modal-body').load($(this).attr('href'), function(e) {
      $('#campaignDayEditModal').modal('show');
    });
  });
  $('#campaignDayEditModal').on('submit', '.modal-body form', function(event){
    event.preventDefault();
    startAjaxLoader(true);
    var campaignDayId = $(this).data('target');
    $.ajax({
      type: 'put',
      url: $(this).attr('action'),
      data: $(this).serialize(),
      success: function(data){
        endAjaxLoader(true);
        if(data.success == true){
          $("#campaign_days_table").DataTable().ajax.reload(null, false);
          $('#campaignDayEditModal').modal('hide');
          flash_message(data.message, false)
        }else{
          $('#campaignDayEditModal').modal('hide');
          flash_message(data.message, true)
        }
      },
      error: function(jqXHR, exception){
        endAjaxLoader(true);
        alert(global_ajax_error_messages(jqXHR));
      }
    })
  });
}

function delay_jobs_index_functions(column_count){
  $('#delayed_jobs_table').DataTable({
    "sPaginationType": "full_numbers",
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
  $('#disposition_types_table').DataTable({
    "sPaginationType": "full_numbers",
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
  $('#my_clubs_table').DataTable({
    "sPaginationType": "full_numbers",
    "sDom": '<"top"fp>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "aaSorting": [[ 0, "asc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count, column_count+1 ] },
                     { "sWidth": "360px", "aTargets": [ column_count+1 ] }],
    "sAjaxSource": $('#my_clubs_table').data('source'),
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      if(aData[4] == 'Disabled'){ $('td', nRow).closest('tr').removeClass('even odd').addClass('alert'); }
    }
  });
}
function domain_index_functions(column_count){
  $('#domains_table').DataTable({
    "sPaginationType": "full_numbers",
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
  $('#products_table').DataTable({
    "sPaginationType": "full_numbers",
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
  $('#products_table').on("click",'a[data-toggle="custom-remote-modal"]', function(event){
    event.preventDefault();
    var targetModal = '#myModal'+ $(this).data('target');
    $(targetModal + ' .modal-body').load($(this).attr('href'), function(e) {
      $(targetModal).modal('show');
      $('.help').popover({offset: 10, trigger: 'hover', html: true });
    });
  });
  $('#products_table').on('click', '.modal-footer input[type="submit"]', function(){
    $('#edit_product_'+$(this).data('target')).submit();
  });
  $('#products_table').on('submit', '.modal-body form', function(event){
    event.preventDefault();
    startAjaxLoader(true);
    var productId = $(this).data('target');
    $.ajax({
      type: 'put',
      url: $(this).attr('action'),
      data: $(this).serialize(),
      success: function(data){
        endAjaxLoader(true);
        if(data.success == true){
          $("#products_table").DataTable().ajax.reload();
          $('#myModal'+productId).modal('hide');
          flash_message("Product ID "+productId+" was updated successfully.", false)
        }else{
          $("#edit_product_"+productId+" span[data-type='errors']").remove()
          $("#edit_product_"+productId+" .control-group").removeClass("error")
          for (var key in data.errors){
            $('#edit_product_'+productId+' #product_'+key).parents(".control-group").addClass("error")
            $('#edit_product_'+productId+' #product_'+key).parent().append("<span class='help-inline' data-type='errors'>"+data.errors[key]+"</span>")
          }
        }
      },
      error: function(jqXHR, exception){
        endAjaxLoader(true);
        alert(global_ajax_error_messages(jqXHR));
      }
    })
  });
}

function bulk_process_products_functions(){
  $("#bulk_process_submit").click(function(event){
    event.preventDefault();
    if($("#bulk_process_file").prop('files').length == 0){
      alert("No file provided for to bulk update products.");
    }else{
      if($("#bulk_process_file").prop('files')[0].size > 1002867){
        alert("File exceeds maximum size limit.");
      }else{
        startAjaxLoader(true);
        $("#bulk_process_form").submit();
      }
    }
  });
}

function terms_of_memberships_table_index_functions(column_count) {
  $('#terms_of_memberships_table').DataTable({
    "sPaginationType": "full_numbers",
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

function user_index_functions(){
  $('#index_search_form').submit(function (event){
    var atLeastOneFilled = false;
    $('#index_search_form input[name!="utf8"], #index_search_form select').each( function(){
      if($(this).val() != "")
        atLeastOneFilled = true;
    });
    if(atLeastOneFilled == false){
      alert("No filters selected.");
      event.preventDefault(); 
    }else{
      startAjaxLoader(true);
      update_select_only = false;

    $.ajax({
        type: "GET",
        url: window.location.pathname.match("search_result") ? window.location.pathname : "users/search_result",
        dataType: 'script',
        contentType: 'application/javascript',
        data: $(this).serialize(),
        success: function(data){
          endAjaxLoader(true);
        },
        error: function(jqXHR, exception){
          endAjaxLoader(true);
          if (jqXHR.status == 0) {
            alert('The search is talking more than expected. Please, try again in a moment.');
          }else
            global_ajax_error_messages(jqXHR);
        }
      });
      return false;
    }
  });

  $('#users .pagination a').on('click', function () {  
    update_select_only = false;
    $.getScript(this.href);  
    return false;  
  }); 

  $("#clear_form").click( function(event) {
    $("#index_search_form input[type=text]").each(function() { $(this).val(''); }); 
    $("select option[value='']").each(function() { $(this).attr('selected', true); ; });
    $("#user_state option[value!='']").remove();
    event.preventDefault();
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
      utm_campaign: $("#user_utm_campaign").val(),
      utm_medium: $("#user_utm_medium").val(),
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
}

function new_payment_gateway_configuration_functions(){
  if($('#payment_gateway_configuration_gateway').val() != 'litle'){
    $('#div_report_group').hide('fast');
    $('#div_descriptor_name').hide('fast');
    $('#div_descriptor_phone').hide('fast');
    $('#div_merchant_key').hide('fast');
  };  
  if($('#payment_gateway_configuration_gateway').val() == 'stripe'){
    $('#div_aus_login').hide('fast');
    $('#div_aus_password').hide('fast');
  }
  
  $('#payment_gateway_configuration_gateway').change(function(){
    if($(this).val()!='litle'){
      $('#div_report_group').hide('fast');
      $('#div_descriptor_name').hide('fast');
      $('#div_descriptor_phone').hide('fast');
      $('#div_merchant_key').hide('fast');
    }else{
      $('#div_report_group').show('fast');
      $('#div_descriptor_name').show('fast');
      $('#div_descriptor_phone').show('fast');
      $('#div_merchant_key').show('fast');
    }
    if($(this).val()=='stripe'){
      $('#div_aus_login').hide('fast');
      $('#div_aus_password').hide('fast');
    }else{
      $('#div_aus_login').show('fast');
      $('#div_aus_password').show('fast');
    }
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
                                changeMonth: true,
                                changeYear: true,
                                yearRange: 'c-100:c'});
  $('#new_user').submit( function(event) {
    startAjaxLoader(true);
    $('#error_explanation').hide();
    event.preventDefault();

    $.ajax({
      type: 'POST',
      dataType: 'json',
      contentType: 'application/json',
      url: "/api/v1/members",
      data: JSON.stringify(retrieve_information()),
      success: function(data) {
        endAjaxLoader(true);
        $('input').parent().parent().removeClass("error");
        if (data.code == 000) {
          alert (data.message);
          window.location.replace('../user/'+data.member_id);
        }else{
          $('#error_explanation').show();
          $('#error_explanation ul').empty();
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
        endAjaxLoader(true);
        alert(global_ajax_error_messages(jqXHR));
      }
    });
  });
  today = new Date()
  $('#setter_cc_blank').click(function(){
    if ($('#setter_cc_blank').prop('checked')) {
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
        $("#th_terms_of_memberships .help").data('popover').options['content'] = data;
      }
    });
  });
};

function edit_user_functions(){
  $('#error_explanation').hide();
  $(".datepicker").datepicker({ constrainInput: true, 
                                maxDate: 0, 
                                dateFormat: "yy-mm-dd",
                                changeMonth: true,
                                changeYear: true,
                                yearRange: 'c-100:c'});    

  $('form').submit( function(event) {
    startAjaxLoader(true);
    event.preventDefault();

    $.ajax({
      type: 'PUT',
      dataType: 'json',
      contentType: "application/json",
      url: "/api/v1/members/"+id,
      data: JSON.stringify(retrieve_information()),
      success: function(data) {
        endAjaxLoader(true);
        alert(data.message);
        $('input').parent().parent().removeClass("error");
        if (data.code == 000)
          window.location.replace('../'+id);
        else{
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
    startAjaxLoader(true);
    event.preventDefault(); 
    $.ajax({
      type: 'POST',
      url: "/api/v1/members/"+id+"/club_cash_transaction",
      data: $("form").serialize(),
      success: function(data) {
        endAjaxLoader(true);
        if (data.code == 000){
          alert(data.message);
          window.location.replace('../'+id);
        }else{
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
  oTable2 = $('#operations_table').DataTable({
    "oLanguage": {"sSearch": "Filtered by:"},
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "full_numbers",
    "sDom": '<"top"p>rt<"bottom"li>',
    "bServerSide": true,
    "aaSorting": [[ 1, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ column_count, column_count+1 ] }],
    "sAjaxSource": $('#operations_table').data('source'),
  });

  $('#operations_table_wrapper .top').prepend($("#dataTableSelect"));
  $(".dataselect").change( function () {
      oTable2.search( $(this).val() ).draw();
  });
};

function transactions_user_functions(column_count){
  $('#transactions_table').DataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": false,
    "sPaginationType": "full_numbers",
    "sDom": '<"top"fp>rt<"bottom"li>',
    "bServerSide": true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 1,2,3,4,5,6 ] }],
    "sAjaxSource": $('#transactions_table').data('source'),
  });
}

function memberships_user_functions(column_count){
  $('#memberships_table').DataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": false,
    "sPaginationType": "full_numbers",
  "sDom": '<"top"flp>rt<"bottom"i>',
    "bServerSide": true,
    "bLengthChange": false,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2,column_count-1 ] }],
    "sAjaxSource": $('#memberships_table').data('source')
  });
}

function fulfillment_files_functions() {
  $('#fulfillment_files_table').DataTable({
    "sPaginationType": "full_numbers",
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

  $("#fulfillment_files_table").on('confirm:complete', '#mark_as_sent', function(event){
    startAjaxLoader(true);
    window.location.href = $(this).attr('href');
  });
}  

function campaigns_functions(){
  $('#campaigns_table').DataTable({
    "sPaginationType": "full_numbers",
    "sDom": '<"top"fp>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 6 ] }],
    "sAjaxSource": $('#campaigns_table').data('source')
  });  
}


function campaignFormFunctions(){
  if ($('#edit_campaign').length) {
    $(".datepicker").datepicker({ constrainInput: true, dateFormat: "yy-mm-dd" });
    disableFields();
    if(canEditTransportId) {
      $('#campaign_transport_campaign_id').prop('disabled', false);
    } 
  }
  else {
    $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd" });
    $("#campaign_terms_of_membership_id").select2({
      ajax: {
        url: getSubscriptionPlansUrl,
        dataType: 'json',
        type: "GET",
        delay: 250,
        quietMillis: 50,
        data: function(params) { return { club_id: clubId, query: params.term, }; },
        processResults: function(data) { return { results: data }; }
      },
      minimumInputLength: 2,
      placeholder: placeholderText,
      theme: "bootstrap"
    });
    $("#campaign_campaign_code").select2({
      ajax: {
        url: getFulfillmentCodesUrl,
        dataType: 'json',
        type: "GET",
        delay: 250,
        quietMillis: 50,
        data: function(params) { return { club_id: clubId, query: params.term, }; },
        processResults: function(data) { return { results: data }; }
      },
      minimumInputLength: 2,
      placeholder: placeholderTextFulfillmentCodes,
      allowClear: true,
      theme: "bootstrap"
    });
    $("#campaign_campaign_type").select2({
      theme: "bootstrap"
    });
    $("#campaign_transport").select2({
      theme: "bootstrap"
    });
  }
  
  function disableFields() {
    var fieldsToDisable = [
      'landing_name',
      'terms_of_membership_id', 
      'enrollment_price', 
      'campaign_type',
      'transport',
      'audience',
      'utm_content',
      'transport_campaign_id',
      'campaign_code'
    ];
    $.each(fieldsToDisable, function(index, field) {
      $('#campaign_' + field).prop('disabled', true);
    });
  }

  $('#campaign_transport').change(function() {
    setCampaignMedium($('#campaign_transport').val());
  });
  function setCampaignMedium(transport_type) {
    var medium = '';
    switch(transport_type) {
      case 'facebook':
      case 'twitter':
        medium = 'display';
        break;
      case 'mailchimp':
        medium = 'email';
        break;
      case 'adwords':
        medium = 'search';
        break;
    }
    $('#campaign_utm_medium').val(medium);
  }
  $(".select2-container").css('display', 'inline-block');
}


function transportSettingsIndexFunctions() {
  $('#transport_settings_table').DataTable({
    "sPaginationType": "full_numbers",
    "sDom": '<"top"fp>rt<"bottom"il>',
    "bJQueryUI": false,
    "bProcessing": true,
    "bServerSide": true,
    "bLengthChange": false,
    "iDisplayLength": 25,
    "bFilter": false,
    "bInfo": false,
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2 ] }],
    "sAjaxSource": $('#transport_settings_table').data('source')
  }); 
}


function transportSettingsFormFunctions() {
  $("#transport_setting_transport").change(function() {
    var transport = $("#transport_setting_transport").val();
    assignRequiredTagToFields(transport);
    showSettingsPane(transport);
  });

  function showSettingsPane(transport) {
    if(!transport) transport = $("#transport_setting_transport").val();
    transport == "facebook" ? $("#transport_settings_values_facebook").show() : $("#transport_settings_values_facebook").hide();
    transport == "mailchimp" ? $("#transport_settings_values_mailchimp").show() : $("#transport_settings_values_mailchimp").hide();
  }

  function assignRequiredTagToFields(transport) {
    var fields = [
      'client_id', 
      'client_secret', 
      'access_token',
      'api_key'
    ];
    $.each(fields, function(index, field) {
      $('#transport_setting_' + field).prop('required', false);
    });
    
    switch(transport) {
      case 'facebook':
        $('#transport_setting_client_id').prop('required', true);
        $('#transport_setting_client_secret').prop('required', true);
        $('#transport_setting_access_token').prop('required', true);
        break;
      case 'mailchimp':
        $('#transport_setting_api_key').prop('required', true);
        break;
    }
  }

  if(!transport && $("#transport_setting_transport").length > 0) {
    transport = $("#transport_setting_transport").val();
  }

  showSettingsPane(transport);
  assignRequiredTagToFields(transport);
}


function club_cash_transactions_functions(column_count){
  $('#club_cash_transactions_table').DataTable({
    "oLanguage": {"sSearch": "Filtered by:"},
    "bJQueryUI": false,
    "bProcessing": true,
    "sPaginationType": "full_numbers",
    "sDom": '<"top"fp>rt<"bottom"li>',
    "bServerSide": true,
    "aaSorting": [[ 0, "desc" ]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ 2 ] }],
    "sAjaxSource": $('#club_cash_transactions_table').data('source')
  });
}

function show_user_functions(){

  var objectsFetch = {transactions:true, notes:false, fulfillments:false, communications:false, operations:false, credit_cards:false, club_cash_transactions:false, memberships:false }

  // $(".btn").on('click',function(event){
  //   if($(this).attr('disabled') == 'disabled')
  //     event.preventDefault(); 
  // })

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
          startAjaxLoader(false);
          $.ajax({
            url: user_prefix+"/"+objects_to_search+"_content",
            success: function(html){
              $(".tab-content #"+objects_to_search+" .tab_body_padding").children().remove();
              $(".tab-content #"+objects_to_search+" .tab_body_padding").append(html);
              objectsFetch[objects_to_search] = true
            }
          });
          endAjaxLoader(false);
        }
      }
    }
    $(".tab-content .active").removeClass("active");
    $(".tab-content #"+objects_to_search+"").addClass("active");
  });
  $('#marketing_sync_table').on('confirm:complete', '#sync_to_remote', function(event){
    startAjaxLoader(true);
  });
  $('#td_mi_future_tom_change').on('click', '#remove_future_tom_change', function(event){
    $('#myModalFutureTomChange').modal('hide');
  });
  $('#td_mi_future_tom_change').on('confirm:complete', '#remove_future_tom_change', function(event, response, response2){
    if(response)
      startAjaxLoader(true);
  });
};

function user_cancellation_functions(){
  disable_form_buttons_upon_submition('user_cancelation_form');
  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd" });
};

function user_change_next_bill_date(){
  disable_form_buttons_upon_submition('user_change_next_bill_date_form');
  $(".datepicker").datepicker({ constrainInput: true, minDate: 1, dateFormat: "yy-mm-dd" });
};

function user_save_the_sale_functions(){
  disable_form_buttons_upon_submition('save_the_sale_form')  
  $(".datepicker").datepicker({ constrainInput: true, minDate: 0, dateFormat: "yy-mm-dd" });
}

function chargeback_user_functions(){
  $('#chargeback_form').submit( function(event) {
    if($("#amount").val().match(/^[0-9 .]+$/)){
      startAjaxLoader(true);
    }else{
      alert("Incorrect chargeback value.");
      event.preventDefault(); 
    };
  })

  $("#adjudication_date").datepicker({ constrainInput: true, 
                                maxDate: 0, 
                                dateFormat: "yy-mm-dd",
                                changeMonth: true,
                                changeYear: true,
                                yearRange: 'c-100:c'});
}

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
      var box = $(this); 
      $.ajax({
        type: 'PUT',
        url: $(this).data('url'),
        data: { new_status: $('#new_status').val(), reason: $('#reason').val(), file: $('#fulfillment_file').val() },
        dataType: 'json',
        success: function(data) {
          if (data.code == "000"){
            box.attr("checked", false)
            $("#div_fulfillment_selected_"+data.id).parent().children().hide();
            $("#div_fulfillment_selected_"+data.id).parent().append("<div class='alert-info alert'>"+data.message+"</div>")
          }else{
            alert(data.message);
            $("#div_fulfillment_selected_"+data.id+" div").remove();
            $("#div_fulfillment_selected_"+data.id).append("<div class='error-info alert'>"+data.message+"</div>")
          };
        },
      });  
    });
    }
  });     
}

function set_product_filter_at_fulfillments_index(settings_others_product) {
  var radio_product_filter = $('[name=radio_product_filter]:checked');
  if (radio_product_filter.val() == 'all') {
    $('#product_filter').val(radio_product_filter.val());
  }else if (radio_product_filter.val() == "sku") {
    $('#product_filter').val($('#input_product_filter').val());
  }else{
    $('#product_filter').val($('#input_product_package').val());
  }
}

function fulfillments_index_functions(create_xls_file_url, make_report_url, fulfillment_file_cant_be_empty_message, settings_others_product){
  $("#report_results").tablesorter({
    headers: { 
      0: { sorter: false }, 
      7: { sorter: false }, 
      8: { sorter: false } 
    } 
  }); 

  $(".datepicker").datepicker({ constrainInput: true, 
                                dateFormat: "yy-mm-dd" });
  
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
      set_product_filter_at_fulfillments_index(settings_others_product)
      $('#fulfillment_report_form').attr("action", create_xls_file_url);
      $('#fulfillment_report_form').submit();
    } else {
      alert(fulfillment_file_cant_be_empty_message);
    }
  });  

  $('#input_product_filter').click(function() {
    $('#radio_product_filter_sku').prop('checked', true);
    $("#input_product_package").val("");
  });

  $('#input_product_package').click(function() {
    $('#radio_product_filter_package').prop('checked', true);
    $("#input_product_filter").val("");
  });

  $("#make_report").click(function() {
    set_product_filter_at_fulfillments_index(settings_others_product);
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
    startAjaxLoader(true);
    event.preventDefault();
    $.ajax({
      type: 'PUT',
      url: url+button.attr("name")+"/mark_as_sent",
      success: function(data) {
        if (data.code == "000"){
          button.parent().children().hide();
          button.parent().parent().after("<tr><td colspan='8'><p style='text-align: center;'><div class='alert-info alert'>"+data.message+"</div></p></td></tr>");
        }else{
          endAjaxLoader(true);
          alert(data.message);
        };
      },
    });
  });
}

function resend_fulfillment(url){
  $('*#resend').click( function(event){
    button = $(this)
    startAjaxLoader(true);
    event.preventDefault();
    $.ajax({
      type: 'PUT',
      url: url+button.attr("name")+"/resend",
      success: function(data) {
        if (data.code == "000"){
          button.parent().children().hide();
          button.parent().parent().after("<tr><td colspan='8'><p style='text-align: center;'><div class='alert-info alert'>"+data.message+"</div></p></td></tr>");
        }else{
          endAjaxLoader(true);
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


function admin_form_functions(){
  var count = 0;

  $('#club_role_table').on('click', '#add_new_club_role', function(event){
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
      $('#club_role_table').append("<tr id='tr_new_club_rol_["+count+"]'><td><select id='select_club_role_"+count+"' name='[club_roles_attributes]["+count+"][role]'>"+options_for_role+"</select></td><td><select id='select_club_role_"+count+"_club_id' name='[club_roles_attributes]["+count+"][club_id]'>"+options_for_club_id+"</select></td><td><input type='button' id='new_club_role_delete' name='"+count+"' class='btn btn-mini btn-danger' value='Delete'></td></tr>")
    };

    $("*[id$='_club_id']").each(function() {
      $(this).data('lastValue', $(this).val());
    });
  });

  $("#div_agent_roles").on('click', "*[id^='agent_roles']", function(){
    $("#clear_global_role").show();
  });

  $("#clear_global_role").click(function(event){
    $("*[id^='agent_roles']").each(function(){
      $(this).attr('checked', false);
      event.preventDefault();
      $("#clear_global_role").hide();
    });
  });

  $("#club_role_table").on('change', "*[id$='_club_id']:not(:last)", function() {
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

  $('#club_role_table').on('click', '#new_club_role_delete', function(){
    if (confirm("Are you sure you want to delete this club role?")) {
      $("#club_role_table tr[id='tr_new_club_rol_["+$(this).attr('name')+"]']").remove();
      club_list = clubs.split(";");
    }
  });

  $('#club_role_table').on('click', '#club_role_edit', function(event){
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

  $('#club_role_table').on('click', '#club_role_update', function(event){
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

  $('#club_role_table').on('confirm:complete', '#club_role_delete', function(event){
    event.preventDefault();
    array = $(this).attr('name').split(";");
    club_role_id = array[0];
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
  tom_create_wizard();
}

function tom_create_wizard() {
  $("#tom_wizard_form").formwizard({ 
    formPluginEnabled: false,
    validationEnabled: true,
    validationOptions:{
      errorPlacement: function(error, element) {
        if(error.text().length > 0 ){
          $("label[for="+error.attr("for")+"][generated=true]").each(function(){
            if($(this).text() == error.text() || $(this).text() != error.text()){
              $(this).remove();
            }
          })
          error.removeClass('error');
          error.addClass('help-inline');
          $("#"+error.attr("for")).parents('.control-group').addClass("error");
          $("#"+error.attr("for")).parent().append(error);
        }
      },
      success: function(error){
        if(error.attr("for").indexOf("time_span") < 0){
          $("#"+error.attr("for")).parents('.control-group').removeClass("error");
          $("label[for="+error.attr("for")+"][generated=true]").each(function(){
            $(this).remove();
          });
        }
      }
    },
    focusFirstInput : true,
    disableUIStyles: true,
    textNext: '',
    textSubmit: ''
  });
}

// // Communications
function switch_days() {
  if ($("#email_template_template_type").val() == 'pillar' || $("#email_template_template_type").val() == 'prebill') {
    $("#control_group_days").show(100);
  }
  else {
   $("#control_group_days").hide(100); 
   $("#email_template_days").val(1);
  }
}

function email_templates_functions() {
  $("#email_template_template_type").change(function() {
    switch_days();
  });

  // $("#et_form").submit(function(event) {
  //   var isValid = true;
  //   $('form input[type="text"], form select').each(function() {
  //     if($(this).hasClass('manual_validation')) {
  //       $('#control_'+$(this).attr('id')+' div[id="error_inline"]').remove();
  //       if ($.trim($(this).val()) == '') {
  //         isValid = false;
  //         $('#control_'+$(this).attr('id')).append('<div id="error_inline" style="display:inline-block;"> can\'t be blank </div>');
  //       }
  //     }
  //   });
  //   if (isValid == false) event.preventDefault();
  // });
}

function email_templates_table_index_functions(column_count) {
  $('#email_templates_table').DataTable({
    "bJQueryUI": false,
    "bProcessing": true,
    "bFilter": true,
    "sPaginationType": "full_numbers",
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
  $("#communications_table").on('click', 'a', function(event){
    if($("#test_communication").valid()){
      startAjaxLoader(true);
      event.preventDefault();
      button = $(this);
      user_id = $("#communication_user_id").val();
      template_id = button.attr('name');
      $.ajax({
        type: "POST",
        url: "",
        data: { email_template_id:template_id, user_id:user_id },
        success: function(data){
          button.parent().next().empty();
          if (data.code == "000"){
            button.parent().next().append("<div class='alert-info alert'>"+data.message+"</div>");
          }else{
            button.parent().next().append("<div class='error-info alert'>"+data.message+"</div>");
          };
          endAjaxLoader(true);
        },
      })
    }
  });
}

function suspected_fulfillments_functions(){
  $("#suspected_fulfillments_form_submit_button").click(function(event){
    event.preventDefault();
    if( (new Date($("#end_date").val()) >= new Date($("#initial_date").val())) == true) { 
      $("#suspected_fulfillments_form").submit();
    }else{
      alert('Invalid range of dates.');
    }
  });

  $('#suspected_list td[data-href]').click(function(event){
    event.preventDefault();
    startAjaxLoader(true)
    $('#suspected_list tr').removeClass("info");
    $(this).parent().addClass("info");
    $('#evidences_information').show();
    $('#evidences_information').load($(this).data('href'), function(){
      endAjaxLoader(true);
    });
  });
    $(".datepicker").datepicker({ constrainInput: true,
                                maxDate: 0,
                                dateFormat: "yy-mm-dd", 
                                changeMonth: true,
                                changeYear: true,
                                yearRange: 'c-100:c' });
}

function suspected_fulfillment_information_functions(){
  $('.pagination').on('click', 'a', function(event){
    event.preventDefault();
    if($(this).prop('href').indexOf('#') == -1 ){
      $('#evidences_information').load($(this).prop('href'));
    };
  });

  //resize columns to have them aligned
  var colWidth;
  colWidth = $('.suspected_fulfillment tbody td').map(function() {
    return $(this).width();
  }).get();
  $('table.evidences tbody tr').each(function(index,row) {
    $(row).find('td').each(function(index2,column){
      if($(column).width() > colWidth[index2]){
        colWidth[index2] = $(column).width()
      }
    });
  });
  $('table.suspected_fulfillment tbody tr').each(function(index,row) {
    $(row).find('td').each(function(index2,column){
      $(column).width(colWidth[index2]);
      $(column).css('max-width', colWidth[index2]);
    });
  });
  $('table.evidences thead tr').each(function(index,row) {
    $(row).find('th').each(function(index2,column){
      $(column).width(colWidth[index2]);
      $(column).css('max-width', colWidth[index2]);
    });
  });
  $('table.evidences tbody tr').each(function(index,row) {
    $(row).find('td').each(function(index2,column){
      $(column).width(colWidth[index2]);
      $(column).css('max-width', colWidth[index2]);
    });
  });
}