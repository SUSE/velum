(function (window) {
  var dom = {
    MIRROR_URL_GROUP: '.mirror-url-group',
    MIRROR_URL_INPUT: '#settings_suse_registry_mirror_url',
    MIRROR_INVALID_INSECURE: '.invalid-insecure',
    MIRROR_INVALID_URL: '.invalid-url',
  };

  function SUSERegistryMirrorPanel(el) {
    this.$el = $(el);

    this.$url = this.$el.find(dom.MIRROR_URL_INPUT);
    this.$urlGroup = this.$el.find(dom.MIRROR_URL_GROUP);
    this.$invalidUrl = this.$el.find(dom.MIRROR_INVALID_URL);
    this.$invalidInsecure = this.$el.find(dom.MIRROR_INVALID_INSECURE);

    this.events();
  }

  SUSERegistryMirrorPanel.prototype.events = function () {
    this.$el.on('input', dom.MIRROR_URL_INPUT, this.validate.bind(this));
  }

  SUSERegistryMirrorPanel.prototype.validate = function () {
    this.clearValidation();

    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }

    this.timeoutId = setTimeout(function () {
      var urlValue = this.$url.val();
      var valid = true;

      try {
        var url = new URL(urlValue);

        valid = (url.protocol === 'http:' || url.protocol === 'https:') &&
                !!url.host;
      } catch (error) {
        valid = false;
      }

      if (valid) {
        this.checkInsecure();
      }

      // avoid validation when it's empty
      if (!this.$url.val()) {
        valid = true;
      }

      this.$urlGroup.toggleClass('has-error', !valid);
      this.$invalidUrl.toggleClass('hide', valid);
      this.timeoutId = null;
    }.bind(this), 1500);
  }

  SUSERegistryMirrorPanel.prototype.clearValidation = function () {
    this.$urlGroup.removeClass('has-error');
    this.$invalidUrl.addClass('hide');
    this.$invalidInsecure.addClass('hide');
  }

  SUSERegistryMirrorPanel.prototype.checkInsecure = function () {
    var url = this.$url.val();
    var isSecure = url.indexOf('https') !== -1;

    this.$el.find(dom.MIRROR_INVALID_INSECURE).toggleClass('hide', isSecure);
  }

  window.SUSERegistryMirrorPanel = SUSERegistryMirrorPanel;
}(window));