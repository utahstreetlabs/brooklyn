require 'ladon'

class SendModelMail < Ladon::Job
  @queue = :email

  class RetryableFailure < Exception; end
  acts_as_retryable_job exceptions: [RetryableFailure]

  def self.find_mailer_class(model_class)
    begin
      "#{model_class}Mailer".constantize
    rescue NameError => e
      if !model_class.superclass
        raise e
      else
        find_mailer_class(model_class.superclass)
      end
    end
  end

  def self.work(model_type, message, model_id, *args)
    model_class = model_type.constantize
    mailer_class = find_mailer_class(model_class)
    model_instance = model_class.where(id: model_id).first
    if model_instance
      mailer_class.send(message, *[model_instance, *args]).deliver
    else
      Rails.logger.warn("Unable to send email for #{model_type} #{model_id} which does not exist")
    end
  end
end
