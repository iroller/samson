class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :gravatar_url

  def gravatar_url
    object.gravatar_url
  end
end
