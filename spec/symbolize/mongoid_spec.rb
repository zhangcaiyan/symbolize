# -*- coding: utf-8 -*-
require 'spec_helper_mongoid'

#
# Test model
class Person
  include Mongoid::Document
  include Mongoid::Symbolize

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

describe "Symbolize" do

  it "should be a module" do
    Mongoid.const_defined?("Symbolize").should be_true
  end

  it "should instantiate" do
    anna = Person.create(:name => 'Anna', :so => :mac, :gui => :cocoa, :language => :pt, :status => :active)
    anna.should be_valid
    # anna.errors.messages.should eql({})
  end

  describe "Person Instantiated" do
    let(:person) { Person.create(:name => 'Anna', :other => :fo, :status => :active  , :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true) }

    it "test_symbolize_string" do
      person.status = 'inactive'
      person.status.should eql(:inactive)
      person.read_attribute(:status).should eql(:inactive)
    end

    it "test_symbolize_symbol" do
      person.status = :active
      person.status.should eql(:active)
      person.save
      person.status.should eql(:active)
      person[:status].should eql(:active)
    end

    # it "should work nice with numbers" do
    #   pending
    #   person.status = 43
    #   person.status.should_not be_nil
    #   # person.status_before_type_cast.should be_nil
    #   # person.read_attribute(:status).should be_nil
    # end

    # it "should acts nice with nil" do
    #   person.status = nil
    #   person.status.should be_nil
    #   person.status_before_type_cast.should be_nil
    #   person.read_attribute(:status).should be_nil
    # end

    # it "should acts nice with blank" do
    #   person.status = ""
    #   person.status.should be_nil
    #   person.status_before_type_cast.should be_nil
    #   person.read_attribute(:status).should be_nil
    # end

    it "should not validates other" do
      person.other = nil
      person.should be_valid
      person.other = ""
      person.should be_valid
    end

    it "should get the correct values" do
      Person.get_status_values.should eql([["Active", :active],["Inactive", :inactive]])
      Person::STATUS_VALUES.should eql({ inactive: "Inactive", active: "Active"})
    end

    it "test_symbolize_humanize" do
      person.status_text.should eql("Active")
    end

    it "should get the correct values" do
      Person.get_gui_values.should =~ [["cocoa", :cocoa], ["qt", :qt], ["gtk", :gtk]]
      Person::GUI_VALUES.should eql({cocoa: "cocoa",  qt: "qt",  gtk: "gtk"})
    end

    it "test_symbolize_humanize" do
      person.gui_text.should eql("qt")
    end

    it "should get the correct values" do
      Person.get_so_values.should =~ [["Linux", :linux], ["Mac OS X", :mac], ["Videogame", :win]]
      Person::SO_VALUES.should eql({linux: "Linux", mac: "Mac OS X", win: "Videogame"})
    end

    it "test_symbolize_humanize" do
      person.so_text.should eql("Linux")
    end

    it "test_symbolize_humanize" do
      person.so = :mac
      person.so_text.should eql("Mac OS X")
    end

    it "should stringify" do
      person.other_text.should eql("fo")
      person.other = :foo
      person.other_text.should eql("foo")
    end

    it "should validate status" do
      person.status = nil
      person.should_not be_valid
      person.should have(1).errors
    end

    it "should not validate so" do
      person.so = nil
      person.should be_valid
    end

    it "should work with weird chars" do
      person.status = :"weird'; chars"
      person.status.should eql(:"weird'; chars")
    end

    it "should work fine through relations" do
      person.extras.create(:key => :one)
      PersonExtra.first.key.should eql(:one)
    end

    it "should work fine through embeds" do
      person.skills.create(:kind => :magic)
      person.skills.first.kind.should eql(:magic)
    end

    # it "should play fine with null db columns" do
    #   new_extra = person.extras.build
    #   new_extra.should_not be_valid
    # end

    # it "should play fine with null db columns" do
    #   new_extra = person.extras.build
    #   new_extra.should_not be_valid
    # end

    it "should default planet to earth" do
      Person.new.planet.should eql(:earth)
    end


    describe "i18n" do

      it "should test i18n ones" do
        person.language_text.should eql("Português")
      end

      it "should get the correct values" do
        Person.get_language_values.should =~ [["Português", :pt], ["Inglês", :en]]
      end

      it "should get the correct values" do
        Person::LANGUAGE_VALUES.should eql({:pt=>"pt", :en=>"en"})
      end

      # it "should test boolean" do
      #   person.sex_text.should eql("Feminino")
      # end

      # it "should get the correct values" do
      #   Person.get_sex_values.should eql([["Feminino", true],["Masculino", false]])
      # end

      # it "should get the correct values" do
      #   Person::SEX_VALUES.should eql({true=>"true", false=>"false"})
      # end

      it "should translate a multiword classname" do
        skill = PersonSkill.new(:kind => :magic)
        skill.kind_text.should eql("Mágica")
      end

      it "should return nil if there's no value" do
        skill = PersonSkill.new(:kind => nil)
        skill.kind_text.should be_nil
      end

    end

    describe "Methods" do

      it "should play nice with other stuff" do
        person.karma.should be_nil
        Person::KARMA_VALUES.should eql({:bad => "bad", :ugly => "ugly", :good => "good"})
      end

      it "should provide a boolean method" do
        person.should_not be_good
        person.karma = :ugly
        person.should be_ugly
      end

      it "should work" do
        person.karma = "good"
        person.should be_good
        person.should_not be_bad
      end

    end

  end

  describe "more tests on Right" do

    it "should use default value on object build" do
      Right.new.kind.should eql(:perm)
    end

    it "should not interfer on create" do
      Right.create!(:name => "p7", :kind => :temp)
      Right.where(name: "p7").first.kind.should eql(:temp)
    end

    it "should work on create" do
      pm = Right.new(:name => "p7")
      pm.should be_valid
      pm.save.should be_true
    end

    it "should work on create" do
      Right.create(:name => "p8")
      Right.first(conditions: { name: "p8" }).kind.should eql(:perm)
    end

    it "should work on edit" do
      pm = Right.where(name: "p8").first
      pm.kind = :temp
      pm.save
      Right.where(name: "p8").first.kind.should eql(:temp)
    end

  end

  describe "Mongoid stuff" do

    it "test_symbolized_finder" do
      Person.create(:name => 'Bob' , :other => :bar, :status => :inactive, :so => :mac, :gui => :gtk, :language => :en, :sex => false, :cool => false)

      Person.where({ :status => :inactive }).all.map(&:name).should eql(['Bob'])
      Person.where(status: :inactive).map(&:name).should eql(['Bob'])
    end

    # it "should work under scope" do
    #   Person.with_scope({ :status => :inactive }) do
    #     Person.all.map(&:name).should eql(['Bob'])
    #   end
    # end

    describe "dirty tracking / changed flag" do
      before do
        @anna = Person.where(name: 'Anna').first
      end

      it "is dirty if you change the attribute value" do
        @anna.language.should == :pt
        @anna.language_changed?.should be_false

        return_value = @anna.language = :en
        return_value.should == :en
        @anna.language_changed?.should be_true
      end

      it "is not dirty if you set the attribute value to the same value it was originally" do
        @anna.language.should == :pt
        @anna.language_changed?.should be_false

        return_value = @anna.language = :pt
        return_value.should == :pt
        @anna.language_changed?.should be_false
      end
    end


  end

end

