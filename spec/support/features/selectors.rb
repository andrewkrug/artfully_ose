Capybara.add_selector(:first_with_class) do
  xpath { |css_class|  "(.//*[contains(@class, '#{css_class}')])[1]" }
end

Capybara.add_selector(:last_with_class) do
  xpath { |css_class| "(.//*[contains(@class, '#{css_class}')])[last()]" }
end

Capybara.add_selector(:first_with_value) do
  xpath { |value| "(.//*[@value='#{value}'])[1]" }
end
