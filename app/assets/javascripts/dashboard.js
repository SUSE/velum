MinionPoller = {
  poll: function() {
    this.request();
  },

  stateWeight: function(state) {
    // I guess updates should be 2

    switch (state) {
      case 'failed':
        return 3;
      case 'pending':
        return 1;
      // applied, not_applied
      default:
        return 0;
    }
  },

  sortMinions: function(minions) {
    minions.sort(function(a, b) {
      return MinionPoller.stateWeight(b.highstate)- MinionPoller.stateWeight(a.highstate);
    });
  },

  request: function() {
    $.ajax({
      url: $('.nodes-container').data('url'),
      dataType: "json",
      cache: false,
      success: function(data) {
        var rendered = "";
        var allApplied = true;
        var updateAvailable = false;
        var updateAvailableNodeCount = 0;

        // In discovery, the minions to be rendered are unassigned, while on the
        // dashboard we don't want to render unassigned minions but we still
        // want to account for them.
        var minions = data.assigned_minions || [];
        var unassignedMinions = data.unassigned_minions || [];

        MinionPoller.selectedMasters = data.assigned_minions.reduce(function(memo, minion) {
          if (minion.role === 'master') {
            memo.push(minion.id);
          }

          return memo;
        }, []);

        if (MinionPoller.renderMode == "discovery") {
          minions = minions.concat(unassignedMinions);
        } else {
          MinionPoller.sortMinions(minions);
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
          if (minions[i].update_status == 1) {
            updateAvailable = true;
            updateAvailableNodeCount++;
          }
        }
        $(".nodes-container tbody").html(rendered);

        MinionPoller.handleAdminUpdate(data.admin || {});

        if (updateAvailable && allApplied) {
          $("#update-all-nodes").attr('disabled', false);
        }

        // disable bootstrap button if there are no minions
        $("#bootstrap").prop('disabled', minions.length === 0);

        MinionPoller.enable_kubeconfig(minions.length > 0 && allApplied);

        $('#out_dated_nodes').text(updateAvailableNodeCount)

        $('.assigned-count').text(minions.length);
        $('.master-count').text(MinionPoller.selectedMasters.length);

        if (unassignedMinions.length > 0) {
          if ($("#node-count").length > 0) {
            $("#node-count").text(unassignedMinions.length + " nodes found");
          } else {
            $('.unassigned-count').text(unassignedMinions.length);
          }
        } else {
          $('.unassigned-count').text(0);
        }

        // remove loading and shows content
        $('.summary-loading').hide();
        $('.summary-content').removeClass('hidden');
        $('.nodes-loading').hide();
        $('.nodes-content').removeClass('hidden');
      }
    }).always(function() {
      // make another request only after the last one finished
      setTimeout(MinionPoller.request, 5000);
    });
  },

  handleAdminUpdate: function(admin) {
    var $notification = $('.admin-outdated-notification');

    if (admin.update_status === undefined) {
      return;
    }

    switch (admin.update_status) {
      case 1:
        $notification.removeClass('hidden');
        $notification.removeClass('admin-outdated-notification--failed');
        break;
      case 2:
        $notification.removeClass('hidden');
        $notification.addClass('admin-outdated-notification--failed');
        break;
      default:
        $notification.addClass('hidden');
        break;
    }
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

    statusText = ''

    switch(minion.update_status) {
      case 1:
        switch (minion.highstate) {
          case "applied":
            statusHtml = '<i class="fa fa-arrow-circle-up text-info fa-2x" aria-hidden="true"></i>';
            statusText = 'Update Available'  
            break;
          case "failed":
            statusHtml = '<i class="fa fa-arrow-circle-up text-warning fa-2x" aria-hidden="true"></i>';
            statusText = 'Update Failed - Retryable'
            break;
          case "pending":
            statusText = 'Update in progress'
            break;
        }
        break;
      case 2:
        statusHtml = '<i class="fa fa-arrow-circle-up text-danger fa-2x" aria-hidden="true"></i>';
        statusText = 'Update Failed'
        break;
    }

    return "\
      <tr> \
        <td>" + statusHtml +  "</td>\
        <td>" + statusText +  "</td>\
        <th>" + minion.minion_id +  "</th>\
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