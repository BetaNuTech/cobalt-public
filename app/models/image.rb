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
class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
  
  validates :path, presence: true
  
  def url
    "https://#{Settings.s3_bucket}.s3.amazonaws.com#{path}"
  end
end
