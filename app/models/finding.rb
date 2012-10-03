class Finding
  #has_many     :task_runs
  #after_save   :log

  include Mongoid::Document
  include ModelHelper

  field :name, type: String
  field :status, type: String
  field :confidence, type: Integer  
  field :content, type: String
  field :created_at, type: Time
  field :updated_at, type: Time

  def to_s
    "#{self.class}"
  end

private
  def log
    TapirLogger.instance.log self.to_s
  end
end
