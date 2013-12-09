require 'active_support/concern'

module Users
  # APIs relating to acceptance of targeted and untargeted invites. A user accepts an invite by visiting the invite's
  # landing page, connecting to a network, and returning to the site.
  #
  # A user who receives a targeted invite is said to have been directly invited. A user may receive many targeted
  # invites (but only one from each inviter). The user may only accept one invite.
  module InviteAcceptance
    extend ActiveSupport::Concern

    class InviteAcceptanceError < Exception; end
    class InvalidInviteAcceptanceState < InviteAcceptanceError; end
    class InviteAcceptanceFound < InviteAcceptanceError; end
    class InviteNotFound < InviteAcceptanceError; end
    class InviterNotFound < InviteAcceptanceError; end

    included do
      has_one :invite_acceptance
      has_many :facebook_u2u_requests, dependent: :destroy
      has_many :facebook_u2u_invites, dependent: :destroy
    end

    #
    # INVITEE METHODS
    #

    # Records this user's acceptance of the indicated invite.
    #
    # @param [String] code the unique code for an invite
    # @option options [Boolean] :ignore_state don't consider the user's state
    # @raise [InvalidInviteAcceptanceState] if the user is not in the connected state
    # @raise [InviteAcceptanceFound] if the user has already accepted an invite
    # @raise [InviteNotFound] if the identified invite could not be found
    # @raise [InviterNotFound] if the invite's inviter could not be found
    # @raise [ActiveRecord::RecordInvalid] if the invite acceptance is invalid
    # @return [::InviteAcceptance]
    def accept_invite!(code, options = {})
      assert_acceptance_state!(options)
      invite = Invite.find_by_uuid(code)
      raise InviteNotFound.new("User #{self.id}: Invite #{code} not found") unless invite
      raise InviterNotFound.new("User #{self.id}: Inviter not found for invite #{code}") unless invite.inviter
      create_invite_acceptance!(invite_uuid: invite.uuid, inviter_id: invite.inviter_id)
    end

    # Records this user's acceptance of a pending Facebook U2U invite. If the user has more than one pending invite,
    # the most recently created one is accepted. If an invite is accepted, the associated FB app requests for all
    # pending invites are deleted.
    #
    # @option options [Boolean] :ignore_state don't consider the user's state
    # @raise [InvalidInviteAcceptanceState] if the user is not in the connected state
    # @raise [InviteAcceptanceFound] if the user has already accepted an invite
    # @raise [InviteNotFound] if no invite could be found corresponding to any of the pending U2U invites
    # @raise [InviterNotFound] if the invite's inviter could not be found
    # @raise [ActiveRecord::RecordInvalid] if the invite acceptance is invalid
    # @return [::InviteAcceptance]
    def accept_pending_facebook_u2u_invite!(options = {})
      assert_acceptance_state!(options)
      profile = for_network(Network::Facebook)
      return nil unless profile
      u2us = profile.pending_u2u_invites
      return nil unless u2us.any?
      (invite, u2u) = Invite.find_from_u2us(u2us)
      raise InviteNotFound.new("User #{self.id}: No invites found for u2us #{u2us.map(&:id)}") unless invite
      raise InviterNotFound.new("User #{self.id}: Inviter not found for invite #{invite.uuid}") unless invite.inviter
      # all database writes must succeed or acceptance fails. only after complete success can we can delete the fb app
      # requests.
      acceptance = transaction do
        acceptance = build_invite_acceptance(invite_uuid: invite.uuid, inviter_id: invite.inviter_id)
        acceptance.facebook_u2u_invite = u2u
        acceptance.save!
        u2us.each do |u2u|
          u2u.complete!(self)
        end
        acceptance
      end
      u2us.each do |u2u|
        u2u.async_delete_app_request
      end
      acceptance
    end

    # Raises an exception if the user is not in a state that allows invite acceptance.
    #
    # @option options [Boolean] :ignore_state don't consider the user's state
    # @raise [InvalidInviteAcceptanceState] if the user is not in the connected state
    # @raise [InviteAcceptanceFound] if the user has already accepted an invite
    def assert_acceptance_state!(options = {})
      unless options[:ignore_state]
        raise InvalidInviteAcceptanceState.new("User #{self.id} is #{self.state}, not connected") unless connected?
      end
      raise InviteAcceptanceFound.new("User #{self.id} has already accepted an invite") if accepted_invite?
    end

    # Marks the user's accepted invite as having been credited.
    def credit_invite_acceptance!
      invite_acceptance.update_attribute(:credited, true)
    end

    # Returns true if the user accepted an invite, whether targeted or untargeted.
    def accepted_invite?
      invite_acceptance.present?
    end

    def accepted_untargeted_invite?
      accepted_invite && accepted_invite.untargeted?
    end

    def accepted_targeted_invite?
      accepted_invite && accepted_invite.targeted?
    end

    # Returns true if the user was granted credit based on his invite acceptance.
    def invite_acceptance_credited?
      accepted_invite? && invite_acceptance.credited?
    end

    # Returns the invite the user accepted, if any, whether targeted or untargeted.
    def accepted_invite
      unless defined?(@invite)
        @invite = invite_acceptance.invite if accepted_invite?
      end
      @invite
    end

    # Returns the user whose invite was accepted by this user, if any, whether targeted or untargeted.
    def accepted_inviter
      unless defined?(@accepted_inviter)
        @accepted_inviter = if accepted_untargeted_invite?
          indirectly_invited_by
        elsif accepted_targeted_invite?
          directly_invited_by
        end
      end
      @accepted_inviter
    end

    # Returns the invited network profile if the user accepted a targeted invite.
    def directly_invited_profile
      unless defined?(@directly_invited_profile)
        @directly_invited_profile = Profile.find(accepted_invite.invitee_id) if accepted_targeted_invite?
      end
      @directly_invited_profile
    end

    # Returns the user who invited this user, if the user accepted a targeted invite.
    def directly_invited_by
      unless defined?(@directly_invited_by)
        @directly_invited_by = self.class.find_by_id(accepted_invite.inviter_id) if accepted_targeted_invite?
      end
      @directly_invited_by
    end

    # Returns true if this user accepted a targeted invite from +user+.
    def directly_invited_by?(user)
      directly_invited_by == user
    end

    # Return all users who sent invites to this user.
    def inviters(reload = false)
      if !defined?(@inviters) || reload
        inviter_ids = []
        inviter_ids << accepted_invite.person_id if accepted_untargeted_invite?
        inviter_ids |= map_connected_profiles {|profile| profile.inviters.map(&:person_id)}
        @inviters = self.class.where(person_id: inviter_ids)
      end
      @inviters
    end

    # Returns the count of targeted invites sent to this user.
    def direct_invite_count
      person.network_profiles.values.inject([]) {|m, p| m.concat(Array.wrap(p)) }.sum(&:inviting_count)
    end

    # Returns the user whose untargeted invite this user accepted, if any.
    def indirectly_invited_by
      unless defined?(@indirectly_invited_by)
        @indirectly_invited_by = self.class.find_by_person_id(accepted_invite.person_id)
      end
      @indirectly_invited_by
    end

    #
    # INVITER METHODS
    #

    # Returns the user's untargeted invite. This should always exist (if the backend is doing its job correctly).
    def untargeted_invite
      unless defined?(@untargeted_invite)
        @untargeted_invite = Invite.find_by_person_id(self.person_id)
      end
      @untargeted_invite
    end

    # Returns the unique invite code that is inserted into the user's untargeted invite URL.
    def untargeted_invite_code
      untargeted_invite.id
    end

    # Returns the list of users who have accepted this user's untargeted invite.
    def untargeted_invitees
      unless defined?(@untargeted_invitees)
        @untargeted_invitees = untargeted_invite ? untargeted_invite.accepters : []
      end
      @untargeted_invitees
    end

    # Returns the social network profiles which this user has directly invited.
    def direct_invitee_profiles
      unless defined?(@direct_invitee_profiles)
        @direct_inviter_profiles = {}
        @direct_invitee_profiles = person.connected_profiles.each_with_object([]) do |p, m|
          invitee_profiles = p.inviting
          invitee_profiles.each { |ip| @direct_inviter_profiles[ip.id] = p }
          m.concat(invitee_profiles)
        end
      end
      @direct_invitee_profiles
    end

    # Returns the users whose social network profiles this user has directly invited.
    def direct_invitees
      unless defined?(@direct_invitees)
        @direct_invitees = self.class.where(person_id: direct_invitee_profiles.map(&:person_id))
      end
      @direct_invitees
    end

    # Returns whichever of this user's social network profile was used to invite +invitee_profile+.
    #
    # Note that the current implementation requires +#direct_invitee_profiles+ to have been called first.
    def direct_inviter_profile(invitee_profile)
      @direct_inviter_profiles[invitee_profile.id] if @direct_inviter_profiles
    end

    # Returns the total number of credited acceptances allowed across all of this user's invites.
    def credited_invite_acceptance_cap
      # this is an instance method to make it easier to customize the cap per user in the future
      Invite.max_creditable_acceptances
    end

    # Returns the number of credited acceptances across all of this user's invites.
    def credited_invite_acceptance_count
      unless defined?(@credited_invite_acceptance_count)
        @credited_invite_acceptance_count = ::InviteAcceptance.count_credited_for_inviter(self.id)
      end
      @credited_invite_acceptance_count
    end

    # Returns the percentage of credited acceptances across all of this user's invites. For example, if the user's
    # credited acceptance cap is 50 and the user has 10 credited acceptances, then the method returns 20.
    def credited_invite_acceptance_percent
      return 0 unless credited_invite_acceptance_cap > 0
      (credited_invite_acceptance_count / credited_invite_acceptance_cap.to_f * 100).floor
    end

    # Returns true if the user has reached the acceptance cap across all of his invites.
    def credited_invite_acceptance_capped?
      credited_invite_acceptance_count >= credited_invite_acceptance_cap
    end

    # The total possible amount the user can earn on an invite. Governed by the cap on the number of times a
    # particular invite can be accepted.
    def total_amount_earnable_for_accepted_invites
      Credit.amount_for_accepted_invite * Invite.max_creditable_acceptances
    end

    def u2u_invite_excludes
      @u2u_invite_excludes ||= Network::Facebook.uids_to_exclude_from_u2u_invites(self)
    end
  end
end
