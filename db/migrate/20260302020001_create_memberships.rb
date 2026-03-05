# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :role, default: 0, null: false # 0=scout, 1=analyst, 2=lead, 3=admin, 4=owner

      t.timestamps
    end

    add_index :memberships, [ :user_id, :organization_id ], unique: true
  end
end
