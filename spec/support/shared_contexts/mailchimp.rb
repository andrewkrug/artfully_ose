shared_context :mailchimp do
  before do
    FakeWeb.register_uri(:post, "https://us5.api.mailchimp.com/1.3/?method=ping", :body => "\"Everything's Chimpy!\"")
    FakeWeb.register_uri(:post, "https://us5.api.mailchimp.com/1.3/?method=lists", :body => mailchimp_lists_json)
  end

  let(:mailchimp_lists_json) { File.read(Rails.root.join("spec", "fixtures", "mailchimp_lists.json")) }
end
