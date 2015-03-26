# = ActiveForm - non persistent ActiveRecord
#
# Simple base class to make AR objects without a corresponding database
# table.  These objects can still use AR validations but can't be saved
# to the database.
#
# == Example
#
#   class FeedbackForm < ActiveForm
#     column :email
#     column :message, :type => :text
#     validates_presence_of :email, :message
#   end
#
class ActiveForm < ActiveRecord::Base
  def self.columns # :nodoc:
    @columns ||= self == ActiveForm ? [] : superclass.columns.dup
  end

  # Define an attribute.  It takes the following options:
  # [+:type+] schema type
  # [+:default+] default value
  # [+:null+] whether it is nullable
  # [+:human_name+] human readable name
  def self.column(name, options = {})
    name = name.to_s
    options.each { |k,v| options[k] = v.to_s if Symbol === v }
    
    if human_name = options.delete(:human_name)
      name.instance_variable_set('@human_name', human_name)
      def name.humanize; @human_name; end
    end
    
    columns << ActiveRecord::ConnectionAdapters::Column.new(
      name,
      options.delete(:default),
      options.delete(:type),
      options.include?(:null) ? options.delete(:null) : true
    )
    
    raise ArgumentError.new("unknown option(s) #{options.inspect}") unless options.empty?
  end

  def self.abstract_class # :nodoc:
    true
  end
  
  def save # :nodoc:
    if result = valid?
      run_callbacks(:save)
      run_callbacks(:create)
    end
    
    result
  end
  
  def save! # :nodoc:
    save or raise ActiveRecord::RecordInvalid.new(self)
  end
end

# Return a form class with give columns.  The given +columns+ are
# either symbols or a single key qvalue map where the key is the
# column name and the value is a options map to be passed to the
# +ActiveForm.column+ method.
def ActiveForm(*columns)
  Class.new(ActiveForm).tap do |f|
    columns.each do |c|
      name, options = Hash === c ? [c.keys.first, c.values.first] : [c, {}]
      f.column name, options
    end
  end
end
