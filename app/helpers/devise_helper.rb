module DeviseHelper
  def devise_error_messages!
    messages = resource.errors.full_messages.join('<br />').html_safe
    if messages.present?
    	messages = content_tag(:div, 'x', :class => 'close', 'data-dismiss' => 'alert') + messages
    	content_tag(:div, messages, :class => "alert alert-error flash", 'data-alert' => 'alert')
  	end
  end
end