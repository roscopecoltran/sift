DELETE FROM parameters;

INSERT INTO parameters (name, value, description, editable) VALUES ('portfolio_nb_error_max', '5000', 'Nombre d\erreurs pendant la moisson avant de basculer sur les mysql et solr de backup', 1);
INSERT INTO parameters (name, value, description, editable) VALUES ('restart_replication_auto', '0', 'Relancer automatiquement les réplications solr et mysql après une moisson réussie (1 = oui, 0 = non)', 1);


INSERT INTO parameters (name, value, description, editable) VALUES ('solr_master', 'http://127.0.0.1:8080/solr', 'Solr maître', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('solr_harvesting', 'http://127.0.0.1:8080/solr', 'Solr utilisé pour les moissons', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('solr_slave', 'http://10.4.4.26:8080/solr', 'Solr esclave', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('solr_requests', 'http://10.4.4.26:8080/solr', 'Solr utilisé pour les recherches', 0); 


INSERT INTO parameters (name, value, description, editable) VALUES ('mysql1', 'localhost', 'Mysql 1', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('mysql_harvesting', 'localhost', 'Mysql utilisé pour les moissons', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('mysql2', '10.4.4.26', 'Mysql 2', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('mysql_requests', '10.4.4.26', 'Mysql utilisé pour les requêtes', 0); 

INSERT INTO parameters (name, value, description, editable) VALUES ('lf_url', 'http://127.0.0.1', 'Ip serveur Libraryfind', 0); 
INSERT INTO parameters (name, value, description, editable) VALUES ('lf_harvesting_url', 'http://127.0.0.1', 'Ip serveur Libraryfind de moisson', 0);
