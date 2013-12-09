class InvitesSent < SimpleDelegator
  include Ladon::Logging

  attr_reader :user

  def initialize(user)
    @user = user
    directed = self.class.directed_invites(user)
    undirected = self.class.undirected_invites(user)
    super(directed + undirected)
    eager_fetch_bought_something
    eager_fetch_credit_amount
  end

  def eager_fetch_bought_something
    if any?
      ids = Order.find_purchaser_ids(map(&:invitee_id).compact.uniq)
      each { |p| p.bought_something = p.invitee_id.in?(ids) if p.invitee_id }
    end
  end

  def eager_fetch_credit_amount
    if any?
      idx = Credit.inviter_credits_for_user(user.id)
      each { |p| p.credit = idx[p.invitee_id] if p.invitee_id }
    end
  end

  def self.directed_invites(user)
    invitees = user.direct_invitees.each_with_object({}) { |u, m| m[u.person_id] = u }
    user.direct_invitee_profiles.map do |invitee_profile|
      inviter_profile = user.direct_inviter_profile(invitee_profile)
      invitee = invitees[invitee_profile.person_id]
      InvitePresenter.new(invitee_profile.name, user, inviter_profile: inviter_profile, invitee: invitee,
        invitee_profile: invitee_profile)
    end
  end

  def self.undirected_invites(user)
    user.untargeted_invitees.map do |invitee|
      InvitePresenter.new(invitee.name, user, invitee: invitee)
    end
  end

  class InvitePresenter
    attr_reader :name, :inviter
    attr_accessor :invitee, :inviter_profile, :invitee_profile, :bought_something, :credit

    def initialize(name, inviter, options = {})
      @name = name
      @inviter = inviter
      @invitee = options[:invitee]
      @inviter_profile = options[:inviter_profile]
      @invitee_profile = options[:invitee_profile]
      @bought_something = options.fetch(:bought_something, false)
      @credit = options[:credit]
    end

    def invitee_id
      invitee.id if invitee
    end

    def bought_something?
      !!bought_something
    end

    def created_at
      if inviter_profile && invitee_profile
        invitee_profile.invites.select { |i| i.inviter_id == inviter_profile.id }.first.created_at
      end
    end

    def qualified?
      invitee && invitee.invite_acceptance_credited?
    end

    def unqualified?
      invitee && !invitee.invite_acceptance_credited?
    end

    def purchased?
      qualified? && bought_something?
    end

    def capped?
      unqualified? && inviter.credited_invite_acceptance_capped?
    end

    def pending?
      invitee.nil?
    end

    def status
      if purchased?
        :accepted_purchased
      elsif qualified?
        :accepted_not_purchased
      elsif capped?
        :accepted_credit_capped
      elsif unqualified?
        :accepted_unqualified
      elsif pending?
        :pending
      end
    end

    def credit_amount
      credit ? credit.amount : 0
    end
  end
end
