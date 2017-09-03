RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
 
if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
  require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'
#require ENV['LIBRARYFIND_HOME'] + 'app/models/log_doc.rb'

  # This script deletes all posts that are over 5 minutes old
    

begin
  SEP ="\t"
  datas = ""
  SEPARATOR = ","
  ENDLINE = "\n"
  h_translate = []
  @active = SiteConfig.find(:first, :conditions => ["field = 'stat_doc'"] )
        if (!@active.blank? and @active.value.to_s != '0')
            @post_ids = LogDoc.find(:all, :select=> "log_docs.*, count(id_doc) as count ", :order=>"count desc, title_doc asc",
                                    :conditions => ["created_at >= ?", 6.days.ago], :group => "id_doc")
            if @post_ids.size > 0
              # header row 
              @headers = ["Id du document", "Titre du document", "Date", "Nombre"] 
              @headers.each do |h|
                h_translate << h
              end
              datas += h_translate.join(SEPARATOR)
              datas += ENDLINE
              # data rows 
              @post_ids.each do |doc| 
                datas += "\"#{doc.id_doc}\""
                datas += SEPARATOR
                datas += "\"#{doc.title_doc}\""
                datas += SEPARATOR
                datas += "\"#{doc.created_at.to_s}\""
                datas += SEPARATOR
                datas += "\"#{doc.count.to_s}\""
                datas += ENDLINE
              end 
              # send it 
              filename = "/srv/stats/" + "Doc_Stat_#{Date.today}.csv"
              myFile = File.open("#{filename}", "a+")
              myFile.write(datas)
              myFile.close
              post_to_distroy = LogDoc.find(:all, :conditions => ["created_at < ?", 6.days.ago])
              LogDoc.destroy(post_to_distroy)
              puts "#{@post_ids.size} posts have been deleted!"
            end
        end
end
  

  
  
