class Facebook < Thor

  desc "app_access_token", "Generates an access token for the application"
  def app_access_token
    load_rails
    puts GraphApi.app_access_token
  end

  desc "create_test_user", "Creates a test user"
  def create_test_user
    load_rails
    GraphApi.create_test_user do |u|
      puts <<-EOT
Created user #{u.id}
  Login URL: #{u.login_url}
  Access token: #{u.access_token}
  Email: #{u.email}
  Password: #{u.password}
EOT
    end
  end

  desc "create_unconnected_test_user", "Creates an unconnected test user"
  def create_unconnected_test_user
    load_rails
    GraphApi.create_test_user(installed: false, permissions: nil) do |u|
      puts <<-EOT
Created user #{u.id}
  Login URL: #{u.login_url}
  Access token: #{u.access_token}
  Email: #{u.email}
  Password: #{u.password}
EOT
    end
  end

  desc "create_test_users NUM [--befriend]", "Creates a number of test users"
  def create_test_users(num)
    load_rails
    users = []
    GraphApi.create_test_users(num.to_i) do |u|
      puts <<-EOT
Created user #{u.id}
  Login URL: #{u.login_url}
  Access token: #{u.access_token}
  Email: #{u.email}
  Password: #{u.password}
EOT
      users.each { |friend| GraphApi.befriend(u, friend) }
      users << u
    end
  end

  desc "list_test_users", "Lists the test users for the Copious app"
  def list_test_users
    load_rails
    GraphApi.list_test_users.each do |u|
      puts <<-EOT
User #{u.id}
  Login URL: #{u.login_url}
  Access token: #{u.access_token}
  Email: #{u.email}
  Password: #{u.password}
EOT
    end
  end

  desc "delete_test_users UIDs", "Delete specific users"
  def delete_test_users(uids)
    load_rails
    uids.split.each do |uid|
      puts "Deleting user #{uid}"
      GraphApi.delete_test_user(uid)
    end
  end

  desc "befriend_other_test_users UID", "Creates friend connections between a specified user and all known test users"
  def befriend_other_test_users(uid)
    load_rails
    GraphApi.befriend_other_test_users(uid) do |from, to|
      puts "Befriended from #{from.id} to #{to.id}"
    end
  end

  desc "befriend_all_test_users", "Creates friend connections between all known test users"
  def befriend_all_test_users
    load_rails
    GraphApi.befriend_all_test_users do |from, to|
      puts "Befriended from #{from.id} to #{to.id}"
    end
  end

  desc "delete_all_test_users", "Deletes all test users"
  def delete_all_test_users
    load_rails
    GraphApi.delete_all_test_users {|u| puts "Deleted user #{u.id}"}
  end

protected
  def load_rails
    require File.expand_path('config/environment.rb')
  end

  def print_user_data(data)
    puts "User #{data.id}"
    puts "  Token: #{data.access_token}"
    puts "  Login url: #{data.login_url}"
  end
end

require 'httparty'
require 'mogli'

class GraphApi
  include HTTParty
  base_uri 'https://graph.facebook.com'

  def self.app_access_token
    query = {
      :client_id => Network::Facebook.app_id,
      :client_secret => Network::Facebook.app_secret,
      :grant_type => :client_credentials
    }
    rep = get('/oauth/access_token', :query => query)
    data = rep.split('&').inject({}) {|rv, pair| kv = pair.split('='); rv[kv[0]] = kv[1]; rv}
    data['access_token']
  end

  def self.client
    Mogli::AppClient.new(Network::Facebook.access_token, Network::Facebook.app_id)
  end

  def self.create_test_user(options={}, &block)
    query = options.reverse_merge(installed: true, permissions: Network::Facebook.scope, access_token: Network::Facebook.access_token)
    begin
      rep = Mogli::TestUser.create(query, client)
    rescue MultiJson::DecodeError => e
      Rails.logger.warn "Facebook test user destroy response is not json, msg => #{e.message}"
    end
    yield(rep) if block_given?
    rep
  end

  def self.create_test_users(num, &block)
    1.upto(num) {|x| create_test_user(&block)}
  end

  def self.list_test_users
    Mogli::TestUser.all(client)
  end

  def self.befriend(from, to, &block)
    unless from.id == to.id
      invite_friend(from, to)
      accept_friend(from, to)
      yield(from, to) if block_given?
    end
  end

  def self.invite_friend(from, to)
    retries = 0
    begin
      res = post("/#{from.id}/friends/#{to.id}", :query => {:access_token => from.access_token})
    rescue MultiJson::DecodeError => e
      Rails.logger.warn "Facebook test user destroy response is not json, msg => #{e.message}"
      unless retries > 2
        retries = retries + 1
        retry
      end
    end
    unless res.parsed_response == true
      msg = res['error']['message']
      unless msg =~ /\(\#522\)/ || msg =~ /\(\#520\)/
        raise "Failed inviting from #{from.id} to #{to.id}: #{msg}"
      end
    end
  end

  def self.accept_friend(from, to)
    res = post("/#{to.id}/friends/#{from.id}", :query => {:access_token => to.access_token})
    unless res.parsed_response == true
      msg = res['error']['message']
      unless msg =~ /\(\#522\)/
        raise "Failed accepting from #{from.id} to #{to.id}: #{msg}"
      end
    end
  end

  def self.befriend_other_test_users(uid, &block)
    users = list_test_users
    from = users.find {|u| u.id == uid}
    users.each {|to| befriend(from, to, &block)}
  end

  def self.befriend_all_test_users(&block)
    users = list_test_users
    users.each {|from| users.each {|to| befriend(from, to, &block)}}
  end

  def self.delete_test_user(u, &block)
    begin
      u.destroy
    rescue MultiJson::DecodeError => e
      Rails.logger.warn "Facebook test user destroy response is not json, msg => #{e.message}"
    end
    yield(u) if block_given?
  end

  def self.delete_all_test_users(&block)
    list_test_users.each {|u| delete_test_user(u, &block)}
  end
end
