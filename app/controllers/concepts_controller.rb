class ConceptsController < ApplicationController

  skip_before_action :check_login_backend
  before_action :set_concept_map
  before_action :set_concepts, only: [:update, :destroy]

  # POST /concept_maps/1/concepts.js
  def create
    @showColor = true
    @concept = @map.concepts.build(concept_params[:concepts_data])
    respond_to do |format|
      if @concept.save
        @map.versionize(DateTime.now)
        format.js {}
      else
        format.js {head :ok}
      end
    end
  end

  # PATCH/PUT /concept_maps/1/concepts/1.js
  def update
    respond_to do |format|
      #new Structur of sending Concepts: hash of hash(multiupdate)
      #Set to an array in method set_concepts
      @concepts.each do |c|
        old = c.label
        #update/PUT was sent by form
        if params.has_key?(:id)&&params[:id]!="-1"
          if c.update(concept_params[:concepts_data])
            @showColor = true
            @concept = c
            #update sent by form means: change of label or color -> don't record single colorchange
            unless @concept.label == old
              @map.versionize(DateTime.now)
            end
            format.js { }
          else
            format.js { head :ok }
          end
        else
          #update was sent by (multi) drag&drop, multicolorchange
          #-1 Fakeid: used for (multi) change of color, drag&drop
          if c.update(concept_params[:concepts_data][c.id.to_s])
            @showColor = true
            @concept = c
            #don't record, when only one conceptposition has changed (single drag&drop)
            unless concept_params[:concepts_data][c.id.to_s][:label] == old
              @map.versionize(DateTime.now)
            end
            format.js { }
          else
            format.js { head :ok }
          end
        end
      end
      #record a multiupdate
      if @concepts.size >1
        @map.versionize(DateTime.now)
      end
    end
  end

  # DELETE /concept_maps/1/concepts/1.js
  def destroy
    #array has only one Object (see set_concepts)
    @concept = @concepts.first
    @concept.destroy
    @map.versionize(DateTime.now)
    respond_to do |format|
      format.js {}
    end
  end

  private

  def set_concepts
    #Consider data structure and special case of sending hash of concepts for multiupdate
    if((params[:id]=="-1"||params[:id].nil?)&&params[:concepts].has_key?(:concepts_data))
      @concepts = Concept.find(params[:concepts][:concepts_data].keys)
    else
      #single Concept is send (create, singleupdate(keyword:form), destroy)
      @concepts = [Concept.find(params[:id])]
    end
    #consider data structure (sending hash of concepts)
    unless !@concepts.nil?&&@concepts.pluck(:concept_map_id).uniq.first == @concept_map.id&&@concepts.pluck(:concept_map_id).uniq.size==1
      redirect_to '/'
    end
  end

  def set_concept_map
    @concept_map = ConceptMap.find(params[:concept_map_id])
    unless !@concept_map.nil? && @concept_map == @map
      redirect_to '/'
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def concept_params
    params.fetch(:concepts, {}).permit(concepts_data:[:label, data:[:x,:y,:color]])
  end

end
