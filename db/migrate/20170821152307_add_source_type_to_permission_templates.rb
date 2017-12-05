class AddSourceTypeToPermissionTemplates < ActiveRecord::Migration[4.2]
  # Recreate the permission_template_accesses table without the FKC on permission_templates.
  # This is required since the sqlite adapter will have to drop the permission_templates table
  # just to perform the upcoming column changes, which will violate the FKC.
  def sqlite_disable_fkc
    # Renaming the dependent column in sqlite actually recreates the table, silently dropping the fkc
    rename_column :permission_template_accesses, :permission_template_id, :permission_template_id_temp
    # Unfortunately, renaming the dependent column is also going to silently remove that field from
    # this index. So we'll drop it for now and recreate when the migration is done
    remove_index :permission_template_accesses, name: 'uk_permission_template_accesses'
    # Rename the table to temp so that we can recreate it with the FKC later
    rename_table :permission_template_accesses, :permission_template_accesses_temp
  end

  # Recreate the permission_template_accesses table with the FKC.
  def sqlite_restore_fkc
    # First recreate the original table, restoring the FKC. Note: This does not account for any
    # changes that an application which implements hyrax may have performed. I'm assuming there
    # is low risk here, but if we need to deal with that then we'll need a more robust way to copy
    # the existing schema from the temp table. I couldn't find a convenient way to do this with
    # sqlite adapter.
    create_table :permission_template_accesses do |t|
      t.references :permission_template, foreign_key: true
      t.string :agent_type
      t.string :agent_id
      t.string :access
      t.timestamps
    end

    # Copy the preserved data from the temp table then drop it
    copy_data_query = "INSERT INTO permission_template_accesses(agent_type, agent_id, access, created_at, updated_at, permission_template_id)" \
                      "SELECT agent_type, agent_id, access, created_at, updated_at, permission_template_id_temp from permission_template_accesses_temp"
    connection.execute copy_data_query
    drop_table :permission_template_accesses_temp

    # Recreate the index we lost. Pulled this from 20171117153051_add_unique_constraint_to_permission_template_accesses
    add_index :permission_template_accesses,
              [:permission_template_id, :agent_id, :agent_type, :access],
              unique: true,
              name: 'uk_permission_template_accesses'
  end

  def up
    is_sql_lite = connection.adapter_name.downcase.starts_with?('sqlite')
    sqlite_disable_fkc if is_sql_lite

    # Separate admin_set_id into source_type/id
    add_column :permission_templates, :source_type, :string
    rename_column :permission_templates, :admin_set_id, :source_id
    Hyrax::PermissionTemplate.find_each do |permission_template|
      permission_template.source_type = 'admin_set'
      permission_template.save!
    end

    sqlite_restore_fkc if is_sql_lite
  end

  def down
    is_sql_lite = connection.adapter_name.downcase.starts_with?('sqlite')
    sqlite_disable_fkc if is_sql_lite

    # Recompose source_type/id into single field admin_set_id
    remove_column :permission_templates, :source_type
    rename_column :permission_templates, :source_id, :admin_set_id

    sqlite_restore_fkc if is_sql_lite
  end
end