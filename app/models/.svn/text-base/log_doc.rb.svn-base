class LogDoc < ActiveRecord::Base
  def self.insert(logdoc_inserts)
      @active = SiteConfig.find(:first, :conditions => ["field = 'stat_doc'"] )
      if (!@active.blank? and @active.value.to_s != '0')
        transaction_start = Time.now
        ActiveRecord::Base.transaction do
          begin
            ActiveRecord::Base.connection.execute("INSERT INTO log_docs(id_doc, title_doc, created_at) 
                                                   VALUES #{logdoc_inserts.join(", ")}")
            logdoc_inserts.clear
          rescue ActiveRecord::Rollback => e
            logger.error("Transaction has been rolled back => #{e.message}")
          rescue Exception => e
            logger.error("Error committing documents in MySql => #{e.message}")
            raise e
          end
        end
        transaction_end = Time.now
        logger.info("Insert transaction total time  => #{transaction_end - transaction_start} seconds.")
      end
  end
end

