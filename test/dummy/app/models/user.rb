class User < ApplicationRecord
  include Scour::Searchable

  has_many :comments, dependent: :destroy
end
