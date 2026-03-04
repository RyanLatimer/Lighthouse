class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true

    # Backfill existing users: username = "First Last"
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE users SET username = first_name || ' ' || last_name
        SQL

        change_column_null :users, :username, false
      end
    end
  end
end
