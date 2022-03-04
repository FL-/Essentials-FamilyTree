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
# INSTALLATION FOR ESSENTIALS VERSION 18
#
# To this script works, put it above PSystem_System. Put a 512x384 background
# for this screen in "Graphics/Pictures/Summary/" as "bg_6" and as "bg_6_egg".
# This last one is only necessary if SHOWFAMILYEGG is true. You also need to
# update the below pictures on same folder in order to reflect the summary
# icon change:
# - bg_1
# - bg_2
# - bg_3
# - bg_4
# - bg_movedetail
# - bg_5
#
# -At PField_DayCare, before line '$Trainer.party[$Trainer.party.length]=egg'
# add line 'egg.family = PokemonFamily.new(egg, father, mother)'
#
# -At PScreen_Summary, change both lines '@page = 5 if @page>5'
# to '@page=6 if @page>6'
#
# -Before line 'if Input.trigger?(Input::A)' add line 'handleInputsEgg'
#
# -After line 'when 5; drawPageFive' add 'when 6; drawPageSix'
#
# -Change line '_INTL("RIBBONS")][page-1]' into:
#
# _INTL("RIBBONS"),
# _INTL("FAMILY TREE")][page-1]
#
# -Change both lines 
# 'if @party[newindex] && (@page==1 || !@party[newindex].egg?)' into:
#
# if @party[newindex] && 
#   (@page==1 || !@party[newindex].egg? || (@page==6 && SHOWFAMILYEGG))
#
# -Change both
# 
#  pbSEStop; pbPlayCry(@pokemon)
#  @ribbonOffset = 0
#  dorefresh = true
#
# into:
#
#  pbSEStop; pbPlayCry(@pokemon)
#  @ribbonOffset = 0
#  if SHOWFAMILYEGG && @pokemon.isEgg? && @page==6
#    dorefresh = false
#    drawPageSix
#  else
#    dorefresh = true
#  end
#
#===============================================================================
#
# INSTALLATION FOR ESSENTIALS VERSION 17
#
# To this script works, put it above PSystem_System. Put a 512x384 background
# for this screen in "Graphics/Pictures/Summary/" as "bg_6" and as "bg_6_egg".
# This last one is only necessary if SHOWFAMILYEGG is true. You also need to
# update the below pictures on same folder in order to reflect the summary
# icon change:
# - bg_1
# - bg_2
# - bg_3
# - bg_4
# - bg_movedetail
# - bg_5
#
# -At PField_DayCare, before line '$Trainer.party[$Trainer.party.length]=egg'
# add line 'egg.family = PokemonFamily.new(egg, father, mother)'
#
# -At PScreen_Summary, change both lines '@page = 5 if @page>5'
# to '@page=6 if @page>6'
#
# -Before line 'if Input.trigger?(Input::A)' add line 'handleInputsEgg'
#
# -After line 'when 5; drawPageFive' add 'when 6; drawPageSix'
#
# -Change line '_INTL("RIBBONS")][page-1]' into:
#
# _INTL("RIBBONS"),
# _INTL("FAMILY TREE")][page-1]
#
# -Change both lines 
# 'if @party[newindex] && (@page==1 || !@party[newindex].egg?)' into:
#
# if @party[newindex] && 
#   (@page==1 || !@party[newindex].egg? || (@page==6 && SHOWFAMILYEGG))
#
# -Change both
# 
#  pbSEStop; pbPlayCry(@pokemon)
#  @ribbonOffset = 0
#  dorefresh = true
#
# into:
#
#  pbSEStop; pbPlayCry(@pokemon)
#  @ribbonOffset = 0
#  if SHOWFAMILYEGG && @pokemon.isEgg? && @page==6
#    dorefresh = false
#    drawPageSix
#  else
#    dorefresh = true
#  end
#
#===============================================================================

class PokemonSummary_Scene
  SHOWFAMILYEGG = true # when true, family tree is also showed in egg screen.

  def drawPageSix
    overlay=@sprites["overlay"].bitmap
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    textpos=[]
    if @pokemon.isEgg?
      overlay.clear
      pbSetSystemFont(overlay)
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_6_egg")
      imagepos = []
      ballimage = sprintf(
        "Graphics/Pictures/Summary/icon_ball_%02d",@pokemon.ballused)
      imagepos.push([ballimage,14,60,0,0,-1,-1])
      pbDrawImagePositions(overlay,imagepos)
      textpos=[
         [_INTL("TRAINER MEMO"),26,16,0,base,shadow],
         [@pokemon.name,46,62,0,base,shadow],
         [_INTL("Item"),62,318,0,base,shadow]
      ]
      if @pokemon.hasItem?
        textpos.push([PBItems.getName(@pokemon.item),16,352,0,
          Color.new(64,64,64), Color.new(176,176,176)])
      else
        textpos.push([_INTL("None"),16,352,0,
          Color.new(184,184,160),Color.new(208,208,200)])
      end
      drawMarkings(overlay,82,292)
    end  
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
  end

  def handleInputsEgg
    if SHOWFAMILYEGG && @pokemon.isEgg?
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