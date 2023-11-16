CREATE VIEW V_SYS_CONFIG_GLOBAL AS
select * from sys_config sc where sc.global_configuration='Y';
