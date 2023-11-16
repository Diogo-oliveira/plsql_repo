/*-- Last Change Revision: $Rev: 1555623 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2014-02-11 08:28:46 +0000 (ter, 11 fev 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_ref_event IS

    g_error         VARCHAR2(1000 CHAR);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception EXCEPTION;
    g_exception_np EXCEPTION;

    /**
    * Reprocess interface events in error    
    * 
    * @param i_prof               Professional identifier, insitution and software
    * @param i_id_ref             Referral identifier
    *
    * @author  Ana Monteiro
    * @version 2.6
    * @since   2013-01-22
    */
    PROCEDURE reprocess_intf_events
    (
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) IS
        l_sql sys_config.value%TYPE;
    BEGIN
        l_sql := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                             i_id_sys_config => pk_ref_constant.g_ref_reproc_intf_events);
        IF l_sql != ' '
        THEN
            EXECUTE IMMEDIATE l_sql
                USING i_id_ref;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- do not return error            
    END reprocess_intf_events;

    /**
    * Notify inter-alert of referral update    
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_id_ref             Referral identifier
    * @param i_id_inst            Institution where the referral was changed
    *
    * @author  Ana Monteiro
    * @version 2.6
    * @since   2010-10-21   
    */
    PROCEDURE set_ref_update
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        i_id_inst    IN p1_external_request.id_inst_dest%TYPE
    ) IS
    BEGIN
        g_error := 'Call set_ref_update / ID_REF=' || i_id_ref || ' FLG_STATUS=' || i_flg_status || ' ID_INST=' ||
                   i_id_inst;
        IF i_flg_status IN (pk_ref_constant.g_p1_status_i,
                            pk_ref_constant.g_p1_status_t,
                            pk_ref_constant.g_p1_status_r,
                            pk_ref_constant.g_p1_status_s,
                            pk_ref_constant.g_p1_status_m,
                            pk_ref_constant.g_p1_status_a,
                            pk_ref_constant.g_p1_status_j,
                            pk_ref_constant.g_p1_status_v)
        THEN
        
            -- notify INTER-ALERT
            g_error := '---- UPDATE REFERRAL';
            pk_ia_event_referral.referral_update(i_id_external_request => i_id_ref, i_id_institution => i_id_inst);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_ref_update;

    /**
    * Check if referral has changed:    
    *  - Referral is issued to dest institution
    *  - Referral is canceled
    *  - Referral is blocked
    *  - Referral is unblocked
    *  - Referral is scheduled
    *  - Referral is declined by physician (including clinical director)
    *  - Referral is refused by physician
    *  - Referral is executed
    *  - Patient referral is missed
    *  - Referral is triaged
    *  - Clinical service change
    *  - Referral is sent to triage
    *  - Referral is declined bureaucratic
    *  - Referral schedule is canceled
    *  - Referral is approved/not approved by clinical director
    *  - Referral is resended
    * 
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_track_old_row      Referral tracking old rowtype (before update)
    * @param i_track_new_row      Referral tracking new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-05-15   
    */
    PROCEDURE set_tracking
    (
        i_event         IN NUMBER,
        i_track_old_row IN p1_tracking%ROWTYPE,
        i_track_new_row IN p1_tracking%ROWTYPE
    ) IS
        l_count           PLS_INTEGER;
        l_flg_prev_status p1_tracking.ext_req_status%TYPE;
        l_action_name     wf_workflow_action.internal_name%TYPE;
        l_prof            profissional;
    
        -- this function returns the last referral status in table p1_tracking
        FUNCTION get_previous_status(i_id_ref IN p1_tracking.id_external_request%TYPE)
            RETURN p1_tracking.ext_req_status%TYPE IS
        
            CURSOR c_track IS
                SELECT t.ext_req_status
                  FROM p1_tracking t
                 WHERE id_external_request = i_id_ref
                      -- this condition is needed
                   AND flg_type NOT IN (pk_ref_constant.g_tracking_type_u, pk_ref_constant.g_tracking_type_r)
                 ORDER BY t.dt_tracking_tstz DESC;
        
            l_prev_status p1_tracking.ext_req_status%TYPE;
        BEGIN
        
            OPEN c_track;
            FETCH c_track
                INTO l_prev_status;
            CLOSE c_track;
        
            RETURN l_prev_status;
        END get_previous_status;
    
    BEGIN
        g_error := 'Call set_tracking / EVENT=' || i_event || ' ID_REF=' || i_track_new_row.id_external_request ||
                         ' ID_TRACKING=' || i_track_new_row.id_tracking || ' ID_ACTION=' ||
                         i_track_new_row.id_workflow_action;
        l_action_name := pk_ref_constant.get_action_name(i_track_new_row.id_workflow_action);
        l_prof        := profissional(i_track_new_row.id_professional,
                                      i_track_new_row.id_institution,
                                      pk_ref_constant.g_id_soft_referral);
    
        g_error := 'CASE ' || l_action_name || ' / ' || g_error;
        CASE l_action_name
        
            WHEN pk_ref_constant.g_ref_action_i THEN
            
                -- checking old status
                g_error           := 'Call get_previous_status / ID_REF=' || i_track_new_row.id_external_request;
                l_flg_prev_status := get_previous_status(i_id_ref => i_track_new_row.id_external_request);
            
                g_error := g_error || ' / PREV_STATUS=' || l_flg_prev_status;
                IF l_flg_prev_status = pk_ref_constant.g_p1_status_b
                THEN
                
                    -------------------------
                    -- Resend the referral
                    -- INTER-ALERT
                    g_error := '---- RESEND REFERRAL';
                    pk_ia_event_referral.referral_resend(i_id_tracking    => i_track_new_row.id_tracking,
                                                         i_id_institution      => i_track_new_row.id_institution);
                
                    -- from v261 this event is registered as referral_resend (and not as referral_update)
                
                ELSIF l_flg_prev_status = pk_ref_constant.g_p1_status_v
                THEN
                    -------------------------
                    -- Attached informed consent - update referral (from v to i)
                    -- INTER-ALERT
                    g_error := '---- ATTACHED INFORMED CONSENT';
                    pk_ia_event_referral.referral_inf_consent_attached(i_id_tracking    => i_track_new_row.id_tracking,
                                                                       i_id_institution => i_track_new_row.id_institution);
                
                END IF;
                
                    -------------------------
                    -- referral is considered created (in SOA) only if it is the first time the referral is issued            
                    l_count := 0;
                        SELECT COUNT(1)
                          INTO l_count
                          FROM p1_tracking
                         WHERE --id_workflow_action = i_track_new_row.id_workflow_action -- not all referrals have id_workflow_action set
                 ext_req_status IN (pk_ref_constant.g_p1_status_i, pk_ref_constant.g_p1_status_j) -- issued or pending approval
                         AND flg_type = pk_ref_constant.g_tracking_type_s
                         AND id_external_request = i_track_new_row.id_external_request;
                
                    g_error := 'l_count=' || l_count;
                    IF l_count = 0
                    THEN
                    
                        -- INTER-ALERT
                        g_error := '---- CREATE REFERRAL';
                        pk_ia_event_referral.referral_create(i_id_external_request => i_track_new_row.id_external_request,
                                                             i_id_institution      => i_track_new_row.id_institution);
                    
                ELSE
                    -- this means that the referral was declined, and in this case, it must be sent an  update event when the referral is issued
                    g_error := 'Call pk_api_ref_event.set_ref_update / FLG_STATUS=' || i_track_new_row.ext_req_status;
                    pk_api_ref_event.set_ref_update(i_lang       => NULL,
                                                    i_prof       => profissional(i_track_new_row.id_professional,
                                                                                 i_track_new_row.id_institution,
                                                                                 0),
                                                    i_id_ref     => i_track_new_row.id_external_request,
                                                    i_flg_status => i_track_new_row.ext_req_status,
                                                    i_id_inst    => i_track_new_row.id_institution);
                    END IF;
                
            WHEN pk_ref_constant.g_ref_action_j THEN
                -- FOR_APPROVAL
                -------------------------
                -- referral is considered created if it is the first time the referral is sent to approval
                l_count := 0;
            
                BEGIN
                    SELECT COUNT(1)
                      INTO l_count
                      FROM p1_tracking
                     WHERE --id_workflow_action = i_track_new_row.id_workflow_action -- not all referrals have id_workflow_action set
                     ext_req_status = pk_ref_constant.g_p1_status_j
                     AND flg_type = pk_ref_constant.g_tracking_type_s
                     AND id_external_request = i_track_new_row.id_external_request;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count := 0;
                END;
            
                g_error := 'l_count=' || l_count;
                IF l_count = 0
                THEN
                
                    -- INTER-ALERT
                    g_error := '---- CREATE REFERRAL';
                    pk_ia_event_referral.referral_create(i_id_external_request => i_track_new_row.id_external_request,
                                                         i_id_institution      => i_track_new_row.id_institution);
                
                END IF;
            
            WHEN pk_ref_constant.g_ref_action_a THEN
                -------------------------
                -- Referral is triaged  
            
                l_count := 0;
            
                BEGIN
                    SELECT COUNT(1)
                      INTO l_count
                      FROM p1_tracking
                     WHERE --id_workflow_action = i_track_new_row.id_workflow_action -- not all referrals have id_workflow_action set
                     ext_req_status = pk_ref_constant.g_p1_status_a
                     AND flg_type = pk_ref_constant.g_tracking_type_s
                     AND id_external_request = i_track_new_row.id_external_request;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count := 0;
                END;
            
                g_error := 'l_count=' || l_count;
                IF l_count = 0
                THEN
                
                    -- INTER-ALERT
                    g_error := '---- TRIAGE REFERRAL';
                    pk_ia_event_referral.referral_triage(i_id_tracking    => i_track_new_row.id_tracking,
                                                         i_id_institution => i_track_new_row.id_institution);
                ELSE
                    -- INTER-ALERT
                    g_error := '---- RETRIAGE REFERRAL';
                    pk_ia_event_referral.referral_retriage(i_id_tracking    => i_track_new_row.id_tracking,
                                                           i_id_institution => i_track_new_row.id_institution);
                END IF;
            
                -- reprocess interface events
                reprocess_intf_events(i_prof => l_prof, i_id_ref => i_track_new_row.id_external_request);
            
            WHEN pk_ref_constant.g_ref_action_s THEN
                -------------------------
                -- Schedule referral
                -- INTER-ALERT
                g_error := '---- SCHEDULE REFERRAL';
                pk_ia_event_referral.referral_schedule(i_id_external_request => i_track_new_row.id_external_request,
                                                       i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_csh THEN
                -------------------------
                -- Referral schedule is cancelled
                -- INTER-ALERT
                g_error := '---- CANCEL REFERRAL SCHEDULE';
                pk_ia_event_referral.referral_unschedule(i_id_external_request => i_track_new_row.id_external_request,
                                                         i_id_institution      => i_track_new_row.id_institution);
            
                -- reprocess interface events
                reprocess_intf_events(i_prof => l_prof, i_id_ref => i_track_new_row.id_external_request);
            
            WHEN pk_ref_constant.g_ref_action_e THEN
                -- INTER-ALERT
                g_error := '---- EXECUTE REFERRAL';
                pk_ia_event_referral.referral_execute(i_id_external_request => i_track_new_row.id_external_request,
                                                      i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_f THEN
                -------------------------
                -- patient referral missed
                -- INTER-ALERT
                g_error := '---- MISSED REFERRAL';
                pk_ia_event_referral.referral_fail(i_id_external_request => i_track_new_row.id_external_request,
                                                   i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_t THEN
                -------------------------
                -- Referral is sent to triage                
                -- INTER-ALERT
                g_error := '---- SENT TO TRIAGE REFERRAL';
                pk_ia_event_referral.referral_send_to_triage(i_id_external_request => i_track_new_row.id_external_request,
                                                             i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_b THEN
                -------------------------
                -- Referral is declined bureaucratic
                -- INTER-ALERT
                g_error := '---- BUREAUCRATIC DECLINE REFERRAL';
                pk_ia_event_referral.referral_bureacratic_decline(i_id_tracking    => i_track_new_row.id_tracking,
                                                                  i_id_institution => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_d THEN
                -------------------------
                -- Medical decline
                -- INTER-ALERT
                g_error := '---- MEDICAL DECLINE';
                pk_ia_event_referral.referral_medical_decline(i_id_tracking    => i_track_new_row.id_tracking,
                                                              i_id_institution => i_track_new_row.id_institution);
            WHEN pk_ref_constant.g_ref_action_x THEN
                -------------------------
                -- Medical refusal
                -- INTER-ALERT
                g_error := '---- MEDICAL REFUSAL';
                pk_ia_event_referral.referral_refuse(i_id_tracking    => i_track_new_row.id_tracking,
                                                     i_id_institution => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_cs THEN
                -------------------------
                -- Clinical service change
                -- INTER-ALERT
                g_error := '---- CLINICAL SERVICE CHANGE';
                pk_ia_event_referral.referral_change_clin_service(i_id_external_request => i_track_new_row.id_external_request,
                                                                  i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_di THEN
                -------------------------
                -- Change institution
                -- INTER-ALERT
                g_error := '---- CHANGE INST';
                pk_ia_event_referral.referral_change_dest_instit(i_id_external_request => i_track_new_row.id_external_request,
                                                                 i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_c THEN
                -------------------------
                -- Cancel referral                        
                -- INTER-ALERT
                g_error := '---- CANCEL REFERRAL';
                pk_ia_event_referral.referral_cancel(i_id_tracking    => i_track_new_row.id_tracking,
                                                     i_id_institution => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_zdn THEN
            
                -------------------------
                -- Cancel referral cancellation
                -- INTER-ALERT
                g_error := '---- CANCEL REFERRAL CANCELLATION';
                pk_ia_event_referral.referral_req_cancel_deny(i_id_external_request => i_track_new_row.id_external_request,
                                                              i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_l THEN
                -------------------------
                -- Lock referral
                -- INTER-ALERT
                g_error := '---- LOCK REFERRAL';
                pk_ia_event_referral.referral_block(i_id_external_request => i_track_new_row.id_external_request,
                                                    i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_w THEN
                -------------------------
                -- Referral response
                -- INTER-ALERT
                g_error := '---- ANSWER REFERRAL';
                pk_ia_event_referral.referral_response_after_app(i_id_external_request => i_track_new_row.id_external_request,
                                                                 i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_z THEN
                -------------------------
                -- Referral request cancellation
                -- INTER-ALERT
                g_error := '---- REQUEST REFERRAL CANCELLATION';
                pk_ia_event_referral.referral_req_cancel(i_id_external_request => i_track_new_row.id_external_request,
                                                         i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_unl THEN
            
                -------------------------
                -- Unlock referral        
                -- INTER-ALERT
                g_error := '---- UNLOCK REFERRAL';
                pk_ia_event_referral.referral_unblock(i_id_external_request => i_track_new_row.id_external_request,
                                                      i_id_institution      => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_v THEN
            
                -------------------------
                -- Referral approved
                -- INTER-ALERT
                g_error := '---- REFERRAL APPROVED';
                pk_ia_event_referral.referral_approved(i_id_tracking    => i_track_new_row.id_tracking,
                                                       i_id_institution => i_track_new_row.id_institution);
        
            WHEN pk_ref_constant.g_ref_action_h THEN
            
                -------------------------
                -- Referral not approved
                -- INTER-ALERT
                g_error := '---- REFERRAL NOT APPROVED';
                pk_ia_event_referral.referral_not_approved(i_id_tracking    => i_track_new_row.id_tracking,
                                                           i_id_institution => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_dcl_r THEN
            
                -------------------------
                -- Referral declined to the registrar
                -- INTER-ALERT
                g_error := '---- REFERRAL DECLINED TO THE REGISTRAR';
                pk_ia_event_referral.referral_declined_to_register(i_id_tracking    => i_track_new_row.id_tracking,
                                                                   i_id_institution => i_track_new_row.id_institution);
            
            WHEN pk_ref_constant.g_ref_action_y THEN
            
                -------------------------
                -- Referral declined from the clinical director
                -- INTER-ALERT
                g_error := '---- REFERRAL DECLINED TO THE REGISTRAR';
                pk_ia_event_referral.referral_declined_clin_dir(i_id_tracking    => i_track_new_row.id_tracking,
                                                                i_id_institution => i_track_new_row.id_institution);
        
            ELSE
                NULL;
            
        END CASE;
    
        IF i_track_new_row.flg_type = pk_ref_constant.g_tracking_type_t
        THEN
        
            -- INTER-ALERT
            g_error := '---- Responsability Transf.';
            pk_ia_event_referral.referral_transfer_resp(i_id_tracking    => i_track_new_row.id_tracking,
                                                        i_id_institution      => i_track_new_row.id_institution);
        
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_tracking;

    /**
    * Check if referral has changed:
    *  - Documents associated to the referral request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_docext_old_row     Doc external old rowtype (before update)
    * @param i_docext_new_row     Doc external new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5.0.7
    * @since   2010-02-04
    */
    PROCEDURE set_doc_external
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_event          IN NUMBER,
        i_docext_old_row IN doc_external%ROWTYPE,
        i_docext_new_row IN doc_external%ROWTYPE
    ) IS
        ln_institution p1_external_request.id_inst_dest%TYPE;
        lv_status      p1_external_request.flg_status%TYPE;
    BEGIN
        g_error := 'Call set_doc_external / EVENT=' || i_event;
        IF i_docext_new_row.id_external_request IS NOT NULL -- doc attached to the referral
        THEN
        SELECT id_inst_dest, flg_status
          INTO ln_institution, lv_status
          FROM p1_external_request
         WHERE id_external_request = i_docext_new_row.id_external_request;
    
            IF i_docext_new_row.flg_status IN (pk_ref_constant.g_inactive, pk_ref_constant.g_active)
               AND ln_institution <> i_docext_new_row.id_institution
            THEN
            
                -- new document
            set_ref_update(i_lang       => i_lang,
                                             i_prof   => i_prof,
                                             i_id_ref => i_docext_new_row.id_external_request,
                           i_flg_status => lv_status,
                           i_id_inst    => ln_institution);
        END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_doc_external;

    /**
    * Check if referral has changed:
    *  - Image document associated to the referral request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_docimg_old_row     Doc image old rowtype (before update)
    * @param i_docimg_new_row     Doc image new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5.0.7
    * @since   2010-02-04
    */
    PROCEDURE set_doc_image
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_event          IN NUMBER,
        i_docimg_old_row IN doc_image%ROWTYPE,
        i_docimg_new_row IN doc_image%ROWTYPE
    ) IS
        ln_institution p1_external_request.id_inst_dest%TYPE;
        lv_status      p1_external_request.flg_status%TYPE;
        lv_p1          p1_external_request.id_external_request%TYPE;
    BEGIN
        g_error := 'Call set_doc_image / EVENT=' || i_event;
        SELECT e.id_external_request, e.id_inst_dest, e.flg_status
          INTO lv_p1, ln_institution, lv_status
          FROM p1_external_request e
          JOIN doc_external d
            ON (e.id_external_request = d.id_external_request)
         WHERE d.id_doc_external = i_docimg_new_row.id_doc_external
           AND d.flg_status = pk_ref_constant.g_active; -- document must be active
    
        IF (i_event = pk_ref_constant.g_update_event AND i_docimg_new_row.flg_status = pk_ref_constant.g_p1_status_i)
               OR i_event = pk_ref_constant.g_insert_event
            THEN
            
            -- new document
            set_ref_update(i_lang       => i_lang,
                           i_prof       => i_prof,
                           i_id_ref     => lv_p1,
                           i_flg_status => lv_status,
                           i_id_inst    => ln_institution);
            
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            NULL; -- doc attached to the patient (not the referral)
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_doc_image;

    /**
    * Check if referral has changed:
    *  - Document comments associated to the referral request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_doccom_old_row     Doc comments old rowtype (before update)
    * @param i_doccom_new_row     Doc comments new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5.0.7
    * @since   2010-02-04
    */
    PROCEDURE set_doc_comments
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_event          IN NUMBER,
        i_doccom_old_row IN doc_comments%ROWTYPE,
        i_doccom_new_row IN doc_comments%ROWTYPE
    ) IS
        ln_institution p1_external_request.id_inst_dest%TYPE;
        lv_status      p1_external_request.flg_status%TYPE;
        lv_p1          p1_external_request.id_external_request%TYPE;
    BEGIN
        g_error := 'Call set_doc_comments / EVENT=' || i_event;
        SELECT e.id_external_request, e.id_inst_dest, e.flg_status
          INTO lv_p1, ln_institution, lv_status
          FROM p1_external_request e
          JOIN doc_external d
            ON (e.id_external_request = d.id_external_request)
         WHERE d.id_doc_external = i_doccom_new_row.id_doc_external
           AND d.flg_status = pk_ref_constant.g_active; -- document must be active
    
        -- new document
        set_ref_update(i_lang       => i_lang,
                       i_prof       => i_prof,
                       i_id_ref     => lv_p1,
                       i_flg_status => lv_status,
                       i_id_inst    => ln_institution);
    
    EXCEPTION
        WHEN no_data_found THEN
            NULL; -- doc attached to the patient (not the referral)
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_doc_comments;

    /**
    * Check if patient has changed: 
    *  - Patient name, gender, dt_birth, address, location, zip_code and country
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_id_patient         Patient identifier that has changed
    * @param i_pat_old_row        Patient old rowtype (before update)
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-05-11   
    *
    */
    FUNCTION set_patient
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_PATIENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_patient;

    /**
    * Check changes on REF_DEST_INSTITUTION_SPEC
    * 
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_track_old_row      Referral old rowtype (before update)
    * @param i_track_new_row      Referral new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.6
    * @since   2013-02-19   
    */
    PROCEDURE set_ref_dest_institution_spec
    (
        i_event   IN NUMBER,
        i_old_row IN ref_dest_institution_spec%ROWTYPE,
        i_new_row IN ref_dest_institution_spec%ROWTYPE
    ) IS
        l_hist_row ref_dest_institution_spec_hist%ROWTYPE;
    BEGIN
        -- inserting the new values when insert or update ref_dest_institution_spec
        l_hist_row.id_dest_institution_spec      := i_new_row.id_dest_institution_spec;
        l_hist_row.id_dest_institution           := i_new_row.id_dest_institution;
        l_hist_row.id_speciality                 := i_new_row.id_speciality;
        l_hist_row.flg_available                 := i_new_row.flg_available;
        l_hist_row.flg_inside_ref_area           := i_new_row.flg_inside_ref_area;
        l_hist_row.id_dest_institution_spec_hist := seq_ref_dest_inst_spec_hist.nextval;
        l_hist_row.flg_ref_line                  := i_new_row.flg_ref_line;
    
        INSERT INTO ref_dest_institution_spec_hist
        VALUES l_hist_row;
    
    END set_ref_dest_institution_spec;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_ref_event;
/
