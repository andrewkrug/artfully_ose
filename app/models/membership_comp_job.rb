class MembershipCompJob < Struct.new(:membership_comp)
  QUEUE = "comp"

  def self.enqueue(membership_comp)
    job = MembershipCompJob.new

    #
    # Weird Rails/DJ bug where calling validate on membership_comp caused the errors
    # to hang around. DJ would choke on when Syck tried to deserialize the errors attr
    # The error message was horrible and misleading (uninitialized constant Syck::Syck)
    #
    # It's probably because we're including ActiveModel::Validations on MembershipComp
    #
    membership_comp.clear_errors
    job.membership_comp = membership_comp

    if run_now?
      job.perform
    else
      Delayed::Job.enqueue job, :queue => QUEUE
    end
  end

  def self.run_now?
    Rails.env.test?
  end

  def perform
    membership_comp.perform
  end

end