module Hyrax
  module Collections
    # Responsible for retrieving collection members
    class MigrationService
      # @api public
      #
      # Migrate all legacy collections to extended collections with collection type assigned.  Legacy collections are those
      # created before Hyrax 2.1.0 and are identified by the lack of the collection having a collection type gid.
      def self.migrate_all_collections
        Rails.logger.info "*** Migrating #{Collection.count} collections"
        Collection.all.each do |col|
          migrate_collection(col)
          print '.'
        end
        Rails.logger.info "--- Migration Complete"
      end

      # @api private
      #
      # Migrate a single legacy collection to extended collections with collection type assigned.  Legacy collections are those
      # created before Hyrax 2.1.0 and are identified by the lack of the collection having a collection type gid.
      #
      # @param collection [Collection] collection object to be migrated
      def self.migrate_collection(collection)
        return if migrated?(collection)
        collection.collection_type_gid = Hyrax::CollectionType.find_or_create_default_collection_type.gid
        grants = []
        collection.edit_groups.each { |g| grants << { agent_type: 'group', agent_id: g, access: Hyrax::PermissionTemplateAccess::MANAGE } }
        collection.edit_users.each { |u| grants << { agent_type: 'user', agent_id: u, access: Hyrax::PermissionTemplateAccess::MANAGE } }
        collection.read_groups.each { |g| grants << { agent_type: 'group', agent_id: g, access: Hyrax::PermissionTemplateAccess::VIEW } }
        collection.read_users.each { |u| grants << { agent_type: 'user', agent_id: u, access: Hyrax::PermissionTemplateAccess::VIEW } }
        Hyrax::Collections::PermissionsCreateService.create_default(collection: collection, creating_user: ::User.find_by_user_key(collection.depositor), grants: grants)
        collection.save
      end
      private_class_method :migrate_collection

      # @api private
      #
      # Determine if collection was already migrated.
      #
      # @param [Collection] collection object to be validated
      def self.migrated?(collection)
        return true if collection.collection_type_gid.present?
        false
      end
      private_class_method :migrated?
    end
  end
end
