Product.instance_eval do 

  delegate_belongs_to :master, :subscribable if Variant.table_exists? && Variant.column_names.include?("subscribable")
  
end

Product.class_eval do  

  def subscribable?
    master.subscribable?
  end
  
end

