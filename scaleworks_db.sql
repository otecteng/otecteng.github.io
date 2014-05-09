create database scaleworks_production;
create user 'scaleworks'@'localhost' identified by 'scaleworks';
grant all privileges on scaleworks_production.* to 'scaleworks'@'localhost' with grant option;
flush privileges;
