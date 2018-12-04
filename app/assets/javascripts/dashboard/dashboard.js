/* eslint-disable */

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
        var migrationAvailable = false;
        var updateAvailableNodeCount = 0;
        var migrationAvailableNodeCount = 0;

        // reset admin migrated
        State.adminMigrated = adminMigrated(data);

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
        State.lastOrchestrationAt = data.last_orchestration_at;

        var pendingStateMinion = minions.find(function (minion) {
          return minion.highstate == "pending";
        });

        State.hasPendingStateNode = !!pendingStateMinion;
        State.hasPendingStateAdmin = data.admin.highstate == "pending";

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

          if (minions[i].tx_update_migration_available) {
            migrationAvailable = true;
            migrationAvailableNodeCount++;
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

        migrationAvailable = migrationAvailable &&
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

        MinionPoller.handleAdminUpdate(data || {});
        MinionPoller.handleAdminMigration(data || {});
        MinionPoller.handleRetryableOrchestrations(data);

        handleBootstrapErrors();
        handleUnsupportedClusterConfiguration();
        showRepoMirrorAlert(data.admin);

        // show/hide "update all nodes" link
        var hasAdminNodeUpdate = data.admin.tx_update_reboot_needed || data.admin.tx_update_failed;
        State.updateAllNodes = updateAvailable && !hasAdminNodeUpdate && !adminMigrated(data);
        $("#update-all-nodes").toggleClass('hidden', !State.updateAllNodes);

        // show/hide "migrate all nodes" link
        var hasAdminNodeMigration = data.admin.tx_update_migration_available || data.admin.tx_update_failed;
        var nodeIsPending = State.minions.filter(function (m) { return m.highstate === "pending" }).length > 0;
        State.migrateAllNodes = migrationAvailable && !hasAdminNodeMigration && !nodeIsPending;
        $("#migrate-all-nodes").toggleClass('hidden', !State.migrateAllNodes);

        MinionPoller.enable_kubeconfig(masterApplied);

        if (updateAvailable) {
          $('#out_dated_nodes').text(updateAvailableNodeCount + ' ');
        } else if (migrationAvailable) {
          $('#out_dated_nodes').text(migrationAvailableNodeCount + ' ');
        }

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
    var acceptHtml = '';
    var rejectHtml = '';

    if (State.hasPendingStateNode || State.pendingRemovalMinionId) {
      acceptHtml = '';
      rejectHtml = '';
    } else if (hasPendingAcceptance(pendingMinionId)) {
      acceptHtml = 'Acceptance in progress';
    } else if (hasPendingRejection(pendingMinionId)) {
      rejectHtml = 'Rejection in progress';
    } else {
      acceptHtml = '<a class="accept-minion" href="#" data-minion-id="' + pendingMinionId + '">Accept</a>';
      rejectHtml = '&nbsp;|&nbsp;<a class="reject-minion" href="#" data-minion-id="' + pendingMinionId + '">Reject</a>';
    }

    return '\
      <tr class="minion_'+ pendingMinionId +'"> \
        <td>' + pendingMinionId + '</td>\
        <td class="pending-accept-link">' + acceptHtml + rejectHtml + '</td>\
      </tr> \
    ';
  },

  handleAdminUpdate: function(data) {
    var notification_class = 'admin-outdated-notification';
    var $notification = createAdminNotification(notification_class);
    var failedToUpdate = data.admin.tx_update_reboot_needed && State.minions.filter(function (m) {
      return m.highstate === "failed"
    }).length > 0

    if (State.hasPendingStateNode || State.hasPendingStateAdmin || State.pendingRemovalMinionId || failedToUpdate) {
      State.updateAdminNode = false;
      return;
    }

    var updateFlag = data.admin.tx_update_reboot_needed ||
                       (data.admin.tx_update_failed && !data.admin.tx_update_migration_available);

    State.updateAdminNode = updateFlag;
    $notification.toggleClass('hidden', !updateFlag);

    if (data.admin.tx_update_reboot_needed) {
      $notification.addClass(notification_class + '--reboot');
    }

    if (data.admin.tx_update_failed) {
      $notification.addClass(notification_class + '--failed');
    }
  },

  handleAdminMigration: function(data) {
    var notification_class = 'admin-migration-notification';
    var $notification = createAdminNotification(notification_class);

    if (State.hasPendingStateNode || State.pendingRemovalMinionId) {
      State.migrateAdminNode = false;
      return;
    }
    // check if any node is offline
    var anyNodeOffline = State.minions.filter(function (m) { return m.online === false }).length > 0;
    var onlyAdminUpdated = (
      !data.admin.tx_update_reboot_needed &&
        State.minions.filter(function (m) { return m.tx_update_reboot_needed }).length > 0
    )
    if (anyNodeOffline || onlyAdminUpdated) {
      return;
    }

    var migrateFlag = data.admin.tx_update_migration_available || data.admin.tx_update_failed;

    State.migrateAdminNode = migrateFlag;
    $notification.toggleClass('hidden', !migrateFlag);

    if (data.admin.tx_update_migration_available && !data.admin.tx_update_failed) {
      if (data.admin.tx_update_reboot_needed) {
        // prevent migration, enforce installing updates first
        $notification.addClass(notification_class + '--maintenance');
        $notification.find('div.message strong').html('<strong> Cluster has migration available. (Install Updates first)</strong>');
      } else if (data.admin.highstate == "pending") {
        $notification.addClass(notification_class + '--maintenance');
        $notification.find('div.message strong').html('<strong> Cluster has migration available. (Waiting for admin reboot)</strong>');
      } else {
        $notification.addClass(notification_class + '--install');
        $notification.find('div.message strong').html('<strong> Cluster has migration available. </strong>');
      }
    }

    if (data.admin.tx_update_failed) {
      $notification.addClass(notification_class + '--failed');
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
    if (data.retryable_migration_orchestration) {
      $('#retry-cluster-migration').removeClass('hidden');
    } else {
      $('#retry-cluster-migration').addClass('hidden');
    }
  },

  enable_kubeconfig: function(enabled) {
    $("#download-kubeconfig").attr("disabled", !enabled);
  },

  alertFailedBootstrap: function() {
    var cachedFailedLastOrchestration = window.localStorage.getItem('failedLastOrchestrationAt');

    if ($('.failed-bootstrap-alert').length ||
        cachedFailedLastOrchestration === State.lastOrchestrationAt) {
      return;
    }

    var $alert = showAlert('At least one of the nodes is in a failed state. Please run "supportconfig" on the failed node(s) to gather the logs.', 'alert', 'failed-bootstrap-alert');

    window.localStorage.removeItem('failedLastOrchestrationAt');
    $alert.on('closed.bs.alert', function () {
      window.localStorage.setItem('failedLastOrchestrationAt', State.lastOrchestrationAt);
      $alert.off('closed.bs.alert');
    })
  },

  renderDashboard: function(minion) {
    var appliedHtml;
    var checked;
    var masterHtml;
    var actionsHtml;
    var removalFailedClass = '';

    switch(minion.highstate) {
      case "not_applied":
        appliedHtml = '<i class="fa fa-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
      case "pending_removal":
      case "pending":
        appliedHtml = '\
          <span class="fa-stack" aria-hidden="true">\
            <i class="fa fa-circle fa-stack-2x text-muted" aria-hidden="true"></i>\
            <i class="fa fa-refresh fa-stack-1x fa-spin fa-inverse" aria-hidden="true"></i>\
          </span>';
        break;
      case "failed":
        appliedHtml = '<i class="fa fa-times-circle text-danger fa-2x" aria-hidden="true"></i>';
        MinionPoller.alertFailedBootstrap();
        break;
      case "removal_failed":
        removalFailedClass = 'removal-failed';
        appliedHtml = '<i class="fa fa-minus-circle text-danger fa-2x" aria-hidden="true"></i> Removal Failed';
        break;
      case "applied":
        appliedHtml = '<i class="fa fa-check-circle-o text-success fa-2x" aria-hidden="true"></i>';
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
          appliedHtml = '<i class="fa fa-arrow-circle-up text-info fa-2x" aria-hidden="true"></i> Update Available';
          break;
        case "failed":
          appliedHtml = '<i class="fa fa-arrow-circle-up text-warning fa-2x" aria-hidden="true"></i> Update Failed - Retryable';
          break;
        case "pending":
          if (!minion.online) {
            appliedHtml += ' Rebooting'
          } else {
            appliedHtml += ' Update in progress'
          }
          break;
      }
    }

    if (minion.tx_update_migration_available && (State.adminMigrated || !overlapSupport())) {
      switch (minion.highstate) {
        case "applied":
          appliedHtml = '<i class="fa fa-arrow-circle-up text-info fa-2x" aria-hidden="true"></i> Migration Available';
          break;
        case "failed":
          appliedHtml = '<i class="fa fa-arrow-circle-up text-warning fa-2x" aria-hidden="true"></i> Migration Failed - Retryable';
          break;
        case "pending":
          if(minion.online) {
            msg = 'Migration in progress'
          } else {
            msg = 'Rebooting'
          }
          appliedHtml = appliedHtml.replace('Update in progress', msg)
          break;
      }
    }

    if (minion.tx_update_failed) {
      appliedHtml = '<i class="fa fa-arrow-circle-up text-danger fa-2x" aria-hidden="true"></i> Update Failed';
    }

    // Public Cloud frameworks do not currently support removing nodes
    if (['azure', 'ec2', 'gce'].indexOf(minion.cloud_framework) > -1) {
      actionsHtml = '';
    } else {
      if (State.pendingRemovalMinionId || State.hasPendingStateNode) {
        actionsHtml = '<a href="#" class="disabled remove-node-link">Remove</a><a href="#" class="disabled force-remove-node-link">Force remove</a>';
      } else {
        actionsHtml = '<a href="#" class="remove-node-link">Remove</a><a href="#" class="force-remove-node-link">Force remove</a>';
      }
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
        <td class="status">' + onlineHtml(minion) +  '</td>\
        <td class="status">' + appliedHtml +  '</td>\
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

    var masterChecked = '';
    var minionChecked = '';
    var disabledHtml = '';
    var disabledClass = '';

    if (State.pendingRemovalMinionId != null){
      disabledHtml = 'disabled="disabled"';
      disabledClass = 'disabled';
      $('.select-nodes-btn').prop('disabled', true);
    }else{
      $('.select-nodes-btn').prop('disabled', false);
    }

    if (isMaster) {
      masterChecked = 'checked';
    }

    var masterHtml = '\
      <input hidden name="roles[master][]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="checkbox" title="Select node as master" ' + masterChecked + '>';

    if (isWorker) {
      minionChecked = 'checked';
    }

    var minionHtml = '\
      <input hidden name="roles[worker][]" id="roles_worker_' + minion.id +
      '" value="' + minion.id + '" type="checkbox" title="Select node for bootstrapping" ' + minionChecked + '>';
    var roleHtml = '\
      <td class="role-column" id="role-column-'+ minion.minion_id +'">' +
        masterHtml +
        minionHtml +
        '<div class="btn-group role-btn-group">\
          <button type="button" '+ disabledHtml +' class="btn btn-default master-btn '+ (isMaster ? 'btn-primary' : '') + '" data-minion-id="' + minion.id + '" data-minion-role="master">Master</button>\
          <button type="button" '+ disabledHtml +' class="btn btn-default worker-btn ' + (isWorker ? 'btn-primary' : '') + '" data-minion-id="' + minion.id + '" data-minion-role="worker">Worker</button>\
          <button type="button" '+ disabledHtml +' class="btn btn-default unused-btn ' + (isUnused ? 'btn-primary' : '') + '" data-minion-id="' + minion.id + '">Unused</button>\
        </div>\
      </td>\
    ';

    var actionHtml = '\
      <td class="action-column">\
        <a class="remove-minion '+ disabledClass +'" href="#" data-minion-id="' + minion.minion_id + '" data-minion-fqdn="' + minion.fqdn + '">Remove</a>\
      </td>\
    ';

    switch (minion.highstate) {
      case "pending_removal":
        $('#set-roles').prop('disabled', true);
        actionHtml = '<td class="action-column">Pending removal</td>';
        break;
    }

    return '\
      <tr class="minion_' + minion.id + '">' +
        '<td>' + minion.minion_id + '</td>\
        <td class="minion-hostname">' + minion.fqdn + '</td>' +
        roleHtml +
        actionHtml +
      '</tr>';
  },

  renderUnassigned: function(minion) {
    return MinionPoller.renderDiscovery(minion);
  }
};

