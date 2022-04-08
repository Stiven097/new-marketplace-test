class Pricing < ApplicationRecord
  belongs_to :design
  enum pricing_type: [:basic, :standard, :premium]
end
