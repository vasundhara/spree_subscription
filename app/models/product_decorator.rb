Spree::Product.instance_eval do 

  delegate_belongs_to :master, :subscribable if Spree::Variant.table_exists? && Spree::Variant.column_names.include?("subscribable")
  
end

Spree::Product.class_eval do  

  def subscribable?
    master.subscribable?
  end
  
end

