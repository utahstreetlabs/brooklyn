require 'brooklyn/sprayer'

class Contact < ActiveRecord::Base
  extend Brooklyn::Memoizable
  include Brooklyn::Sprayer

  belongs_to :email_account
  belongs_to :person

  attr_accessible :email, :fullname, :firstname, :lastname

  def display_name
    name = fullname
    name ||= [firstname, lastname].select { |n| n.present? }.join(' ')
    name = email.split('@')[0] if (name.nil? || name.blank?) && email.present?
    name
  end
  memoize :display_name

  def invite
    self.class.send_email(:contact_invitation, self)
  end

  # associate this contact with an existing user (via the +person+ table).  initially, contacts are generally created
  # as standalone entities but when we find an existing user with the same email, we want to create a linkage.
  # also delete the standalone +person+ if it's not connected to anything else.
  def associate_with_person!(person)
    unless self.person == person
      orphan = self.person
      self.person = person
      save!
      begin
        orphan.delete
      rescue ActiveRecord::StatementInvalid => e
        # since foreign keys all point to person, tracking them all here is bound to fall out of sync.
        # instead, we just attempt the delete and let the FK constraint restrict it in the DB.
      end
    end
  end

  def self.find_by_ids_with_email_accounts(ids)
    self.where(id: ids).includes(:email_account)
  end
end
