$(function() {
  // https://stackoverflow.com/questions/10420352/converting-file-size-in-bytes-to-human-readable-string
  // https://creativecommons.org/licenses/by-sa/4.0/
  function humanFileSize(bytes, si) {
      var thresh = si ? 1000 : 1024;
      if(Math.abs(bytes) < thresh) {
          return bytes + ' B';
      }
      var units = si
          ? ['kB','MB','GB','TB','PB','EB','ZB','YB']
          : ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
      var u = -1;
      do {
          bytes /= thresh;
          ++u;
      } while(Math.abs(bytes) >= thresh && u < units.length - 1);
      return bytes.toFixed(1)+' '+units[u];
  }

  function calcClusterVcpus() {
      vcpusPerVm = $('.instance-type-description .vcpu-count').data('vcpus');
      vmCount = clusterSize.getValue();
      $('#cluster-cpu-count').html(vcpusPerVm * vmCount);
  }

  function calcClusterRam() {
      bytesPerVm = $('.instance-type-description .ram-size').data('bytes');
      siUnits = $('.instance-type-description .ram-size').data('si');
      vmCount = clusterSize.getValue();
      totalBytes = bytesPerVm * vmCount;
      $('#cluster-ram-size').attr('data-bytes', totalBytes);
      $('#cluster-ram-size').html(humanFileSize(totalBytes, siUnits))
  }

  var updateClusterSize = function() {
      calcClusterVcpus();
      calcClusterRam();
  }

  var clusterSize = $('#cloud_cluster_instance_count').slider()
    .on('slide change', updateClusterSize).data('slider');

  $('input[name="cloud_cluster[instance_type]"]').click(function() {
      definition = $(this).siblings('.definition').html();
      $('.instance-type-description').html(definition);
      ramSize = $('.instance-type-description .ram-size')
      ramSize.html(
          humanFileSize(ramSize.data('bytes'), ramSize.data('si'))
      )

      if (this.id === 'cloud_cluster_instance_type_custom') {
        $('.cluster-cpu-count,.cluster-ram-size').hide();
        $('input#cloud_cluster_instance_type_custom[type="text"]').
            show().focus();
      } else {
        $('input#cloud_cluster_instance_type_custom[type="text"]').
            val("").hide();
        updateClusterSize();
        $('.cluster-cpu-count,.cluster-ram-size').show();
      }
  });

  // kick things off
  $('input[name="cloud_cluster[instance_type]"][checked="checked"]').click();

  // only submit once
  $('form#new_cloud_cluster').submit(function(){
      $(this).find('input[type=submit]').prop('disabled', true);
  });
});
