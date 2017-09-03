# -*- coding: utf-8 -*- 
# LibraryFind - Quality find done better.

# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
require 'ipaddr'
class Admin::LogViewGenericController < ApplicationController
  include ApplicationHelper
  include Admin::LogViewGenericHelper
  
  layout 'admin'
  before_filter :authorize, :except => 'login',
  :role => 'administrator', 
  :msg => 'Access to this page is restricted.'
  
  SEPARATOR = ","
  ENDLINE = "\n"
  
  def initialize
    super
    @search_tabs = SearchTab.find(:all)
		more_search_tab = SearchTab.new
		more_search_tab.id = -1
		more_search_tab.label = "plusderesultats"
		more_search_tab.description = "Recherches synchrones"
		@search_tabs.push(more_search_tab)
    @profiles = ManageRole.find(:all)
    @plages_ip = ProfilPostes.findAll()
  end
  
  def index
    stat = SiteConfig.find(:first, :conditions => ["field = 'stat_Doc'"] )
    if (!stat.blank?)
      @status = stat.value
    end 
  end
  
  def requests
    case params[:mode]
      when "c"
      @group_collections = CollectionGroup.find(:all)
      @title = "Nombre de requêtes sur chaque couple d'index"
      method = "couple_request"
      @headers = ["profil", "tab_filter","search_group", "search_type_label", "date", "total"]
      when "t"
      @group_collections = CollectionGroup.find(:all)
      @title = "Liste des requêtes les plus fréquentes"
      method = "list_most_search_popular"
      @headers = ["profil","search_input", "search_type_label", "search_group", "tab_filter", "date","total"]
      when "lif"
      @group_collections = CollectionGroup.find(:all)
      @title = "Liste des requêtes infructueuses"
      method = "list_infructueuses"
      @headers = ["profil", "search_input", "search_input2", "search_input3", "search_type_label", "search_group", "tab_filter", "date", "total"]
      when "n"
      @search_tabs_subjects = SearchTabSubject.find(:all)
      @title = "Nombre de clics sur chacun des liens lançant une requête préprogrammée"
      method = "search_theme"
      @headers = ["profil","search_tab_subject_id","date","total"]
      when "s"  
      @title = "Nombre de clics sur le lien \"Voir Aussi\""
      method = "see_also"
      @headers = ["profil","tab_filter","date","total"]
      when "r"
      @title = "Nombre de requêtes via des rebonds"
      method = "rebonce"
      @headers = ["profil","tab_filter","date","total"]
      when "sp"
      @title = "Nombre de requêtes via le correcteur orthographique"
      method = "spell"
      @headers = ["profil","tab_filter","date","total"]
      when "frq"
      @title = "Nombre de requêtes infructueuses"
      method = "fructueuses"
      @headers = ["profil","tab_filter","date","total"]
    else
      @title = "Nombre total de requêtes"
      params[:mode] = "all"
      method = "total_request"
      @headers = ["profil","tab_filter","date","total"]
    end    
    classe = "LogSearch"
    generic(classe, method, true)
  end
  def show
      _content=""
      # Test if GET db exists
      if not params[:id].blank?
        _id = params[:id];
        if (!_id.blank?)
          fichier = File.open("/srv/stats/#{_id}.csv", "r")
          fichier.each_line { |ligne|
            _content += "#{ligne}"            
            _content += "\n"
          }
          fichier.close
          if (!_content.nil?)
            _filename = _id
            _filename += ".csv"
            send_data(_content, :type => 'text/csv', :filename => _filename , :disposition => 'attachment');
          end 
        end
      end
  end
  
  def docstat
    
    @fils=[]
      Dir.foreach("/srv/stats") do |entry|
      f = entry.split('log_statistic')
      if (entry != '.') && (entry != '..') && ( !f[0].blank?)
        @fils << entry 
      end
    end
    @status = params[:status].to_i
    if (@status == 0)
      @title = "Les statistiques sur les documents sont desactivées"
    else
      @title = "Les statistiques sur les documents sont activées"
    end
    case params[:mode]
      when "Affiche"
      method = "Affiche"
      when "docActive"
      method = "Activer"
      when "docDesactive"
      method = "Desactiver"
    end 
    classe = "LogSearch"
    generic(classe, method, true)
  end
  
  def carts
    case params[:mode]
      when "s"
      @group_collections = CollectionGroup.find(:all)
      @title = "Nombre de notices sauvegardées dans les paniers"
      method = "doc_save_in_cart"
      @headers = ["profil","date","total"]
    else    
      params[:mode] = "f"
      @title = "Nombre de paniers utilisés"
      @headers = ["profil","date","total"]
      method = "cart_use"
    end
    
    classe = "LogCartUsage"
    generic(classe, method, true)
  end
  
  def consult
    @types = nil
    case params[:mode]
      when "p"
      @title = "Nombre de notices imprimées"
      @headers = ["profil","date","total"]
      method = "print_notice"
      when "e"
      @title = "Nombre de notices envoyées par email"
      @headers = ["profil","date","total"]
      method = "email_notice"
      when "pdf"
      @title = "Nombre de notices générées en pdf"
      @headers = ["profil","date","total"]
      method = "pdf_notice"
      when "cc"
      @title = "Nombre de notices consultées par collection"
      @headers = ["collection_name","date","total"]
      method = "consult_notice_by_collection"
      when "top"
      @types = LogConsult.get_material_type()
      @title = "Notices les plus consultées"
      @headers = ["idDoc", "collection_id", "alt_name", "title", "material_type", "date", "total", ]
      method = "topConsulted"
      when "export"
      @title = "Nombre de notices exportées"
      @headers =  ["context", "date","total"]
      method = "export_notice"
      when "rss"
      @title = "Nombre de RSS"
      @headers =  ["host","date","total"]
      method = "consult_rss"
    else
      params[:mode] = "c"
      @title = "Nombre de notices consultées"
      @headers = ["profil","date","total"]
      method = "consult_notice"
    end
    
    classe = "LogConsult"
    generic(classe, method, true)
  end
  
  def document
    
    params[:mode] = "d"
    @title = "Nombre de documents consultés"
    @headers = ["collection_name", "indoor", "date","total"]
    method = "consult_ressource"
    
    classe = "LogConsultRessource"
    generic(classe, method, true)
  end
  
  def save_notice
    case params[:mode]
      when "l"
      @title = "Nombre de notices sauvegardées dans des listes"
      @headers = ["profil", "date","total"]
      method = "notice_save_in_list"
      when "m"
      @title = "Nombre de notices sauvegardées dans Mes documents"
      @headers = ["profil", "date","total"]
      method = "notice_save_mydoc"
    else
      params[:mode] = "s"
      @title = "Nombre de notices sauvegardées"
      @headers = ["profil", "date","total"]
      method = "notice_save_total"
    end
    
    classe = "LogSaveNotice"
    generic(classe, method, true)
  end
  
  def tag
    case params[:mode]
      when "dt"
      @title = "Nombre de mots clés supprimés"
      @headers = ["date","total"]
      method = "tag_delete"
      when "cn"
      @title = "Nombre de mots clés créés sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "tag_create_by_notice"
      when "dn"
      @title = "Nombre de mots clés supprimés sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "tag_delete_by_notice"
      when "cl"
      @title = "Nombre de mots clés créés sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "tag_create_by_liste"
      when "dl"
      @title = "Nombre de mots clés supprimés sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "tag_delete_by_liste"
    else
      params[:mode] = "ct"
      @title = "Nombre de mots clés créés"
      @headers = ["date","total"]
      method = "tag_create"
    end
    
    classe = "LogTag"
    generic(classe, method, true)
  end
  
  def comment
    case params[:mode]
      when "dt"
      @title = "Nombre de commentaires supprimés"
      @headers = ["date","total"]
      method = "comment_delete"
      when "cn"
      @title = "Nombre de commentaires créés sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "comment_create_by_notice"
      when "dn"
      @title = "Nombre de commentaires supprimés sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "comment_delete_by_notice"
      when "cl"
      @title = "Nombre de commentaires créés sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "comment_create_by_liste"
      when "dl"
      @title = "Nombre de commentaires supprimés sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "comment_delete_by_liste"
    else
      params[:mode] = "ct"
      @title = "Nombre de commentaires créés"
      @headers = ["date","total"]
      method = "comment_create"
    end
    
    classe = "LogComment"
    generic(classe, method, true)
  end
  
  def note
    case params[:mode]
      when "dt"
      @title = "Nombre de notes supprimées"
      @headers = ["date","total"]
      method = "note_delete"
      when "cn"
      @title = "Nombre de notes créées sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "note_create_by_notice"
      when "dn"
      @title = "Nombre de notes supprimées sur des notices"
      @headers = ["notice_id", "date","total"]
      method = "note_delete_by_notice"
      when "cl"
      @title = "Nombre de notes créées sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "note_create_by_liste"
      when "dl"
      @title = "Nombre de notes supprimées sur des listes"
      @headers = ["liste_id", "date","total"]
      method = "note_delete_by_liste"
    else
      params[:mode] = "ct"
      @title = "Nombre de notes créées"
      @headers = ["date","total"]
      method = "note_create"
    end
    
    classe = "LogNote"
    generic(classe, method, true)
  end
  
  def list_consult
    case params[:mode]
      when "v"
      @title = "Nombre de consultations de listes"
      @headers = ["date","total"]
      method = "total_liste_consult"
      when "vl"
      @title = "Nombre de consultations par liste"
      @headers = ["liste_id", "title", "date","total"]
      method = "total_consult_by_list"
      when "d"
      @title = "Nombre de listes supprimées"
      @headers = ["notice_id", "date","total"]
      method = "total_liste_delete"
    else
      params[:mode] = "c"
      @title = "Nombre de listes créées"
      @headers = ["date","total"]
      method = "total_liste_create"
    end
    
    classe = "LogListConsult"
    generic(classe, method, true)
    
  end
  
  def save_request
    case params[:mode]
      when "c"
    else
      params[:mode] = "s"
      @title = "Nombre de requêtes sauvegardées"
      @headers =  ["profil", "date","total"]
      method = "save_request"
    end
    
    classe = "LogSaveRequest"
    generic(classe, method, true)
  end
  def nb_user
    case params[:mode]
      when "c"
      @title = "Nombre d'utilisateurs actifs"
      @headers =  ["date", "total"]
      method = "number_account_actif"
      classe = "LogAccount"
      generic(classe, method, true)
    end
  end
  
  
  def consult_account
    case params[:mode]
      when "s"
      @title = "Nombre d'utilisateurs "
      @headers =  ["date", "total"]
      method = "number_account"
      when "c"
      @title = "Nombre de compte"
      @headers =  ["date", "total"]
      method = "number_account"
      when "g"
      @title = "Nombre d'utilisateurs actifs"
      @headers =  ["date", "total"]
      method = "number_account_actif"
      when "e"
      @title = "Exports FOAF"
      @headers =  ["date", "total"]
      method = "export_foaf_user"
      when "x"
      @title = "Exports XML"
      @headers =  ["date", "total"]
      method = "export_foaf_user"
    end
    
    classe = "LogAccount"
    generic(classe, method, true)
  end
  
  
  def rebonce_tag
    case params[:mode]
      when "n"
      @title = "Nombre de rebonds sur les mots clés via une notice"
      @headers = ["tag_label", "date","total"]
      method = "by_notice"
      when "l"
      @title = "Nombre de rebonds sur les mots clés via une liste"
      @headers = ["tag_label", "date","total"]
      method = "by_liste"
    else
      params[:mode] = "all"
      @title = "Nombre de rebonds sur les mots clés"
      @headers = ["tag_label", "date","total"]
      method = "total"
    end
    
    classe = "LogRebonceTag"
    generic(classe, method, true)
  end
  
  def rebonce_profil
    case params[:mode]
      when "n"
      # other case
    else
      params[:mode] = "all"
      @title = "Nombre de rebonds sur les profils"
      @headers = ["name","uuid", "date","total"]
      method = "rebonce"
    end
    
    classe = "LogRebonceProfil"
    generic(classe, method, true)
  end
  
  def rebonce_liste
    case params[:mode]
      when "n"
      # other case
    else
      params[:mode] = "all"
      @title = "Nombre de rebonds sur les listes"
      @headers = ["liste_id", "title", "date","total"]
      method = "total_consult_by_list"
    end
    
    classe = "LogListConsult"
    generic(classe, method, true)
  end
  
  def facette
    case params[:mode]
      when "c"
      # other case
    else
      params[:mode] = "s"
      @title = "Nombre d'action sur les facettes"
      @headers =  ["facette", "date","total"]
      method = "facette"
    end
    
    classe = "LogFacetteUsage"
    generic(classe, method, true)
  end
  
  def top_notice
    
    params[:max] = extract_param("max", Integer, 5);
    params[:page] = extract_param("page", Integer, 1);
    params[:unit] = extract_param("unit", String, "");
    params[:date_from] = extract_param("date_from", String, nil);
    params[:date_to] = extract_param("date_to", String, nil);
      
    params[:profil] = extract_param("profil", String, nil);
    params[:order] = extract_param("order", String, "total");
    
    is_export = export_csv?()
    
    case params[:mode]
      when "comment"
      @title = "Les notices les plus commentées"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "total"]
      results = Notice.topByComment(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      
      when "tag"
      @title = "Les notices les plus taggées"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "total"]
      results = Notice.topByTag(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      
      when "liste"
      @title = "Les notices les plus dans les listes"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "total"]
      results = Notice.topByListe(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      
      when "sub"
      # Need some test to finish that
      @title = "Les notices les plus attendues"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type", "subscriptions_count"]
      results = Notice.topBySubscription(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      
      when "export"
      @title = "Les notices les plus exportées"
      @headers = ["idDoc", "collection_id", "alt_name", "title", "material_type", "date","total"]
      method = "topExport"
      generic("LogConsult", method, true)
      return
    else
      params[:mode] = "note"
      @title = "Les notices les mieux notées"
      @headers =  ["doc_identifier", "doc_collection_id", "alt_name", "dc_title", "ptitle", "dc_type","notes_avg", "notes_count"]
      results = Notice.topByNote(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
    end
    
    if (!results.nil?)
      @items = results[:result]
      total = results[:count].to_i
      page = results[:page].to_i
      max = results[:max].to_i
    else
      @items = []
      total = 0
      page = 1
      max = 10
    end
    
    if (is_export)
      export_csv
    else
      @pages = Paginator.new self, total, max, page
    end
  end
  
  def top_liste
    
    params[:max] = extract_param("max", Integer, 5);
    params[:page] = extract_param("page", Integer, 1);
    params[:unit] = extract_param("unit", String, "");
    params[:date_from] = extract_param("date_from", String, nil);
   params[:date_to] = extract_param("date_to", String, nil);
      
    params[:profil] = extract_param("profil", String, nil);
    params[:order] = extract_param("order", String, "total");

    
    is_export = export_csv?()
    
    case params[:mode]
      when "comment"
      @title = "Les listes les plus commentées"
      @headers =  ["id","title","comments_count"]
      results = List.topByComment(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      when "notice"
      @title = "Les listes avec le plus grand nombre de notices sauvegardées"
      @headers =  ["id","title","notices_count"]
      results = List.topByNotice(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      when "tag"
      @title = "Les listes les plus taggées"
      @headers =  ["id","title","tags_count"]
      results = List.topByTag(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
      when "liste"
      @title = "Les listes les plus dans les listes"
      @headers =  ["id","title","lists_count", "lists_count_public"]
      results = List.topByListe(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
    else
      params[:mode] = "note"
      @title = "Les listes les mieux notées"
      @headers =  ["id","title","notes_avg", "notes_count"]
      results = List.topByNote(params[:page], params[:max], params[:unit], params[:date_from], params[:date_to], params[:profil], params[:order])
    end
    
    if (!results.nil?)
      @items = results[:result]
      total = results[:count].to_i
      page = results[:page].to_i
      max = results[:max].to_i
    else
      @items = []
      total = 0
      page = 1
      max = 10
    end
    
    if (is_export)
      export_csv
    else
      @pages = Paginator.new self, total, max, page
    end
  end
  
  private
  def generic(classe, method, by_profil=false)
    
    params[:order] = extract_param("order", String, "total");
    params[:tab_filter] = extract_param("tab_filter", String, "");
    params[:unit] = extract_param("unit", String, "");
    params[:page] = extract_param("page", Integer, 1);
    params[:max] = extract_param("max", Integer, 25);
    params[:date_from] = extract_param("date_from", String, nil);
    params[:date_to] = extract_param("date_to", String, nil);
    params[:profil] = extract_param("profil", String, nil);
    params[:material_type] = extract_param("material_type", String, nil);
    params[:profil_poste] = extract_param("plage_ip", String, nil);
    params[:tab] = extract_param("tab", String, nil);

    is_export = export_csv?()
    is_export_XML = export_XML?()
    is_export_foaf = export_foaf?()
          
    results = nil
    eval("results = #{classe}.#{method}(params[:unit], params[:date_from], params[:date_to], params[:tab_filter], params[:order], params[:page], params[:max], params[:profil], params[:material_type], params[:profil_poste])")
    
    if (!results.nil?)
      @items = results[:result]
      total = results[:count].to_i
      page = results[:page].to_i
      max = results[:max].to_i
    else
      @items = []
      total = 0
      page = 1
      max = 10
    end
    
    if (is_export)
      export_csv
    elsif (is_export_foaf)
      export_foaf
    elsif (is_export_XML)
      export_XML
    else
      @pages = Paginator.new self, total, max, page
    end
  end
  
  def export_csv?
    params[:export] = extract_param("export", String, nil);
    if (!params[:export].blank?)
      params[:max] = 999999
      params[:page] = 1
      return true
    end
    return false
  end
  
  def export_foaf?
    params[:foaf] = extract_param("foaf", String, nil);
    if (!params[:foaf].blank? and params[:foaf]=="1")
      params[:max] = 999999
      params[:page] = 1
      return true
    end
    return false
  end

  def export_XML?
    params[:xml] = extract_param("XML", String, nil);
    if (!params[:xml].blank? and params[:xml]=="1")
      params[:max] = 999999
      params[:page] = 1
      return true
    end
    return false
  end
  
  def export_foaf
    require 'htmlentities'
    coder = HTMLEntities.new
    
    datas = '<rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
      xmlns:foaf="http://xmlns.com/foaf/0.1/"
      xmlns:admin="http://webns.net/mvcb/">'
    
    @items.each{ |item|
      tag_rq = "SELECT * FROM objects_tags, tags WHERE objects_tags.uuid = '#{item['uuid']}' and objects_tags.tag_id = tags.id"
      tags = ObjectsTag.find_by_sql(tag_rq)

      comment_rq = "SELECT note_id, comment_date, comments.object_uid as nuid, comments.uuid, comments.content, comments.title as ctitle, comments.id as c_id FROM comments, notices, notes WHERE comments.uuid = '#{item['uuid']}' and comments.parent_id is NULL and comments.object_type = 1 and CONCAT(notices.doc_identifier, ';', notices.doc_collection_id) = comments.object_uid GROUP BY comments.id"
      comments_notices = Comment.find_by_sql(comment_rq)

      comment_rq = "SELECT note_id, comment_date, content, comments.object_uid as luid, comments.uuid, comments.title as ctitle, comments.id as c_id FROM comments, lists WHERE comments.uuid = '#{item['uuid']}' and comments.parent_id is NULL and comments.object_type = 2 and lists.id = comments.object_uid GROUP BY comments.id"
      comments_list = Comment.find_by_sql(comment_rq)

      lists_rq = "SELECT * FROM lists where uuid = '#{item['uuid']}'"
      lists = List.find_by_sql(lists_rq)

      datas += '<foaf:Person>'
      datas += '<foaf:nick>' + coder.encode(item["name"]) + '</foaf:nick>'
      datas += '<foaf:mbox rdf:resource="mailto:'+ coder.encode(item["uuid"]) + '"/>'
      datas += '<foaf:homepage rdf:resource="http://10.1.2.119/account/myaccount/profile?p_id='+ coder.encode(item["md5"]) + '"/>'
      

      #list user tags
      datas += '<div xmlns:ctag="http://commontag.org/ns#" rel="ctag:tagged">'
      tags.each{ |tag|
        datas += '<a typeof="ctag:Tag" rel="ctag:means" property="ctag:label" content="' + coder.encode(tag["label"]) + '" resource="http://10.1.2.119/permalien/tag?tag=' + coder.encode(tag["id"]) + '">' + coder.encode(tag["label"]) + '</a>' 
     }      
      datas += '<span rel="foaf:maker" resource="http://10.1.2.119/account/myaccount/profile?p_id=' + coder.encode(item["md5"]) + '"/>'
      datas += '</div>'

      #list user comment and note for notices comments
      comments_notices.each{ |comment|
        nuid = comment["nuid"].split(";")[0] + '%3b' + comment["nuid"].split(";")[1]
        datas += '<div xmlns:v="http://rdf.data-vocabulary.org/#" typeof="v:Review"><span property="v:itemreviewed">http://10.1.2.119/permalien/document?doc=' + nuid + '%3b0</span>'
        datas += '<span property="v:reviewer">' + coder.encode(comment["uuid"]) + '</span>'
        datas += '<span property="v:dtreviewed">' + coder.encode(comment["comment_date"]) + '</span>'
        datas += '<span property="v:summary">' + coder.encode(comment["ctitle"]) + '</span>'
        datas += '<span property="v:description">' + coder.encode(comment["content"]) + '</span>'

        if (comment["note_id"] != 0)
          note_rq = "SELECT note FROM notes where id = #{comment["note_id"]}"
          note = Note.find_by_sql(note_rq)
          datas += '<span property="v:rating">' + coder.encode(note[0]["note"]) + '</span>'
        end

	comment_rq = "SELECT comment_date, comments.uuid, comments.content FROM comments WHERE comments.parent_id = #{comment['c_id']}"
        comments_son = Comment.find_by_sql(comment_rq)

	comments_son.each{ |comment_son|
	   datas += '<div xmlns:v="http://rdf.data-vocabulary.org/#" typeof="v:Review">'
	   datas += '<span property="v:reviewer">' + coder.encode(comment_son["uuid"]) + '</span>'
	   datas += '<span property="v:dtreviewed">' + coder.encode(comment_son["comment_date"]) + '</span>'
	   datas += '<span property="v:description">' + coder.encode(comment_son["content"]) + '</span>'
	   datas += '</div>'
	}

        datas += '</div>'

      }

      #list user comment and note for list comments
      comments_list.each{ |comment|
        datas += '<div xmlns:v="http://rdf.data-vocabulary.org/#" typeof="v:Review"><span property="v:itemreviewed">http://10.1.2.119/permalien/liste?id=' + coder.encode(comment["luid"])      + '</span>'
        datas += '<span property="v:reviewer">' + coder.encode(comment["uuid"]) + '</span>'
        datas += '<span property="v:dtreviewed">' + coder.encode(comment["comment_date"]) + '</span>'
        datas += '<span property="v:summary">' + coder.encode(comment["ctitle"]) + '</span>'
        datas += '<span property="v:description">' + coder.encode(comment["content"]) + '</span>'

        if (comment["note_id"] != 0)
          note_rq = "SELECT note FROM notes where id = #{comment["note_id"]}"
          note = Note.find_by_sql(note_rq)
          datas += '<span property="v:rating">' + coder.encode(note[0]["note"]) + '</span>'
        end

	comment_rq = "SELECT comment_date, comments.uuid, comments.content FROM comments WHERE comments.parent_id = #{comment['c_id']}"
        comments_son = Comment.find_by_sql(comment_rq)

	comments_son.each{ |comment_son|
	   datas += '<div xmlns:v="http://rdf.data-vocabulary.org/#" typeof="v:Review">'
	   datas += '<span property="v:reviewer">' + coder.encode(comment_son["uuid"]) + '</span>'
	   datas += '<span property="v:dtreviewed">' + coder.encode(comment_son["comment_date"]) + '</span>'
	   datas += '<span property="v:description">' + coder.encode(comment_son["content"]) + '</span>'
	   datas += '</div>'
	}
        datas += '</div>'
      }

      #lists all list
      lists.each{ |list|
        datas += '<div xmlns:dc="http://purl.org/dc/dcmitype" typeof="dc:Collection" ressource="http://10.1.2.119/permalien/liste?id=' +  coder.encode(list["id"]) + '">'
        datas += '<span property="dc:identifier">' + coder.encode(list["id"]) +  '</span>'
        datas += '<span property="dc:title">' + coder.encode(list["title"]) +  '</span>'
        datas += '<span property="dc:description">' + coder.encode(list["description"]) +  '</span>'
        datas += '<span property="dc:created">' + coder.encode(list["created_at"]) +  '</span>'
        datas += '<span property="dc:creator">' + coder.encode(list["uuid"]) +  '</span>'
        
        notices_rq = "SELECT * from list_user_records, notices where list_id = #{list['id']} and CONCAT(notices.doc_identifier, ';', notices.doc_collection_id) = CONCAT(list_user_records.doc_identifier, ';', list_user_records.doc_collection_id)"
        notices = List.find_by_sql(notices_rq)

        notices.each{ |notice|
          datas += '<div xmlns:dc="http://purl.org/dc/elements/1.1/" about="http://10.1.2.119/permalien/document?doc=' + notice.doc_identifier + '%3b' + notice.doc_collection_id  + '%3b0">'
          datas += '<span property="dc:title">' +  coder.encode(notice["dc_title"]) + '</span>'
          datas += '<span property="dc:author">' + coder.encode(notice["dc_author"]) + '</span>'
          datas += '<span property="dc:type">' + coder.encode(notice["dc_type"]) + '</span>'
          datas += '</div>'
        }

        

        datas += "</div>"
      }

      

      datas += '</foaf:Person>'
    }
    datas += '</rdf:RDF>'
    time = Time.now
    send_data(datas, :type => 'application/rdf+xml', :filename => "Autres_données_usagers_RDF__#{time.day}-#{time.month}-#{time.year}.rdf" , :disposition => 'attachment');
  end

  def export_XML
    require 'htmlentities'
    coder = HTMLEntities.new
    datas = '<?xml version="1.0" encoding="UTF-8"?>'
    datas += "<root>"
    @items.each{ |item|
      datas += '<id_usager uuid="'  + coder.encode(item["uuid"]) + '">'
      
      #alerte
      alerte_rq = "SELECT * FROM subscriptions, notices WHERE subscriptions.uuid = '#{item['uuid']}' and CONCAT(notices.doc_identifier, ';', notices.doc_collection_id) = subscriptions.object_uid"
      alertes = Subscription.find_by_sql(alerte_rq)
      alertes.each { |alerte|
        datas += '<alerte object="' +  coder.encode(alerte["object_uid"]) + '" date="' +  coder.encode(alerte["subscription_date"]) + '" state="' +  coder.encode(alerte["state"]) + '" mail_notification="' +  coder.encode(alerte["mail_notification"]) + '">'
        datas += '<dc_identifier>' + coder.encode(alerte["object_uid"])  + '</dc_identifier>'
        datas += '<dc_title_court>' + coder.encode(alerte["dc_title"]) + '</dc_title_court>'
        datas += '<dc_creator>' + coder.encode(alerte["dc_author"]) + '</dc_creator>'
        datas += '<dc_type>' + coder.encode(alerte["dc_type"]) + '</dc_type>'
        datas += '</alerte>'
      }

      #recherche
      recherche_rq = "SELECT search_type, search_input, search_type2, search_operator1, search_operator2, search_input2, search_input3, full_name, tab_filter, search_type3,  users_history_searches.id as id  FROM users_history_searches, history_searches, collection_groups WHERE users_history_searches.uuid = '#{item['uuid']}' and users_history_searches.id_history_search = history_searches.id and CONCAT('g' , collection_groups.id) = history_searches.search_group"
      recherches = HistorySearch.find_by_sql(recherche_rq)
      recherches.each { |recherche|
        datas += '<recherche_' + coder.encode(recherche["id"]) + '>'
        datas += '<expression1 index="' + coder.encode(recherche["search_type"]) + '">' + coder.encode(recherche["search_input"]) + '</expression1>'
        datas += '<expression2 index="' + coder.encode(recherche["search_type2"]) + '" operateur="' + coder.encode(recherche["search_operator1"]) + '">' + coder.encode(recherche["search_input2"]) + '</expression2>'
        datas += '<expression3 index="' + coder.encode(recherche["search_type3"]) + '" operateur="' + coder.encode(recherche["search_operator2"]) + '">' + coder.encode(recherche["search_input3"]) + '</expression3>'
        datas += '<grp_ressources>' + coder.encode(recherche["full_name"]) + '</grp_ressources>'
        datas += '<nom_onglet>' + coder.encode(recherche["tab_filter"]) + '</nom_onglet>'
        datas += '</recherche_' + coder.encode(recherche["id"]) + '>'
      }

      datas += '</id_usager>'
    }
    time = Time.now
    datas += '</root>'
    send_data(datas, :type => 'application/xml', :filename => "Données_usagers_alertes_recherches_#{time.day}-#{time.month}-#{time.year}.xml" , :disposition => 'attachment');
  end
    
  
  def export_csv
    datas = ""
    h_translate = []
    @headers.each do |h|
      h_translate << verify_write(translate(h))
    end
    datas += h_translate.join(SEPARATOR)
    datas += ENDLINE
    
    size_h = @headers.size()
    
    @items.each do |i|
      cpt = 1
      @headers.each do |he|
        case he
          when "date"
            if !params[:unit].blank?
              datas += verify_write(format_date_stats(i))
            else
              datas += ""
            end 
          when "indoor"
            if i[he] == "0"
              datas += verify_write(translate("l_outdoor"))
            else
              datas += verify_write(translate("l_indoor"))
            end
          when "facette"
            datas += verify_write(translate(i[he]))
          when "search_group"
            datas += verify_write(get_label_gc(@group_collections, i[he]))
          when "search_tab_subject_id"
            datas += verify_write(get_label_search_tab_subject(@search_tabs_subjects, i[he]))
        else
          datas += verify_write("#{i[he]}")
        end
        
        if cpt < size_h
          datas += SEPARATOR
        else
          datas += ENDLINE
        end
        cpt += 1
      end
    end
    send_data(datas, :filename=>"#{@title}.csv")
  end
  
  def verify_write(data)
    if data.nil?
      return ""
    end
    return data.gsub(SEPARATOR,"").gsub(ENDLINE, "")
  end
  
end
