class ProjectsController < ApplicationController
  before_action :set_user
  before_action :set_project, only: [:show, :edit, :update, :destroy]
  skip_before_action :check_login_frontend

  layout 'backend'

  # GET /projects
  def index
    @projects = @user.projects.order(created_at: :desc)
  end

  # GET /projects/1
  # GET /projects/1.text
  # GET /projects/1.json
  def show
    @surveys = @project.surveys.order(created_at: :desc)
    respond_to do |format|
      format.html {}
      format.text {
        if params.has_key?(:versions)
          send_file @project.to_zip(true, true), filename: @project.name+".zip", type: "application/zip"
        else
          send_file @project.to_zip(true, false), filename: @project.name+".zip", type: "application/zip"
        end
      }
      format.json {
        if params.has_key?(:versions)
          send_file @project.to_zip(false, true), filename: @project.name+".zip", type: "application/zip"
        else
          send_file @project.to_zip(false, false), filename: @project.name+".zip", type: "application/zip"
        end
      }
    end
  end

  # GET /projects/new.js
  def new
    @project = Project.new
    respond_to do |format|
      format.js {
      }
      format.zip {
        render 'import.js.erb', content_type: Mime::JS
      }
    end
  end

  # GET /projects/1/edit.js
  def edit
  end

  # POST /projects.js
  def create
    respond_to do |format|
      format.js {
        @project = @user.projects.build(project_params)
        if @project.save
         redirect_to user_project_path(@user, @project)
        else
          render :new
        end
      }
      format.html {
        if params.has_key?(:project) && !params[:project][:file].nil?
          res = true
          params[:project][:file].each do |f|
            @project = @user.projects.build
            res = res && @project.import_file(f.tempfile)
          end
        end
        if res
          if params[:project][:file].size == 1
            redirect_to user_project_path(@user, @project), notice: I18n.t('projects.imported')
          else
            redirect_to user_projects_path(@user), notice: I18n.t('projects.imported')
          end
        else
          redirect_to user_projects_path(@user), notice: I18n.t('error_import')
        end
      }
    end
  end

  # PATCH/PUT /projects/1.js
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.js {}
      else
        format.js { render :edit }
      end
    end
  end

  # DELETE /projects/1
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to user_projects_path(@user), notice: I18n.t('projects.destroyed')}
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

  def set_user
    @user = User.find(params[:user_id])
    if @user.nil? || (@user.id != @login.id &&  !@login.admin?)
      redirect_to '/backend'
    end
  end

    def set_project
      @project = Project.find(params[:id])
      if @project.nil? || (@project.user != @user)
        redirect_to '/backend'
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.fetch(:project, {}).permit([:name, :description])
    end
end
