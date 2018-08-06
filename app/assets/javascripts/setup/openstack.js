(function (window) {
  var dom = {
    PROJECT_NAME_INPUT: '#settings_cloud_openstack_project',
    PROJECT_ID_INPUT: '#settings_cloud_openstack_project_id',

    DOMAIN_NAME_INPUT: '#settings_cloud_openstack_domain',
    DOMAIN_ID_INPUT: '#settings_cloud_openstack_domain_id',
  };

  function OpenStackSettings(el) {
    this.$el = $(el);

    this.$projectIdInput = this.$el.find(dom.PROJECT_ID_INPUT);
    this.$projectNameInput = this.$el.find(dom.PROJECT_NAME_INPUT);

    this.$domainIdInput = this.$el.find(dom.DOMAIN_ID_INPUT);
    this.$domainNameInput = this.$el.find(dom.DOMAIN_NAME_INPUT);

    this.events();
  }

  OpenStackSettings.prototype.events = function () {
    this.$el.on('input', dom.PROJECT_ID_INPUT, this.onProjectIdInput.bind(this));
    this.$el.on('input', dom.PROJECT_NAME_INPUT, this.onProjectNameInput.bind(this));

    this.$el.on('input', dom.DOMAIN_ID_INPUT, this.onDomainIdInput.bind(this));
    this.$el.on('input', dom.DOMAIN_NAME_INPUT, this.onDomainNameInput.bind(this));
  }

  OpenStackSettings.prototype.onProjectIdInput = function (e) {
    this.$projectNameInput.prop('disabled', !this.isEmpty(this.$projectIdInput));
  }

  OpenStackSettings.prototype.onProjectNameInput = function (e) {
    this.$projectIdInput.prop('disabled', !this.isEmpty(this.$projectNameInput));
  }

  OpenStackSettings.prototype.onDomainIdInput = function (e) {
    this.$domainNameInput.prop('disabled', !this.isEmpty(this.$domainIdInput));
  }

  OpenStackSettings.prototype.onDomainNameInput = function (e) {
    this.$domainIdInput.prop('disabled', !this.isEmpty(this.$domainNameInput));
  }

  OpenStackSettings.prototype.isEmpty = function (els) {
    var value = $.map(els, function (el) { return el.value }).join('');

    return value.length === 0;
  }

  window.OpenStackSettings = OpenStackSettings;
}(window));
