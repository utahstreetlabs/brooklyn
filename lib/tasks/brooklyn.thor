require 'active_support/core_ext/object'
require 'nokogiri'
require 'typhoeus'
require 'yaml'
YAML::ENGINE.yamler = 'syck'

class Brooklyn < Thor
  S3_DEV_BUCKET = "s3://utahstreetlabs-dev-#{ENV['USER']}"
  S3_STAGING_BUCKET = 's3://utahstreetlabs-staging'
  DEV_UPLOAD_DIR = File.join('public', 'uploads', 'development')
  DB_CONFIG = File.join('config', 'database.yml')
  SDKJS_SOURCE = 'public/assets/sdk.js.gz'
  BOOKMARKLETJS_SOURCE = 'public/assets/bookmarklet.js.gz'

  desc "import_profile_photos [--force]", "import profile photos for users that do not have them"
  method_options :force => :boolean
  def import_profile_photos
    load_rails
    users = options.force?? User.all : User.where(:profile_photo => nil)
    users.each do |user|
      user.async_set_profile_photo_from_network
    end
  end

  desc "rebuild_from_staging", "copies staging db data and uploads to development"
  def rebuild_from_staging
    invoke :rebuild_development_db_from_staging
    invoke :rebuild_development_uploads_from_staging
  end

  desc "rebuild_development_db_from_staging", "copies staging db data to development db"
  def rebuild_development_db_from_staging
    dev = db_config['development']
    st = db_config['staging']
    run_command("rake db:drop db:create")
    dump_command = "ssh staging.copious.com 'mysqldump -u #{st['username']} -p#{st['password']} -h #{st['host']} #{st['database']}'"
    load_command = "mysql -u #{dev['username']} -p#{dev['password']} -h #{dev['host']} #{dev['database']}"
    run_command("#{dump_command} | #{load_command}")
    run_command("rake sunspot:reindex")
  end

  desc "rebuild_development_uploads_from_staging", "copies staging upload files from S3 to local uploads dir"
  def rebuild_development_uploads_from_staging
    using_s3cmd do
      run_command("rm -rf #{DEV_UPLOAD_DIR}")
      run_command("mkdir -p #{DEV_UPLOAD_DIR}")
      run_command("s3cmd -P cp --recursive #{S3_STAGING_BUCKET} #{S3_DEV_BUCKET}")
    end
  end

  desc "copy_development_uploads_to_s3", "copies development upload files from local uploads dir to s3"
  def copy_development_uploads_to_s3
    using_s3cmd do
      run_command("s3cmd -P sync #{DEV_UPLOAD_DIR}/listing_photo #{S3_DEV_BUCKET}")
      run_command("s3cmd -P sync #{DEV_UPLOAD_DIR}/user #{S3_DEV_BUCKET}")
    end
  end

  desc "smoke", "request the home page and check for a valid response"
  method_option :host, default: 'localhost', desc: 'the host the application runs on'
  method_option :port, default: 8080, desc: 'the port the application listens on'
  method_option :timeout, default: 500, desc: 'the number of milliseconds after which the request times out'
  def smoke
    success = false
    url = "http://#{options[:host]}:#{options[:port]}/"
