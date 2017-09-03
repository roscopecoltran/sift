DELETE FROM parameters;

INSERT INTO parameters (name, value, description, editable) VALUES ('portfolio_nb_error_max', '5000', 'Nombre d\erreurs pendant la moisson avant de basculer sur les mysql et solr de backup', 1);
INSERT INTO parameters (name, value, description, editable) VALUES ('restart_replication_auto', '0', 'Relancer automatiquement les réplications solr et mysql après une moisson réussie (1 = oui, 0 = non)', 1);


INSERT INTO parameters (name, value, description, editable) VALUES ('solr_master', 'http://10.1.2.157:8080/solr', 'Solr maître', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('solr_harvesting', 'http://10.1.2.157:8080/solr', 'Solr utilisé pour les moissons', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('solr_slave', 'http://10.1.2.113:8080/solr', 'Solr esclave', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('solr_requests', 'http://10.1.2.113:8080/solr', 'Solr utilisé pour les recherches', 0); 


INSERT INTO parameters (name, value, description, editable) VALUES ('mysql1', '10.1.2.157', 'Mysql 1', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('mysql_harvesting', '10.1.2.157', 'Mysql utilisé pour les moissons', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('mysql2', '10.1.2.113', 'Mysql 2', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('mysql_requests', '10.1.2.113', 'Mysql utilisé pour les requêtes', 0); 

INSERT INTO parameters (name, value, description, editable) VALUES ('lf_url', 'http://10.1.2.111', 'Ip serveur Libraryfind', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('lf_harvesting_url', 'http://10.1.2.112', 'Ip serveur Libraryfind de moisson', 0);
