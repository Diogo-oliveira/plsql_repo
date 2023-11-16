/*-- Last Change Revision: $Rev: 1877302 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-11-12 09:57:24 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_supplies IS

    FUNCTION set_supply_preparation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_supplies     IN table_number,
        i_id_patient   IN patient.id_patient%TYPE,
        i_unic_id      IN table_number,
        i_prepared_by  IN table_varchar,
        i_prep_notes   IN table_varchar,
        i_new_supplies IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_supplies_api_db.set_supply_preparation(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_supplies     => i_supplies,
                                                         i_id_patient   => i_id_patient,
                                                         i_unic_id      => i_unic_id,
                                                         i_prepared_by  => i_prepared_by,
                                                         i_prep_notes   => i_prep_notes,
                                                         i_new_supplies => i_new_supplies,
                                                         o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_PREPARATION',
                                              o_error);
        
            RETURN FALSE;
    END set_supply_preparation;

    FUNCTION set_conclude_devolution
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        i_barcode    IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_supplies_api_db.set_supply_devolution(i_lang     => i_lang,
                                                        i_prof     => i_prof,
                                                        i_supplies => i_supplies,
                                                        i_barcode  => i_barcode,
                                                        o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CONCLUDE_DEVOLUTION',
                                              o_error);
        
            RETURN FALSE;
    END set_conclude_devolution;

    FUNCTION get_list_req_cons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN episode.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_supplies_api_db.get_supply_listview(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_supply_area => NULL,
                                                      i_patient        => i_patient,
                                                      i_episode        => i_episode,
                                                      i_flg_type       => table_varchar(pk_supplies_constant.g_supply_type,
                                                                                        pk_supplies_constant.g_supply_kit_type,
                                                                                        pk_supplies_constant.g_supply_set_type),
                                                      o_list           => o_list,
                                                      o_error          => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LIST_REQ_CONS',
                                              o_error);
            pk_types.open_cursor_if_closed(o_list);
            RETURN FALSE;
    END get_list_req_cons;

    FUNCTION get_list_req_cons_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN episode.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN supply.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_API_DB.GET_LIST_REQ_CONS_REPORT';
        IF NOT pk_supplies_api_db.get_list_req_cons_report(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_patient  => i_patient,
                                                           i_episode  => i_episode,
                                                           i_flg_type => i_flg_type,
                                                           o_list     => o_list,
                                                           o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_list_req_cons_report;

    FUNCTION get_translation_code(i_supply IN supply.id_supply%TYPE) RETURN VARCHAR2 IS
        l_code supply.code_supply%TYPE;
    BEGIN
        SELECT s.code_supply
          INTO l_code
          FROM supply s
         WHERE s.id_supply = i_supply;
    
        RETURN l_code;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_translation_code;

    FUNCTION update_supply_workflow_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        i_id_prof_cancel     IN professional.id_professional%TYPE,
        i_cancel_notes       IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason   IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel          IN supply_workflow.dt_cancel%TYPE,
        i_flg_status         IN supply_workflow.flg_status%TYPE,
        i_notes              IN supply_workflow.notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL PK_SUPPLIES_API_DB.UPDATE_SUPPLY_WORKFLOW_STATUS';
    
        IF NOT pk_supplies_api_db.update_supply_workflow_status(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_supplies         => table_number(i_id_supply_workflow),
                                                                i_id_prof_cancel   => i_id_prof_cancel,
                                                                i_cancel_notes     => i_cancel_notes,
                                                                i_id_cancel_reason => i_id_cancel_reason,
                                                                i_dt_cancel        => i_dt_cancel,
                                                                i_flg_status       => i_flg_status,
                                                                i_notes            => table_varchar(i_notes),
                                                                o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END update_supply_workflow_status;

END pk_api_supplies;
/
