-- CHANGED BY: goncalo.almeida
-- CHANGE DATE: 21/Jul/2011 10:26
-- CHANGE REASON: ALERT-189415
BEGIN
    UPDATE rep_scope_inst_soft_market rsism
       SET rsism.flg_report_type = 'U'
     WHERE flg_report_type IS NULL;
END;
/
-- CHANGE END

-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 27-Dec-2011
-- CHANGE REASON: ALERT-206242
DECLARE 
    o_error_out t_error_out; 
    return_bool BOOLEAN; 
BEGIN 
    return_bool := pk_reports.insert_into_report_scope(i_lang => 0, 
                                                       i_report => 437, 
                                                       i_section => 0, 
                                                       i_report_type => NULL, 
                                                       i_report_scope => 'P', 
                                                       i_id_institution => 0, 
                                                       i_id_software => 0, 
                                                       i_id_market => 0, 
                                                       o_error => o_error_out); 
                             
                                         
    IF o_error_out IS NOT NULL 
    THEN 
        dbms_output.put_line('ERROR : ' || o_error_out.ora_sqlerrm); 
    END IF; 
END; 
/ 
-- CHANGE END; 

-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 27-Dec-2011
-- CHANGE REASON: ALERT-206242
DECLARE 
    o_error_out t_error_out; 
    return_bool BOOLEAN; 
BEGIN 
    return_bool := pk_reports.insert_into_report_scope(i_lang => 0, 
                                                       i_report => 490, 
                                                       i_section => 0, 
                                                       i_report_type => NULL, 
                                                       i_report_scope => 'V', 
                                                       i_id_institution => 0, 
                                                       i_id_software => 0, 
                                                       i_id_market => 0, 
                                                       o_error => o_error_out); 
                             
                                         
    IF o_error_out IS NOT NULL 
    THEN 
        dbms_output.put_line('ERROR : ' || o_error_out.ora_sqlerrm); 
    END IF; 
END; 
/ 
-- CHANGE END; 