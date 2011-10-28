
#
# Test model
class Person
  include Mongoid::Document
  include Mongoid::Symbolize
  include Mongoid::Timestamps

  symbolize :other
  symbolize :language, :in => [:pt, :en]
#  symbolize :sex, :in => [true, false], :scopes => true
  symbolize :status , :in => [:active, :inactive], :i18n => false, :capitalize => true, :scopes => true
  symbolize :so, :allow_blank => true, :in => {
    :linux => 'Linux',
    :mac   => 'Mac OS X',
    :win   => 'Videogame'
  }, :scopes => true
  symbolize :gui, :allow_blank => true, :in => [:cocoa, :qt, :gtk], :i18n => false
  symbolize :karma, :in => %w{good bad ugly}, :methods => true, :i18n => false, :allow_nil => true
  symbolize :planet, :in => %w{earth centauri tatooine}, :default => :earth
 # symbolize :cool, :in => [true, false], :scopes => true

  has_many :rights, :dependent => :destroy
  has_many :extras, :dependent => :destroy, :class_name => "PersonExtra"
  embeds_many :skills, :class_name => "PersonSkill"
end

class PersonSkill
  include Mongoid::Document
  include Mongoid::Symbolize
  embedded_in :person, :inverse_of => :skills

  symbolize :kind, :in => [:agility, :magic]
end

class PersonExtra
  include Mongoid::Document
  include Mongoid::Symbolize
  belongs_to :person, :inverse_of => :extras

  symbolize :key, :in => [:one, :another]
end

class Right
  include Mongoid::Document
  include Mongoid::Symbolize

  validates_presence_of :name
  symbolize :kind, :in => [:temp, :perm], :default => :perm
end


require 'mongoid'
Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("foo_#{Time.now.to_i}")
end

class Project
  include Mongoid::Document

  field :name
  field :state, :default => 'active'

  # Comment 1 line and it works, both fails:
  default_scope where(:state => 'active')
 # scope :inactive, any_in(:state => [:done, :wip])
  scope :dead, all_of(:state => :wip, :name => "zim")

end
