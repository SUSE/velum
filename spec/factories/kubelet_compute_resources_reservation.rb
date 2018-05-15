FactoryGirl.define do
  factory :kube_resouces_reservation, class: KubeletComputeResourcesReservation do
    sequence(:cpu) { |n| "#{n}m" }
    sequence(:memory) { |n| "#{n}M" }
    sequence(:ephemeral_storage) { |n| "#{n}Gi" }
    component "kube"
  end
  factory :system_resouces_reservation, class: KubeletComputeResourcesReservation do
    sequence(:cpu) { |n| "#{n}m" }
    sequence(:memory) { |n| "#{n}M" }
    sequence(:ephemeral_storage) { |n| "#{n}Gi" }
    component "system"
  end
end
