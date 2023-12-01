class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject
      t.text :body

      t.timestamps
    end
  end
end
