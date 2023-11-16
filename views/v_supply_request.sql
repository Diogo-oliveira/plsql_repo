-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 2011-09-02
-- CHANGE REASON: INTERALERT-2063	
CREATE OR REPLACE VIEW V_SUPPLY_REQUEST AS
SELECT sw.id_supply_workflow,
	 sw.id_episode,
	 sw.id_context,
	 sw.flg_context,
	 sw.flg_status,
	 sw.dt_supply_workflow,
	 sw.id_professional,
	 sw.dt_cancel,
	 sw.id_prof_cancel,
	 sw.id_supply,
	 sw.quantity,
	 sw.notes,
	 s.code_supply,
	 s.id_content,
	 s.id_supply_type,
	 s.flg_type,
	 sw.flg_reusable,
	 sw.flg_cons_type,
	 e.id_dep_clin_serv
FROM supply_request sr
JOIN supply_workflow sw ON sw.id_supply_request = sr.id_supply_request
JOIN supply s ON s.id_supply = sw.id_supply
JOIN epis_info e ON e.id_episode = sw.id_episode;
--CHANGE END

-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 2011-09-02
-- CHANGE REASON: ALERT-193627	
CREATE OR REPLACE VIEW V_SUPPLY_REQUEST AS
SELECT sr.id_supply_request,
sr.id_professional,
sr.id_episode,
sr.id_room_req,
sr.id_context,
sr.flg_context,
sr.dt_request,
sr.flg_status,
sr.flg_reason,
sr.flg_prof_prep,
sr.id_prof_cancel,
sr.dt_cancel,
sr.notes_cancel,
sr.id_cancel_reason,
sr.notes
FROM supply_request sr;
--CHANGE END
