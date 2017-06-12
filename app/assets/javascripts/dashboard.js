MinionPoller = {
  selectedNodes: [],

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

        // for the dashboard, if we rely on radio, the first time this comes
        // it won't detect that there's a master, so we need to rely on the data
        // itself for counting masters
        if (MinionPoller.renderMode === 'dashboard') {
          MinionPoller.selectedMasters = data.assigned_minions.reduce(function(memo, minion) {
            if (minion.role === 'master') {
              memo.push(minion.id);
            }

            return memo;
          }, []);
        } else {
          MinionPoller.selectedMasters = $("input[name='roles[master][]']:checked").map(function() {
            return parseInt($( this ).val());
          }).get();
        }

        if (MinionPoller.renderMode !== "Dashboard") {
          minions = unassignedMinions;
        } else {
          MinionPoller.sortMinions(minions);
        }

        var renderMethod = 'render' + MinionPoller.renderMode;
        for (i = 0; i < minions.length; i++) {
          rendered += MinionPoller[renderMethod].call(MinionPoller, minions[i]);

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

        var addNodesUrl = $('.unassigned-count').data('url');
        if (unassignedMinions.length > 0) {
          // discovery page uses #node-count,
          // overview page otherwise
          if ($("#node-count").length > 0) {
            $("#node-count").text(unassignedMinions.length + " nodes found");
          } else {
            $('.unassigned-count').html(unassignedMinions.length + ' <a href="' + addNodesUrl + '">(new)</a>');
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

  renderDashboard: function(minion) {
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

  renderDiscovery: function(minion, onlyWorkers) {
    var masterHtml;
    var masterChecked = '';
    var minionHtml;
    var minionChecked = '';

    if (MinionPoller.selectedMasters && MinionPoller.selectedMasters.indexOf(minion.id) != -1) {
      masterChecked = 'checked';
      minionChecked += 'disabled="disabled" checked ';
    }

    if (onlyWorkers) {
      masterHtml = '';
    } else {
      masterHtml = '<td class="text-center">\
        <input name="roles[master][]" id="roles_master_' + minion.id +
        '" value="' + minion.id + '" type="radio" ' + masterChecked + '></td>';
    }

    if (MinionPoller.selectedNodes && MinionPoller.selectedNodes.indexOf(minion.id) != -1) {
      minionChecked += 'checked';
    }

    minionHtml = '<input name="roles[worker][]" id="roles_minion_' + minion.id +
      '" value="' + minion.id + '" type="checkbox" ' + minionChecked + '>';

    return "\
      <tr> \
        <td>" + minionHtml +  "</td>\
        <td>" + minion.minion_id +  "</td>\
        <td>" + minion.fqdn +  "</td>\
        " + masterHtml + "\
      </tr>";
  },

  renderUnassigned: function(minion) {
    return MinionPoller.renderDiscovery(minion, true);
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

// enable/disable Add nodes button to assign nodes
function toggleAddNodesButton() {
  var selectedNodes = $("input[name='roles[worker][]']:checked").length;

  $('.add-nodes-btn').prop('disabled', selectedNodes === 0);
};

$('body').on('change', '.new-nodes-container input[name="roles[worker][]"]', toggleAddNodesButton);

// checkbox on the top the checks/unchecks all nodes
$('.check-all').on('change', function() {
  $('input[name="roles[worker][]"]:not(:disabled)').prop('checked', this.checked).change();
  toggleAddNodesButton();
});

// when checking/unchecking a node
// stores it on MinionPoller.selectedNodes for future rendering
$('body').on('change', 'input[name="roles[worker][]"]', function() {
  var value = parseInt(this.value, 10);

  if (this.checked) {
    MinionPoller.selectedNodes.push(value);
  } else {
    var index = MinionPoller.selectedNodes.indexOf(value);
    MinionPoller.selectedNodes.splice(index, 1);
  }
});

// when selecting a master
// selects node and makes it impossible to uncheck
// enable and keep the previous state of the previous master (selected or not)
// if user select node as master, it checks it as selected
$('body').on('change', 'input[name="roles[master][]"]', function() {
  var $previousMaster = $('input[name="roles[worker][]"]:disabled');
  var previousMasterValue = parseInt($previousMaster.val(), 10);
  var checked = MinionPoller.selectedNodes.indexOf(previousMasterValue) !== -1;

  $previousMaster.prop('disabled', false);
  $previousMaster.prop('checked', checked);

  if (this.checked) {
    var $checkbox = $(this).closest('tr').find('input[name="roles[worker][]"]');

    $checkbox.prop('checked', true);
    $checkbox.prop('disabled', true);
  }
});
