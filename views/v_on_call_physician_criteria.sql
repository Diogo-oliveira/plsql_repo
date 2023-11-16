

-- José Brito 27/04/2009 ALERT-10317
CREATE OR REPLACE VIEW v_on_call_physician_criteria AS
SELECT ocp.id_on_call_physician,
			 ocp.id_professional,
			 s.id_speciality,
			 s.code_speciality,
			 ocp.notes,
			 ocp.dt_start,
			 ocp.dt_end
	FROM on_call_physician ocp, professional p, speciality s
 WHERE ocp.id_professional = p.id_professional
	 AND p.id_speciality = s.id_speciality
	 AND ocp.flg_status = sys_context('ALERT_CONTEXT', 'g_on_call_active')
	 AND ocp.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
 ORDER BY ocp.dt_start DESC;
/

