FactoryGirl.define do
  #
  # pass :price => 2000 just like anything else
  #
  factory :chart do
    ignore do
      price nil
      capacity nil
    end

    name 'Test Chart'
    is_template false
    organization

    after(:create) do |chart, evaluator|
      unless evaluator.capacity.nil?
        chart.sections.first.capacity = evaluator.capacity
        chart.sections.first.save
      end

      unless evaluator.price.nil?
        chart.sections.first.ticket_types.first.price = evaluator.price
        chart.sections.first.ticket_types.first.save
      end
    end
  end

  factory :chart_with_sections, :parent => :chart do
    skip_create_first_section true
    after(:create) do |chart|
      2.times do
        chart.sections << FactoryGirl.create(:section)
      end
    end
  end

  factory :chart_with_free_sections, :parent => :chart do
    after(:create) do |chart|
      2.times do
        chart.sections << FactoryGirl.create(:free_section)
      end
    end
  end

  factory :assigned_chart, :parent => :chart_with_sections do
    event
  end

  factory :chart_template, :parent => :chart do
    is_template true
  end
end