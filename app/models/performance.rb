# Performance define the Role some Actor is playing in some Stage
#
# == Named scopes
#
# stage_type(type): find Peformances by Stage type
class Performance < ActiveRecord::Base
  belongs_to :agent, :polymorphic => true
  belongs_to :stage, :polymorphic => true
  belongs_to :role

  acts_as_sortable :columns => [ { :content => :agent,
                                   :sortable => false },
                                 { :name => :role,
                                   :render => 'edit_role_form',
                                   :sortable => true }
                               ]

  named_scope :stage_type, lambda { |type|
    type ?
      { :conditions => [ "stage_type = ?", type.to_s.classify ] } :
      {}
  }

  validates_presence_of :agent_id, :agent_type, :stage_id, :stage_type, :role_id
  validates_uniqueness_of :agent_id, :scope => [ :agent_type, :stage_id, :stage_type ]
  validates_uniqueness_of :agent_type, :scope => [ :agent_id, :stage_id, :stage_type ]

  def affordances
    role.actions.inject([]) do |affordances, action|
      affordances << ActiveRecord::Authorization::Affordance.new(agent, action)
    end
  end
end
