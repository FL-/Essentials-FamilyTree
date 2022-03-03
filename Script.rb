#===============================================================================
# * Family Tree - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It displays a sixth page at pokémon
# summary showing a little info about the pokémon mother, father, grandmothers
# and grandfathers if the pokémon has any.
#
#===============================================================================
#
# To this script works, put it above main, put a 512x384 background for this
# screen in "Graphics/Pictures/summary6" and in "Graphics/Pictures/summaryEgg6".
# This last one is only necessary if SHOWFAMILYEGG is true. You also need to
# update the below pictures in order to reflect the summary icon change:
# - summary1
# - summary2
# - summary3
# - summary4
# - summary4details
# - summary5
#
# -At PokemonDayCare, before line '$Trainer.party[$Trainer.party.length]=egg'
# add line 'egg.family = PokemonFamily.new(egg, father, mother)'
#
# -At PokemonSummary, change both lines '@page=4 if @page>4'
# to '@page=5 if @page>5'
#
# -Before line 'if Input.trigger?(Input::UP) && @partyindex>0'
# add line 'handleInputsEgg'
#
# -Change line 'if @page!=0' to 'if @page!=0 && !(SHOWFAMILYEGG && @page==5)'
#
# -After line 'drawPageFive(@pokemon)' add
#
# when 5
#  drawPageSix(@pokemon)
#
#===============================================================================

class PokemonSummaryScene
  SHOWFAMILYEGG = true # when true, family tree is also showed in egg screen.
  
  def drawPageSix(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap(@pokemon.isEgg? ? 
        "Graphics/Pictures/summaryEgg6" : "Graphics/Pictures/summary6")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([
          sprintf("Graphics/Pictures/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    naturename=PBNatures.getName(pokemon.nature)
    itemname=pokemon.item==0 ? _INTL("None") : PBItems.getName(pokemon.item)
    pokename=@pokemon.name
    if @pokemon.name.split('').last=="♂" || @pokemon.name.split('').last=="♀"
      pokename=@pokemon.name[0..-2]
    end
    textpos=[
      [_INTL("FAMILY TREE"),26,16,0,base,shadow],
      [pokename,46,62,0,base,shadow],
      [_INTL("Item"),16,320,0,base,shadow],
      [itemname,16,352,0,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    textpos.push([_INTL("{1}",pokemon.level),46,92,0,
          Color.new(64,64,64),Color.new(176,176,176)]) if !@pokemon.isEgg?
    if !@pokemon.isEgg?
      if pokemon.gender==0
        textpos.push([_INTL("♂"),178,62,0,
            Color.new(24,112,216),Color.new(136,168,208)])
      elsif pokemon.gender==1
        textpos.push([_INTL("♀"),178,62,0,
            Color.new(248,56,32),Color.new(224,152,144)])
      end
    end    
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    # Draw parents
    parentsY=[78,234]
    for i in 0...2
      parent = @pokemon.family && @pokemon.family[i] ? @pokemon.family[i] : nil
      iconParentParam = parent ? [parent.species,
          parent.gender==1,false,parent.form,false] : [0,0,false,0,false]
      iconParent=AnimatedBitmap.new(pbCheckPokemonIconFiles(iconParentParam))
      overlay.blt(234,parentsY[i],iconParent.bitmap,Rect.new(0,0,64,64))
      textpos.push([parent ? parent.name : _INTL("???"),
          320,parentsY[i],0,base,shadow])
      parentSpecieName=parent ? PBSpecies.getName(parent.species) : _INTL("???")
      if (parentSpecieName.split('').last=="♂" ||
          parentSpecieName.split('').last=="♀")
        parentSpecieName=parentSpecieName[0..-2]
      end
      textpos.push([parentSpecieName,320,32+parentsY[i],0,base,shadow])
      if parent
        if parent.gender==0
          textpos.push([_INTL("♂"),500,32+parentsY[i],1,
              Color.new(24,112,216),Color.new(136,168,208)])
        elsif parent.gender==1
          textpos.push([_INTL("♀"),500,32+parentsY[i],1,
              Color.new(248,56,32),Color.new(224,152,144)])
        end
      end    
      grandX = [380,448]
      for j in 0...2
        iconGrandParam = parent && parent[j] ? [parent[j].species,
            parent[j].gender==1,false,parent[j].form,false] : 
            [0,0,false,0,false]
        iconGrand=AnimatedBitmap.new(pbCheckPokemonIconFiles(iconGrandParam))
        overlay.blt(
            grandX[j],68+parentsY[i],iconGrand.bitmap,Rect.new(0,0,64,64))
      end
    end
    pbDrawTextPositions(overlay,textpos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end
  
  def handleInputsEgg
    if SHOWFAMILYEGG && @pokemon.isEgg?
      if Input.trigger?(Input::LEFT) && @page==5
        @page=0 
        pbPlayCursorSE()
        dorefresh=true
      end
      if Input.trigger?(Input::RIGHT) && @page==0
        @page=5 
        pbPlayCursorSE()
        dorefresh=true
      end
    end
    if dorefresh
      case @page
        when 0
          drawPageOne(@pokemon)
        when 5
          drawPageSix(@pokemon)
      end
    end
  end
end


class PokemonFamily
  MAXGENERATIONS = 3 # Tree stored generation limit
  
  attr_reader :mother # PokemonFamily object
  attr_reader :father # PokemonFamily object
  
  attr_reader :species
  attr_reader :gender
  attr_reader :form
  attr_reader :name # nickname
  # You can add more data here and on initialize class. Just 
  # don't store the entire pokémon object.
  
  def initialize(pokemon, father=nil,mother=nil)
    initializedAsParent = !father || !mother
    if pokemon.family && pokemon.family.father
      @father = pokemon.family.father
    elsif father 
      @father = PokemonFamily.new(father)
    end
    if pokemon.family && pokemon.family.mother
      @mother = pokemon.family.mother
    elsif mother
      @mother = PokemonFamily.new(mother)
    end
    
    # This data is only initialized as a parent in a cub.
    if initializedAsParent 
      @species=pokemon.species
      @gender=pokemon.gender
      @name=pokemon.name
      @form=pokemon.form
    end
    
    applyGenerationLimit(MAXGENERATIONS)
  end
  
  def applyGenerationLimit(generation)
    if generation>1
      father.applyGenerationLimit(generation-1) if @father
      mother.applyGenerationLimit(generation-1) if @mother
    else
      father=nil
      mother=nil
    end  
  end 
  
  def [](value) # [0] = father, [1] = mother
    if value==0
    return @father
    elsif value==1
    return @mother
    end
    return nil
  end
end  
  
class PokeBattle_Pokemon
  attr_accessor :family
end