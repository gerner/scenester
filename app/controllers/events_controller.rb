require 'foursquare'

class EventsController < ApplicationController
  # GET /events
  # GET /events.xml
  def index
    @nav_cat = :today
    Time.zone = "America/Los_Angeles"
    now = Time.new
    today = Time.local(now.year, now.month, now.day, 4, 0, 0)
    #TODO: this should really be in the user's timezone, or in the event catalog's timezone
    @events = Event.paginate(:conditions => ["start > ?", now], :page => params[:page], :per_page => params[:per_page], :order => 'start ASC', :include => [:venue])

    respond_to do |format|
      format.html # index.html.erb
      format.rss
      format.xml  { render :xml => @events }
      format.ics  { render :text => Event.to_ics(@events) }
    end
  end

  def search
    unless params[:q]
      redirect_to :action => "index"
      return
    end
    logger.info("query: #{params[:q]}")

    Time.zone = "America/Los_Angeles"
    @q = params[:q]

    #TODO: cat pages should probably be separate methods
    case(@q)
    when "tag:music"
      @nav_cat = :music
    when "tag:arts"
      @nav_cat = :art
    when "tag:theater"
      @nav_cat = :theater
    when "tag:tech"
      @nav_cat = :tech
    end
    now = Time.new
    #TODO: this should really be in the user's timezone, or in the event catalog's timezone
    @events = Event.paginate(:conditions => Event.search_conditions(@q, :clauses => ["start > ? AND start < ?"], :values => [now, now.advance(:months => 1)]), :page => params[:page], :per_page => params[:per_page], :order => :start, :include => [:venue])
    respond_to do |format|
      format.html # index.html.erb
      format.rss
      format.xml  { render :xml => @events }
      format.ics  { render :text => Event.to_ics(@events) }
    end
  end

  def foursquare
    authorization_code="EWPW4SAQO3THR24WGOJ4TSY5AK5VFSIVSTBG2HQAFYRFZLQ0"

    t = Time.now
    user = Foursquare::User.new(authorization_code)
    checkins = user.checkins["response"]["checkins"]["items"]
    logger.info("foursquare responded in #{((Time.now - t) * 1000).round}ms")
    @events = []
    #vtimes = []
    checkins.each do |c|
      venue = c["venue"]["name"]
      t = Time.at(c["createdAt"])
      e = Event.find_attending(venue, t).includes(:venue).first
      @events << e if e
      #vtimes << {:venue => venue, :time => t}
    end

    #@events = Event.find_attending(vtimes)

    respond_to do |format|
      format.html { render 'index' }

    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find_by_slug(params[:id])
    if @event.slug != params[:id]
      redirect_to event_path(@event), :status=>:moved_permanently 
      return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
      format.json { render :json => @event }
    end
  end

  def show_partial
    @event = Event.find_by_slug(params[:id])

    render @event
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find_by_slug(params[:id])
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])

    respond_to do |format|
      if @event.save
        format.html { redirect_to(@event, :notice => 'Event was successfully created.') }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find_by_slug(params[:id])

    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { redirect_to(@event, :notice => 'Event was successfully updated.') }
        format.xml  { head :ok }
        format.json { render :nothing =>  true }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
        format.json { render :nothing =>  true }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find_by_slug(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end

  # PUT /events/1/recommend
  def recommend
    @event = Event.find_by_slug(params[:id])
    @event.recommended = true
    @event.save

    redirect_to(:back)
  end

  # DELETE /events/1/recommend
  def unrecommend
    @event = Event.find_by_slug(params[:id])
    @event.recommended = false
    @event.save

    redirect_to(:back)
  end
end
