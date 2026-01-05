class Webhooks::ActivationsController < ApplicationController
  before_action :ensure_admin

  def create
    webhook = Current.account.webhooks.find(params[:webhook_id])
    webhook.activate

    respond_to do |format|
      format.html { redirect_to webhook }
      format.json { head :no_content }
    end
  end
end
