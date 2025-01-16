# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.string :message
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
