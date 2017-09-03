class SearchTabSubject < ActiveRecord::Base

  has_many  :children, :dependent => :delete_all, :class_name => "SearchTabSubject", :foreign_key => :parent_id
	belongs_to :search_tab, :foreign_key => :tab_id
	belongs_to :collection_group

  include ApplicationHelper
  def	getElemWhereParentId(value)
    ret = Array.new();
    
    @dataBaseRecord.each do |oLine|
      if (oLine.parent_id == value)
        ret << oLine;
      end
    end
    return ret;
  end
  
  def haveSon?(value)
    @dataBaseRecord.each do |oLine|
      if (oLine.parent_id == value)
        return true;
      end
    end
    return false;
  end
  
  def setSon(parentSQL, treeFather)
    son = getElemWhereParentId(parentSQL.id);
    if (son != nil)
      son.each do |aLine|
        child = treeFather << aLine;	
        setSon(aLine, child);
      end
    end
  end
  
  def CreateSubMenuTree(tab_id=nil)
    @dataBaseRecord = SearchTabSubject.find(:all, :conditions => "hide='0'", :order => 'rank, parent_id');
    parentTab = getElemWhereParentId(0);
    tree = Tree.new('ROOT');
    if (parentTab != nil)
      parentTab.each do |aLine| 
        next if ((!tab_id.nil?) && (tab_id.to_i != aLine.tab_id.to_i))
        child = tree << aLine;
        setSon(aLine, child);
      end
    end
    return tree;
  end
  
  def CreateSubMenuTreeAdmin
    @dataBaseRecord = SearchTabSubject.find(:all, :order => 'rank, parent_id');
    parentTab = getElemWhereParentId(0);
    tree = Tree.new('ROOT');
    if (parentTab != nil)
      parentTab.each do |aLine|
        child = tree << aLine;
        setSon(aLine, child);
      end
    end
    return tree;
  end
  
  def validate
    if !parent_id.to_i.zero?
      _parent = SearchTabSubject.find_by_id(parent_id)
      errors.add("PARENT_LABEL", "INVALID_PARENT") if _parent.tab_id.to_i != tab_id.to_i
    end
  end
end
