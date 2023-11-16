CREATE OR REPLACE VIEW V_REHAB_SESSION_TYPE AS
SELECT rst.id_rehab_session_type, rst.code_rehab_session_type, dcs.id_dep_clin_serv, d.id_institution
			FROM rehab_session_type rst
		 INNER JOIN rehab_dep_clin_serv rdcs ON rst.id_rehab_session_type = rdcs.id_rehab_session_type
		 INNER JOIN dep_clin_serv dcs ON dcs.id_dep_clin_serv = rdcs.id_dep_clin_serv
		 INNER JOIN department d ON d.id_department = dcs.id_department;
