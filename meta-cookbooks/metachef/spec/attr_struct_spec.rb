require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require METACHEF_DIR("libraries/metachef.rb")

describe ClusterChef::AttrStruct do
  let(:car_class) do
    Class.new do
      include ClusterChef::AttrStruct
      dsl_attr :name
      dsl_attr :model
      dsl_attr :doors, :kind_of => Integer
      dsl_attr :engine
    end
  end
  let(:engine_class) do
    Class.new do
      include ClusterChef::AttrStruct
      dsl_attr :name
      dsl_attr :displacement
      dsl_attr :cylinders, :kind_of => Integer
    end
  end

  let(:chevy_350){    engine_class.new('chevy', 350, 8) }
  let(:hot_rod){      car_class.new('39 ford', 'tudor', 2, chevy_350) }

  context '#to_hash' do
    it('succeeds'){  chevy_350.to_hash.should == { 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8} }
    it('nests'){     hot_rod.to_hash.should   == { "name" => "39 ford", "model" => "tudor", "doors" => 2, "engine"=> { 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8} } }
    it('is a Hash'){ hot_rod.to_hash.class.should == Hash }
  end

  context '#to_mash' do
    it('succeeds') do
      msh = chevy_350.to_mash
      msh.should == Mash.new({ 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8})
      msh['name'].should == 'chevy'
      msh[:name ].should == 'chevy'
    end
    it('nests'){     hot_rod.to_mash.should   == Mash.new({ "name" => "39 ford", "model" => "tudor", "doors" => 2, "engine"=> { 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8} }) }
    it('is a Mash'){ hot_rod.to_mash.class.should == Mash }
  end

  context '#dsl_attr' do
    it 'adds a set-or-return accessor' do
      chevy_350.cylinders(6).should == 6
      chevy_350.cylinders.should    == 6
    end

    it 'adds the key to .keys' do
      car_class.keys.should == [:name, :model, :doors, :engine]
    end
    it 'does not duplicate or re-order keys' do
      car_class.new.engine.should be_nil
      car_class.dsl_attr(:engine, :default => 4)
      car_class.new.engine.should == 4
    end
  end
end
