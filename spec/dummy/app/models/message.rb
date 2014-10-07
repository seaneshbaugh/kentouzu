class Message < ActiveRecord::Base
  has_drafts :if => Proc.new { |b| self.first_name == 'Draft' }
end
