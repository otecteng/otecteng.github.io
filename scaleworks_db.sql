create database scaleworks_production;
create user 'scaleworks'@'%' identified by 'scaleworks'
grant all privileges on scaleworks_production.* to 'scaleworks'@'%' with grant option;
flush privileges;
