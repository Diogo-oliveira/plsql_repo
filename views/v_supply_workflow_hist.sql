-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 2011-09-02
-- CHANGE REASON: INTERALERT-2063
CREATE OR REPLACE VIEW V_SUPPLY_WORKFLOW_HIST AS
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
FROM supply s
JOIN supply_workflow_HIST sw ON sw.id_supply = s.id_supply
JOIN epis_info e ON e.id_episode = sw.id_episode;
--CHANGE END

-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 2011-09-02
-- CHANGE REASON: ALERT-193627
CREATE OR REPLACE VIEW V_SUPPLY_WORKFLOW_HIST AS
SELECT sw.id_supply_workflow_hist,
sw.id_supply_workflow,
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
	 sw.id_supply_request
FROM supply s
JOIN supply_workflow_HIST sw ON sw.id_supply = s.id_supply;
--CHANGE END


-- CHANGED BY: Teresa Coutinho
-- CHANGE DATE: 2012-04-09
-- CHANGE REASON: ALERT-226633 
CREATE OR REPLACE VIEW V_SUPPLY_WORKFLOW_HIST AS
SELECT sw.id_supply_workflow_hist, 
       sw.id_supply_workflow, 
       sw.id_professional, 
       sw.id_episode, 
       sw.id_supply_request, 
       sw.id_supply, 
       sw.id_supply_location, 
       sw.barcode_req, 
       sw.barcode_scanned, 
       sw.quantity, 
       sw.id_unit_measure, 
       sw.id_context, 
       sw.flg_context, 
       sw.flg_status, 
       sw.flg_reason, 
       sw.dt_request, 
       sw.dt_returned, 
       sw.notes, 
       sw.id_prof_cancel, 
       sw.dt_cancel, 
       sw.notes_cancel, 
       sw.id_cancel_reason, 
       sw.notes_reject, 
       sw.dt_reject, 
       sw.id_prof_reject, 
       sw.dt_supply_workflow, 
       sw.id_req_reason, 
       sw.id_del_reason, 
       sw.id_supply_set, 
       sw.id_sup_workflow_parent, 
       sw.asset_number, 
       sw.flg_outdated, 
       sw.total_quantity, 
       sw.total_avail_quantity, 
       sw.cod_table, 
       sw.flg_cons_type, 
       sw.flg_reusable, 
       sw.flg_editable, 
       sw.flg_preparing, 
       sw.flg_countable, 
       sw.id_supply_area, 
       sw.dt_expiration, 
       sw.flg_validation, 
       sw.lot,       
	 s.code_supply,
	 s.id_content,
	 s.id_supply_type,
	 s.flg_type	
FROM supply s
JOIN supply_workflow_HIST sw ON sw.id_supply = s.id_supply;