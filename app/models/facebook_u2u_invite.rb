require 'ladon/error_handling'
require 'mogli'

# Represents a Facebook U2U app request functioning as an invitation for a user to join Copious. Specifically it
# represents the "full" form of the app request directed to a specific user. Such a request is a component of an
# aggregate app request represented by +FacebookU2uRequest+.
#
# The lifecycle of a U2U invite has two states:
#
# 1. +pending+ - the app request was created on the Facebook side and can be retrieved with an Open Graph query.
#    on our side, the invitee has not yet accepted this or any other U2U invite, so the invite does not yet have
#    an associated user. typically the invite will be found by querying by the invitee's Facebook uid.
# 2. +complete+ - the invitee accepted either this or some other U2U invite and has been associated with all of the
#    invite requests tagged with his Facebook uid. the associated app request may or may not have been deleted on
#    the Facebook side yet.
#
# Facebook best practice is to delete the app request once the rinvite has been accepted. This is not done
# automatically upon transitioning to +complete+, because if the user has many pending invites outstanding, they all
# need to be successfully completed before any app requests are deleted.
#
# @see https://developers.facebook.com/docs/requests/
class FacebookU2uInvite < ActiveRecord::Base
  include Ladon::ErrorHandling

  belongs_to :request, class_name: 'FacebookU2uRequest', foreign_key: :facebook_u2u_request_id
  belongs_to :user
  attr_accessible :fb_user_id, :invite_code, :source

  # Returns the Open Graph id of the full app request
  def full_request_id
    "#{request.fb_request_id}_#{fb_user_id}"
  end

  # Returns the full app request, or +nil+ if the request has been deleted.
  #
  # @return [Mogli::AppRequest]
  def app_request
    Mogli::AppRequest.find(full_request_id, client)
  rescue Mogli::Client::ClientException => e
    # raises `Mogli::Client::ClientException: GraphMethodException: Unsupported get request.` when the app request has
    # been deleted already
    nil
  end

  # Returns an authenticated Mogli client that can be used to make Open Graph requests
  #
  # @return [Mogli::Client]
  def client
    Mogli::Client.new(Network::Facebook.access_token)
  end

  def pending?
    user_id.nil?
  end

  def complete?
    !pending?
  end

  def complete!(user)
    self.user_id = user.id
    save!
  end

  def async_delete_app_request
    Facebook::DeleteU2uInviteRequestJob.enqueue(self.id)
  end

  # Deletes the "full" version of the app request from Facebook. Idempotent.
  #
  # @see https://developers.facebook.com/docs/requests/#deleting
  def delete_app_request!
    logger.debug("Deleting Facebook U2U app request #{full_request_id}")
    # destroy appears to return true for any delete attempt on an already-deleted request
    Mogli::AppRequest.new(id: full_request_id, client: client).destroy
    true
  rescue MultiJson::DecodeError => e
    # we seem to get `MultiJson::DecodeError: "757: unexpected token at 'true'"` from this request upon success, so just
    # let it go
    true
  end

  def source
    super
  rescue NoMethodError # back compat, remove when this attribute is in the production db schema
    nil
  end

  def source=(*)
    super
  rescue NoMethodError # back compat, remove when this attribute is in the production db schema
    nil
  end

  after_commit on: :create do
    Facebook::AfterU2uInviteCreationJob.enqueue(self.id)
  end

  # normally these will just be archived rather than deleted, but in case of deletion we need to delete the app
  # request as well
  after_destroy do
    # that said, don't let an exception deleting the app request roll back deletion of the invite itself
    self.class.with_error_handling("Delete Facebook U2U invite #{id}", facebook_u2u_invite_id: id) do
      delete_app_request!
    end
  end

  # Returns all pending invites (optionally limited to a particular FB user) in reverse chronological order.
  #
  # @param [String] uid includes only invites for this FB user
  # @return [ActiveRecord::Relation]
  def self.find_all_pending(uid = nil)
    relation = where(user_id: nil)
    relation = relation.where(fb_user_id: uid) if uid.present?
    relation.order('created_at DESC')
  end

  # Returns all pending invites created since +datetime+.
  #
  # @options option [User] :sender includes only invites sent by this user
  # @return [ActiveRecord::Relation]
  def self.find_all_pending_since(datetime, options = {})
    relation = where(user_id: nil).where("#{quoted_table_name}.created_at >= ?", datetime)
    if options[:sender]
      relation = relation.joins(:request).where(facebook_u2u_requests: {user_id: options[:sender].id})
    end
    relation
  end

  # Returns the FB user ids with pending invites created since +datetime+.
  #
  # @options option [User] :sender includes only invites sent by this user
  # @return [Array]
  def self.find_all_fb_user_ids_pending_since(datetime, options = {})
    find_all_pending_since(datetime, options).select(:fb_user_id).map(&:fb_user_id).uniq
  end

  # Returns the count of complete invites.
  #
  # @options option [User] :sender includes only invites sent by this user
  # @return [Integer]
  def self.count_complete(options = {})
    relation = where("#{quoted_table_name}.user_id IS NOT NULL")
    if options[:sender]
      relation = relation.joins(:request).where(facebook_u2u_requests: {user_id: options[:sender].id})
    end
    relation.count
  end
end
