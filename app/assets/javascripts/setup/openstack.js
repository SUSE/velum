(function (window) {
  var dom = {
    NAME_INPUTS: '#settings_cloud_openstack_domain, #settings_cloud_openstack_project',
    ID_INPUTS: '#settings_cloud_openstack_domain_id, #settings_cloud_openstack_project_id',
  };

  function OpenStackSettings(el) {
    this.$el = $(el);

    this.$idInputs = this.$el.find(dom.ID_INPUTS);
    this.$nameInputs = this.$el.find(dom.NAME_INPUTS);

    this.events();
  }

  OpenStackSettings.prototype.events = function () {
    this.$el.on('input', dom.ID_INPUTS, this.onIdInputs.bind(this));
    this.$el.on('input', dom.NAME_INPUTS, this.onNameInputs.bind(this));
  }

  OpenStackSettings.prototype.onIdInputs = function (e) {
    this.$nameInputs.prop('disabled', !this.isEmpty(this.$idInputs));
  }

  OpenStackSettings.prototype.onNameInputs = function (e) {
    this.$idInputs.prop('disabled', !this.isEmpty(this.$nameInputs));
  }

  OpenStackSettings.prototype.isEmpty = function (els) {
    var value = $.map(els, function (el) { return el.value }).join('');

    return value.length === 0;
  }

  window.OpenStackSettings = OpenStackSettings;
}(window));