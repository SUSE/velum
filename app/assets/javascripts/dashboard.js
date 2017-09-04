State = {
  nextClicked: false,
  bootstrapErrors: [],
},

MinionPoller = {
  selectedNodes: [],
  selectedMasters: [],
  pollingTimeoutId: null,
  initialized: false,

  poll: function() {
    this.request();
  },

  stop: function() {
    if (this.pollingTimeoutId) {
      clearTimeout(this.pollingTimeoutId);
    }
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
      return MinionPoller.stateWeight(b.highstate) - MinionPoller.stateWeight(a.highstate);
    });
  },

  request: function() {
    $.ajax({
      url: $('.nodes-container').data('url'),
      dataType: "json",
      cache: false,
      success: function(data) {
        var rendered = "";
        var pendingRendered = "";
        var masterApplied = false;
        var updateAvailable = false;
        var hasPendingStateNode = false;
        var updateAvailableNodeCount = 0;

        // In discovery, the minions to be rendered are unassigned, while on the
        // dashboard we don't want to render unassigned minions but we still
        // want to account for them.
        var minions = data.assigned_minions || [];
        var unassignedMinions = data.unassigned_minions || [];
        var allMinions = minions.concat(unassignedMinions);
        var pendingMinions = data.pending_minions || [];

        // for the dashboard, if we rely on radio, the first time this comes
        // it won't detect that there's a master, so we need to rely on the data
        // itself for counting masters
        if (MinionPoller.renderMode === 'Dashboard') {
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

        var minionId = function(node) {
          return node.id;
        }

        var isMaster = function(node) {
          return node.role === "master";
        }

        var isWorker = function(node) {
          return node.role === "worker";
        }

        if (!MinionPoller.initialized) {
          if (MinionPoller.selectedNodes.length == 0) {
            MinionPoller.selectedNodes = $.grep(minions, isWorker).map(minionId);
          }
          if (MinionPoller.selectedMasters.length == 0) {
            MinionPoller.selectedMasters = $.grep(minions, isMaster).map(minionId);
          }
          MinionPoller.initialized = true;
        }

        switch (MinionPoller.renderMode) {
        case "Discovery":
          minions = allMinions;
          break;
        case "Unassigned":
          minions = unassignedMinions;
          break;
        default:
          MinionPoller.sortMinions(allMinions);
        }

        var renderMethod = 'render' + MinionPoller.renderMode;
        for (var i = 0; i < minions.length; i++) {
          rendered += MinionPoller[renderMethod].call(MinionPoller, minions[i]);

          if (minions[i].role == "master" && minions[i].highstate == "applied") {
            masterApplied = true;
          }

          if (minions[i].highstate === "pending") {
            hasPendingStateNode = true;
          }

          if (minions[i].update_status == 1 || minions[i].update_status == 3) {
            updateAvailable = true;
            updateAvailableNodeCount++;
          }
        }
        $(".nodes-container tbody").html(rendered);

        // `hasPendingStateNode` variable aux to determine if
        // update is possible
        updateAvailable = updateAvailable && !hasPendingStateNode;

        // Build Pending Nodes display table
        if (pendingMinions.length) {
          for (i = 0; i < pendingMinions.length; i++) {
            pendingRendered += MinionPoller.renderPendingNodes(pendingMinions[i], hasPendingStateNode);
          }

          $(".pending-nodes-container tbody").html(pendingRendered);
        }

        // Show / Hide the table depending the presence of pending nodes
        var acceptLinks = $('.pending-nodes-container td > a');
        $(".pending-nodes-container #accept-all").prop('disabled', acceptLinks.length === 0)
        $(".pending-nodes-container .has-content").toggleClass('hidden', pendingMinions.length === 0);
        $(".pending-nodes-container .empty-text").toggleClass('hidden', pendingMinions.length > 0);

        // show/hide panels on discovery page
        $('.discovery-nodes-panel').toggleClass('hide', allMinions.length === 0);
        $('.discovery-empty-panel').toggleClass('hide', allMinions.length > 0);

        MinionPoller.handleAdminUpdate(data.admin || {}, hasPendingStateNode);
        MinionPoller.handleRetryableBootstrapOrchestration(data.retryable_bootstrap_orchestration);

        handleBootstrapErrors();

        // show/hide "update all nodes" link
        var hasAdminNodeUpdate = data.admin.update_status === 1 || data.admin.update_status === 2;
        $("#update-all-nodes").toggleClass('hidden', !updateAvailable || hasAdminNodeUpdate);

        MinionPoller.enable_kubeconfig(masterApplied);

        $('#out_dated_nodes').text(updateAvailableNodeCount + ' ');

        $('.assigned-count').text(minions.length);
        $('.master-count').text(MinionPoller.selectedMasters.length);

        if (allMinions.length > 0) {
          if (MinionPoller.renderMode === "Discovery") {
            $("#node-count").text(allMinions.length + " nodes found");
          } else {
            var addNodesUrl = $('.unassigned-count').data('url');
            var unassignedCountText = unassignedMinions.length;

            if (!hasPendingStateNode) {
                unassignedCountText += ' <a href="' + addNodesUrl + '">(new)</a>';
            }

            $('.unassigned-count').html(unassignedCountText);
          }
        } else {
          $('.unassigned-count').text(0);
        }

        // remove loading and shows content
        $('.summary-loading').hide();
        $('.summary-content').removeClass('hidden');
        $('.nodes-loading').hide();
        $('.nodes-content').removeClass('hidden');

        handleBootstrapErrors();
        toggleMinimumNodesAlert();
        $('.connection-failed-alert').fadeOut(100);
      }
    }).fail(function() {
      $('.connection-failed-alert').fadeIn(100);
    }).always(function() {
      // make another request only after the last one finished
      MinionPoller.pollingTimeoutId = setTimeout(MinionPoller.request, 5000);
    });
  },

  renderPendingNodes: function(pendingMinionId, hasPendingStateNode) {
    var acceptHtml;

    if (hasPendingStateNode) {
      acceptHtml = '';
    } else if (hasPendingAcceptance(pendingMinionId)) {
      acceptHtml = 'Acceptance in progress';
    } else {
      acceptHtml = '<a class="accept-minion" href="#" data-minion-id="' + pendingMinionId + '">Accept Node</a>';
    }

    return '\
      <tr> \
        <td>' + pendingMinionId + '</td>\
        <td>' + acceptHtml + '</td>\
      </tr> \
    ';
  },

  handleAdminUpdate: function(admin, hasPendingStateNode) {
    var $notification = $('.admin-outdated-notification');

    if (admin.update_status === undefined || hasPendingStateNode) {
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

  handleRetryableBootstrapOrchestration: function(retryableBootstrapOrchestration) {
    if (retryableBootstrapOrchestration) {
      $('#retry-cluster-bootstrap').removeClass('hidden');
    } else {
      $('#retry-cluster-bootstrap').addClass('hidden');
    }
  },

  enable_kubeconfig: function(enabled) {
    $("#download-kubeconfig").attr("disabled", !enabled);
  },

  alertFailedBootstrap: function() {
    if (!$('.failed-bootstrap-alert').length) {
      showAlert('At least one of the nodes is in a failed state. Please run "supportconfig" on the failed node(s) to gather the logs.', 'alert', 'failed-bootstrap-alert');
    }
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
            <i class="fa fa-circle fa-stack-2x text-muted" aria-hidden="true"></i>\
            <i class="fa fa-refresh fa-stack-1x fa-spin fa-inverse" aria-hidden="true"></i>\
          </span>';
        break;
      case "failed":
        statusHtml = '<i class="fa fa-times-circle text-danger fa-2x" aria-hidden="true"></i>';
        MinionPoller.alertFailedBootstrap();
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
      '" value="' + minion.id + '" type="checkbox" disabled="" ' + checked + '> ';

    switch(minion.update_status) {
      case 1:
        switch (minion.highstate) {
          case "applied":
            statusHtml = '<i class="fa fa-arrow-circle-up text-info fa-2x" aria-hidden="true"></i> Update Available';
            break;
          case "failed":
            statusHtml = '<i class="fa fa-arrow-circle-up text-warning fa-2x" aria-hidden="true"></i> Update Failed - Retryable';
            break;
          case "pending":
            statusHtml += ' Update in progress'
            break;
        }
        break;
      case 2:
        statusHtml = '<i class="fa fa-arrow-circle-up text-danger fa-2x" aria-hidden="true"></i> Update Failed';
        break;
    }

    return '\
      <tr> \
        <td class="status">' + statusHtml +  '</td>\
        <td><strong>' + minion.minion_id +  '</strong></td>\
        <td>' + minion.fqdn +  '</td>\
        <td>' + masterHtml + minion.role + '</td>\
      </tr>';
  },

  renderDiscovery: function(minion) {
    var isMaster = MinionPoller.selectedMasters.indexOf(minion.id) !== -1;
    var isWorker = MinionPoller.selectedNodes.indexOf(minion.id) !== -1;
    var isUnused = !isMaster && !isWorker;

    var masterHtml;
    var masterChecked = '';
    var minionHtml;
    var minionChecked = '';

    if (isMaster) {
      masterChecked = 'checked';
    }

    masterHtml = '\
      <input name="roles[master][]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="checkbox" title="Select node as master" ' + masterChecked + '>';

    if (isWorker) {
      minionChecked = 'checked';
    }

    minionHtml = '<input name="roles[worker][]" id="roles_worker_' + minion.id +
      '" value="' + minion.id + '" type="checkbox" title="Select node for bootstrapping" ' + minionChecked + '>';

    var roleHtml = '\
      <td class="role-column">' +
        masterHtml +
        minionHtml +
        '<div class="btn-group role-btn-group">\
          <button type="button" class="btn btn-default master-btn '+ (isMaster ? 'btn-primary' : '') + '" data-minion-id="' + minion.id + '" data-minion-role="master">Master</button>\
          <button type="button" class="btn btn-default worker-btn ' + (isWorker ? 'btn-primary' : '') + '" data-minion-id="' + minion.id + '" data-minion-role="worker">Worker</button>\
          <button type="button" class="btn btn-default unused-btn ' + (isUnused ? 'btn-primary' : '') + '" data-minion-id="' + minion.id + '">Unused</button>\
        </div>\
      </td>\
    ';

    return '\
      <tr class="minion_' + minion.id + '"> \
        <td>' + minion.minion_id + '</td>\
        <td>' + minion.fqdn + '</td>' +
        roleHtml +
      '</tr>';
  },

  renderUnassigned: function(minion) {
    var minionHtml;
    var minionChecked = '';

    if (MinionPoller.selectedNodes.indexOf(minion.id) != -1) {
      minionChecked += 'checked';
    }

    minionHtml = '<input name="roles[worker][]" id="roles_minion_' + minion.id +
      '" value="' + minion.id + '" type="checkbox" title="Select node for bootstrapping" ' + minionChecked + '>';

    return "\
      <tr> \
        <td>" + minionHtml +  "</td>\
        <td>" + minion.minion_id +  "</td>\
        <td>" + minion.fqdn +  "</td>\
      </tr>";
  }
};

function hasPendingAcceptance(minionId) {
  return sessionStorage.getItem(minionId) === 'true';
}

function setPendingAcceptance(minionId) {
  sessionStorage.setItem(minionId, true);
  $('.pending-nodes-container a[data-minion-id="' + minionId + '"]').parent().text('Acceptance in progress');
}

function requestMinionApproval(selector) {
  $.ajax({
    url: '/accept-minion.json',
    method: 'POST',
    data: { minion_id: selector }
  });
}

function checkAcceptAllAvaiability() {
  var $acceptLinks = $('.pending-nodes-container td > a');

  $('#accept-all').prop('disabled', $acceptLinks.length === 0);
}

$('body').on('click', '#accept-all', function(e) {
  var $btn = $(this);
  var $acceptLinks = $('.pending-nodes-container td > a');

  e.preventDefault();
  $btn.prop('disabled', true);
  $acceptLinks.each(function(_, el) {
    setPendingAcceptance(el.dataset.minionId);
  });
  requestMinionApproval('*');
});

$('body').on('click', '.accept-minion', function(e) {
  var minionId = $(this).data('minionId');

  e.preventDefault();
  setPendingAcceptance(minionId);
  requestMinionApproval(minionId);
  checkAcceptAllAvaiability();
});

$('.update-admin-modal').on('hide.bs.modal', function(e) {
  var isRebooting = $('.update-admin-modal').data('rebooting');

  if (isRebooting) {
    e.preventDefault();
  }
});

// unlock modal, now closable
function unlockUpdateAdminModal() {
  var $modal = $('.update-admin-modal');
  var $btn = $modal.find('.btn');

  $modal.data('rebooting', false);
  $modal.find('.close').show();
  $btn.prop('disabled', false);
}

// lock modal, won't close
function lockUpdateAdminModal() {
  var $modal = $('.update-admin-modal');
  var $btn = $modal.find('.btn');

  $btn.prop('disabled', true);
  $modal.data('rebooting', true);
  $modal.find('.close').hide();
}

// reboot to update admin node handler
$('body').on('click', '.reboot-update-btn', function(e) {
  var REBOOTING = 3;
  var $btn = $(this);
  var $modal = $('.update-admin-modal');

  e.preventDefault();

  $btn.html('<i class="fa fa-spinner fa-pulse fa-fw"></i> Rebooting...');
  lockUpdateAdminModal();

  $.post($btn.data('url'))
  .done(function(data) {
    if (data.status === REBOOTING) {
      setTimeout(healthCheckToReload, 5000);
    } else {
      // update not needed
      unlockUpdateAdminModal();
      $btn.text('Reboot to update');
    }
  })
  .fail(function() {
    unlockUpdateAdminModal();
    $btn.text('Reboot to update (failed last time)');
  });
});

// health check request
// if successful, reload page
// schedule another check otherwise
function healthCheckToReload() {
  var healthCheckUrl = $('.reboot-update-btn').data('healthCheck');

  $.get(healthCheckUrl)
  .success(function() {
    window.location.reload();
  })
  .fail(function() {
    setTimeout(healthCheckToReload, 3000);
  });
};

// enable/disable Add nodes button to assign nodes
function toggleAddNodesButton() {
  var selectedNodes = $("input[name='roles[worker][]']:checked").length;

  $('.add-nodes-btn').prop('disabled', selectedNodes === 0);
};

// unassigned nodes page
$('body').on('change', '.new-nodes-container input[name="roles[worker][]"]', toggleAddNodesButton);

// return number of selected nodes
function selectedWorkersLength() {
  return $('input[name="roles[worker][]"]:checked').length;
}

// return number of selected masters
function selectedMastersLength() {
  return $('input[name="roles[master][]"]:checked').length;
}


function isBootstrappable() {
  var errors = [];

  // We need at least one master
  if (selectedMastersLength() < 1) {
    errors.push("You haven't selected one master at least");
  }

  // We need at least one worker
  if (selectedWorkersLength() < 1) {
    errors.push("You haven't selected one worker at least");
  }

  // We need an odd number of masters
  if (selectedMastersLength() % 2 !== 1) {
    errors.push('The number of masters has to be an odd number');
  }

  State.bootstrapErrors = errors;

  return errors.length === 0;
}

// return true if the selected masters vs workers are in a supported state
function isSupportedConfiguration() {
  // We need at least three nodes in total
  return (selectedWorkersLength() + selectedMastersLength()) >= 3;
}

// handle bootstra button title
function handleBootstrapErrors() {
  var nextClicked = State.nextClicked;
  var title;

  if (nextClicked && !isBootstrappable()) {
    var errors = State.bootstrapErrors;
    var listHtml = errors.map(function(e) { return '<li>' + e + '</li>' }).join('');
    $('.discovery-bootstrap-alert .list').html(listHtml);
    $('.discovery-bootstrap-alert').fadeIn(100);
    $('#set-roles').prop('disabled', true);
  } else {
    $('.discovery-bootstrap-alert').fadeOut(100);
    $('#set-roles').prop('disabled', false);
  }
}

// hide minimum nodes alert
function toggleMinimumNodesAlert() {
  if (isSupportedConfiguration()) {
    $('.discovery-minimum-nodes-alert').fadeOut(500);
  } else {
    $('.discovery-minimum-nodes-alert').fadeIn(100);
  }
}

// bootstrap cluster button click listener
// if it has the minimum amount of nodes, form is submitted as expected
// otherwise it shows the modal if didn't show yet
$('body').on('click', '#set-roles', function(e) {
  var $warningModal = $('.warn-minimum-nodes-modal');

  e.preventDefault();
  State.nextClicked = true;
  handleBootstrapErrors();

  if (isBootstrappable()) {
    if (!isSupportedConfiguration()) {
      $warningModal.modal('show');
      $warningModal.data('wasOpenedBefore', true);

      return false;
    } else {
      MinionPoller.stop();
      $('form').submit();
    }
  } else {
    window.scrollTo(0, 0);
  }
});

// if user wants to bootstrap anyway, submit form
$('body').on('click', '.bootstrap-anyway', function() {
  $('.warn-minimum-nodes-modal').modal('hide');
  $('form').submit();
});

// checkbox on the top the checks/unchecks all nodes (only on unassigned page)
$('body').on('change', '.check-all', function() {
  $('input[name="roles[worker][]"]:not(:disabled)').prop('checked', this.checked).change();
});

// deselect all nodes
$('body').on('click', '.deselect-nodes-btn', function() {
  var unusedSelector = '.role-btn-group .unused-btn';

  $(this).addClass('hidden');
  $('.select-nodes-btn').show();
  $(unusedSelector).click();
  handleBootstrapErrors();
  toggleAddNodesButton();
});

// select remaining nodes as workers
$('body').on('click', '.select-nodes-btn', function() {
  var workersSelector = 'input[name="roles[master][]"]:not(:checked) ~ .role-btn-group .worker-btn';

  $(this).hide();
  $('.deselect-nodes-btn').removeClass('hidden');
  $(workersSelector).click();

  handleBootstrapErrors();
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

    if (index !== -1) {
      MinionPoller.selectedNodes.splice(index, 1);
    }
  }
});

// when selecting a master
// selects node and makes it impossible to uncheck
// enable and keep the previous state of the previous master (selected or not)
// if user select node as master, it checks it as selected
$('body').on('change', 'input[name="roles[master][]"]', function() {
  var value = parseInt(this.value, 10);

  if (this.checked) {
    MinionPoller.selectedMasters.push(value);
  } else {
    var index = MinionPoller.selectedMasters.indexOf(value);

    if (index !== -1) {
      MinionPoller.selectedMasters.splice(index, 1);
    }
  }
});

function unselectRoles(target) {
  var $td = $(target).closest('td');

  $td.find('.btn').removeClass('btn-primary');
  $td.find('input').prop('checked', false).change();
}

$('body').on('click', '.role-btn-group .btn', function(e) {
  e.preventDefault();

  var dataset = e.target.dataset;
  var minionId = dataset['minionId'];
  var role = dataset['minionRole'];

  unselectRoles(e.target);
  $(e.target).addClass('btn-primary');
  $('#roles_' + role + '_' +  minionId).prop('checked', true).change();

  toggleMinimumNodesAlert();
  handleBootstrapErrors();
});
