# -*- coding: utf-8 -*-
require 'spec_helper'

#
# Test models
class Person
  include Mongoid::Document
  include Mongoid::Symbolize
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  symbolize :other, :i18n => false

  symbolize :language, :in => [:pt, :en]
  symbolize :sex, :type => Boolean, :scopes => true, :i18n => true
  symbolize :status, :in => [:active, :inactive], :i18n => false, :capitalize => true, :scopes => :shallow
  symbolize :so, :allow_blank => true, :in => {
    :linux => 'Linux',
    :mac => 'Mac OS X',
    :win => 'Videogame',
  },             :scopes => true
  symbolize :gui, :allow_blank => true, :in => [:cocoa, :qt, :gtk], :i18n => false
  symbolize :karma, :in => %w(good bad ugly), :methods => true, :i18n => false, :allow_nil => true
  symbolize :planet, :in => %w(earth centauri tatooine), :default => :earth
  # symbolize :cool, :in => [true, false], :scopes => true

  symbolize :year, :in => Time.now.year.downto(1980).to_a, :validate => false

  has_many :rights, :dependent => :destroy
  has_many :extras, :dependent => :destroy, :class_name => 'PersonExtra'
  embeds_many :skills, :class_name => 'PersonSkill'
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
  include Mongoid::Attributes::Dynamic

  validates :name, :presence => true
  symbolize :kind, :in => [:temp, :perm], :default => :perm
end

class Project
  include Mongoid::Document

  field :name
  field :state, :default => 'active'

  # Comment 1 line and it works, both fails:
  default_scope -> { where(:state => 'active') }
  scope :inactive, -> { any_in(:state => [:done, :wip]) }
  scope :dead, -> { all_of(:state => :wip, :name => 'zim') }
end

