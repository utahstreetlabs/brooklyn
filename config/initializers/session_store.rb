# Be sure to restart your server when you modify this file.

Brooklyn::Application.config.session_store :cookie_store, key: '_brooklyn_session', expire_after: Time.zone.local(2038)
                                                                                    # the end of 32 bit int time
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Brooklyn::Application.config.session_store :active_record_store
