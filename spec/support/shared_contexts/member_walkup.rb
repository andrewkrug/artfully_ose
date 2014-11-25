shared_context 'member walkup when no member is found' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :member_uuid => member.uuid }

  before(:each) do
    # Remove the member
    member.delete
  end
end

shared_context 'member walkup when no show is found' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :show_id => walkup_show.id }

  before(:each) do
    # Remove the show
    walkup_show.delete
  end
end

shared_context 'member walkup when no ticket type is found' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :member_uuid => member.uuid, :show_id => walkup_show.id }

  before(:each) do
    member_ticket_type.delete
  end
end

shared_context 'member walkup when member tickets are sold out' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :member_uuid => member.uuid, :show_id => walkup_show.id }

  before(:each) do
    sell_out_of member_ticket_type
  end
end

shared_context 'member walkup when the tickets per membership limit has been reached' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :member_uuid => member.uuid, :show_id => walkup_show.id }

  before(:each) do
    max_out_ticket_purchases member, member_ticket_type
  end
end

shared_context 'member walkup when it is valid' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :member_uuid => member.uuid, :show_id => walkup_show.id }
end

shared_context 'member walkup when it is not valid' do
  include_context 'walkup with $0 member tickets'

  let(:walkup) { MemberWalkup.new :member_uuid => member.uuid, :show_id => walkup_show.id }

  before(:each) do
    walkup.stub(:valid? => false)
  end
end
