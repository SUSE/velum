(function () {
  var globals = this;

  var dom = {
    URL_GROUP: '.form-group-url',
    URL_INPUT: '.url',
    URL_INVALID_INSECURE: '.invalid-insecure',
    URL_INVALID_FORMAT: '.invalid-format',
    INVALID: '.help-block',
    CERTIFICATE_GROUP: '.form-group-certificate',
    REGISTRY_SELECT: '.registry-select',
    CREATE_REGISTRY_BTN: '.add-entry-btn'
  };

  function RegistryForm(el) {
    this.$el = $(el);
    this.$url = this.$el.find(dom.URL_INPUT);
    this.$urlGroup = this.$el.find(dom.URL_GROUP);
    this.$invalidUrlFormat = this.$el.find(dom.URL_INVALID_FORMAT);
    this.$invalidUrlInsecure = this.$el.find(dom.URL_INVALID_INSECURE);
    this.$certificateGroup = this.$el.find(dom.CERTIFICATE_GROUP);
    this.$registrySelect = this.$el.find(dom.REGISTRY_SELECT);

    this.events();
    this.init();
  }

  RegistryForm.prototype.events = function () {
    this.$el.on('input', dom.URL_INPUT, this.validate.bind(this));
    this.$el.on('input', dom.URL_INPUT, this.toggleCertificateField.bind(this));
    this.$el.on('change', dom.REGISTRY_SELECT, this.toggleCreateRegistry.bind(this));
  };

  RegistryForm.prototype.toggleCreateRegistry = function () {
    var selected = this.$registrySelect.val();
    this.$el.find(dom.CREATE_REGISTRY_BTN).toggleClass('hide', !!selected);
  };

  RegistryForm.prototype.toggleCertificateField = function () {
    var urlValue = this.$url.val();
    var isHttps = this.isValidURL(urlValue)
               && urlValue.indexOf('https://') === 0;

    this.$certificateGroup.toggleClass('hide', !isHttps);
  };

  RegistryForm.prototype.isValidURL = function (urlValue) {
    var url;
    var isHttps;

    try {
      url = new URL(urlValue);
      isHttps = url.protocol === 'https:';

      return (url.protocol === 'http:' || isHttps) && !!url.host;
    } catch (error) {
      return false;
    }
  };

  RegistryForm.prototype.validate = function () {
    this.clearValidation();

    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }

    this.timeoutId = setTimeout(function () {
      var urlValue = this.$url.val();
      var valid = this.isValidURL(urlValue);

      if (valid) {
        this.checkInsecure();
      }

      // avoid validation when it's empty
      if (!urlValue) {
        valid = true;
      }

      this.$urlGroup.toggleClass('has-error', !valid);
      this.$invalidUrlFormat.toggleClass('hide', valid);
      this.timeoutId = null;
    }.bind(this), 750);
  };

  RegistryForm.prototype.clearValidation = function () {
    this.$urlGroup.find(dom.INVALID).addClass('hide');
    this.$urlGroup.removeClass('has-error');
  };

  RegistryForm.prototype.checkInsecure = function () {
    var url = this.$url.val();
    var isSecure = url.indexOf('https') === 0;

    this.$el.find(dom.URL_INVALID_INSECURE).toggleClass('hide', isSecure);
  };

  RegistryForm.prototype.init = function () {
    this.toggleCreateRegistry();
  };

  globals.RegistryForm = RegistryForm;
}.call(window));
