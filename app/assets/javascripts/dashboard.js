MinionPoller = {
  poll: function() {
    this.request();
    return setInterval(this.request, 5000);
  },

  request: function() {
    $.ajax({
      url: $('.nodes-container').data('url'),
      dataType: "json",
      cache: false,
      success: function(data) {
        var rendered = "";
        var allApplied = true;

        MinionPoller.selectedMasters = $("input[name='roles[master][]']:checked").map(function() {
          return parseInt($( this ).val());
        }).get();

        // In discovery, the minions to be rendered are unassigned, while on the
        // dashboard we don't want to render unassigned minions but we still
        // want to account for them.
        var minions = data.assigned_minions || [];
        var unassignedMinions = data.unassigned_minions || [];
        if (MinionPoller.renderMode == "discovery") {
          minions = minions.concat(unassignedMinions);
        }

        for (i = 0; i < minions.length; i++) {
          if (MinionPoller.renderMode == "discovery") {
            rendered += MinionPoller.renderDiscovery(minions[i]);
          } else {
            rendered += MinionPoller.render(minions[i]);
          }
          if (minions[i].highstate != "applied") {
            allApplied = false;
          }
        }
        $(".nodes-container tbody").html(rendered);

        MinionPoller.handleAdminUpdate(data.admin || {});

        // disable bootstrap button if there are no minions
        if (minions.length == 0) {
          $("#bootstrap").prop('disabled', true);
          MinionPoller.enable_kubeconfig(false);
        } else {
          $("#bootstrap").prop('disabled', false);
          MinionPoller.enable_kubeconfig(allApplied);
        }

        if (unassignedMinions.length > 0) {
          if ($("#node-count").length > 0) {
            $("#node-count").text(unassignedMinions.length + " nodes found");
          } else {
            $('#unassigned_count').html(unassignedMinions.length + " \
            <strong>new</strong> nodes are available but have not been added to the cluster yet");
          }
        } else {
          $('#unassigned_count').html('');
        }
      }
    });
  },

  handleAdminUpdate: function(admin) {
    if (admin.update_status === undefined) {
      return;
    }

    $('.update-admin-btn').toggleClass('hidden', admin.update_status === 0);
  },


  enable_kubeconfig: function(enabled) {
    $("#download-kubeconfig").attr("disabled", !enabled);
  },

  render: function(minion) {
    var statusHtml;
    var checked;
    var masterHtml;

    switch(minion.highstate) {
      case "not_applied":
        statusHtml = '<i class="fa fa-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
      case "pending":
        statusHtml = '\
          <span class="fa-stack" aria-hidden="true">\
            <i class="fa fa-circle fa-stack-2x text-success" aria-hidden="true"></i>\
            <i class="fa fa-refresh fa-stack-1x fa-spin fa-inverse" aria-hidden="true"></i>\
          </span>';
        break;
      case "failed":
        statusHtml = '<i class="fa fa-times-circle text-danger fa-2x" aria-hidden="true"></i>';
        break;
      case "applied":
        statusHtml = '<i class="fa fa-check-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
    }

    if ((MinionPoller.selectedMasters && MinionPoller.selectedMasters.indexOf(minion.id) != -1) || minion.role == "master") {
      checked =  "checked";
    } else {
      checked = '';
    }
    masterHtml = '<input name="roles[master][]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="radio" disabled="" ' + checked + '>';

    return "\
      <tr> \
        <th>" + minion.minion_id +  "</th>\
        <td class='text-center'>" + statusHtml +  "</td>\
        <td>" + minion.fqdn +  "</td>\
        <td>" + (minion.role || '') +  "</td>\
        <td class='text-center'>" + masterHtml + "</td>\
      </tr>";
  },

  renderDiscovery: function(minion) {
    var masterHtml;
    var checked;

    if (MinionPoller.selectedMasters && MinionPoller.selectedMasters.indexOf(minion.id) != -1) {
      checked = "checked";
    } else {
      checked = '';
    }
    masterHtml = '<input name="roles[master][]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="radio" ' + checked + '>';

    return "\
      <tr> \
        <th>" + minion.minion_id +  "</th>\
        <td>" + minion.fqdn +  "</td>\
        <td class='text-center'>" + masterHtml + "</td>\
      </tr>";
  }
};

// reboot to update admin node handler
$('body').on('click', '.reboot-update-btn', function(e) {
  var $btn = $(this);

  e.preventDefault();

  $btn.text('Rebooting...');
  $btn.prop('disabled', true);

  $.ajax({
    url: $btn.data('url'),
    method: 'POST'
  })
  .done(function() {
    $('.update-admin-modal').modal('hide');
    $btn.text('Reboot to update');
  })
  .fail(function() {
    $btn.text('Update admin node (failed last time)');
  })
  .always(function() {
    $btn.prop('disabled', false);
  });
});