class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    resource.is_a?(Member) ? portal_root_path : root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    resource_or_scope == :member ? new_member_session_path : root_path
  end
end