#    say_trace "Requesting #{url}"
    response = Typhoeus::Request.get(url, timeout: options[:timeout].to_i)
    if response.success?
      doc = Nokogiri::HTML(response.body)
      if doc.css('body.logged_out_home').any? or doc.css('body.home_index').any?
        say_ok "Success in #{timestamp(response.time)} ms"
        success = true
      else
        say_error "False positive in #{timestamp(response.time)} ms"
      end
    elsif response.timed_out?
      say_error "Timed out after #{timestamp(response.time)} ms"
    elsif response.code == 0
      say_error "No response in #{timestamp(response.time)} ms"
    else
      say_error "Request error (code #{response.code}) in #{timestamp(response.time)} ms"
    end
    # wanted to override exit_on_failure? and raise Thor::Error, but that wasn't setting the exit code properly
    exit(1) unless success
  end

  desc "sync_networks NETWORK", "Force sync of person ids for a network"
  method_option :ids, :type => :array, :default => [], :required => true, :aliases => "-i"
  def sync_networks(network)
    load_rails
    require 'resque'
    require 'rubicon'
    options[:ids].each do |person_id|
      Rubicon::Jobs::Sync.enqueue(Rubicon::Jobs::Sync, person_id, network)
      puts "Enqueued sync of data for (network=>#{network},person_id=>#{person_id})"
    end
  end

  desc "sync_network_attrs NETWORK", "Force sync of profile data for person ids for a network"
  method_option :ids, :type => :array, :default => [], :required => true, :aliases => "-i"
  def sync_network_attrs(network)
    load_rails
    require 'resque'
    require 'rubicon'
    num_synced = 0
    options[:ids].each do |person_id|
      ::Rubicon::Jobs::SyncAttrs.perform(person_id, network)
      User.find_for_person(person_id).touch_last_synced
      say_ok "Synced profile attributes for (network=>#{network},person_id=>#{person_id})"
    end
  end

  desc "delete_inactive_user_stashes (SECONDS)", "Delete stashes of users not active in the past SECONDS seconds"
  def delete_inactive_user_stashes(seconds = 0)
    load_rails
    num_deleted = Users::DeleteInactiveStashesJob.perform(seconds)
    say_ok "Deleted #{num_deleted} stashes inactive since #{Time.zone.now.ago(seconds)}"
  end

  desc "sync_stale_user_network_profiles (SECONDS)", "Sync network profiles of users not synced in the past SECONDS seconds"
  def sync_stale_user_network_profiles(seconds = 0)
    load_rails
    num_synced = Users::SyncStaleNetworkProfilesJob.perform(seconds)
    say_ok "Synced network profiles for #{num_synced} users not sinced since #{Time.zone.now.ago(seconds)}"
  end

  desc 'sync_listings', 'Sync listings from all external sources'
  def sync_listings
    load_rails
    Listing.sync_all_sources
  end

  desc 'listing_datafeed', 'generate a csv of the listings'
  def listing_datafeed
    load_rails
    require 'csv'
    urls = Rails.application.routes.url_helpers
    puts(['title', 'price', 'total price', 'category', 'state', 'order status',
          'tags', 'url', 'dimensions', 'seller email', 'seller name',
          'admin url',
          'date joined', 'date listed'].to_csv)
    Listing.includes(:seller, :order, :category).with_states(:incomplete, :active, :sold).find_each do |listing|
      seller = listing.seller
      order = listing.order
      category = listing.category
      puts([listing.title, listing.price.to_i, listing.total_price.to_i,
       category ? category.name : nil,
       listing.state,
       order ? order.status : nil,
       listing.tags.map(&:slug).join('^'),
       urls.listing_url(listing, :host => 'copious.com'),
       listing.dimension_values.includes(:dimension).map do |dv|
         "#{dv.dimension.name}: #{dv.value}"
       end.join('^'),
       seller.email,
       seller.name,
       urls.admin_listing_url(listing.id, :host => 'copious.com'),
       seller.created_at,
       listing.created_at].to_csv)
    end
  end

  desc 'tag_seed INPUT OUTPUT', 'generate a tag seed file from a CSV list of tags'
  method_option :type, :aliases => "-t"
  def tag_seed(input, output)
    require 'csv'
    require 'seed-fu'
    SeedFu::Writer.write(output, class_name: 'Tag', constraints: [:name]) do |writer|
      CSV.foreach(input, skip_blanks: true) do |row|
        attrs = {name: row.first, slug: row.first.parameterize, type: options[:type]}
        writer << attrs
      end
    end
  end

  desc 'set_primary_tag NAME', 'updates tags to have a new primary tag'
  method_option :children, :type => :array, :default => [], :required => true, :aliases => "-c"
  def set_primary_tag(name)
    load_rails
    Tag.where(name: name).first.merge_by_name(options[:children])
  end

  desc 'remove_tag_type', 'reset type of tags'
  method_option :type, :aliases => "-t", :required => true
  def remove_tag_type
    load_rails
    Tag.where(type: options[:type]).each do |t|
      t.type = nil
      t.save!
    end
  end

  desc 'dump_fb_data OUTPUT', 'dump facebook data to a yaml file'
  def dump_fb_data(output)
    load_rails
    profiles = {}
    FacebookProfile.find_each do |p|
      say_trace "Reading profile #{p.id}"
      profiles[p.id] = p.attributes.merge('friends' => [])
    end
    FacebookFriend.find_each do |f|
      say_trace "Reading friend #{f.id}"
      profiles[f.friend1_id]['friends'] <<
        {'id' => f.friend2_id, 'created_at' => f.created_at, 'updated_at' => f.updated_at}
      profiles[f.friend2_id]['friends'] <<
        {'id' => f.friend1_id, 'created_at' => f.created_at, 'updated_at' => f.updated_at}
    end
    File.open(output, "w") do |f|
      profiles.each_pair do |id, p|
        say_trace "Dumping profile #{id}"
        YAML.dump(p, f)
      end
    end
    say_ok "Dumped #{profiles.size} profiles to #{output}"
  end

  desc 'copy_listing_state', 'copy listing state to anchor'
  def copy_listing_state
    load_rails
    Listing.find_each do |l|
      say_trace "Copying listing #{l.slug}"
      a = Anchor::Listing.new(listing_id: l.id, state: l.state)
      a.update
    end
  end

  desc 'dump_listings_to_tags', 'dump map from listing ids to tag ids'
  method_option :out, default: 'listings_to_tags.yaml'
  method_option :since, default: '2011-12-01', desc: 'dump a yaml map of listing ids to tag ids'
  def dump_listings_to_tags
    output = options[:out]
    since = Time.parse(options[:since])
    load_rails
    hash = {}
    hash.default_proc = proc { [] }
    ListingTagAttachment.where('created_at > ?', since).find_each do |l|
      hash[l.listing_id] <<= l.tag_id
    end
    File.open(output, "w") do |f|
      YAML.dump(hash, f)
    end
    say_ok "Dumped #{hash.size} profiles to #{output}"
  end

  desc 'add_suggested_user', 'add user (via slug) to the suggested users table'
  method_option :slug, :required => true, :aliases => "-s"
  method_option :position, :required => false, :aliases => "-p"
  def add_suggested_user
    load_rails
    user = User.find_by_slug(options[:slug])
    us = user.build_user_suggestion
    us.position = options[:position] if options[:position].present?
    us.save!
  end

  desc 'add_suggested_users', 'add users (via slug) to the suggested users table, in position order'
  method_option :slugs, :type => :array, :default => [], :required => true, :aliases => "-s"
  def add_suggested_users
    load_rails
    options[:slugs].each do |slug|
      user = User.find_by_slug(slug)
      us = user.build_user_suggestion
      us.save!
    end
  end

  desc 'remove_suggested_user', 'remove user (via slug) from the suggested users table'
  method_option :slug, :type => :string, :required => true, :aliases => "-s"
  method_option :position, :required => false, :aliases => "-p"
  def remove_suggested_user
    load_rails
    user = User.find_by_slug(options[:slug])
    us = UserSuggestion.where(user_id: user.id).first
    us.destroy if us
  end

  desc 'modify_images', 'modify a bunch of images - generally used for helping product test ideas'
  method_option :indir, default: 'original_images'
  method_option :outdir, default: 'modified_images'
  def modify_images
    require 'RMagick'
    indir = options[:indir]
    outdir = options[:outdir]
    Dir.mkdir(outdir) unless Dir.exists?(outdir)
    Dir.foreach(indir) do |entry|
      file = "#{indir}/#{entry}"
      if File.file?(file)
        img = ::Magick::Image::read(file).first
        # swap this out to try different transformations
        new_img = img.resize_to_fill(220, 220)
        new_img.write("#{outdir}/modified_#{entry}")
        img.destroy!
        new_img.destroy!
      end
    end
  end

  desc 'cache_recent_listing_ids USER_ID', 'cache recent listing ids for a registered user'
  def cache_recent_listing_ids(user_id)
    load_rails
    user = User.find(user_id)
    raise ArgumentError.new('User is not in registered state') unless user.registered?
    listed_ids = user.fill_recent_listed_listing_ids
    saved_ids = user.fill_recent_saved_listing_ids
    loved_ids = user.fill_recent_loved_listing_ids
    say_ok "User #{user.id}: listed #{listed_ids.join(', ')}, saved #{saved_ids.join(', ')}, loved #{loved_ids.join(', ')}"
  end

  desc 'cache_all_recent_listing_ids', 'cache recent listing ids for every registered user'
  def cache_all_recent_listing_ids
    load_rails
    i = 0
    User.select(:id).with_state(:registered).order(:id).find_each do |user|
      listed_ids = user.fill_recent_listed_listing_ids
      loved_ids = user.fill_recent_loved_listing_ids
      saved_ids = user.fill_recent_saved_listing_ids
      say_ok "User #{user.id}: listed #{listed_ids.join(', ')}, saved #{saved_ids.join(', ')}, loved #{loved_ids.join(', ')}"
      i += 1
      say_trace "  ** #{i} users processed" if i % 1000 == 0
    end
    say_ok "#{i} processed in total"
  end

  desc 'import_anchor_offers', 'import offers from anchor to mysql after running the db:migrate'
  method_option :mongo_host, aliases: '-H', default: '127.0.0.1', desc: "mongo host holding anchor offers"
  method_option :mongo_port, aliases: '-P', default: 27017, desc: "port on mongo host for anchor"
  def import_anchor_offers
    load_rails
    require 'mongo'
    require 'progress_bar'

    mongo = Mongo::Connection.new(options.mongo_host, options.mongo_port, slave_ok: true)
    env = ENV['RAILS_ENV'] || 'development'
    db = "anchor_#{env}"
    anchor_offers = mongo.db(db).collection('offers')
    count = anchor_offers.count

    say_trace "Importing #{count} offers from mongo://#{options.mongo_host}:#{options.mongo_port}/#{db}"
    progress = ProgressBar.new(count)

    anchor_offers.find.each do |anchor_offer|
      id = anchor_offer['_id'].to_s
      offer = Offer.find_by_uuid(id)
      raise "Error migrating offer #{id}" unless offer.persisted?
      progress.increment!
    end

    say_trace "Updating offer credits"
    ActiveRecord::Base.connection.execute(
      "UPDATE credits c JOIN offers o ON c.offer_uuid = o.uuid SET c.offer_id = o.id")
  end

  desc 'fixup_old_size_tags', 'remove tags that used to be size tags and add them to the general tag pool for a listing'
  def fixup_old_size_tags
    load_rails
    Listing.where('size_id is not null').each do |l|
      tags = Tag.where(id: l.size.id).where("type != 's' || type is null")
      if tags.any?
        say_trace "Updating listing #{l.id} with size tag #{l.size.slug}"
        l.size = nil
        tags.each do |t|
          l.tags << t unless l.tags.include?(t)
        end
        l.save!
        say_trace "New tags: #{l.tags.map(&:slug).inspect}"
      end
    end
  end

  desc 're_onboard', 're-onboard old users with low follow counts'
  def re_onboard
    load_rails
    all_ids = User.where(id: User.find_by_sql("SELECT t.id FROM \
  (SELECT users.name, users.id, users.created_at, count(follows.user_id) AS followee_count \
   FROM users LEFT OUTER JOIN follows ON users.id = follows.follower_id GROUP BY users.id) \
  AS t \
  WHERE followee_count < 10 and created_at < '2012-01-16'").map(&:id))
    count = 0
    total = all_ids.count
    batch_size = 10
    all_ids.each_slice(batch_size) do |ids|
      User.where(id: ids).update_all(needs_onboarding: true)
      count += batch_size
      say_trace "Updated #{[count, total].min} of #{total} users who need onboarding"
    end
  end

  desc 'migrate_invite_ids', 'migrate users.invite_id to invite_acceptances'
  def migrate_invite_ids
    load_rails
    # I'd use progress bar, but it seems to shit the bed in production
    count = 0
    User.where('invite_id IS NOT NULL').includes(:invite_acceptance).find_each(batch_size: 100) do |user|
      next if user.invite_acceptance
      begin
        # we have no way of knowing if any of these invitees were actually granted invites or not. safest bet is to just
        # assume they were all ineligible and start every inviter's acceptance counter at 0.
        acceptance = user.accept_invite!(user.invite_id, ignore_state: true)
        say_trace "User #{user.id}: Migrated invite id #{user.invite_id} to acceptance #{acceptance.id}"
        count += 1
      rescue Exception => e
        say_error "User #{user.id}: #{e.message}"
      end
    end
    say_ok "#{count} invite ids migrated"
  end

  desc 'migrate_external_descriptions', 'migrate old external listings without descriptions to new model'
  def migrate_external_descriptions
    load_rails
    count = 0
    ExternalListing.where('description IS NULL').find_each(batch_size: 100) do |listing|
      begin
        all_comments = listing.comment_summary.comments.values
        first_comment = all_comments.sort_by(&:created_at).first
        if first_comment && (first_comment.user_id == listing.seller.id)
          # Note that we leave the first comment intact in case there were any replies to it.  We don't
          # want to delete the replies.  This will result in the external listing description being a duplicate
          # of the first comment text, but that should be ok for the ~12k affected listings.
          listing.description = first_comment.text
          listing.save!
        end
        count += 1
      rescue Exception => e
        say_error "ExternalListing #{listing.id}: #{e.message}"
      end
    end
    say_ok "#{count} external listings migrated"
  end

  desc 'update_inviters', 'get a list of users who have sent invitations. may include dupes'
  def list_inviters
    load_rails
    require 'progress_bar'
    progress = ProgressBar.new(User.count)
    User.find_each do |user|
      if (user.untargeted_invitees + user.direct_invitees + user.facebook_u2u_requests).any?
        user.update_attribute(:inviter, true)
      end
      begin
        progress.increment!
      rescue
        puts 'progressbar exploded. weird.'
      end
    end
  end

  desc 'update_sdk_js', 'update sdk.js (and bookmarklet.js) to the latest versions'
  def update_sdk_js
    env = ENV['RAILS_ENV'] || 'development'
    using_s3cmd do
      run_command "s3cmd put --add-header 'Cache-Control: public, max-age=3600' --add-header 'Content-Encoding: gzip' --acl-public #{SDKJS_SOURCE} s3://sdk-#{env}.copious.com/assets/sdk.js"
      run_command "s3cmd put --add-header 'Cache-Control: public, max-age=3600' --add-header 'Content-Encoding: gzip' --acl-public #{BOOKMARKLETJS_SOURCE} s3://sdk-#{env}.copious.com/assets/bookmarklet.js"
    end
  end

  desc 'add_default_collections', 'add default collections for each user'
  def add_default_collections
    load_rails
    require 'progress_bar'
    progress = ProgressBar.new(User.count)
    User.find_each do |user|
      begin
        user.create_default_collections!
      rescue Exception => e
        puts "Failed to create default collections for #{user.name}, user number #{user.id} cause #{e}"
      end
      begin
        progress.increment!
      rescue
        puts 'progressbar exploded. weird.'
      end
    end
  end

protected
  def load_rails
    require File.expand_path('config/environment.rb')
  end

  def db_config
    @db_config ||= YAML.load_file(DB_CONFIG)
  end

  def say_trace(msg)
    say_status :TRACE, msg, :blue
  end

  def say_ok(msg)
    say_status :OK, msg, :green
  end

  def say_error(msg)
    say_status :ERROR, msg, :red
  end

  def timestamp(time)
    sprintf("%.02f", (time || 0) * 1000)
  end

  def prog_in_path?(prog)
    %x[which #{prog}].present?
  end

  def run_command(command)
    say_status :run, command
    # for some reason this buffers up the command output for a while and then spits it all out at once.
    # I've tried flushing both STDOUT and f but it didn't seem to help. As it is now, it's not any better than
    # %x[], at least for s3cmd.
    IO.popen("#{command} 2>&1") do |f|
      while line = f.gets do
        puts line
      end
    end
  end

  def using_s3cmd(&block)
    if prog_in_path?('s3cmd')
      yield
    else
      shell.print_wrapped <<-OUTPUT
You do not appear to have s3cmd installed. You can install it on OS X with `brew install s3cmd`. See
http://s3tools.org/s3cmd for more info.
      OUTPUT
    end
  end
end
