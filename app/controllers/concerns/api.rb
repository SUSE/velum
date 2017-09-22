# Api implements general use case methods when working with API controllers.
module Api
  extend ActiveSupport::Concern

  def ok(status: 200, content: nil)
    if content.blank?
      render status: status, nothing: true
    else
      respond_to do |format|
        format.json { render status: status, json: content.as_json }
      end
    end
  end

  def ko(status: 422, content: nil)
    if content.blank?
      render status: status, nothing: true
    else
      respond_to do |format|
        format.json { render status: status, json: content.as_json }
      end
    end
  end
end
