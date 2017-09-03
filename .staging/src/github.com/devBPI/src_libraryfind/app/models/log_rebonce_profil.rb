class LogRebonceProfil < ActiveRecord::Base
  
  def self.rebonce(unit = "day",  date_from_str = nil, date_to_str = nil, tab = nil, order = "time",  page = 1, max = 50,  profil = nil, material_type = nil, profil_poste=nil)
    select_clause = "c.name, c.uuid, count(l.uuid_md5) total"
    from_clause = ", community_users c" 
    where_clause = "c.MD5 = l.uuid_md5"  
    group_by_clause = ""
    return self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit, date_from_str, date_to_str, profil, order, page, max, profil_poste)
  end
  
  private
  def self.generic_request(select_clause, from_clause, where_clause, group_by_clause, unit = "day", date_from_str = nil, date_to_str = nil, profil = nil, order = "time", page = 1, max = 50, profil_poste=nil)
    # CLAUSE SELECT
    requete = "select SQL_CALC_FOUND_ROWS #{select_clause}"
    
    case unit
      when "month"
      requete += ", month(l.created_at) month, year(l.created_at) year "
      when "year"
      requete += ", year(l.created_at) year "
      when "day"
      requete += ", day(l.created_at) day, month(l.created_at) month, year(l.created_at) year "
    end
    
    requete += " from log_rebonce_profils l "
    
    if (!from_clause.blank?)
      requete += " #{from_clause} "
    end
    
    # CLAUSE CONDITION
    requete += " where #{where_clause}"
    
    date_from = UtilFormat.get_date(date_from_str)
    if (!date_from.nil?)
      requete += " and l.created_at > '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      requete += " and l.created_at < '#{date_to}' "
    end
    if (!profil_poste.blank?)
          p_poste = ProfilPostes.loadProfil(profil_poste)
         if (p_poste["Type"].to_i==1)
           requete += " and l.profil_poste = '#{p_poste["Value"]["profil"]}' "
          else 
            requete += " and INET_ATON(l.host) >= INET_ATON('#{p_poste["Value"]["ipStart"]}') and INET_ATON(l.host) <= INET_ATON('#{p_poste["Value"]["ipEnd"]}') "
          end
        end   
    if (!profil.blank?)
      requete += " and profil = '#{profil}' "
    end
    
    # CLAUSE GROUP BY
    if (!group_by_clause.blank? or (unit == "month" or unit=="year" or unit=="day"))
      requete += " group by #{group_by_clause}"
      if (!group_by_clause.blank? and (unit == "month" or unit=="year" or unit=="day"))
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
    
    res = LogRebonceProfil.find_by_sql(requete)
    
    total = 0
    count = LogRebonceProfil.find_by_sql("SELECT FOUND_ROWS() as total")
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
