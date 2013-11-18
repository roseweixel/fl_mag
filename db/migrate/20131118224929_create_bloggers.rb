class CreateBloggers < ActiveRecord::Migration
  def change
    create_table :bloggers do |t|
      t.string :name
      t.string :xml_address
      t.integer :semester

      t.timestamps
    end
  end
end