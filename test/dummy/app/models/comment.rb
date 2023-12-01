class Comment < ApplicationRecord
  include Scour::Searchable

  belongs_to :user
end
