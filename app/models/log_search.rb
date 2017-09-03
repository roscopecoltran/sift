class LogSearch < ActiveRecord::Base
  include ApplicationHelper
  belongs_to :history_search, :foreign_key => :search_history_id
  belongs_to :search_tab_subject, :foreign_key => :search_tab_subject_id
  
  # unit = day/month/year
  # date = dd-mm-yyyy
  def self.total_request(unit = "day", date_from_str = nil, date_to_str = nil, tab = nil, order = "time",  page = 1, max = 50,  profil = nil, material_type = nil, profil_poste=nil)
    
    select_clause = "count(h.tab_filter) total, s.label as search_type_label"
    from_clause = " , (SELECT DISTINCT label, field_filter, search_tab_id FROM search_tab_filters) s"
    where_clause = " and h.search_type = s.field_filter and s.search_tab_id = (select id from search_tabs where label = h.tab_filter)"
    group_by_clause = ""
    
		return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end
  
  def self.couple_request(unit = "day", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil)
    
    select_clause = "h.tab_filter, h.search_group, s.label as search_type_label, count(h.search_group) total"
    from_clause = " , (SELECT DISTINCT label, field_filter, search_tab_id FROM search_tab_filters) s "
    group_by_clause = "h.search_group, s.label"
    where_clause = " and s.field_filter =  h.search_type and s.search_tab_id = (select id from search_tabs where label = h.tab_filter)"
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end
  
  def self.list_most_search_popular(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil= nil, material_type = nil, profil_poste=nil)
    
    select_clause = "h.*, s.label as search_type_label, count(l.search_history_id) total"
    from_clause = " , (SELECT DISTINCT label, field_filter, search_tab_id FROM search_tab_filters) s "
    group_by_clause = "l.search_history_id"
    where_clause = "and h.search_tab_subject_id = -1 and s.field_filter = h.search_type and s.search_tab_id = (select id from search_tabs where label = h.tab_filter)"
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end

  def self.list_infructueuses(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil , profil_poste=nil)
    select_clause = "h.*,h.hits, count(h.tab_filter) total, s.label as search_type_label"
    from_clause = " , (SELECT DISTINCT label, field_filter, search_tab_id FROM search_tab_filters) s"
    group_by_clause = "h.search_input"
    where_clause = "and h.hits = '0' and h.search_type = s.field_filter and s.field_filter = h.search_type and s.search_tab_id = (select id from search_tabs     where label = h.tab_filter)"  
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end

  def self.search_theme(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
    
    select_clause = "h.search_tab_subject_id, count(l.search_history_id) total"
    from_clause = ""
    group_by_clause = "l.search_history_id"
    where_clause = "and h.search_tab_subject_id != -1 "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end
  
  def self.see_also(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    group_by_clause = "h.tab_filter"
    where_clause = "and l.log_action = 'seealso' "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end
  
  def self.rebonce(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    group_by_clause = "h.tab_filter"
    where_clause = "and l.log_action = 'rebond'"
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste )
  end
  
  def self.getLogSearchByParams(items)
    rec = LogSearch.find(:first, :conditions => " context ='#{items[:context]}' and search_history_id ='#{items[:search_history_id]}' and host ='#{items[:host]}'")
    if (!rec.nil?)
      return rec
    else
      return nil
    end
  end
  
  def self.updateLogSearchByParams(id)
    ret = LogSearch.update(id, :hits => '0')
    if (!ret.nil?)
      return ret
    else
      return nil
    end
  end
  
  def self.spell(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
    
    select_clause = "h.tab_filter, count(h.tab_filter) total"
    from_clause = ""
    group_by_clause = ""
    where_clause = "and l.log_action = 'spell' "
    
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end

  def self.fructueuses(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
      
      select_clause = "h.tab_filter, count(h.tab_filter) total "
      from_clause = ""
      group_by_clause = ""
      where_clause = "and h.hits = 0"
      
      return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, tab, order, page, max, profil, profil_poste)
  end
  
  def self.Affiche(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
    
  end
  
  def self.Activer(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
    ActiveRecord::Base.transaction do
      stat = SiteConfig.find(:first, :conditions => ["field = 'stat_Doc'"] )
      begin
        if (!stat.blank?)
          ActiveRecord::Base.connection.execute("UPDATE site_configs SET value= '1', updated_at='#{DateTime.now}' WHERE field = 'stat_doc' ")
        else
          ActiveRecord::Base.connection.execute("INSERT INTO site_configs(field, value,updated_at) VALUES ('stat_doc','1','#{DateTime.now}')")
        end 
      rescue ActiveRecord::Rollback => e
        logger.error("Transaction has been rolled back => #{e.message}")
      rescue Exception => e
        logger.error("Error committing documents in MySql => #{e.message}")
      raise e
      end
    end
    return 
  end
  
  def self.Desactiver(unit = "", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, material_type = nil, profil_poste=nil )
      ActiveRecord::Base.transaction do
        begin
          ActiveRecord::Base.connection.execute("UPDATE site_configs set value='0', updated_at='#{DateTime.now}' WHERE field = 'stat_doc' ")
        rescue ActiveRecord::Rollback => e
          logger.error("Transaction has been rolled back => #{e.message}")
        rescue Exception => e
          logger.error("Error committing documents in MySql => #{e.message}")
          raise e
        end
      end
      return 
    end
   
  private
  def self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit = "day", date_from_str = nil, date_to_str = nil, tab = nil, order = "time", page = 1, max = 50, profil = nil, profil_poste=nil)
    # CLAUSE SELECT
    requete = "select SQL_CALC_FOUND_ROWS #{select_clause}"
    
    # Gestion de la recherche sur profil
    if(!select_clause.blank?)
      requete += ","
    end
    if(!profil.blank?)
      requete += "profil"
    else
      requete += " 'Tous' as profil"
    end
    
    if(!select_clause.blank? or !profil.blank?)
      requete += ","
    end
    if(!tab.blank?)
      requete += "h.tab_filter"
    else
      requete += " 'Tous' as tab_filter"
    end
    
    case unit
      when "month"
      requete += ", month(created_at) month, year(created_at) year "
      when "year"
      requete += ", year(created_at) year "
      when "day"
      requete += ", day(created_at) day, month(created_at) month, year(created_at) year "
    end
    
    requete += " from history_searches h, log_searches l "
    
    if (!from_clause.blank?)
      requete += " #{from_clause} "
    end
    
    # CLAUSE CONDITION
    requete += " where h.id = l.search_history_id "
    
    date_from = UtilFormat.get_date(date_from_str)
    if (!date_from.nil?)
      requete += " and l.created_at > '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      requete += " and l.created_at < '#{date_to}' "
    end
    

    if (!profil.blank?)
      requete += " and profil = '#{profil}' "
    end
    if (!tab.blank?)
      requete += " and tab_filter = '#{tab}' "
    end
    if (!profil_poste.blank?)
      p_poste = ProfilPostes.loadProfil(profil_poste)
     if (p_poste["Type"].to_i==1)
       requete += " and l.profil_poste = '#{p_poste["Value"]["profil"]}' "
      else 
        requete += " and INET_ATON(l.host) >= INET_ATON('#{p_poste["Value"]["ipStart"]}') and INET_ATON(l.host) <= INET_ATON('#{p_poste["Value"]["ipEnd"]}') "
      end
    end
    if (!where_clause.blank?)
      requete += " #{where_clause}"
    end
    
    # CLAUSE GROUP BY
    if (!group_by_clause.blank? or (unit == "month" or unit=="year" or unit=="day"))
      requete += " group by #{group_by_clause}"
      
      # Si on filtre sur aucun profil, il ne faut pas grouper par profil
      if (!profil.blank?)
          if (!group_by_clause.blank?)
            requete += ","
          end
          requete += " profil "
      end
      if ((!profil.blank? or !group_by_clause.blank?) and (unit == "month" or unit=="year" or unit=="day"))
        requete += ","
      end
    end
    
    case unit
      when "month"
      requete += " month, year"
      when "year"
      requete += " year"
      when "day"
      requete += " day, month, year"
    end
    
    # CLAUSE ORDER
    requete += " order by "
    
    if (order == "time")
      case unit
        when "month"
        requete += "year desc, month desc"
        when "year"
        requete += "year desc"
        when "day"
        requete += "year desc, month desc, day desc"
      else
        requete += "total DESC"
      end
    else
      requete += "total DESC"
    end
    
    # PAGINATE
    if page > 0:
      offset = (page.to_i-1) * max.to_i
      requete += " limit #{offset}, #{max}"
    end
    
    res = LogSearch.find_by_sql(requete)
		
    total = 0
    count = LogSearch.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    
    return {:result => tab, :count => total, :page => page, :max => max}
  end
  
end
