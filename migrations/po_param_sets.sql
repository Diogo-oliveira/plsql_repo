-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 04/02/2015 17:05
-- CHANGE REASON: [ALERT-307236] 
DECLARE
    CURSOR c_param_hpg IS
        SELECT pph.*, hp.id_content hp_id_content
          FROM po_param_hpg pph
          JOIN health_program hp
            ON hp.id_health_program = pph.id_health_program;
BEGIN

    FOR i IN c_param_hpg
    LOOP
        BEGIN
        
            INSERT INTO po_param_sets
                (id_po_param,
                 id_inst_owner,
                 id_task_type,
                 task_type_content,
                 id_software,
                 id_institution,
                 rank,
                 flg_available)
            VALUES
                (i.id_po_param,
                 i.id_inst_owner,
                 101,
                 i.hp_id_content,
                 i.id_software,
                 i.id_institution,
                 i.rank,
                 i.flg_available);
        
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('NAO MIGRADO OU JA EXISTENTE:' || i.id_po_param);
        END;
    END LOOP;

END;
/
-- CHANGE END: mario.mineiro