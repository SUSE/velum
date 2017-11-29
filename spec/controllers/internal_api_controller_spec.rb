require "rails_helper"

describe InternalApiController, type: :controller do

  include ApiHelper

  controller do
    include Api

    def ok_action_blank
      ok
    end

    def ok_action_not_blank
      ok content: { some: "content" }
    end

    def ko_action_blank
      ko
    end

    def ko_action_not_blank
      ko content: { some: "content" }
    end
  end

  before do
    routes.draw do
      get :ok_action_blank, action: :ok_action_blank, controller: :internal_api
      get :ok_action_not_blank, action: :ok_action_not_blank, controller: :internal_api
      get :ko_action_blank, action: :ko_action_blank, controller: :internal_api
      get :ko_action_not_blank, action: :ko_action_not_blank, controller: :internal_api
    end
  end

  context "with an invalid authentication" do
    describe "get any endpoint" do
      it "returns a Unauthorized HTTP status" do
        get :ok_action_blank
        expect(response.status).to eq 401
      end
    end
  end

  context "with a valid authentication" do
    before do
      http_login
      request.accept = "application/json"
    end

    context "when ok without content is called" do
      it "returns 200 HTTP status and blank content" do
        get :ok_action_blank
        expect(response.status).to eq 200
        expect(response.body).to be_blank
      end
    end

    context "when ok with content is called" do
      it "returns 200 HTTP status and not blank content" do
        get :ok_action_not_blank
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq("some" => "content")
      end
    end

    context "when ko without content is called" do
      it "returns 422 HTTP status and blank content" do
        get :ko_action_blank
        expect(response.status).to eq 422
        expect(response.body).to be_blank
      end
    end

    context "when ok with content is called" do
      it "returns 422 HTTP status and not blank content" do
        get :ko_action_not_blank
        expect(response.status).to eq 422
        expect(JSON.parse(response.body)).to eq("some" => "content")
      end
    end
  end
end
