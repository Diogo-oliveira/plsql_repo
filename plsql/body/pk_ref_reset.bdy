/*-- Last Change Revision: $Rev: 2027592 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_reset IS
    /**
    *  This function deletes all data related to Referral.
    *
    * @param      I_LANG                      Language ID
    * @param      I_ID_EXTERNAL_REQUEST       External Request ID
    * @param      O_ERROR                     Error message
    *
    * @return     BOOLEAN             TRUE if sucess, FALSE otherwise
    *
    * @author     Ana.coelho
    * @version
    * @since      12/04/2010
    */
    FUNCTION clear_referral_reset
    (
        i_lang                IN language.id_language%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rid_doc counter;
    
        CURSOR c_ref_session IS
            SELECT s.id_session
              FROM ref_ext_session s
             WHERE s.id_external_request = i_id_external_request;
    
        l_id_session ref_ext_session.id_session%TYPE;
        l_rows       table_varchar;
    BEGIN
        g_lang      := i_lang;
        g_func_name := 'CLEAR_P1_EXT_REQUEST';
    
        g_error := 'START ' || g_func_name || ' ' || i_id_external_request;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- ID'S from P1's documents
        FOR r_id_doc IN (SELECT id_doc_external
                           FROM doc_external
                          WHERE id_external_request = i_id_external_request)
        LOOP
            l_rid_doc := r_id_doc.id_doc_external;
        
            g_error := 'DEL DOC_ACTIVITY_PARAM';
            DELETE FROM doc_activity_param
             WHERE id_doc_activity IN (SELECT id_doc_activity
                                         FROM doc_activity
                                        WHERE id_doc_external = l_rid_doc);
        
            g_error := 'DEL DOC_ACTIVITY';
            DELETE FROM doc_activity
             WHERE id_doc_external = l_rid_doc;
        
            g_error := 'DEL DOC_IMAGE';
            DELETE FROM doc_image
             WHERE id_doc_external = l_rid_doc;
        
            g_error := 'DEL DOC_COMMENTS';
            DELETE FROM doc_comments
             WHERE id_doc_external = l_rid_doc;
        
            g_error := 'DEL DOC_EXTERNAL_US_HIST';
            DELETE FROM doc_external_us_hist
             WHERE id_doc_external_us = l_rid_doc;
        
            g_error := 'DEL DOC_EXTERNAL_US';
            DELETE FROM doc_external_us
             WHERE id_doc_external_us = l_rid_doc;
        
            g_error := 'DEL DOC_EXTERNAL';
            -- DELETE FROM doc_external
            -- WHERE id_doc_external = l_rid_doc;
            l_rows  := table_varchar();
            g_error := 'Call ts_doc_external.del / ID_DOC_EXTERNAL=' || l_rid_doc;
            ts_doc_external.del(id_doc_external_in => l_rid_doc);
        
            g_error := 'Call t_data_gov_mnt.process_delete';
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => profissional(0, 0, 0),
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END LOOP;
    
        g_error := 'DEL EPIS_REPORT_SECTION';
        DELETE FROM epis_report_section
         WHERE id_epis_report IN (SELECT id_epis_report
                                    FROM epis_report
                                   WHERE id_external_request = i_id_external_request);
    
        g_error := 'DEL EPIS_REPORT';
        DELETE FROM epis_report
         WHERE id_external_request = i_id_external_request;
    
        -- CHANGED BY: Ana Monteiro
        -- CHANGED DATE: 2010-JUN-14
        -- CHANGED REASON: ALERT-70412 - FERTIS
        OPEN c_ref_session;
        LOOP
            g_error := 'FETCH c_ref_session';
            FETCH c_ref_session
                INTO l_id_session;
            EXIT WHEN c_ref_session%NOTFOUND;
        
            g_error := 'DEL REF_EXT_XML_DATA / ID_EXTERNAL_REQUEST=' || i_id_external_request || ' ID_SESSION=' ||
                       l_id_session;
            DELETE FROM ref_ext_xml_data d
             WHERE d.id_session = l_id_session;
        
        END LOOP;
        CLOSE c_ref_session;
    
        g_error := 'DEL ref_comments_read / ID_EXTERNAL_REQUEST=' || i_id_external_request;
        DELETE FROM ref_comments_read c
         WHERE c.id_ref_comment IN (SELECT id_ref_comment
                                      FROM ref_comments
                                     WHERE id_external_request = i_id_external_request);
    
        g_error := 'DEL ref_comments / ID_EXTERNAL_REQUEST=' || i_id_external_request;
        DELETE FROM ref_comments c
         WHERE c.id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_EXT_SESSION / ID_EXTERNAL_REQUEST=' || i_id_external_request;
        DELETE FROM ref_ext_session s
         WHERE s.id_external_request = i_id_external_request;
    
        -- CHANGE END: Ana Monteiro
        g_error := 'DEL REF_TRANS_RESP_HIST';
        DELETE FROM ref_trans_resp_hist p
         WHERE p.id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_TRANS_RESPONSIBILITY';
        DELETE FROM ref_trans_responsibility p
         WHERE p.id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_DETAIL';
        DELETE FROM p1_detail
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_TRACKING';
        DELETE FROM p1_tracking
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_TASK_DONE';
        DELETE FROM p1_task_done
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_EXR_TEMP';
        DELETE FROM p1_exr_temp
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_EXR_ANALYSIS';
        DELETE FROM p1_exr_analysis
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_EXR_EXAM';
        DELETE FROM p1_exr_exam
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_EXR_INTERVENTION';
        DELETE FROM p1_exr_intervention
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_EXR_DIAGNOSIS';
        DELETE FROM p1_exr_diagnosis
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'UPD DOC_EXTERNAL';
        -- UPDATE doc_external
        --   SET id_external_request = NULL
        -- WHERE id_external_request = i_id_external_request;
    
        l_rows  := table_varchar();
        g_error := 'Call ts_doc_external.del / ID_DOC_EXTERNAL=' || l_rid_doc;
        ts_doc_external.upd(id_external_request_in => NULL,
                            where_in               => 'id_external_request=' || i_id_external_request);
    
        g_error := 'Call t_data_gov_mnt.process_delete';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => profissional(0, 0, 0),
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'DEL REFERRAL_EA';
        DELETE FROM referral_ea r
         WHERE r.id_external_request = i_id_external_request;
    
        g_error := 'UPDATE WAITING_LIST_HIST';
        UPDATE waiting_list_hist w
           SET w.id_external_request = NULL
         WHERE w.id_external_request = i_id_external_request;
    
        g_error := 'UPDATE WAITING_LIST';
        UPDATE waiting_list w
           SET w.id_external_request = NULL
         WHERE w.id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_MAP';
        DELETE FROM ref_map r
         WHERE r.id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_ORIG_DATA';
        DELETE FROM ref_orig_data
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_PIO';
        DELETE FROM ref_pio
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_PIO_TRACKING';
        DELETE FROM ref_pio_tracking
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_UPDATE_EVENT';
        DELETE FROM ref_update_event
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL REF_REPORT';
        DELETE FROM ref_report
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_EXTERNAL_REQUEST';
        DELETE FROM p1_external_request
         WHERE id_external_request = i_id_external_request;
    
        g_error := 'DEL P1_MATCH';
        DELETE FROM p1_match p
         WHERE p.id_patient = i_id_external_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => g_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            IF c_ref_session%ISOPEN
            THEN
                CLOSE c_ref_session;
            END IF;
            RETURN FALSE;
    END clear_referral_reset;
BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_reset;
/