function removeNode(minionId, hostname) {
  var $alert = $('.failed-removal-alert');
  var error = 'Failed to remove node '+ minionId +'. Please try again.';

  if (confirm('Are you sure you want to remove ' + hostname + '?')) {
    setPendingRemoval(minionId);
    $.ajax({
      url: '/minions/'+ minionId +'/remove-minion.json',
      method: 'POST',
      data: { minion_id: minionId },
      dataType: 'text'
    }).fail(function () {
      $alert.remove();
      removePendingRemoval();
      showAlert(error, 'alert', 'failed-removal-alert');
    });
  }
}

function rejectNode(minionId) {
  var $alert = $('.failed-rejection-alert');
  var error = 'Failed to reject node '+ minionId +'. Please try again.';

  if (confirm('Are you sure you want to reject ' + minionId + '?')) {
    setPendingRejection(minionId);
    $.ajax({
      url: '/minions/'+ minionId +'/reject-minion.json',
      method: 'POST',
      data: { minion_id: minionId },
      dataType: 'text'
    }).fail(function () {
      removePendingRejection(minionId);
      $alert.remove();
      showAlert(error, 'alert', 'failed-rejection-alert');
    });
  }
}

function isTheLast(minion, role) {
  var remainingValid = State.minions.filter(function (m) {
    return m.role === role &&
           m.highstate !== 'removal_failed';
  });

  return minion.role === role &&
         remainingValid.length === 1 &&
         !(minion.highstate === 'removal_failed');
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

function hasPendingRejection(minionId) {
  return sessionStorage.getItem('reject-'+minionId) === 'true';
}

function setPendingRejection(minionId) {
  sessionStorage.setItem('reject-'+minionId, true);
  $('.pending-nodes-container a[data-minion-id="' + minionId + '"]').parent().text('Rejection in progress');
}

function removePendingRejection(minionId) {
  sessionStorage.removeItem('reject-'+minionId);
}

function setPendingRemoval(minionId) {
  $('.nodes-container a[data-minion-id="' + minionId + '"]').parent().text('Pending removal');
  $('#set-roles').data('previous', $('#set-roles').prop('disabled'));
  $('#set-roles').prop('disabled', true);
  $('.select-nodes-btn').prop('disabled', true);
  $('.role-column .btn').prop('disabled', true);
  $('.remove-minion').addClass('disabled');
}

function removePendingRemoval() {
  $('.role-column .btn').prop('disabled', false);
  $('.remove-minion').removeClass('disabled', false);
  $('.select-nodes-btn').prop('disabled', false);
  $('#set-roles').data('previous', $('#set-roles').prop('disabled'));
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
    url: '/minions/'+ selector +'/accept-minion.json',
    method: 'POST',
    data: { minion_id: selector },
    dataType: 'text'
  }).fail(function () {
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

$('body').on('click', '.remove-minion', function(e) {
  var minionId = $(this).data('minion-id');
  var fqdn = $(this).data('minion-fqdn')

  e.preventDefault();
  if ($(this).hasClass('disabled')) {
    return;
  }
  removeNode(minionId, fqdn);
});

$('body').on('click', '.reject-minion', function(e) {
  var minionId = $(this).data('minion-id');

  e.preventDefault();
  rejectNode(minionId);
});

$('.update-admin-modal').on('hide.bs.modal', function(e) {
  var isRebooting = $('.update-admin-modal').data('rebooting');

  if (isRebooting) {
    e.preventDefault();
  }
});

$('.migrate-admin-modal').on('hide.bs.modal', function(e) {
  var isMigrating = $('.migrate-admin-modal').data('migrating');

  if (isMigrating) {
    e.preventDefault();
  }
});

$('.mirror-sync-modal').on('hide.bs.modal', function(e) {
  var isSyncing = $('.mirror-sync-modal').data('syncing');

  if (isSyncing) {
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

// unlock modal, now closable
function unlockMigrateAdminModal() {
  var $modal = $('.migrate-admin-modal');
  var $btn = $modal.find('.btn');

  $modal.data('migrating', false);
  $modal.find('.close').show();
  $btn.prop('disabled', false);
}

// lock modal, won't close
function lockMigrateAdminModal() {
  var $modal = $('.migrate-admin-modal');
  var $btn = $modal.find('.btn');

  $btn.prop('disabled', true);
  $modal.data('migrating', true);
  $modal.find('.close').hide();
}

// unlock modal, now closable
function unlockMirrorSyncModal() {
  var $modal = $('.warn-mirror-sync-modal');
  var $btn = $modal.find('.btn');

  $modal.data('syncing', false);
  $modal.find('.close').show();
  $btn.prop('disabled', false);
}

// lock modal, won't close
function lockMirrorSyncModal() {
  var $modal = $('.warn-mirror-sync-modal');
  var $btn = $modal.find('.btn');

  $btn.prop('disabled', true);
  $modal.data('syncing', true);
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

// migrate admin node handler
$('body').on('click', '.trigger-migrate-admin-btn', function(e) {
  var $btn = $(this);
  var $modal = $('.migrate-admin-modal');

  // should any node have an out of sync mirror, open the sync modal
  if(showMirrorSyncModal() > 0) {
    $modal.modal('hide');
    return
  }

  e.preventDefault();

  $btn.html('<i class="fa fa-spinner fa-pulse fa-fw"></i> Migrating...');
  lockMigrateAdminModal();

  State.hasPendingStateNode = true;

  $.post($btn.data('url'))
  .done(function(data) {
    // Here we need to wait for the orchestration to complete, AND check for a reboot
    setTimeout(migrationCheckToReload, 10000);
  })
  .fail(function() {
    unlockMigrateAdminModal();
    $btn.text('Migrate admin (failed last time)');
  });
});

$('body').on('click', '.confirm-mirror-synced-btn', function(e) {
  var $btn = $(this);
  var $modal = $('.migrate-admin-modal');

  e.preventDefault();

  $btn.html('<i class="fa fa-spinner fa-pulse fa-fw"></i> Checking...');
  lockMirrorSyncModal();

  $.post($btn.data('url'))
  .success(function() {
    window.location.reload();
  })
  .fail(function() {
    // mark failed
    unlockMirrorSyncModal();
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

// migration status check
function migrationCheckToReload() {
  var migrationCheckUrl = $('.migrate-update-btn').data('migrationCheck');

  $.get(migrationCheckUrl)
  .success(function() {
    // check for in_progress migration
    setTimeout(migrationCheckToReload, 10000);
  })
  .fail(function() {
    // rebooting
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
  if (State.pendingRemovalMinionId) {
    return;
  }
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
  $('#migrate-all-nodes').toggleClass('hidden', !State.migrateAllNodes);
  $('.pending-accept-link').removeClass('hidden');
  $('.admin-outdated-notification').toggleClass('hidden', !State.updateAdminNode);
};

function disableOrchTriggers(typeSelector) {
  $('.actions-column[data-id=' + State.pendingRemovalMinionId + ']').text('Pending removal');
  $('.force-remove-node-link').addClass('disabled');
  $('.remove-node-link').addClass('disabled');
  $('.assign-nodes-link').addClass('disabled');
  $('#update-all-nodes').addClass('hidden');
  $('#migrate-all-nodes').addClass('hidden');
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

function showRepoMirrorAlert(admin) {
  // show mirror sync alert only when there's no node in pending state
  if (State.minions.filter(function (m) { return m.highstate === "pending" }).length > 0) {
    return;
  }
  var minions = State.minions;
  var $alert = $('.repomirror-sync-alert');
  // + 1 for the admin
  var node_number = minions.length;
  var in_sync = true;

  // check admin
  in_sync = admin.tx_update_migration_mirror_synced

  // check minions
  if (in_sync) {
    for (var i = 0; i < node_number; i++) {
      in_sync = minions[i].tx_update_migration_mirror_synced
      if (!in_sync) { break; }
    }
  }

  if (!in_sync) {
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

function onlineHtml(minion) {
  if(minion.online) {
    return '<i class="fa fa-circle text-success fa-2x" aria-hidden="true" title="Online"></i>';
  } else {
    return '<i class="fa fa-circle text-danger fa-2x" aria-hidden="true" title="Offline (last updated at: ' + minion.updated_at + ' admin server time)"></i>';
  }
}

function showMirrorSyncModal() {
  unsynced_node_number = State.minions.filter(function (m) { return m.tx_update_migration_mirror_synced === false }).length;
  if(unsynced_node_number > 0) {
    $('.warn-mirror-sync-modal').modal('show');
  }
  return unsynced_node_number;
}

function overlapSupport() {
  return State.minions.filter(function (m) {
    return m.tx_update_reboot_needed && m.tx_update_migration_available
  }).length > 0
}

function adminMigrated(data) {
  // check if we are in the middle of a migration
  var migrated = false;
  for (var i = 0; i < data.assigned_minions.length; i++) {
    if (data.assigned_minions[i].os_release != data.admin.os_release) {
      migrated = true;
    }
  }
  return migrated;
}

function createAdminNotification(n) {
  var notification = $('.' + n);
  // cleanup old messages
  ['reboot', 'failed', 'maintenance', 'install'].forEach(function(id) {
    notification.removeClass(n + '--' + id);
  });

  return notification;
}
