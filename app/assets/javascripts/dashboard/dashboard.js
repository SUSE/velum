State = {
  nextClicked: false,
  bootstrapErrors: [],
  assignableErrors: [],
  pendingRemovalMinionId: null,
  hasPendingStateNode: false,
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
      case 'removal_failed':
        return 2;
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
        var updateAvailableNodeCount = 0;

        // reset pending
        State.hasPendingStateNode = false;

        // In discovery, the minions to be rendered are unassigned, while on the
        // dashboard we don't want to render unassigned minions but we still
        // want to account for them.
        var minions = data.assigned_minions || [];
        var unassignedMinions = data.unassigned_minions || [];
        var allMinions = minions.concat(unassignedMinions);
        var pendingMinions = data.pending_minions || [];
        var pendingCloudJobs = data.pending_cloud_jobs || 0;
        var cloudJobsFailed = data.cloud_jobs_failed || 0;

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

        // handle public cloud bootstrapping alerts
        if (pendingCloudJobs > 0) {
            $('#discovery-pending-cloud-jobs-count').text(pendingCloudJobs);
            if (pendingCloudJobs == 1) {
                $('#discovery-pending-cloud-jobs span.singular').removeClass('hidden');
                $('#discovery-pending-cloud-jobs span.plural').addClass('hidden');
            } else {
                $('#discovery-pending-cloud-jobs span.plural').removeClass('hidden');
                $('#discovery-pending-cloud-jobs span.singular').addClass('hidden');
            }
            $('#discovery-pending-cloud-jobs').removeClass('hidden');
        } else {
            $('#discovery-pending-cloud-jobs').addClass('hidden');
        }
        if (cloudJobsFailed > 0) {
            $('#discovery-cloud-job-errors-count').text(cloudJobsFailed);
            if (cloudJobsFailed == 1) {
                $('#discovery-bootstrap-alert span.singular').removeClass('hidden');
                $('#discovery-bootstrap-alert span.plural').addClass('hidden');
            } else {
                $('#discovery-bootstrap-alert span.plural').removeClass('hidden');
                $('#discovery-bootstrap-alert span.singular').addClass('hidden');
            }
            $('#discovery-bootstrap-alert').removeClass('hidden');
        } else {
            $('#discovery-bootstrap-alert').addClass('hidden');
        }

        switch (MinionPoller.renderMode) {
        case "Discovery":
          minions = allMinions;
          break;
        case "Unassigned":
          State.assignedMinions = minions;
          minions = unassignedMinions;
          break;
        default:
          MinionPoller.sortMinions(allMinions);
        }

        State.minions = minions;

        var pendingStateMinion = minions.find(function (minion) {
          return minion.highstate == "pending";
        });

        State.hasPendingStateNode = !!pendingStateMinion;

        // find if there's a node pending removal
        // to set State.pendingRemovalMinionId
        // and render minions properly
        var pendingRemovalMinion = minions.find(function(minion) {
          return minion.highstate == "pending_removal";
        });

        if (pendingRemovalMinion) {
          State.pendingRemovalMinionId = pendingRemovalMinion.minion_id;
        } else {
          State.pendingRemovalMinionId = null;
        }

        var renderMethod = 'render' + MinionPoller.renderMode;
        for (var i = 0; i < minions.length; i++) {
          rendered += MinionPoller[renderMethod].call(MinionPoller, minions[i]);

          if (minions[i].role == "master" && minions[i].highstate == "applied") {
            masterApplied = true;
          }

          if (minions[i].tx_update_reboot_needed) {
            updateAvailable = true;
            updateAvailableNodeCount++;
          }

          // removes node from the pending acceptance state in the browser
          removePendingAcceptance(minions[i].minion_id);
        }
        $(".nodes-container tbody").html(rendered);

        // `State.hasPendingStateNode` variable aux to determine if
        // update is possible
        updateAvailable = updateAvailable &&
                          !State.hasPendingStateNode &&
                          !State.pendingRemovalMinionId;

        // Build Pending Nodes display table
        if (pendingMinions.length) {
          for (i = 0; i < pendingMinions.length; i++) {
            pendingRendered += MinionPoller.renderPendingNodes(pendingMinions[i]);
          }

          $(".pending-nodes-container tbody").html(pendingRendered);
        }

        // Show / Hide the table depending the presence of pending nodes
        checkAcceptAllAvailability();
        $(".pending-nodes-container .has-content").toggleClass('hidden', pendingMinions.length === 0);
        $(".pending-nodes-container .empty-text").toggleClass('hidden', pendingMinions.length > 0);

        // show/hide panels on discovery page
        $('.discovery-nodes-panel').toggleClass('hide', allMinions.length === 0);
        $('.discovery-empty-panel').toggleClass('hide', allMinions.length > 0);

        MinionPoller.handleAdminUpdate(data.admin || {});
        MinionPoller.handleRetryableOrchestrations(data);

        handleBootstrapErrors();
        handleUnsupportedClusterConfiguration();

        // show/hide "update all nodes" link
        var hasAdminNodeUpdate = data.admin.tx_update_reboot_needed || data.admin.tx_update_failed;
        State.updateAllNodes = updateAvailable && !hasAdminNodeUpdate;
        $("#update-all-nodes").toggleClass('hidden', !State.updateAllNodes);

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

            if (!State.hasPendingStateNode &&
                !State.pendingRemovalMinionId &&
                unassignedMinions.length) {
              unassignedCountText += ' <a href="' + addNodesUrl + '" class="assign-nodes-link">(new)</a>';
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

  renderPendingNodes: function(pendingMinionId) {
    var acceptHtml;

    if (State.hasPendingStateNode || State.pendingRemovalMinionId) {
      acceptHtml = '';
    } else if (hasPendingAcceptance(pendingMinionId)) {
      acceptHtml = 'Acceptance in progress';
    } else {
      acceptHtml = '<a class="accept-minion" href="#" data-minion-id="' + pendingMinionId + '">Accept Node</a>';
    }

    return '\
      <tr> \
        <td>' + pendingMinionId + '</td>\
        <td class="pending-accept-link">' + acceptHtml + '</td>\
      </tr> \
    ';
  },

  handleAdminUpdate: function(admin) {
    var $notification = $('.admin-outdated-notification');

    if (State.hasPendingStateNode ||
        State.pendingRemovalMinionId) {
      State.updateAdminNode = false;
      return;
    }

    if (admin.tx_update_reboot_needed) {
      State.updateAdminNode = true;
      $notification.removeClass('hidden');
      $notification.removeClass('admin-outdated-notification--failed');
    } else if (admin.tx_update_failed) {
      State.updateAdminNode = true;
      $notification.removeClass('hidden');
      $notification.addClass('admin-outdated-notification--failed');
    } else {
      State.updateAdminNode = false;
      $notification.addClass('hidden');
    }
  },

  handleRetryableOrchestrations: function(data) {
    if (data.retryable_bootstrap_orchestration) {
      $('#retry-cluster-bootstrap').removeClass('hidden');
    } else {
      $('#retry-cluster-bootstrap').addClass('hidden');
    }
    if (data.retryable_upgrade_orchestration) {
      $('#retry-cluster-upgrade').removeClass('hidden');
    } else {
      $('#retry-cluster-upgrade').addClass('hidden');
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
    var actionsHtml;
    var removalFailedClass = '';

    switch(minion.highstate) {
      case "not_applied":
        statusHtml = '<i class="fa fa-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
      case "pending_removal":
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
      case "removal_failed":
        removalFailedClass = 'removal-failed';
        statusHtml = '<i class="fa fa-minus-circle text-danger fa-2x" aria-hidden="true"></i> Removal Failed';
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


    if (minion.tx_update_reboot_needed) {
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
    } else if (minion.tx_update_failed) {
      statusHtml = '<i class="fa fa-arrow-circle-up text-danger fa-2x" aria-hidden="true"></i> Update Failed';
    }

    if (State.pendingRemovalMinionId || State.hasPendingStateNode) {
      actionsHtml = '<a href="#" class="disabled remove-node-link">Remove</a><a href="#" class="disabled force-remove-node-link">Force remove</a>';
    } else {
      actionsHtml = '<a href="#" class="remove-node-link">Remove</a><a href="#" class="force-remove-node-link">Force remove</a>';
    }

    if (minion.minion_id === State.pendingRemovalMinionId) {
      actionsHtml = 'Pending removal';
    }

    // do not show any action if only 1 master and 1 worker
    if (isTheLast(minion, 'worker') || isTheLast(minion, 'master')) {
      actionsHtml = '';
    }

    return '\
      <tr> \
        <td class="status">' + statusHtml +  '</td>\
        <td><strong>' + minion.minion_id +  '</strong></td>\
        <td class="minion-hostname">' + minion.fqdn +  '</td>\
        <td>' + masterHtml + minion.role + '</td>\
        <td class="actions-column ' + removalFailedClass + '" data-id="' + minion.minion_id + '" data-hostname="' + minion.fqdn + '">' + actionsHtml + '</td>\
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
        <td class="minion-hostname">' + minion.fqdn + '</td>' +
        roleHtml +
      '</tr>';
  },

  renderUnassigned: function(minion) {
    return MinionPoller.renderDiscovery(minion);
  }
};

function isTheLast(minion, role) {
  return minion.role === role &&
         State.minions.filter(function (m) { return m.role === role }).length === 1;
}

function hasPendingAcceptance(minionId) {
  return sessionStorage.getItem(minionId) === 'true';
}

function setPendingAcceptance(minionId) {
  sessionStorage.setItem(minionId, true);
  $('.pending-nodes-container a[data-minion-id="' + minionId + '"]').parent().text('Acceptance in progress');
}

function removePendingAcceptance(minionId) {
  sessionStorage.removeItem(minionId);
}

function requestMinionApproval(selector, minionIds) {
  var $alert = $('.failed-acceptance-alert');
  var error = 'Failed to accept all nodes. Please try again.';

  // normalize input
  if (!Array.isArray(minionIds)) {
    error = 'Failed to accept ' + minionIds + ' node. Please try again.';
    minionIds = [minionIds];
  }

  // set pending acceptance
  $.each(minionIds, function(_, id) {
    setPendingAcceptance(id);
  });

  $alert.remove();
  $.ajax({
    url: '/accept-minion.json',
    method: 'POST',
    data: { minion_id: selector }
  }).error(function () {
    $alert.remove();
    showAlert(error, 'alert', 'failed-acceptance-alert');
    $.each(minionIds, function (_, id) {
      removePendingAcceptance(id);
    });
  });
}

function checkAcceptAllAvailability() {
  var $acceptLinks = $('.pending-nodes-container td > a');

  $('#accept-all').prop('disabled', $acceptLinks.length === 0);
}

$('body').on('click', '#accept-all', function(e) {
  var $btn = $(this);
  var $acceptLinks = $('.pending-nodes-container td > a');

  e.preventDefault();
  $btn.prop('disabled', true);
  var minionIds = $.map($acceptLinks, function(el) {
    return el.dataset.minionId;
  });

  requestMinionApproval('*', minionIds);
});

$('body').on('click', '.accept-minion', function(e) {
  var minionId = $(this).data('minionId');

  e.preventDefault();
  requestMinionApproval(minionId, minionId);
  checkAcceptAllAvailability();
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
  var $btn = $(this);
  var $modal = $('.update-admin-modal');

  e.preventDefault();

  $btn.html('<i class="fa fa-spinner fa-pulse fa-fw"></i> Rebooting...');
  lockUpdateAdminModal();

  $.post($btn.data('url'))
  .done(function(data) {
    if (data.status === 'rebooting') {
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

// begin unassigned
function isAssignable() {
  var errors = [];
  var masters = State.assignedMinions.filter(function (m) { return m.role === 'master' });

  // We need an odd number of masters
  if (selectedMastersLength() > 0 &&
      (masters.length + selectedMastersLength()) % 2 === 0) {
    errors.push('The number of masters to be added needs to maintain the odd constraint number in the cluster');
  }

  // We need unique hostnames
  if (!hasUniqueHostnames()) {
    errors.push("There's a node in the cluster or selected with conflicting hostnames");
  }

  State.assignableErrors = errors;

  return errors.length === 0;
}

function showNodesSelectionErrors(errors, container) {
  var html = errors.map(function (e) { return '<li>' + e + '</li>' }).join('');
  $(container + ' .list').html(html);
  $(container).fadeIn(100);
}

function handleUnassignedErrors() {
  if (State.addNodesClicked && !isAssignable()) {
    showNodesSelectionErrors(State.assignableErrors, '.unassigned-alert')
    $('.add-nodes-btn').prop('disabled', true);
  } else {
    $('.unassigned-alert').fadeOut(100);
    $('.add-nodes-btn').prop('disabled', $('input:checked').length === 0);
  }
}

$('body').on('click', '.add-nodes-btn', function(e) {
  State.addNodesClicked = true;

  e.preventDefault();
  handleUnassignedErrors();

  if (isAssignable()) {
    MinionPoller.stop();
    $('form').submit();
  } else {
    window.scrollTo(0, 0);
  }
});
// end unassigned

// return number of selected nodes
function selectedWorkersLength() {
  return $('input[name="roles[worker][]"]:checked').length;
}

// return number of selected masters
function selectedMastersLength() {
  return $('input[name="roles[master][]"]:checked').length;
}

function hasUniqueHostnames() {
  var i = 0;
  var $newHostnames = $('input[name="roles[worker][]"]:checked, input[name="roles[master][]"]:checked').closest('tr').find('.minion-hostname');
  var newHostnames = $newHostnames.map(function (i, el) { return $(el).text() }).toArray() || [];
  var currentHostnames = $('.new-nodes-container').data('current-hostnames') || [];
  var hostnames = newHostnames.concat(currentHostnames);
  var obj = {};

  for (; i < hostnames.length; i++) {
    var hostname = hostnames[i].toLowerCase();

    if (obj[hostname] === 0) {
      return false;
    }

    obj[hostname] = 0;
  }

  return true;
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

  // We need unique hostnames
  if (!hasUniqueHostnames()) {
    errors.push("All nodes must have unique hostnames");
  }

  State.bootstrapErrors = errors;

  return errors.length === 0;
}

// return true if the selected masters vs workers are in a supported state
function isSupportedConfiguration() {
  // We need at least three nodes in total
  return (selectedWorkersLength() + selectedMastersLength()) >= 3;
}

// handle bootstrap button title
function handleBootstrapErrors() {
  if (State.nextClicked && !isBootstrappable()) {
    showNodesSelectionErrors(State.bootstrapErrors, '.discovery-bootstrap-alert')
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
  handleUnassignedErrors();
});

// select remaining nodes as workers
$('body').on('click', '.select-nodes-btn', function() {
  var workersSelector = 'input[name="roles[master][]"]:not(:checked) ~ .role-btn-group .worker-btn';

  $(this).hide();
  $('.deselect-nodes-btn').removeClass('hidden');
  $(workersSelector).click();

  handleBootstrapErrors();
  handleUnassignedErrors();
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
  handleUnassignedErrors();
});

// normal removal
$('body').on('click', '.remove-node-link', function (e) {
  var $this = $(this);
  var data = $this.parent().data();
  var minionId = data.id;
  var hostname = data.hostname;

  e.preventDefault();
  removePendingAcceptance(minionId);

  if ($this.hasClass('disabled')) {
    return;
  }

  if (confirm('Are you sure you want to remove ' + hostname + '?')) {
    if (canRemoveWithoutWarning(minionId)) {
      requestNodeRemoval(minionId);
    } else {
      showWarningRemovalModal('.warn-node-removal-modal', minionId);
    }
  }
});

$('body').on('click', '.remove-anyway', function (e) {
  var minionId = $('.warn-node-removal-modal').data('minionId');

  e.preventDefault();
  closeWarningRemovalModal('.warn-node-removal-modal');
  requestNodeRemoval(minionId);
});

function showWarningRemovalModal(modalSelector, minionId) {
  var itemsHtml = '';
  var errors = State.removalErrors || [];
  var $modal = $(modalSelector);

  for (var i = 0; i < errors.length; i++) {
    itemsHtml += '<li>' + errors[i] + '</li>';
  }

  $modal.find('.constraints-list').html(itemsHtml);
  $modal.find('.constraints-wrapper').toggle(!!errors.length);
  $(modalSelector).modal('show');
  $(modalSelector).data('minionId', minionId);
}

function closeWarningRemovalModal(modalSelector) {
  $(modalSelector).modal('hide');
  State.removalErrors = [];
}

function requestNodeRemoval(id) {
  State.pendingRemovalMinionId = id;

  $.ajax({
    url: '/minions/' + id,
    method: 'DELETE',
  }).done(disableOrchTriggers)
    .fail(enableOrchTriggers)
    .fail(notifyRemovalError);
}

function canRemoveWithoutWarning(minionId) {
  var errors = [];
  var minion = State.minions.find(function (m) { return m.minion_id === minionId });
  var newCluster = State.minions.filter(function (m) { return m.minion_id !== minionId });
  var masters = newCluster.filter(function (m) { return m.role === 'master' });
  var workers = newCluster.filter(function (m) { return m.role === 'worker' });

  // We need at least one master
  if (masters.length < 1) {
    errors.push("You need at least one master");
  }

  // We need at least one worker
  if (workers.length < 1) {
    errors.push("You need at least one worker");
  }

  // We need at least three nodes
  if (masters.length + workers.length < 3) {
    errors.push("Minimum of three nodes");
  }

  // We need an odd number of masters
  if (minion.role === 'master' && masters.length % 2 !== 1) {
    errors.push('The number of masters has to be an odd number');
  }

  State.removalErrors = errors;

  return errors.length === 0;
};

function notifyRemovalError(a, b, c) {
  var text;

  if (a.responseText.indexOf('Orchestration') === 0) {
    text = a.responseText;
  } else {
    text = 'An attempt to remove node ' + State.pendingRemovalMinionId + ' has failed.';
  }

  showAlert(text, 'alert', 'failed-remove-alert');
};

function enableOrchTriggers() {
  $('.actions-column[data-id=' + State.pendingRemovalMinionId + ']').html('<a href="#" class="remove-node-link">Remove</a><a href="#" class="remove-node-link">Force remove</a>');
  $('.remove-node-link').removeClass('disabled');
  $('.force-remove-node-link').removeClass('disabled');
  $('.assign-nodes-link').removeClass('disabled');
  $('#update-all-nodes').toggleClass('hidden', !State.updateAllNodes);
  $('.pending-accept-link').removeClass('hidden');
  $('.admin-outdated-notification').toggleClass('hidden', !State.updateAdminNode);
};

function disableOrchTriggers(typeSelector) {
  $('.actions-column[data-id=' + State.pendingRemovalMinionId + ']').text('Pending removal');
  $('.force-remove-node-link').addClass('disabled');
  $('.remove-node-link').addClass('disabled');
  $('.assign-nodes-link').addClass('disabled');
  $('#update-all-nodes').addClass('hidden');
  $('.pending-accept-link').addClass('hidden');
  $('.admin-outdated-notification').addClass('hidden');
}

function handleUnsupportedClusterConfiguration() {
  var masters = State.minions.filter(function (m) { return m.role === 'master' });
  var workers = State.minions.filter(function (m) { return m.role === 'worker' });
  var $alert = $('.unsupported-alert');

  // We need at least three nodes
  if (masters.length + workers.length < 3) {
    $alert.find('.reason').text('a minimum of three nodes');
    $alert.fadeIn(100);
  } else if (masters.length % 2 === 0) {
    // We need an odd number of masters
    $alert.find('.reason').text('an odd number of masters nodes');
    $alert.fadeIn(100);
  } else {
    $alert.fadeOut(500);
  }
}

// forced removal
$('body').on('click', '.force-remove-node-link', function (e) {
  var $this = $(this);
  var data = $this.parent().data();
  var minionId = data.id;
  var hostname = data.hostname;

  e.preventDefault();
  removePendingAcceptance(minionId);

  if ($this.hasClass('disabled')) {
    return;
  }

  if (confirm('Are you sure you want to force remove ' + hostname + '?')) {
    showWarningRemovalModal('.warn-node-force-removal-modal', minionId);
  }
});

$('body').on('click', '.force-remove-anyway', function (e) {
  var minionId = $('.warn-node-force-removal-modal').data('minionId');

  closeWarningRemovalModal('.warn-node-force-removal-modal');
  requestNodeForceRemoval(minionId);
  return false;
});

function requestNodeForceRemoval(minionId) {
  State.pendingRemovalMinionId = minionId;

  $.ajax({
    url: '/minions/' + minionId + '/force',
    method: 'DELETE',
  }).done(disableOrchTriggers)
    .fail(enableOrchTriggers)
    .fail(notifyRemovalError);
}
