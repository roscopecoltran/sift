# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

class Dispatch  < DispatchAbstract
  
  def driver
    # logger.debug("LibraryFind: " + ::LIBRARYFIND_WSDL.to_s)
    
    case LIBRARYFIND_WSDL
      when LIBRARYFIND_WSDL_ENGINE
      require 'soap/wsdlDriver'
      driver = SOAP::WSDLDriverFactory.new(LIBRARYFIND_WSDL_HOST).create_rpc_driver
      return driver
    else
      m = MetaSearch.new()
      m.setInfosUser(@info_users)
      return m
    end
  end

  def driverUpdate(search_history_id, hits, context)
    case LIBRARYFIND_WSDL
      when LIBRARYFIND_WSDL_ENGINE
      require 'soap/wsdlDriver'
      driver = SOAP::WSDLDriverFactory.new(LIBRARYFIND_WSDL_HOST).create_rpc_driver
      return driver
    else
      l = LogManagement.instance
      l.setInfosUser(@info_users)
    end
    return l
  end

  def AddLogConsultSolr(logs, ids)
    objdriver = driver
    objdriver.send :addLogConsultSolr, logs, ids
  end

  def addLogSearchUpdate(search_history_id, hits, context)
    objdriver = driverUpdate(search_history_id, hits, context)
    objdriver.send :addLogSearchUpdate, search_history_id, hits, context
  end  
  
#  def SimpleSearch(ssets, qtype, sarg, sstart, smax) 
#    objdriver = driver;
#    objdriver.send :SimpleSearch, ssets, qtype, sarg, sstart, smax
#  end 
#  
#  def SimpleSearchAsync(ssets, qtype, sarg, sstart, smax)
#    objdriver = driver;
#    objdriver.send :SimpleSearchAsync, ssets, qtype, sarg, sstart, smax
#  end
  
  def SearchSync(_sets, _qtype, _arg, _qoperator, options = nil, _session_id=nil, _action_type=1, _data=nil, obj_bool=true, memcache = nil)
    objdriver = driver
    case objdriver.class.to_s
      when "SOAP::RPC::Driver"
      if _session_id == nil
        objdriver.send :SearchSync, _sets, _qtype, _arg, _qoperator, options
      else
        objdriver.send :SearchSync, _sets, _qtype, _arg, _qoperator, options, _session_id, _action_type, _data, obj_bool
      end
    else
      objdriver.send :SearchSync, _sets, _qtype, _arg,  _qoperator, options, _session_id, _action_type, _data, obj_bool, memcache
    end
  end
  
  def SolrSearch(_sets, _qtype, _arg, _start, _max, _qoperator, _filter, options = nil, _session_id=nil, _action_type=1, _data=nil, obj_bool=true)
    objdriver = driver
    case objdriver.class.to_s
      when "SOAP::RPC::Driver"
      if _session_id == nil
        objdriver.send :SolrSearch, _sets, _qtype, _arg, _start, _max, _qoperator, _filter, options
      else
        objdriver.send :SolrSearch, _sets, _qtype, _arg, _start, _max, _qoperator, _filter, options, _session_id, _action_type, _data, obj_bool
      end
    else
      objdriver.send :SolrSearch, _sets, _qtype, _arg, _start, _max, _qoperator, _filter, options, _session_id, _action_type, _data, obj_bool
    end
  end
    
  def ListCollections()
    objdriver = driver
    objdriver.send :ListCollections
  end

  def ListGroupsSyn(id_CG=nil, tab_name = "")
    objdriver = driver
    objdriver.send :ListGroupsSyn, id_CG, tab_name
  end
  
  def ListGroups(bool_advanced=false)
    objdriver = driver
    objdriver.send :ListGroups, bool_advanced
  end  
  
  def ListAlpha(tab_id)
      objdriver = driver
      objdriver.send :ListAlpha, tab_id
  end  
    
  def GetGroupMembers(name)
    objdriver = driver
    objdriver.send :GetGroupMembers, name
  end
  
  def GetId(sid, logs = {}) 
    objdriver = driver
    objdriver.send :GetId, sid, logs
  end 
  
  def getCollectionAuthenticationInfo(collection_id)
    objdriver = driver
    objdriver.send :getCollectionAuthenticationInfo, collection_id
  end
    
  def CheckJobStatus(sids)
    objdriver = driver
    objdriver.send :CheckJobStatus, sids
  end
  
  def CheckJobsStatus(sids)
    objdriver = driver
    objdriver.send :CheckJobStatus, sids
  end
  
  def GetJobRecord(jid, _max)
    objdriver = driver
    objdriver.send :GetJobRecord, jid, _max
  end
  
  def GetJobsRecords(jids)
    objdriver = driver
    objdriver.send :GetJobsRecords, jids
  end
  
  def KillThread(jobid, threadid)
    objdriver = driver
    objdriver.send :KillThread, jobid, threadid
  end
  
  def GetTabs()
    objdriver = driver
    objdriver.send :GetTabs
  end
  
  def GetFilter()
    objdriver = driver
    objdriver.send :GetFilter
  end
  
  def topTenMostViewed()
    objdriver = driver
    objdriver.send :topTenMostViewed
  end
  
  def getTheme(theme)
    objdriver = driver
    objdriver.send :getTheme, theme
  end
  
  def autoComplete(word, field)
    objdriver = driver;
    objdriver.send :autoComplete, word, field;
  end
  
  def spellCheck(query)
    objdriver = driver;
    objdriver.send :spellCheck, query;
  end
  
  def GetTotalHitsByJobs(params)
    objdriver = driver;
    objdriver.send :GetTotalHitsByJobs, params;
  end
  
  def SeeAlso(params)
    objdriver = driver;
    objdriver.send :SeeAlso, params;
  end
  
  def GetMoreInfoForISBN(isbn, with_image=true)
    objdriver = driver;
    objdriver.send :GetMoreInfoForISBN, isbn, with_image;
  end
  
  def GetEditorials(id)
    objdriver = driver;
    objdriver.send :GetEditorials, id
  end
  
  def GetPrimaryDocumentTypes
    objdriver = driver
    objdriver.send :GetPrimaryDocumentTypes
  end
  
  
end
