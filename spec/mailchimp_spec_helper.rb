module MailchimpSpecHelper
  def expect_to_not_queue(&block)
    expect {
      instance_eval(&block)
    }.to_not change {
      Delayed::Job.where(:queue => MailchimpKit::QUEUE).count
    }
  end

  def expect_to_queue(&block)
    expect {
      instance_eval(&block)
    }.to change {
      Delayed::Job.where(:queue => MailchimpKit::QUEUE).count
    }.by(1)
  end
end