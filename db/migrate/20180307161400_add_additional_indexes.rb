class AddAdditionalIndexes < ActiveRecord::Migration[4.2]

  def change
    add_index :login_events, [:user_id, :id]
    add_index :login_events, [:ip, :id], :length => {:ip => 50}
  end

end
