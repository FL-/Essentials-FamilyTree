#===============================================================================
# * Family Tree - by FL (Credits will be apreciated)
#  updated to v21.1 by Eurritimia
#===============================================================================
#
# This script is for Pokémon Essentials. It displays a sixth page at pokémon
# summary showing a little info about the pokémon mother, father, grandmothers
# and grandfathers if the pokémon has any.
#
#== INSTALLATION ===============================================================
#
# No need to add that many files, now only bg_family_tree.png and 
# page_family_tree.png are needed in Graphics/UI/Summary. It requires Modular 
# UI Scenes from Lucidious89, however.
#
#== NOTES ======================================================================
#
# This won't work on eggs generated before this script was installed.
#
#===============================================================================

UIHandlers.add(:summary, :page_family, {
  "name"      => "FAMILY TREE",
  "suffix"    => "family_tree",
  "order"     => 60,
  "layout"    => proc { |pkmn, scene| scene.drawPageFamily }
})

UIHandlers.add(:summary, :page_family_egg, {
  "name"      => "FAMILY TREE",
  "suffix"    => "family_tree",
  "order"     => 60,
  "onlyEggs"  => true,
  "condition" => proc { next PokemonSummary_Scene::SHOW_FAMILY_EGG },
  "layout"    => proc { |pkmn, scene| scene.drawPageFamily }
})

class PokemonSummary_Scene
  SHOW_FAMILY_EGG = true # when true, family tree is also showed in egg screen.

  def drawPageFamily
    overlay=@sprites["overlay"].bitmap
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    textpos=[]    
    # Draw parents
    parents_y = [78,234]
    for i in 0...2
      parent_text_line_1_y = parents_y[i]-6
      parent_text_line_2_y = parent_text_line_1_y + 32
      parent = @pokemon&.family&.[](i)
      overlay.blt(
        234,parents_y[i],
        AnimatedBitmap.new(get_parent_icon(parent)).bitmap,Rect.new(0,0,64,64)
      )
      textpos.push([
        parent ? parent.name : _INTL("???"),
        320,parent_text_line_1_y,0,base,shadow
      ])
      parent_species_name = "/" 
      if parent
        parent_species_name += GameData::Species.get(parent.species).name
      else
        parent_species_name += _INTL("???")
      end
      if ["♂","♀"].include?(parent_species_name.split('').last)
        parent_species_name=parent_species_name[0..-2]
      end
      textpos.push([parent_species_name,320,parent_text_line_2_y,0,base,shadow])
      if parent
        if parent.gender==0
          textpos.push([
            _INTL("♂"),500,parent_text_line_2_y,1,
            Color.new(24,112,216),Color.new(136,168,208)
          ])
        elsif parent.gender==1
          textpos.push([
            _INTL("♀"),500,parent_text_line_2_y,1,
            Color.new(248,56,32),Color.new(224,152,144)
          ])
        end
      end
      for j in 0...2
        overlay.blt(
          [380,448][j],68+parents_y[i],
          AnimatedBitmap.new(get_parent_icon(parent&.[](j))).bitmap,
          Rect.new(0,0,64,64)
        )
      end
    end
    pbDrawTextPositions(overlay,textpos)
  end

  def get_parent_icon(parent)
    return parent ? parent.icon_filename : GameData::Species.icon_filename(nil)
  end
end

class PokemonFamily
  MAX_GENERATIONS = 3 # Tree stored generation limit

  attr_reader :mother # PokemonFamily object
  attr_reader :father # PokemonFamily object

  attr_reader :species
  attr_reader :form
  attr_reader :gender
  attr_reader :shiny
  attr_reader :name # nickname
  # You can add more data here and on initialize class. Just
  # don't store the entire pokémon object.

  def initialize(pokemon, father=nil,mother=nil)
    @father = format_parent(pokemon, father, 0)
    @mother = format_parent(pokemon, mother, 1)
    initialize_cub_data(pokemon) if !father || !mother
    apply_generation_limit(MAX_GENERATIONS)
  end

  # [0] = father, [1] = mother
  def [](value)
    return case value
      when 0; @father
      when 1; @mother
      else; nil
    end
  end

  def format_parent(pokemon, parent, index)
    return pokemon.family[index] if pokemon.family && pokemon.family[index]
    return PokemonFamily.new(parent) if parent
    return nil
  end

  def initialize_cub_data(pokemon)
    @species=pokemon.species
    @form=pokemon.form
    @gender=pokemon.gender
    @shiny=pokemon.shiny?
    @name=pokemon.name
  end

  def apply_generation_limit(generation)
    if generation>1
      @father.apply_generation_limit(generation-1) if @father
      @mother.apply_generation_limit(generation-1) if @mother
    else
      @father=nil
      @mother=nil
    end
  end

  def icon_filename
    return GameData::Species.icon_filename(@species, @form, @gender, @shiny)
  end
end 

class Pokemon
  attr_accessor :family
end

class DayCare
	module EggGenerator
		module_function

		def generate(mother, father)
		  # Determine which Pokémon is the mother and which is the father
		  # Ensure mother is female, if the pair contains a female
		  # Ensure father is male, if the pair contains a male
		  # Ensure father is genderless, if the pair is a genderless with Ditto
		  if mother.male? || father.female? || mother.genderless?
			mother, father = father, mother
		  end
		  mother_data = [mother, mother.species_data.egg_groups.include?(:Ditto)]
		  father_data = [father, father.species_data.egg_groups.include?(:Ditto)]
		  # Determine which parent the egg's species is based from
		  species_parent = (mother_data[1]) ? father : mother
		  # Determine the egg's species
		  baby_species = determine_egg_species(species_parent.species, mother, father)
		  mother_data.push(mother.species_data.breeding_can_produce?(baby_species))
		  father_data.push(father.species_data.breeding_can_produce?(baby_species))
		  # Generate egg
		  egg = generate_basic_egg(baby_species)
		  # Inherit properties from parent(s)
		  inherit_form(egg, species_parent, mother_data, father_data)
		  inherit_nature(egg, mother, father)
		  inherit_ability(egg, mother_data, father_data)
		  inherit_moves(egg, mother_data, father_data)
		  inherit_IVs(egg, mother, father)
		  inherit_poke_ball(egg, mother_data, father_data)
		  # Calculate other properties of the egg
		  set_shininess(egg, mother, father)   # Masuda method and Shiny Charm
		  set_pokerus(egg)
		  # Recalculate egg's stats
		  egg.calc_stats
		  egg.family = PokemonFamily.new(egg, mother, father)
		  return egg
		end
	end
end
