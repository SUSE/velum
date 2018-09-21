(function () {
  var globals = this;

  var dom = {
    PROJECT_NAME_INPUT: '#settings_cloud_openstack_project',
    PROJECT_NAME_LABEL: 'label[for=settings_cloud_openstack_project]',
    PROJECT_ID_INPUT: '#settings_cloud_openstack_project_id',
    PROJECT_ID_LABEL: 'label[for=settings_cloud_openstack_project_id]',

    DOMAIN_NAME_INPUT: '#settings_cloud_openstack_domain',
    DOMAIN_NAME_LABEL: 'label[for=settings_cloud_openstack_domain]',
    DOMAIN_ID_INPUT: '#settings_cloud_openstack_domain_id',
    DOMAIN_ID_LABEL: 'label[for=settings_cloud_openstack_domain_id]',

    REQUIRED_INPUTS: 'input[required="required"]'
  };

  function OpenStackSettings(el) {
    this.$el = $(el);

    this.$projectIdInput = this.$el.find(dom.PROJECT_ID_INPUT);
    this.$projectIdLabel = this.$el.find(dom.PROJECT_ID_LABEL);
    this.$projectNameInput = this.$el.find(dom.PROJECT_NAME_INPUT);
    this.$projectNameLabel = this.$el.find(dom.PROJECT_NAME_LABEL);

    this.$domainIdInput = this.$el.find(dom.DOMAIN_ID_INPUT);
    this.$domainIdLabel = this.$el.find(dom.DOMAIN_ID_LABEL);
    this.$domainNameInput = this.$el.find(dom.DOMAIN_NAME_INPUT);
    this.$domainNameLabel = this.$el.find(dom.DOMAIN_NAME_LABEL);

    this.$requiredInputs = this.$el.find(dom.REQUIRED_INPUTS);

    this.events();
  }

  OpenStackSettings.prototype.events = function () {
    this.$el.on('input', dom.PROJECT_ID_INPUT, this.onProjectIdInput.bind(this));
    this.$el.on('input', dom.PROJECT_NAME_INPUT, this.onProjectNameInput.bind(this));
    this.$el.on('input', dom.DOMAIN_ID_INPUT, this.onDomainIdInput.bind(this));
    this.$el.on('input', dom.DOMAIN_NAME_INPUT, this.onDomainNameInput.bind(this));

    this.$el.on('settings.enabled', this.settingsEnabled.bind(this));
    this.$el.on('settings.disabled', this.settingsDisabled.bind(this));
  };

  OpenStackSettings.prototype.onProjectIdInput = function () {
    var isIdEmpty = this.isEmpty(this.$projectIdInput);

    this.$projectNameInput.prop('disabled', !isIdEmpty);
    this.$projectNameLabel.attr('required', isIdEmpty);
  };

  OpenStackSettings.prototype.onProjectNameInput = function () {
    var isNameEmpty = this.isEmpty(this.$projectNameInput);

    this.$projectIdInput.prop('disabled', !isNameEmpty);
    this.$projectIdLabel.attr('required', isNameEmpty);
  };

  OpenStackSettings.prototype.onDomainIdInput = function () {
    var isIdEmpty = this.isEmpty(this.$domainIdInput);

    this.$domainNameInput.prop('disabled', !isIdEmpty);
    this.$domainNameLabel.attr('required', isIdEmpty);
  };

  OpenStackSettings.prototype.onDomainNameInput = function () {
    var isNameEmpty = this.isEmpty(this.$domainNameInput);

    this.$domainIdInput.prop('disabled', !isNameEmpty);
    this.$domainIdLabel.attr('required', isNameEmpty);
  };

  OpenStackSettings.prototype.settingsDisabled = function () {
    this.$requiredInputs.prop('required', false);
  };

  OpenStackSettings.prototype.settingsEnabled = function () {
    this.$requiredInputs.prop('required', true);
    this.onDomainNameInput();
    this.onDomainIdInput();
    this.onProjectNameInput();
    this.onProjectIdInput();
  };

  OpenStackSettings.prototype.isEmpty = function (els) {
    var value = $.map(els, function (el) { return el.value; }).join('');

    return value.length === 0;
  };

  globals.OpenStackSettings = OpenStackSettings;
}.call(window));
