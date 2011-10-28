
#
# Test model
class User < ActiveRecord::Base
  symbolize :other
  symbolize :language, :in => [:pt, :en]
  symbolize :sex, :in => [true, false], :scopes => true
  symbolize :status , :in => [:active, :inactive], :i18n => false, :capitalize => true, :scopes => true
  symbolize :so, :allow_blank => true, :in => {
    :linux => 'Linux',
    :mac   => 'Mac OS X',
    :win   => 'Videogame'
  }, :scopes => true
  symbolize :gui, :allow_blank => true, :in => [:cocoa, :qt, :gtk], :i18n => false
  symbolize :karma, :in => %w{ good bad ugly}, :methods => true, :i18n => false, :allow_nil => true
  symbolize :cool, :in => [true, false], :scopes => true

  has_many :extras, :dependent => :destroy, :class_name => "UserExtra"
  has_many :access, :dependent => :destroy, :class_name => "UserAccess"
end

class UserSkill < ActiveRecord::Base
  symbolize :kind, :in => [:agility, :magic]
end

class UserExtra < ActiveRecord::Base
  symbolize :key, :in => [:one, :another]
end

class Permission < ActiveRecord::Base
  validates_presence_of :name
  symbolize :kind, :in => [:temp, :perm], :default => :perm
  symbolize :lvl, :in => (1..9).to_a, :i18n => false#, :default => 1
end

# Make with_scope public-usable for testing
#if ActiveRecord::VERSION::MAJOR < 3
class << ActiveRecord::Base
  public :with_scope
end
#end
