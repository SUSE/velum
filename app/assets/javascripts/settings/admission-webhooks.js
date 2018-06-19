(function (window) {
  var dom = {
    DISABLED_RADIO: '#admission_webhook_enabled_false',
    FILE_INPUTS: 'input[type=file]',
    CURRENT_CERT_INPUT: '#admission_webhook_current_cert',
    SUBMIT_BTN: 'input[type=submit]',
    MODAL: '.warn-disable-admission-webhooks-modal',
    PROCEED_ANYWAY: '.disable-anyway'
  };

  function AdmissionWebhookForm(el) {
    this.$el = $(el);
    this.$disabled = this.$el.find(dom.DISABLED_RADIO);
    this.$fileInputs = this.$el.find(dom.FILE_INPUTS);
    this.$currentCert = this.$el.find(dom.CURRENT_CERT_INPUT);
    this.$modal = $(dom.MODAL);

    this.events();
  }

  AdmissionWebhookForm.prototype.events = function () {
    this.$el.on('click', dom.SUBMIT_BTN, this.checkWarning.bind(this));
    this.$modal.on('click', dom.PROCEED_ANYWAY, this.closeAndSubmit.bind(this));
  }

  AdmissionWebhookForm.prototype.checkWarning = function (e) {
    if (this.$disabled.is(':checked')) {
      this.$fileInputs.prop('required', false);
    }

    if (this.$disabled.is(':checked') && this.$currentCert.val()) {
      this.$modal.modal('show');
      return false;
    }
  }

  AdmissionWebhookForm.prototype.closeAndSubmit = function (e) {
    this.$modal.modal('hide');
    this.$el[0].submit();
  }

  window.AdmissionWebhookForm = AdmissionWebhookForm;
}(window));