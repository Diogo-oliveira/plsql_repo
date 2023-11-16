-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 15/06/2018 14:28
-- CHANGE REASON: [EMR-4137] 
DECLARE
    TYPE cv_rec IS REF CURSOR;
    rec           cv_rec;
    l_id_sup_wflw NUMBER;
    l_count_set   NUMBER;
    l_swflw_id    NUMBER;
    
    CURSOR v_sql IS 
       SELECT a.id_supply_workflow,
              a.id_sup_workflow_parent,
               a.id_supply,
               a.id_supply_set,
               a.id_episode,
               a.dt_request,
               a.id_professional,
               a.id_supply_request,
               a.id_supply_location,
               a.id_context,
               a.flg_context,
               a.flg_status,
               a.dt_returned,
               a.dt_supply_workflow,
               a.flg_outdated,
               a.flg_cons_type,
               a.flg_reusable,
               a.flg_editable,
               a.id_supply_area,
               a.create_time
          FROM supply_workflow a
         WHERE a.id_supply_set IS NOT NULL
        ORDER BY dt_request;

BEGIN
    FOR rec IN v_sql
        
    LOOP
		    BEGIN
        SELECT COUNT(*)
          INTO l_count_set
          FROM supply_workflow a
         INNER JOIN supply b  
            ON a.id_supply = b.id_supply
         WHERE a.id_episode = rec.id_episode
           AND a.id_supply = rec.id_supply_set
					 AND a.flg_status not in ('C', 'U')
           AND TO_CHAR(a.dt_request, 'YYYY-MM-DD HH24:MI:SS') = TO_CHAR(rec.dt_request,'YYYY-MM-DD HH24:MI:SS')
           AND b.flg_type = 'S';
      
        IF l_count_set = 0
        THEN
            l_swflw_id := seq_supply_workflow.nextval;
            INSERT INTO supply_workflow
                (id_supply_workflow,
                 id_professional,
                 id_episode,
                 id_supply_request,
                 id_supply,
                 id_supply_location,
                 quantity,
                 id_context,
                 flg_context,
                 flg_status,
                 dt_request,
                 dt_returned,
                 dt_supply_workflow,
                 total_quantity,
                 flg_outdated,
                 flg_cons_type,
                 flg_reusable,
                 flg_editable,
                 id_supply_area)
            VALUES
                (l_swflw_id,
                 rec.id_professional,
                 rec.id_episode,
                 rec.id_supply_request,
                 rec.id_supply_set,
                 rec.id_supply_location,
                 1,
                 rec.id_context,
                 rec.flg_context,
                 rec.flg_status,
                 rec.dt_request,
                 rec.dt_returned,
                 rec.dt_supply_workflow,
                 1,
                 rec.flg_outdated,
                 rec.flg_cons_type,
                 rec.flg_reusable,
                 rec.flg_editable,
                 rec.id_supply_area);
            UPDATE supply_workflow b
               SET b.id_sup_workflow_parent = l_swflw_id
             WHERE b.id_supply_workflow = rec.id_supply_workflow;
        
        ELSE
            SELECT a.id_supply_workflow
              INTO l_id_sup_wflw
              FROM supply_workflow a
             INNER JOIN supply b
                ON a.id_supply = b.id_supply
             WHERE a.id_episode = rec.id_episode
               AND a.id_supply = rec.id_supply_set
							 AND a.flg_status not in ('C', 'U')
               AND TO_CHAR(a.dt_request, 'YYYY-MM-DD HH24:MI:SS') = TO_CHAR(rec.dt_request,'YYYY-MM-DD HH24:MI:SS')
               AND b.flg_type = 'S';
        
            UPDATE supply_workflow b
               SET b.id_sup_workflow_parent = l_id_sup_wflw
             WHERE b.id_supply_workflow = rec.id_supply_workflow;
        END IF;
    EXCEPTION WHEN OTHERS THEN
		   dbms_output.put_line(rec.id_supply_workflow);
		END;
    END LOOP;
END;

/
-- CHANGE END: Pedro Henriques