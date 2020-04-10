class CreateActiveBars < ActiveRecord::Migration[5.2]
  def change
    create_table :active_bars do |t|
      t.string :name

      t.timestamps
    end
  end
end
