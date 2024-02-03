# == Schema Information
#
# Table name: images
#
#  id             :integer          not null, primary key
#  caption        :string
#  imageable_id   :integer
#  imageable_type :string
#  path           :string(2000)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
