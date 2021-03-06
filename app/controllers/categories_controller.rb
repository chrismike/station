# Categories methods and filters for Category
class CategoriesController < ApplicationController
  before_filter :categories_domain!, :only => [ :index, :new, :create ]

  # List categories belonging to a Container
  #
  # GET /:categories_domain_type/:categories_domain_id/categories
  # GET /categories_domain_type/:categories_domain_id/categories.xml
  def index
    @categories = @categories_domain.domain_categories.column_sort(params[:order], params[:direction])
    @title = t('category.other_in_domain', :domain => @categories_domain.name)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  # Show category
  #
  # GET /categories/1
  # GET /categories/1.xml
  def show
    @categorizables = category.categorizables

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # New Category form
  #
  # GET /:categories_domain_type/:categories_domain_id/categories/new
  # GET /:categories_domain_type/:categories_domain_id/categories/new.xml
  def new
    @category = @categories_domain.domain_categories.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # Edit category form
  #
  # GET /categories/1/edit
  def edit
    category
  end

  # Create new category
  #
  # POST /:categories_domain_type/:categories_domain_id/categories
  # POST /:categories_domain_type/:categories_domain_id/categories.xml
  def create
    @category = @categories_domain.domain_categories.new(params[:category])

    respond_to do |format|
      if @category.save
        flash[:success] = t('category.created')
        format.html { redirect_to(@category) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
        format.js
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  # Update category
  #
  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    respond_to do |format|
      if category.update_attributes(params[:category])
        flash[:success] = t('category.updated')
        format.html { redirect_to(@category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Destroy category
  #
  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    category.destroy

    respond_to do |format|
      format.html { redirect_to(polymorphic_path([ @categories_domain, Category.new ])) }
      format.xml  { head :ok }
    end
  end

  protected

  # Sets @categories_domain, getting a CategoriesDomain from path (using record_from_path) or site
  def categories_domain!
    @categories_domain = record_from_path(:acts_as => :categories_domain) || site
  end

  # Find Category using params[:id]
  #
  # Sets @category and @categories_domain variables
  def category
    @category ||= Category.find(params[:id])
    raise ActiveRecord::RecordNotFound, "Category not found" unless @category
    @categories_domain ||= @category.domain
    @category
  end
end

