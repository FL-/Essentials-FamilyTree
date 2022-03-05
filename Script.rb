#===============================================================================
# * Family Tree - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It displays a sixth page at pokémon
# summary showing a little info about the pokémon mother, father, grandmothers
# and grandfathers if the pokémon has any.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above PSystem_System. 
#
# Put a 512x384 background for this screen in "Graphics/Pictures/Summary/" as 
# "bg_6" and as "bg_6_egg". This last one is only necessary if SHOW_FAMILY_EGG
# is true. You also need to update the below pictures on same folder in order
# to reflect the summary icon change:
# - bg_1
# - bg_2
# - bg_3
# - bg_4
# - bg_movedetail
# - bg_5
#
# - At PScreen_Summary, change both lines '@page = 5 if @page>5'
# to '@page=6 if @page>6'
#
# - Change line '_INTL("RIBBONS")][page-1]' into:
#
# _INTL("RIBBONS"),
# _INTL("FAMILY TREE")][page-1]
#
#== NOTES ======================================================================
#
# This won't work on eggs generated before this script was installed.
#
#===============================================================================

if !PluginManager.installed?("Family Tree")
  PluginManager.register({                                                 
    :name    => "Family Tree",                                        
    :version => "1.3",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=339384",             
    :credits => "FL"
  })
end

class PokemonSummary_Scene
  SHOW_FAMILY_EGG = true # when true, family tree is also showed in egg screen.

  alias :_pbChangePokemon_FL_fam :pbChangePokemon
  def pbChangePokemon
    _pbChangePokemon_FL_fam
    if SHOW_FAMILY_EGG && @pokemon.egg? && @page==6
      @ignore_refresh=true
      drawPageSix
    end
  end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex>0
      newindex -= 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg? || (
        @page==6 && SHOW_FAMILY_EGG
      )) 
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex<@party.length-1
      newindex += 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg? || (
        @page==6 && SHOW_FAMILY_EGG
      ))
        @partyindex = newindex
        break
      end
    end
  end

  alias :_drawPage_FL_fam :drawPage
  def drawPage(page)
    if @ignore_refresh
      @ignore_refresh = false
      return
    end
    _drawPage_FL_fam(page)
    drawPageSix if page==6
  end

  alias :_pbUpdate_FL_fam :pbUpdate
  def pbUpdate
    _pbUpdate_FL_fam
    if SHOW_FAMILY_EGG && @pokemon.egg?
      if Input.trigger?(Input::LEFT) && @page==6
        @page=1
        pbPlayCursorSE()
        dorefresh=true
      end
      if Input.trigger?(Input::RIGHT) && @page==1
        @page=6
        pbPlayCursorSE()
        dorefresh=true
      end
    end
    if dorefresh
      case @page
        when 1; drawPageOneEgg
        when 6; drawPageSix
      end
    end
  end

  def drawPageSix
    overlay=@sprites["overlay"].bitmap
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    textpos=[]
    if @pokemon.egg?
      overlay.clear
      pbSetSystemFont(overlay)
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_6_egg")
      ballimage = sprintf(
        "Graphics/Pictures/Summary/icon_ball_%s", @pokemon.poke_ball
      )
      if !pbResolveBitmap(ballimage)
        ballimage = sprintf(
          "Graphics/Pictures/Summary/icon_ball_%02d", 
          pbGetBallType(@pokemon.poke_ball)
        )
      end
      pbDrawImagePositions(overlay,[[ballimage,14,60,0,0,-1,-1]])
      textpos=[
         [_INTL("TRAINER MEMO"),26,10,0,base,shadow],
         [@pokemon.name,46,56,0,base,shadow],
         [_INTL("Item"),66,312,0,base,shadow]
      ]
      textpos.push([
        _INTL("None"),16,346,0,Color.new(192,200,208),Color.new(208,216,224)
      ])
      drawMarkings(overlay,84,292)
    end  
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

alias :_pbDayCareGenerateEgg_FL_fam :pbDayCareGenerateEgg
def pbDayCareGenerateEgg
  _pbDayCareGenerateEgg_FL_fam
  pkmn0 = $PokemonGlobal.daycare[0][0]
  pkmn1 = $PokemonGlobal.daycare[1][0]
  mother = nil
  father = nil
  if pkmn0.female? || pbIsDitto?(pkmn0)
    mother = pkmn0
    father = pkmn1
  else
    mother = pkmn1
    father = pkmn0
  end
  $Trainer.party[-1].family = PokemonFamily.new(
    $Trainer.party[-1], father, mother
  )
end