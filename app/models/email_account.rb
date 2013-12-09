require 'state_machine'

class EmailAccount < ActiveRecord::Base
  include Brooklyn::UniqueIndexEnforceable

  belongs_to :user
  has_many :contacts, :dependent => :destroy

  attr_accessible :identifier, :email, :provider

  state_machine :sync_state, :initial => :never do
    # never:         newly created account, no contacts imported
    # processing:    in the process of importing contacts
    # complete:      contacts successfully imported
    # error:         error occurred while importing contacts

    event :start_sync do
      transition :never => :processing
    end

    before_transition :on => :mark_sync_complete do |account|
      account.synced_at = Time.now
    end
    event :mark_sync_complete do
      transition :processing => :complete
    end

    event :mark_sync_error do
      transition :processing => :error
    end
  end

  def sync_contacts_from_data(data)
    cache = contacts.inject({}) { |map, c| map[c.email] = c; map }
    data.each do |c|
      c.fetch('emails', []).each do |email|
        # giving priority to name->formatted over displayName based on experience with gmail / yahoo / msn
        # might change down the road
        first, last, full = (name = c['name']) ? name.values_at('givenName', 'familyName', 'formatted') :
          [nil, nil, nil]
        full ||= c['displayName']

        hashed = { :email => email, :fullname => full, :firstname => first, :lastname => last }
        if contact = cache[email]
          contact.update_attributes(hashed)
        else
          contact = contacts.build(hashed)
          contact.build_person
        end
        contact.save!

        if contact_person = Person.find_by_any_email(email)
          # repoint this contact's +person+ attribute to be the same as the person we found
          contact.associate_with_person!(contact_person)
          contact_user = contact_person.user
          if contact_user and contact_user.registered?
            user.follow!(contact_user) unless user == contact_user
          end
        end
      end
    end
  end

  def async_sync_contacts!
    Contacts::Import.enqueue(id)
  end

  def sync_contacts!
    begin
      start_sync!
      sync_contacts_from_data(RPXNow.contacts(identifier))
      mark_sync_complete!
    rescue Exception => e
      mark_sync_error!
      raise
    end
  end

  def unregistered_contacts
    # skipping the person table in the join to avoid reading millions of extra rows
    Contact.find_by_sql(["SELECT c.* FROM contacts c LEFT OUTER JOIN users u ON c.person_id = u.person_id
      WHERE c.email_account_id = ? AND (u.person_id IS NULL OR u.registered_at IS NULL)", id])
  end

  def self.get_or_create_with_user_and_token(user, janrain_token)
    data = RPXNow.user_data(janrain_token)
    account = self.where(user_id: user.id, identifier: data[:identifier]).includes(:contacts).first
    if account.nil?
      account = self.new(email: data[:email], provider: data[:providerName], identifier: data[:identifier])
      account.user = user
      account.save!
    end
    account
  end
end
