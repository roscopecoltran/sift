  class HistorySearch < ActiveRecord::Base
    
    has_many :users_history_search, :foreign_key => :id_history_search, :dependent => :destroy
    
    def self.parseSearchWord(txt)
      if !txt.blank?
        return txt.gsub("'","''")
      end
      return ""
    end
    
    # Try to find a HistorySearch by attributes
    # Attribute filter will be set to ALL if empty
    # Attributes search_input, search_group and search_type are mandatory
    # All others attributes are optionals but group of (operator, input, type) are required if attributes want to be set
    def self.getHistorySearchByConditionalParams(tab_filter, search_input, search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, search_tab_subject_id)
      logger.debug("[HistorySearch][getSearch] Checking search : tab_filter = #{tab_filter} search_input = #{search_input} and search_group = #{search_group} and search_type = #{search_type} and search_operator1 = #{search_operator1} and search_input2 = #{search_input2} and search_type2 = #{search_type2} and search_operator2 = #{search_operator2} and search_input3 = #{search_input3} and search_type3 = #{search_type3} and tab_filter = #{tab_filter}")
      if(!tab_filter.nil?)
        conditions = "tab_filter = '#{tab_filter}' "
      else
        conditions = "tab_filter = 'ALL' "
      end
      
      conditions += " and search_input = '#{self.parseSearchWord(search_input)}' and search_group = '#{search_group}' and search_type = '#{search_type}' "
      
      if(!search_input2.nil?)
        conditions += " and search_operator1 = '#{search_operator1}' and search_input2 = '#{self.parseSearchWord(search_input2)}' and search_type2 = '#{search_type2}' "
      end
      
      if(!search_input3.nil?)
        conditions += " and search_operator2 = '#{search_operator2}' and search_input3 = '#{self.parseSearchWord(search_input3)}' and search_type3 = '#{search_type3}' "
      end
      
      if(!search_tab_subject_id.nil?)
       conditions += " and search_tab_subject_id = #{search_tab_subject_id}"
      end
      return HistorySearch.find(:first, :conditions => conditions)
    end
    
    def self.saveHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, search_tab_subject_id, hits, alpha)
      rh = HistorySearch.new()
      rh.tab_filter = tab_filter
      #rh.search_input = self.parseSearchWord(search_input)
			rh.search_input = search_input
      rh.search_group = search_group
      rh.search_type = search_type
      rh.search_operator1 = search_operator1
      #rh.search_input2 = self.parseSearchWord(search_input2)
			rh.search_input2 = search_input2
      rh.search_type2 = search_type2
      rh.search_operator2 = search_operator2
      #rh.search_input3 = self.parseSearchWord(search_input3)
			rh.search_input3 = search_input3
      rh.search_type3 = search_type3
      rh.search_tab_subject_id = search_tab_subject_id
      rh.hits = hits
      rh.job_ids = alpha
      rh.save
      return rh
    end
    
    def self.getHistoryIdByjobsId(job_ids)
       rec = HistorySearch.find(:first, :conditions => " job_ids ='#{job_ids}'")
       if (!rec.nil?)
         return rec.id
       else 
         return nil
       end
    end

    def self.deleteHistorySearch(history_search_ids)
      ids = history_search_ids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      HistorySearch.destroy_all(" id IN #{ids}" )
    end
    
    def self.getHistorySearch(id_history_search)
      return HistorySearch.find(:first, :conditions => " id='#{id_history_search}' ")
    end
    
    def self.findHistorySearch(tab_filter, search_input,search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, search_tab_subject_id, alpha)
      if (alpha)

        return HistorySearch.find(:first, :conditions => " tab_filter = '#{tab_filter}' and search_input = '#{self.parseSearchWord(search_input)}' and search_group = '#{search_group}' and search_type = '#{search_type}' and search_operator1 = '#{search_operator1}' and search_input2 = '#{self.parseSearchWord(search_input2)}' and search_type2  = '#{search_type2}' and search_operator2 = '#{search_operator2}' and search_input3  = '#{self.parseSearchWord(search_input3)}' and search_type3 = '#{search_type3}' and search_tab_subject_id = '#{search_tab_subject_id}' and job_ids = '#{alpha}'")

      else
        return HistorySearch.find(:first, :conditions => " tab_filter = '#{tab_filter}' and search_input = '#{self.parseSearchWord(search_input)}' and search_group = '#{search_group}' and search_type = '#{search_type}' and search_operator1 = '#{search_operator1}' and search_input2 = '#{self.parseSearchWord(search_input2)}' and search_type2  = '#{search_type2}' and search_operator2 = '#{search_operator2}' and search_input3  = '#{self.parseSearchWord(search_input3)}' and search_type3 = '#{search_type3}' and search_tab_subject_id = '#{search_tab_subject_id}'")

      end
    end
    
    def self.getUserSearchesHistory(uuid, page = 1)

			limit = page * 10

      query = "SELECT uhs.id, uhs.save_date, uhs.results_count, uhs.id_history_search, "
      query += "hs.search_input, hs.search_group, hs.search_type, hs.tab_filter, hs.search_operator1, "
      query += "hs.search_input2, hs.search_type2, hs.search_operator2, hs.search_input3, hs.search_type3, hs.search_tab_subject_id, hs.hits, "
      query += "cg.full_name as collection_group_name FROM users_history_searches uhs, history_searches hs, collection_groups cg "
      query += "WHERE hs.id = uhs.id_history_search "
      query += "and cg.id = SUBSTR(hs.search_group,2) "
      query += "and uhs.uuid = '#{uuid}' "
      query += "group by uhs.id "
			query += "order by uhs.save_date DESC "
			query += "LIMIT 0, #{limit}"

      return HistorySearch.find_by_sql(query)
    end
    
  end