describe 'Symbolize' do

  it 'should be a module' do
    expect(Mongoid.const_defined?('Symbolize')).to be true
  end

  it 'should instantiate' do
    anna = Person.create(:name => 'Anna', :so => :mac, :gui => :cocoa, :language => :pt, :status => :active, :sex => true)
    # anna.should be_valid
    expect(anna.errors.messages).to eql({})
  end

  describe 'Person Instantiated' do
    let(:person) { Person.create(:name => 'Anna', :other => :fo, :status => :active, :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true) }

    it 'test_symbolize_string' do
      person.status = 'inactive'
      expect(person.status).to eql(:inactive)
      expect(person.read_attribute(:status)).to eql(:inactive)
    end

    it 'test_symbolize_symbol' do
      person.status = :active
      expect(person.status).to eql(:active)
      person.save
      expect(person.status).to eql(:active)
      expect(person[:status]).to eql(:active)
    end

    it 'should make strings symbols from initializer' do
      other = Person.new(:language => 'en', :so => :mac, :gui => :cocoa, :language => :pt, :sex => true, :status => 'active')
      expect(other[:status]).to eq(:active)
      expect(other.status).to eq(:active)
    end

    # it "should work nice with numbers" do
    #   pending
    #   person.status = 43
    #   person.status.should_not be_nil
    #   # person.status_before_type_cast.should be_nil
    #   # person.read_attribute(:status).should be_nil
    # end

    it 'should acts nice with nil when reading' do
      person.karma = nil
      expect(person.karma).to be_nil
      person.save
      expect(person.read_attribute(:karma)).to be_nil
    end

    it 'should acts nice with nil #symbol_text' do
      person.karma = nil
      expect(person.karma).to be_nil
      person.save
      expect(person.karma_text).to be_nil
    end

    it 'should acts nice with blank when reading' do
      person.so = ''
      expect(person.so).to be_blank
      person.save
      expect(person.read_attribute(:so)).to be_blank
    end

    it 'should acts nice with blank #symbol_text' do
      person.so = ''
      expect(person.so).to be_blank
      person.save
      expect(person.so_text).to be_nil
    end

    it 'should not validates other' do
      person.other = nil
      expect(person).to be_valid
      person.other = ''
      expect(person).to be_valid
    end

    it 'should get the correct values' do
      expect(Person.get_status_values).to eql([['Active', :active], ['Inactive', :inactive]])
      expect(Person::STATUS_VALUES).to eql(:inactive => 'Inactive', :active => 'Active')
    end

    it 'should get the values for RailsAdmin' do
      expect(Person.status_enum).to eql([['Active', :active], ['Inactive', :inactive]])
    end

    it 'should have a human _text method' do
      expect(person.status_text).to eql('Active')
    end

    it 'should work nice with i18n' do
      expect(person.language_text).to eql('Português')
    end

    it 'test_symbolize_humanize' do
      expect(person.status_text).to eql('Active')
    end

    it 'should get the correct values' do
      expect(Person.get_gui_values).to match_array([['cocoa', :cocoa], ['qt', :qt], ['gtk', :gtk]])
      expect(Person::GUI_VALUES).to eql(:cocoa => 'cocoa',  :qt => 'qt',  :gtk => 'gtk')
    end

    it 'test_symbolize_humanize' do
      expect(person.gui_text).to eql('qt')
    end

    it 'should get the correct values' do
      expect(Person.get_so_values).to match_array([['Linux', :linux], ['Mac OS X', :mac], ['Videogame', :win]])
      expect(Person::SO_VALUES).to eql(:linux => 'Linux', :mac => 'Mac OS X', :win => 'Videogame')
    end

    it 'test_symbolize_humanize' do
      expect(person.so_text).to eql('Linux')
    end

    it 'test_symbolize_humanize' do
      person.so = :mac
      expect(person.so_text).to eql('Mac OS X')
    end

    it 'should stringify' do
      expect(person.other_text).to eql('fo')
      person.other = :foo
      expect(person.other_text).to eql('foo')
    end

    it 'should work with weird chars' do
      person.status = :"weird'; chars"
      expect(person.status).to eql(:"weird'; chars")
    end

    it 'should work fine through relations' do
      person.extras.create(:key => :one)
      expect(PersonExtra.first.key).to eql(:one)
    end

    it 'should work fine through embeds' do
      person.skills.create(:kind => :magic)
      expect(person.skills.first.kind).to eql(:magic)
    end

    it 'should default planet to earth' do
      expect(Person.new.planet).to eql(:earth)
    end

    describe 'validation' do

      it 'should validate from initializer' do
        other = Person.new(:language => 'en', :so => :mac, :gui => :cocoa, :language => :pt, :sex => true, :status => 'active')
        expect(other).to be_valid
        expect(other.errors.messages).to eq({})
      end

      it 'should validate nil' do
        person.status = nil
        expect(person).not_to be_valid
        expect(person.errors.messages).to have_key(:status)
      end

      it 'should validate not included' do
        person.language = 'xx'
        expect(person).not_to be_valid
        expect(person.errors.messages).to have_key(:language)
      end

      it 'should not validate so' do
        person.so = nil
        expect(person).to be_valid
      end

      it 'should validate ok' do
        person.language = 'pt'
        expect(person).to be_valid
        expect(person.errors.messages).to eq({})
      end

    end

    describe 'i18n' do

      it 'should test i18n ones' do
        expect(person.language_text).to eql('Português')
      end

      it 'should get the correct values' do
        expect(Person.get_language_values).to match_array([['Português', :pt], ['Inglês', :en]])
      end

      it 'should get the correct values' do
        expect(Person::LANGUAGE_VALUES).to eql(:pt => 'pt', :en => 'en')
      end

      it 'should test boolean' do
        expect(person.sex_text).to eql('Feminino')
      end

      it 'should get the correct values' do
        expect(Person.get_sex_values).to eql([['Feminino', true], ['Masculino', false]])
      end

      it 'should get the correct values' do
        expect(Person::SEX_VALUES).to eql(true => 'true', false => 'false')
      end

      it 'should translate a multiword classname' do
        skill = PersonSkill.new(:kind => :magic)
        expect(skill.kind_text).to eql('Mágica')
      end

      it "should return nil if there's no value" do
        skill = PersonSkill.new(:kind => nil)
        expect(skill.kind_text).to be_nil
      end

      it "should return the proper 'false' i18n if the attr value is false" do
        person = Person.new(:sex => false)
        expect(person.sex_text).to eq('Masculino')
      end

      it 'should use i18n if i18n => true' do
        expect(person.sex_text).to eql('Feminino')
      end

    end

    describe 'Methods' do

      it 'should play nice with other stuff' do
        expect(person.karma).to be_nil
        expect(Person::KARMA_VALUES).to eql(:bad => 'bad', :ugly => 'ugly', :good => 'good')
      end

      it 'should provide a boolean method' do
        expect(person).not_to be_good
        person.karma = :ugly
        expect(person).to be_ugly
      end

      it 'should work' do
        person.karma = 'good'
        expect(person).to be_good
        expect(person).not_to be_bad
      end

    end

  end

  describe 'more tests on Right' do

    it 'should not interfer on create' do
      Right.create!(:name => 'p7', :kind => :temp)
      expect(Right.where(:name => 'p7').first.kind).to eql(:temp)
    end

    it 'should work on create' do
      pm = Right.new(:name => 'p7')
      expect(pm).to be_valid
      expect(pm.save).to be true
    end

    it 'should work on create' do
      Right.create(:name => 'p8')
      expect(Right.find_by(:name => 'p8').kind).to eql(:perm)
    end

    it 'should work on edit' do
      Right.create(:name => 'p8')
      pm = Right.where(:name => 'p8').first
      pm.kind = :temp
      pm.save
      expect(Right.where(:name => 'p8').first.kind).to eql(:temp)
    end

  end

  describe 'Default Values' do

    it 'should use default value on object build' do
      expect(Right.new.kind).to eql(:perm)
    end

    it 'should use default value in string' do
      expect(Project.new.state).to eql('active')
    end

  end

  describe 'Scopes' do
    it 'should work under scope' do
      # Person.with_scope({ :status => :inactive }) do
      #   Person.all.map(&:name).should eql(['Bob'])
      # end
    end

    it 'should work under scope' do
      Project.create(:name => 'A', :state => :done)
      Project.create(:name => 'B', :state => :active)
      expect(Project.count).to eql(1)
    end

    it 'should now shallow scoped scopes' do
      Person.create(:name => 'Bob', :other => :bar, :status => :active, :so => :linux, :gui => :gtk, :language => :en, :sex => false, :cool => false)
      expect(Person).not_to respond_to(:status)
    end

    it 'should set some scopes' do
      Person.create(:name => 'Bob', :other => :bar, :status => :active, :so => :linux, :gui => :gtk, :language => :en, :sex => false, :cool => false)
      expect(Person.so(:linux)).to be_a(Mongoid::Criteria)
      expect(Person.so(:linux).count).to eq(1)
    end

    it 'should work with a shallow scope too' do
      Person.create!(:name => 'Bob', :other => :bar, :status => :active, :so => :linux, :gui => :gtk, :language => :en, :sex => false, :cool => false)
      expect(Person.active).to be_a(Mongoid::Criteria)
      expect(Person.active.count).to eq(1)
    end

  end

  describe 'Mongoid stuff' do

    it 'test_symbolized_finder' do
      Person.create(:name => 'Bob', :other => :bar, :status => :inactive, :so => :mac, :gui => :gtk, :language => :en, :sex => false, :cool => false)

      expect(Person.where(:status => :inactive).all.map(&:name)).to eql(['Bob'])
      expect(Person.where(:status => :inactive).map(&:name)).to eql(['Bob'])
    end

    describe 'dirty tracking / changed flag' do

      before do
        Person.create!(:name => 'Anna', :other => :fo, :status => :active, :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true)
        @anna = Person.where(:name => 'Anna').first
      end

      it 'is dirty if you change the attribute value' do
        expect(@anna.language).to eq(:pt)
        expect(@anna.language_changed?).to be false

        return_value = @anna.language = :en
        expect(return_value).to eq(:en)
        expect(@anna.language_changed?).to be true
      end

      it 'is not dirty if you set the attribute value to the same value it was originally' do
        expect(@anna.language).to eq(:pt)
        expect(@anna.language_changed?).to be false

        return_value = @anna.language = :pt
        expect(return_value).to eq(:pt)
        expect(@anna.language_changed?).to be false
      end

    end

  end

end
