  $(document).ready(function() {
    switch_days_after_join_date();
    switch_external_attributes();
    email_templates_functions();
  });

  $("#template_type").change(function() {
    switch_days_after_join_date();
  });

  $("#client").change(function() {
    switch_external_attributes();
  });

  function switch_days_after_join_date() {
    if ($("#template_type").val() == 'pillar') {
      $("#control_group_days_after_join_date").show(100);
    }
    else {
     $("#control_group_days_after_join_date").hide(100); 
     $("#email_template_days_after_join_date").val(1);
    }
  }
