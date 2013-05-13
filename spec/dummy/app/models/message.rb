class Message < ActiveRecord::Base
  attr_accessible :first_name, :last_name, :subject, :body

  has_drafts :if => Proc.new { |b| self.first_name == 'Draft' }
end
