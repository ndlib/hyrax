FactoryBot.define do
  factory :collection do
    # @example let(:collection) { build(:collection, collection_type_settings: [:not_nestable, :discoverable, :sharable, :allow_multiple_membership]) }

    transient do
      user { create(:user) }
      # allow defaulting to default user collection
      collection_type_settings nil
      with_permission_template false
      create_access false
    end
    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      if evaluator.collection_type_settings.present?
        collection.collection_type = create(:collection_type, *evaluator.collection_type_settings)
      elsif collection.collection_type_gid.nil?
        collection.collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      end
    end

    after(:create) do |collection, evaluator|
      # create the permission template if it was requested, OR if
      # nested reindexing is included (so we can apply the user's
      # permissions).
      if evaluator.with_permission_template || RSpec.current_example.metadata[:with_nested_reindexing]
        attributes = { source_id: collection.id, source_type: 'collection' }
        attributes[:depositor] = evaluator.user if evaluator.create_access
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
      end
      # Nested indexing requires that the user's permissions be saved
      # on the Fedora object... if simply in local memory, they are
      # lost when the adapter pulls the object from Fedora to reindex.
      if RSpec.current_example.metadata[:with_nested_reindexing]
        unless evaluator.create_access # access created above when create_access is true
          create(:permission_template_access,
                 :manage,
                 permission_template: collection.permission_template,
                 agent_type: 'user',
                 agent_id: evaluator.user.user_key)
        end
        collection.update_access_controls!
      end
    end

    factory :public_collection, traits: [:public]

    trait :public do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :private_collection do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    factory :institution_collection do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end

    factory :named_collection do
      title ['collection title']
      description ['collection description']
    end
  end

  factory :user_collection, class: Collection do
    transient do
      user { create(:user) }
    end

    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      collection.collection_type_gid = collection_type.gid
    end
  end

  factory :typeless_collection, class: Collection do
    # To create a pre-Hyrax 2.1.0 collection without a collection type gid...
    #   col = build(:typeless_collection, ...)
    #   col.save(validate: false)
    transient do
      user { create(:user) }
      do_save false
    end

    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      collection.save(validate: false) if evaluator.do_save
    end
  end
end
