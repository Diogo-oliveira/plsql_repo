/*-- Last Change Revision: $Rev: 2026643 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_allergy IS
    /**
     * This function returns the institution market or the default value
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     *
     * @return   NUMBER
     *
     * @version  2.6.1.2
     * @since    09-Set-2011
     
     * @alter    Rui Duarte
    */
    FUNCTION prv_get_inst_market
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
        l_inst_market market.id_market%TYPE;
    BEGIN
        l_inst_market := nvl(n1 => pk_utils.get_institution_market(i_lang, i_prof.institution), n2 => g_default_market);
        RETURN l_inst_market;
    END;

    /**
     * This function returns the current revision id of an allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  i_pat_allergy     Patient Allergy ID
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @alter    Filipe Machado
    */

    FUNCTION get_revision
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_allergy IN pat_allergy.id_pat_allergy%TYPE
    ) RETURN NUMBER IS
    
        l_rev NUMBER;
    BEGIN
    
        SELECT pa.revision
          INTO l_rev
          FROM pat_allergy pa
         WHERE pa.id_pat_allergy = i_pat_allergy;
    
        RETURN l_rev;
    
    END get_revision;

    /**
     * This function returns the next revision ID of an allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  i_pat_allergy        Patient allergy ID
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @alter    Filipe Machado
    */
    FUNCTION set_next_revision
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_allergy IN pat_allergy.id_pat_allergy%TYPE
    ) RETURN NUMBER IS
    
        l_revision NUMBER;
    BEGIN
    
        SELECT revision + 1
          INTO l_revision
          FROM pat_allergy pa
         WHERE pa.id_pat_allergy = i_pat_allergy;
    
        RETURN l_revision;
    
    END set_next_revision;

    PROCEDURE get_aism_cfg_vars
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_market OUT institution.id_market%TYPE,
        o_inst   OUT institution.id_institution%TYPE,
        o_soft   OUT software.id_software%TYPE
    ) IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_AISM_CFG_VARS';
        --
        l_inst_market institution.id_market%TYPE;
    BEGIN
        g_error := 'Getting the default market';
        pk_alertlog.log_debug(g_error);
        l_inst_market := prv_get_inst_market(i_lang, i_prof);
    
        BEGIN
            g_error := 'GET ALLERGY_INST_SOFT_MARKET CFG_VARS';
            pk_alertlog.log_debug(g_error);
            SELECT id_market, id_institution, id_software
              INTO o_market, o_inst, o_soft
              FROM (SELECT aism.id_market,
                           aism.id_institution,
                           aism.id_software,
                           row_number() over(ORDER BY decode(aism.id_market, l_inst_market, 1, 2), --
                           decode(aism.id_institution, i_prof.institution, 1, 2), --
                           decode(aism.id_software, i_prof.software, 1, 2)) line_number
                      FROM allergy_inst_soft_market aism
                     WHERE aism.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND aism.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND aism.id_market IN (pk_alert_constant.g_id_market_all, l_inst_market))
             WHERE line_number = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_market := l_inst_market;
                o_inst   := i_prof.institution;
                o_soft   := i_prof.software;
        END;
    END get_aism_cfg_vars;
    /**
     * This function returns the episodes that belongs to a visit
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  i_episode            Episode ID
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @alter    Filipe Machado
    */

    FUNCTION get_visit_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number IS
    
        l_epis_visit table_number := table_number();
    
    BEGIN
    
        SELECT a.id_episode
          BULK COLLECT
          INTO l_epis_visit
          FROM episode a
         WHERE a.id_visit = (SELECT e.id_visit
                               FROM episode e
                              WHERE e.id_episode = i_episode)
         ORDER BY a.dt_creation DESC;
    
        RETURN l_epis_visit;
    
    END get_visit_episodes;

    /**
     * This function returns the episodes that belongs to a patient
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  i_episode            Episode ID
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @alter    Filipe Machado
    */

    FUNCTION get_all_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN table_number IS
    
        l_epis table_number := table_number();
    
    BEGIN
    
        SELECT a.id_episode
          BULK COLLECT
          INTO l_epis
          FROM episode a
         WHERE a.id_patient = i_patient
         ORDER BY a.dt_creation DESC;
    
        RETURN l_epis;
    
    END get_all_episodes;

    /**
     * This function returns the scope of episodes
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     * @param    IN  i_episode         Episode ID
     * @param    IN  i_flg_filter      Flag filter
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.3
     * @since    22-Nov-2010
     * @created  Filipe Machado
    */

    FUNCTION get_scope
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2
    ) RETURN table_number IS
    
        l_epis     table_number := table_number();
        l_epis_all table_number := table_number();
    
    BEGIN
    
        -- get all episodes that belongs to the patient    
        l_epis_all := get_all_episodes(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
        CASE
            WHEN i_flg_filter = g_rep_type_episode THEN
                l_epis.extend(1);
                l_epis(l_epis.count) := nvl(i_episode, 1);
            
            WHEN i_flg_filter = g_rep_type_visit THEN
                -- get all episodes that belongs to current visit
                l_epis := get_visit_episodes(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
            
            WHEN i_flg_filter = g_rep_type_patient THEN
                l_epis := l_epis_all;
            
            ELSE
                l_epis := l_epis_all;
        END CASE;
    
        RETURN l_epis;
    
    END get_scope;

    /**
     * This function cancels a patient allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  id_cancel_reason     Cancel reason ID
     * @param    IN  cancel_notes         Cancel notes
     * @param    IN  i_id_pat_allergy     Patient Allergy ID
     * @param    IN  o_error              Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
     *
     * @version  2.6.0
     * @since    2010-Mar-11
     * @alter    Jos?Brito
    */
    FUNCTION call_cancel_allergy
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_cancel_reason       IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes           IN pat_allergy.cancel_notes%TYPE,
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_message debug_msg;
        l_episode episode.id_episode%TYPE;
        l_rowids  table_varchar;
    
    BEGIN
        l_message := 'CANCEL_ALLERGY - CALL PK_ALLERGY.SET_ALLERGY_HISTORY';
        IF (NOT pk_allergy.set_allergy_history(i_lang, i_id_pat_allergy, o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        ts_pat_allergy.upd(id_pat_allergy_in         => i_id_pat_allergy,
                           flg_status_in             => g_pat_allergy_flg_cancelled,
                           cancel_notes_in           => i_cancel_notes,
                           id_cancel_reason_in       => i_id_cancel_reason,
                           id_prof_write_in          => i_prof.id,
                           dt_pat_allergy_tstz_in    => current_timestamp,
                           flg_cda_reconciliation_in => i_flg_cda_reconciliation,
                           rows_out                  => l_rowids);
    
        -- CHAMAR A FUNCAO UPDATE DO PACKAGE T_DATA_GOV_MNT
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_message := 'CANCEL_ALLERGY - SELECT INTO STATEMENT';
        BEGIN
        
            SELECT pa.id_episode
              INTO l_episode
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_episode := 0;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_CANCEL_ALLERGY',
                                              o_error);
            RETURN FALSE;
    END call_cancel_allergy;

    /**
    * 
    * Verify if an allergy was reviwed on episode
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  id record area (id_pat_allergy)
    *
    * @author                  
    * @since                   2010-OCT-26
    * @version                 v2.5.1.2
    * @reason                  ALERT-127537
    */
    FUNCTION check_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE
    ) RETURN NUMBER IS
        l_count PLS_INTEGER;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM review_detail rd
         WHERE rd.id_episode = i_id_episode
           AND rd.id_record_area = i_id_record_area
           AND rd.flg_context = g_allergy_review_context
           AND rownum = 1;
    
        IF l_count > 0
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    
    END check_review;

    /**
     * This function is can be used to CaNCEL a patient's allergy.
     *
     * @param    IN  i_lang                     Language ID
     * @param    IN  i_prof                     Professional structure
     * @param    IN  i_id_pat_allergy           Patient Allergy ID
     * @param    IN  id_cancel_reason           Cancel reason ID
     * @param    IN  cancel_notes               Cancel notes
     * @param    IN  i_flg_cda_reconciliation   Identifies allergy record origin Y- CDA, N-PFH
     * @param    IN  o_error                    Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.4.0.3
     * @since    2014-May-27
     * @author   Gisela Couto
    */
    FUNCTION cancel_allergy
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_cancel_reason       IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes           IN pat_allergy.cancel_notes%TYPE,
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_message debug_msg;
    BEGIN
        IF NOT (call_cancel_allergy(i_lang                   => i_lang,
                                    i_prof                   => i_prof,
                                    i_id_pat_allergy         => i_id_pat_allergy,
                                    i_id_cancel_reason       => i_id_cancel_reason,
                                    i_cancel_notes           => i_cancel_notes,
                                    i_flg_cda_reconciliation => i_flg_cda_reconciliation,
                                    o_error                  => o_error))
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /**
     * This function cancels a patient allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  id_cancel_reason     Cancel reason ID
     * @param    IN  cancel_notes         Cancel notes
     * @param    IN  i_id_pat_allergy     Patient Allergy ID
     * @param    IN  o_error              Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION cancel_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN pat_allergy.id_pat_allergy%TYPE,
        i_id_cancel_reason IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_message debug_msg;
        l_episode episode.id_episode%TYPE;
        l_rowids  table_varchar;
    
    BEGIN
        l_message := 'CANCEL_ALLERGY - CALL PK_ALLERGY.SET_ALLERGY_HISTORY';
        IF (NOT pk_allergy.set_allergy_history(i_lang, i_id_pat_allergy, o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        ts_pat_allergy.upd(id_pat_allergy_in      => i_id_pat_allergy,
                           flg_status_in          => g_pat_allergy_flg_cancelled,
                           cancel_notes_in        => i_cancel_notes,
                           id_cancel_reason_in    => i_id_cancel_reason,
                           id_prof_write_in       => i_prof.id,
                           dt_pat_allergy_tstz_in => current_timestamp,
                           rows_out               => l_rowids);
    
        -- CHAMAR A FUNCAO UPDATE DO PACKAGE T_DATA_GOV_MNT
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_message := 'CANCEL_ALLERGY - SELECT INTO STATEMENT';
        BEGIN
        
            SELECT pa.id_episode
              INTO l_episode
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_episode := 0;
        END;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_allergy;

    FUNCTION cancel_allergy_intf
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN table_number,
        i_id_cancel_reason IN table_number,
        i_cancel_notes     IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_message debug_msg;
        l_episode episode.id_episode%TYPE;
        l_rowids  table_varchar;
    
    BEGIN
        l_message := 'CANCEL_ALLERGY - CALL PK_ALLERGY.SET_ALLERGY_HISTORY';
    
        FOR i IN 1 .. i_id_pat_allergy.count
        LOOP
        
            IF (NOT pk_allergy.set_allergy_history(i_lang, i_id_pat_allergy(i), o_error))
            THEN
                RAISE l_exception;
            END IF;
        
            ts_pat_allergy.upd(id_pat_allergy_in      => i_id_pat_allergy(i),
                               flg_status_in          => g_pat_allergy_flg_cancelled,
                               cancel_notes_in        => i_cancel_notes(i),
                               id_cancel_reason_in    => i_id_cancel_reason(i),
                               id_prof_write_in       => i_prof.id,
                               dt_pat_allergy_tstz_in => current_timestamp,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO UPDATE DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            l_message := 'CANCEL_ALLERGY - SELECT INTO STATEMENT';
            BEGIN
            
                SELECT pa.id_episode
                  INTO l_episode
                  FROM pat_allergy pa
                 WHERE pa.id_pat_allergy = i_id_pat_allergy(i);
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_episode := 0;
            END;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALLERGY_INTF',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_allergy_intf;

    /**
    * This function cancels a patient allergy
    *
    * @param    IN  i_lang               Language ID
    * @param    IN  i_prof               Professional structure
    * @param    IN  id_cancel_reason     Cancel reason ID
    * @param    IN  cancel_notes         Cancel notes
    * @param    IN  i_id_pat_allergy     Patient Allergy ID
    * @param    IN  o_error              Error structure
    *
    * @return   BOOLEAN
    *
    * @version  2.5.1.2
    * @since    27-Oct-2010
    * @author   Filipe Machado
    */
    FUNCTION cancel_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN table_number,
        i_id_cancel_reason IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_error VARCHAR2(200 CHAR);
    BEGIN
    
        l_error := 'CALL CANCEL ALLERGY';
        pk_alertlog.log_debug(l_error);
    
        FOR i IN 1 .. i_id_pat_allergy.count
        LOOP
            IF NOT call_cancel_allergy(i_lang                   => i_lang,
                                       i_prof                   => i_prof,
                                       i_id_pat_allergy         => i_id_pat_allergy(i),
                                       i_id_cancel_reason       => i_id_cancel_reason,
                                       i_cancel_notes           => i_cancel_notes,
                                       i_flg_cda_reconciliation => pk_alert_constant.g_no,
                                       o_error                  => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_allergy;

    /**
     * This function cancels a patient allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  i_id_unawareness     Unawareness Allergy ID
     * @param    IN  i_cancel_notes       Cancel notes
     * @param    OUT o_error              Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-21
     * @author   Thiago Brito
    */
    FUNCTION cancel_unawareness
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_unawareness   IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_id_cancel_reason IN pat_allergy_unawareness.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy_unawareness.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar := table_varchar();
    BEGIN
    
        g_error := 'ts_pat_allergy_unawareness.upd';
        ts_pat_allergy_unawareness.upd(flg_status_in        => g_pat_allergy_flg_cancelled,
                                       id_prof_cancel_in    => i_prof.id,
                                       cancel_notes_in      => i_cancel_notes,
                                       cancel_notes_nin     => FALSE,
                                       dt_cancel_in         => current_timestamp,
                                       id_cancel_reason_in  => i_id_cancel_reason,
                                       id_cancel_reason_nin => FALSE,
                                       where_in             => 'id_pat_allergy_unawareness = ' || i_id_unawareness,
                                       rows_out             => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_UNAWARENESS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_unawareness;

    /**
     * This function verifies if an allergy is or is not a drug allergy.
     *
     * @param    IN  i_id_allergy     Allergy ID
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-21
     * @author   Thiago Brito
    */
    FUNCTION is_drug_allergy(i_id_allergy IN allergy.id_allergy%TYPE) RETURN BOOLEAN IS
    
        l_is_drug_allergy PLS_INTEGER := 0;
    
    BEGIN
    
        BEGIN
        
            SELECT COUNT(a.id_allergy)
              INTO l_is_drug_allergy
              FROM allergy_inst_soft_market a
             WHERE a.id_allergy_parent IN (g_drug_class_id_allergy, g_drug_id_allergy, g_drug_com_id_allergy)
               AND a.id_allergy = i_id_allergy;
        
            IF (l_is_drug_allergy = 0)
            THEN
                RETURN FALSE;
            ELSE
                RETURN TRUE;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END is_drug_allergy;

    /********************************************************
    * This Function validates if an allergy is a drug allergy 
    *
    * @param    IN  i_id_allergy     Allergy ID
    * @return   varchar2 
    *
    * 'M' -identifies that is a drug allergy
    * 'O'- Identifies that is otheer kind of allergy(not a drug one)
    *
    * @author   Pedro Fernandes
    * @version  2.6.1.2 
    * @since    27-07-2011
    *
    */
    FUNCTION get_flg_is_drug_allergy(i_id_allergy IN allergy.id_allergy%TYPE) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(1);
    BEGIN
    
        IF is_drug_allergy(i_id_allergy => i_id_allergy)
        THEN
            l_ret := 'M';
        ELSE
            l_ret := 'O';
        END IF;
        RETURN l_ret;
    END get_flg_is_drug_allergy;

    /**
     * This function returns the number of active allergies related with
     * a patient.
     *
     * @param    IN  i_lang      Language ID
     * @param    IN  i_prof      Professional structure
     * @param    IN  i_patient   Patient ID
     * @param    IN  o_number    Quantity of known allergies
     * @param    IN  o_error     Error structure
     *
     * @return   INTEGER         Number of active allergies related with a patient
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_count_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_number  OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_number := get_count_allergy(i_lang, i_patient, o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_COUNT_ALLERGY',
                                                     o_error);
    END get_count_allergy;

    /**
     * This function returns the number of active allergies related with
     * a patient.
     *
     * @param    IN  i_lang      Language ID
     * @param    IN  i_prof      Professional structure
     * @param    IN  i_patient   Patient ID
     * @param    IN  o_error     Error structure
     *
     * @return   INTEGER         Number of active allergies related with a patient
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_count_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN PLS_INTEGER IS
        l_number_of_allergies PLS_INTEGER;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_number_of_allergies
          FROM pat_allergy pa
         WHERE pa.id_patient = i_patient
           AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved);
    
        RETURN l_number_of_allergies;
    
    END get_count_allergy;

    /**
     * This function returns the detail of an allergy for the review screen.
     * 
     * @param    IN     i_lang             Language ID
     * @param    IN     i_prof             Professional structure
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    OUT    o_allergy_detail   Detail of an allergy
     * @param    IN OUT o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-28
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_rev_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_pat_allergy    IN patient.id_patient%TYPE,
        o_allergy_detail OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_allergy_detail';
        OPEN o_allergy_detail FOR
            SELECT id_pat_allergy,
                   flg_status,
                   dt_pat_allergy,
                   dt_pat_allergy_tstz,
                   prof_name,
                   prof_spec,
                   prof_specialty,
                   allergen,
                   flg_type,
                   reaction,
                   year_of_onset,
                   status,
                   severity,
                   symptoms,
                   aproved,
                   notes,
                   id_cancel_reason,
                   cancel_reason,
                   cancel_notes,
                   flg_update,
                   desc_update,
                   revision,
                   flg_edit,
                   desc_edit,
                   flg_review,
                   review_notes
              FROM ( -- ALLERGY
                    SELECT pa.id_pat_allergy,
                            pa.flg_status,
                            pk_date_utils.date_char_tsz(i_lang,
                                                        pa.dt_pat_allergy_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_pat_allergy,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) prof_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             pa.id_prof_write,
                                                             pa.dt_pat_allergy_tstz,
                                                             pa.id_episode) prof_spec,
                            pk_prof_utils.get_prof_speciality(i_lang, i_prof) prof_specialty,
                            decode(pa.id_allergy,
                                   NULL,
                                   pa.desc_allergy,
                                   (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                                      FROM allergy a
                                     WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                            pa.flg_type,
                            pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS reaction,
                            pa.year_begin AS year_of_onset,
                            pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang) AS status,
                            pa.id_allergy_severity,
                            (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                               FROM allergy_severity s
                              WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                            get_symptoms(i_lang, pa.id_pat_allergy) symptoms,
                            decode(pa.flg_aproved,
                                   g_unawareness_outdated,
                                   pa.desc_aproved,
                                   pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) aproved,
                            pa.notes,
                            pa.dt_pat_allergy_tstz,
                            pa.id_cancel_reason,
                            decode(pa.id_cancel_reason,
                                   NULL,
                                   NULL,
                                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                                      FROM cancel_reason cr
                                     WHERE cr.id_cancel_reason = pa.id_cancel_reason)) cancel_reason,
                            pa.cancel_notes,
                            decode(pa.flg_status, g_pat_allergy_flg_cancelled, g_documented, pk_alert_constant.g_cancelled) flg_update,
                            decode(pa.flg_status,
                                   g_pat_allergy_flg_cancelled,
                                   pk_message.get_message(i_lang, 'ALLERGY_M040'),
                                   decode(pa.flg_edit,
                                          NULL,
                                          decode(pa.desc_edit,
                                                 NULL,
                                                 pk_message.get_message(i_lang, 'ALLERGY_M018'),
                                                 pk_message.get_message(i_lang, 'ALLERGY_M052')),
                                          pk_message.get_message(i_lang, 'ALLERGY_M018'))) desc_update,
                            revision,
                            pa.flg_edit,
                            decode(pa.flg_edit,
                                   g_unawareness_outdated,
                                   pa.desc_edit,
                                   pk_sysdomain.get_domain(g_pat_allergy_edit, pa.flg_edit, i_lang)) desc_edit,
                            pk_alert_constant.g_no flg_review,
                            NULL review_notes
                      FROM pat_allergy pa
                     WHERE pa.id_pat_allergy = i_pat_allergy)
             ORDER BY dt_pat_allergy_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_REV_INFO',
                                                     o_error);
        
    END get_allergy_rev_info;

    /**
     * This function is used to get the list of allergy by patient
     * to be used by the viewer
     *
     * @param    IN     i_lang       Language ID
     * @param    IN     i_prof       Professional structure
     * @param    IN     i_patient    Patient ID
     * @param    IN     i_episode    Episode ID
     * @param    OUT    o_allergy    Current allergies cursor
     * @param    OUT    o_error      Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Nov-02
     * @author   Thiago Brito
    */
    FUNCTION get_viewer_allergy_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN get_allergy_lst(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_episode     => i_episode,
                               i_pat_allergy => NULL,
                               o_allergies   => o_allergy,
                               o_error       => o_error);
    END get_viewer_allergy_list;

    --

    FUNCTION get_unawareness_allergies
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_status      IN VARCHAR2 DEFAULT g_unawareness_active,
        i_flg_filter  IN VARCHAR2,
        i_dt_begin    IN VARCHAR2,
        i_dt_end      IN VARCHAR2,
        o_unawareness OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_documented          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                               i_code_mess => 'ALLERGY_M026');
        l_cancel_reason_label CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                               i_code_mess => 'ALLERGY_M038');
        l_notes_label         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                               i_code_mess => 'ALLERGY_M025');
        l_cancel_notes_label  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                               i_code_mess => 'COMMON_M073');
    
        l_epis table_number := table_number();
    
    BEGIN
    
        -- get scope of episodes
        l_epis := get_scope(i_lang       => i_lang,
                            i_prof       => i_prof,
                            i_patient    => i_patient,
                            i_episode    => i_episode,
                            i_flg_filter => i_flg_filter);
    
        OPEN o_unawareness FOR
            SELECT pau.id_allergy_unawareness,
                   pau.id_pat_allergy_unawareness,
                   pau.id_episode,
                   pau.flg_status,
                   pk_sysdomain.get_domain(g_pat_allergy_unaware, pau.flg_status, i_lang) AS desc_status,
                   pau.dt_creation AS date_creation,
                   pk_date_utils.date_send_tsz(i_lang, pau.dt_creation, i_prof) AS date_creation_rep,
                   pk_date_utils.date_char_tsz(i_lang, pau.dt_cancel, i_prof.institution, i_prof.software) AS dt_creation,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pau.id_prof_cancel) AS prof_nick_name,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(pau.id_professional,
                                                                  i_prof.institution,
                                                                  i_prof.software)) AS desc_specialty,
                   decode(i_episode, pau.id_episode, NULL, l_documented) AS msg_previous_episode,
                   (SELECT pk_translation.get_translation(i_lang, au.code_unawareness_type)
                      FROM allergy_unawareness au
                     WHERE au.id_allergy_unawareness = pau.id_allergy_unawareness) AS title,
                   l_notes_label AS msg_notes,
                   pau.notes,
                   l_cancel_reason_label AS msg_cancel_reason,
                   pau.id_cancel_reason,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = pau.id_cancel_reason) AS cancel_reason_desc,
                   pau.cancel_notes cancel_notes,
                   l_cancel_notes_label AS msg_notes_cancel,
                   decode(i_episode, pau.id_episode, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_previous_episode
              FROM pat_allergy_unawareness pau
             WHERE pau.id_patient = i_patient
               AND pau.flg_status = g_unawareness_cancelled
               AND i_status != g_unawareness_active
               AND nvl(pau.id_episode, nvl(i_episode, 1)) IN
                   (SELECT *
                      FROM TABLE(l_epis))
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof) >= pau.dt_creation OR i_dt_begin IS NULL)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof) <= pau.dt_creation OR i_dt_end IS NULL)
            UNION ALL
            SELECT pau.id_allergy_unawareness,
                   pau.id_pat_allergy_unawareness,
                   pau.id_episode,
                   decode(i_status, g_unawareness_active, g_unawareness_active, g_unawareness_outdated) status,
                   pk_sysdomain.get_domain(g_pat_allergy_unaware,
                                           decode(i_status,
                                                  g_unawareness_active,
                                                  g_unawareness_active,
                                                  g_unawareness_outdated),
                                           i_lang) AS desc_status,
                   pau.dt_creation AS date_creation,
                   pk_date_utils.date_send_tsz(i_lang, pau.dt_creation, i_prof) AS date_creation_rep,
                   pk_date_utils.date_char_tsz(i_lang, pau.dt_creation, i_prof.institution, i_prof.software) AS dt_creation,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pau.id_professional) AS prof_nick_name,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(pau.id_professional,
                                                                  i_prof.institution,
                                                                  i_prof.software)) AS desc_specialty,
                   decode(i_episode, pau.id_episode, NULL, l_documented) AS msg_previous_episode,
                   (SELECT pk_translation.get_translation(i_lang, au.code_unawareness_type)
                      FROM allergy_unawareness au
                     WHERE au.id_allergy_unawareness = pau.id_allergy_unawareness) AS title,
                   l_notes_label AS msg_notes,
                   pau.notes,
                   l_cancel_reason_label AS msg_cancel_reason,
                   NULL id_cancel_reason,
                   NULL cancel_reason_desc,
                   pau.cancel_notes cancel_notes,
                   l_cancel_notes_label AS msg_notes_cancel,
                   decode(i_episode, pau.id_episode, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_previous_episode
              FROM pat_allergy_unawareness pau
             WHERE pau.id_patient = i_patient
               AND instr(i_status, pau.flg_status) > 0
               AND pau.flg_status <> g_unawareness_cancelled
               AND nvl(pau.id_episode, nvl(i_episode, 1)) IN
                   (SELECT *
                      FROM TABLE(l_epis))
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof) >= pau.dt_creation OR i_dt_begin IS NULL)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof) <= pau.dt_creation OR i_dt_end IS NULL)
            
             ORDER BY flg_previous_episode ASC, id_pat_allergy_unawareness DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => NULL,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_UNAWARENESS_ALLERGIES',
                                                     o_error    => o_error);
    END get_unawareness_allergies;
    --
    FUNCTION get_unawareness_active
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_filter         IN VARCHAR2,
        i_dt_begin           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_unawareness_active OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_unawareness_allergies(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_patient     => i_patient,
                                         i_episode     => i_episode,
                                         i_status      => g_unawareness_active,
                                         i_flg_filter  => i_flg_filter,
                                         i_dt_begin    => i_dt_begin,
                                         i_dt_end      => i_dt_end,
                                         o_unawareness => o_unawareness_active,
                                         o_error       => o_error);
    END get_unawareness_active;
    --
    FUNCTION get_unawareness_outdated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_filter           IN VARCHAR2,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_unawareness_allergies(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_patient     => i_patient,
                                         i_episode     => i_episode,
                                         i_status      => g_unawareness_outdated || ', ' || g_pat_allergy_flg_cancelled,
                                         i_flg_filter  => i_flg_filter,
                                         i_dt_begin    => i_dt_begin,
                                         i_dt_end      => i_dt_end,
                                         o_unawareness => o_unawareness_outdated,
                                         o_error       => o_error);
    END get_unawareness_outdated;
    --

    FUNCTION get_dt_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_year_begin  IN NUMBER,
        i_month_begin IN NUMBER,
        i_day_begin   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_desc_dt sys_message.desc_message%TYPE;
    
    BEGIN
        SELECT decode(i_year_begin,
                      '',
                      '',
                      decode(i_month_begin,
                             '',
                             to_char(i_year_begin),
                             decode(i_day_begin,
                                    '',
                                    pk_date_utils.get_month_year(i_lang,
                                                                 i_prof,
                                                                 to_date(i_year_begin || lpad(i_month_begin, 2, '0'),
                                                                         'YYYYMM')),
                                    pk_date_utils.dt_chr(i_lang,
                                                         to_date(i_year_begin || lpad(i_month_begin, 2, '0') ||
                                                                 lpad(i_day_begin, 2, '0'),
                                                                 'YYYYMMDD'),
                                                         i_prof)))) desc_dt
          INTO l_desc_dt
          FROM dual;
    
        RETURN l_desc_dt;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_str;

    FUNCTION get_allergy_lst_rep
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_filter     IN VARCHAR2,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_allergies_hist OUT pk_types.cursor_type,
        o_allergies_rev  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        --
        l_current_epis_desc  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                              i_code_mess => 'ALLERGY_T009');
        l_previous_epis_desc CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                              i_code_mess => 'ALLERGY_T003');
    
        l_with_notes CONSTANT sys_message.desc_message%TYPE := '(' ||
                                                               lower(pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => 'COMMON_M008')) || ')';
        l_free_text  CONSTANT sys_message.desc_message%TYPE := '(' ||
                                                               lower(pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => 'TOOLS_T014')) || ')';
    
        l_viewer_cat_desc CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                           i_code_mess => 'COMMON_M036');
        l_epis table_number := table_number();
    
        l_label_create       VARCHAR2(30 CHAR);
        l_label_edit         VARCHAR2(30 CHAR);
        l_label_review       VARCHAR2(30 CHAR);
        l_label_createreview VARCHAR2(30 CHAR);
        l_label_editreview   VARCHAR2(30 CHAR);
    
    BEGIN
    
        l_label_create       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M015');
        l_label_edit         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M016');
        l_label_review       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M018');
        l_label_createreview := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M013');
        l_label_editreview   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M014');
    
        -- get scope of episodes
        l_epis := get_scope(i_lang       => i_lang,
                            i_prof       => i_prof,
                            i_patient    => i_patient,
                            i_episode    => i_episode,
                            i_flg_filter => i_flg_filter);
    
        l_message := 'OPEN O_ALLERGIES';
        OPEN o_allergies FOR
            SELECT pa.id_allergy,
                   pa.id_pat_allergy,
                   pa.id_episode,
                   l_current_epis_desc AS desc_epis,
                   decode(pa.id_allergy,
                          NULL,
                          pa.desc_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                             FROM allergy a
                            WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                   pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS type_reaction,
                   
                   pa.year_begin AS year_begin,
                   pa.month_begin AS month_begin,
                   pa.day_begin AS day_begin,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) start_date,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) AS dt_pat_allergy,
                   get_flg_is_drug_allergy(i_id_allergy => pa.id_allergy) allergy_type,
                   pa.flg_type,
                   pa.flg_status,
                   decode(pa.flg_status,
                          g_pat_allergy_flg_active,
                          1,
                          g_pat_allergy_flg_passive,
                          2,
                          g_pat_allergy_flg_cancelled,
                          3,
                          4) rank,
                   get_status_string(pa.flg_status,
                                     pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status_string,
                   pa.id_allergy_severity,
                   (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                      FROM allergy_severity s
                     WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                   get_status_color(pa.flg_status) AS status_color,
                   decode(pa.id_allergy, NULL, decode(pa.desc_allergy, NULL, NULL, l_free_text), NULL) AS free_text,
                   decode(pa.notes, NULL, NULL, l_with_notes) AS with_notes,
                   decode(pa.cancel_notes, NULL, NULL, l_with_notes) AS cancelled_with_notes,
                   -- Thiago Brito, 02-11-2009 - Needed for the new episodes screen on Viewer
                   decode(pa.notes, NULL, NULL, l_with_notes) AS title_notes,
                   
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pa.id_prof_write, pa.dt_pat_allergy_tstz, i_episode) AS desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) AS nick_name,
                   upper(pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status,
                   decode(nvl(pa.year_begin, 0), 0, pa.year_begin) AS hour_target,
                   nvl(pa.flg_type, 'N/A') AS viewer_category,
                   pa.id_prof_write AS viewer_id_prof,
                   pa.id_episode AS viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) AS viewer_date,
                   pa.notes,
                   get_symptoms(i_lang, pa.id_pat_allergy) symptoms,
                   g_flg_allergy flg_type_rep,
                   g_flg_allergy flg_source_rep,
                   pa.id_cancel_reason,
                   decode(pa.id_cancel_reason,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                             FROM cancel_reason cr
                            WHERE cr.id_cancel_reason = pa.id_cancel_reason)) cancel_reason,
                   pa.cancel_notes,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_pat_allergy_rev_tstz,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) AS dt_pat_allergy_rev,
                   pa.revision revision,
                   decode(pa.flg_aproved,
                          g_unawareness_outdated,
                          pa.desc_aproved,
                          pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) approved,
                   rd.revision revision_rep,
                   rd.id_episode id_episode_rev,
                   rd.flg_auto,
                   decode(rd.flg_auto,
                          pk_alert_constant.g_yes,
                          decode(rd.revision, 1, l_label_createreview, l_label_editreview),
                          pk_alert_constant.g_no,
                          '',
                          NULL,
                          '') label_review,
                   rd.review_notes
              FROM pat_allergy pa
              LEFT JOIN review_detail rd
                ON (rd.id_record_area = pa.id_pat_allergy AND pa.revision = rd.revision AND
                   rd.flg_auto = pk_alert_constant.g_yes AND rd.flg_context = g_allergy_review_context)
            
             WHERE pa.id_patient = i_patient
               AND pa.id_episode IN (SELECT *
                                       FROM TABLE(l_epis))
               AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_cancelled, g_pat_allergy_flg_passive)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof) >= pa.dt_pat_allergy_tstz OR
                   i_dt_begin IS NULL)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof) <= pa.dt_pat_allergy_tstz OR i_dt_end IS NULL)
             ORDER BY pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => g_pat_allergy_type, i_val => pa.flg_type),
                      rank,
                      allergen ASC;
    
        l_message := 'OPEN O_ALLERGIES_HIST';
        OPEN o_allergies_hist FOR
            SELECT pa.id_allergy,
                   pa.id_pat_allergy,
                   pa.id_episode,
                   l_current_epis_desc AS desc_epis,
                   decode(pa.id_allergy,
                          NULL,
                          pa.desc_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                             FROM allergy a
                            WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                   pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS type_reaction,
                   
                   pa.year_begin AS year_begin,
                   pa.month_begin AS month_begin,
                   pa.day_begin AS day_begin,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) start_date,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) AS dt_pat_allergy,
                   get_flg_is_drug_allergy(i_id_allergy => pa.id_allergy) allergy_type,
                   pa.flg_type,
                   pa.flg_status,
                   decode(pa.flg_status,
                          g_pat_allergy_flg_active,
                          1,
                          g_pat_allergy_flg_passive,
                          2,
                          g_pat_allergy_flg_cancelled,
                          3,
                          4) rank,
                   get_status_string(pa.flg_status,
                                     pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status_string,
                   pa.id_allergy_severity,
                   (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                      FROM allergy_severity s
                     WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                   get_status_color(pa.flg_status) AS status_color,
                   decode(pa.id_allergy, NULL, decode(pa.desc_allergy, NULL, NULL, l_free_text), NULL) AS free_text,
                   decode(pa.notes, NULL, NULL, l_with_notes) AS with_notes,
                   decode(pa.cancel_notes, NULL, NULL, l_with_notes) AS cancelled_with_notes,
                   -- Thiago Brito, 02-11-2009 - Needed for the new episodes screen on Viewer
                   decode(pa.notes, NULL, NULL, l_with_notes) AS title_notes,
                   
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pa.id_prof_write, pa.dt_pat_allergy_tstz, i_episode) AS desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) AS nick_name,
                   upper(pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status,
                   decode(nvl(pa.year_begin, 0), 0, pa.year_begin) AS hour_target,
                   nvl(pa.flg_type, 'N/A') AS viewer_category,
                   pa.id_prof_write AS viewer_id_prof,
                   pa.id_episode AS viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) AS viewer_date,
                   pa.notes,
                   
                   get_allergy_symptoms_hist_str(i_lang, pa.id_pat_allergy, pa.revision) symptoms,
                   g_flg_allergy flg_type_rep,
                   g_flg_allergy flg_source_rep,
                   pa.id_cancel_reason,
                   decode(pa.id_cancel_reason,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                             FROM cancel_reason cr
                            WHERE cr.id_cancel_reason = pa.id_cancel_reason)) cancel_reason,
                   pa.cancel_notes,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_pat_allergy_rev_tstz,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) AS dt_pat_allergy_rev,
                   pa.revision revision,
                   decode(pa.flg_aproved,
                          g_unawareness_outdated,
                          pa.desc_aproved,
                          pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) approved,
                   rd.revision revision_rep,
                   rd.id_episode id_episode_rev,
                   rd.flg_auto,
                   decode(rd.flg_auto,
                          pk_alert_constant.g_yes,
                          decode(rd.revision, 1, l_label_createreview, l_label_editreview),
                          pk_alert_constant.g_no,
                          '',
                          NULL,
                          decode(pa.revision, 1, l_label_create, l_label_edit),
                          '') label_review,
                   rd.review_notes
              FROM pat_allergy_hist pa
              LEFT JOIN review_detail rd
                ON (rd.id_record_area = pa.id_pat_allergy AND pa.revision = rd.revision AND
                   rd.flg_auto = pk_alert_constant.g_yes AND rd.flg_context = pk_review.get_allergies_context())
             WHERE pa.id_patient = i_patient
               AND pa.id_episode IN (SELECT *
                                       FROM TABLE(l_epis))
               AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_cancelled, g_pat_allergy_flg_passive)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof) >= pa.dt_pat_allergy_tstz OR
                   i_dt_begin IS NULL)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof) <= pa.dt_pat_allergy_tstz OR i_dt_end IS NULL)
            /* ORDER BY pa.dt_pat_allergy_tstz;*/
             ORDER BY pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => g_pat_allergy_type, i_val => pa.flg_type),
                      rank,
                      allergen ASC;
    
        l_message := 'OPEN O_ALLERGIES_REV';
        OPEN o_allergies_rev FOR
            SELECT pa.id_allergy,
                   pa.id_pat_allergy,
                   pa.id_episode,
                   l_current_epis_desc AS desc_epis,
                   decode(pa.id_allergy,
                          NULL,
                          pa.desc_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                             FROM allergy a
                            WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                   pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS type_reaction,
                   
                   pa.year_begin AS year_begin,
                   pa.month_begin AS month_begin,
                   pa.day_begin AS day_begin,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) start_date,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) AS dt_pat_allergy,
                   get_flg_is_drug_allergy(i_id_allergy => pa.id_allergy) allergy_type,
                   pa.flg_type,
                   pa.flg_status,
                   decode(pa.flg_status,
                          g_pat_allergy_flg_active,
                          1,
                          g_pat_allergy_flg_passive,
                          2,
                          g_pat_allergy_flg_cancelled,
                          3,
                          4) rank,
                   get_status_string(pa.flg_status,
                                     pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status_string,
                   pa.id_allergy_severity,
                   (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                      FROM allergy_severity s
                     WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                   get_status_color(pa.flg_status) AS status_color,
                   decode(pa.id_allergy, NULL, decode(pa.desc_allergy, NULL, NULL, l_free_text), NULL) AS free_text,
                   decode(pa.notes, NULL, NULL, l_with_notes) AS with_notes,
                   decode(pa.cancel_notes, NULL, NULL, l_with_notes) AS cancelled_with_notes,
                   -- Thiago Brito, 02-11-2009 - Needed for the new episodes screen on Viewer
                   decode(pa.notes, NULL, NULL, l_with_notes) AS title_notes,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pa.id_prof_write, pa.dt_pat_allergy_tstz, i_episode) AS desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) AS nick_name,
                   upper(pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status,
                   decode(nvl(pa.year_begin, 0), 0, pa.year_begin) AS hour_target,
                   nvl(pa.flg_type, 'N/A') AS viewer_category,
                   pa.id_prof_write AS viewer_id_prof,
                   pa.id_episode AS viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) AS viewer_date,
                   pa.notes,
                   get_symptoms(i_lang, pa.id_pat_allergy) symptoms,
                   g_flg_allergy flg_type_rep,
                   g_flg_allergy flg_source_rep,
                   pa.id_cancel_reason,
                   decode(pa.id_cancel_reason,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                             FROM cancel_reason cr
                            WHERE cr.id_cancel_reason = pa.id_cancel_reason)) cancel_reason,
                   pa.cancel_notes,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, rd.id_episode) AS desc_speciality_rev,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS nick_name_rev,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_pat_allergy_rev_tstz,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) AS dt_pat_allergy_rev,
                   pa.revision revision,
                   decode(pa.flg_aproved,
                          g_unawareness_outdated,
                          pa.desc_aproved,
                          pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) approved,
                   rd.revision revision_rep,
                   rd.id_episode id_episode_rev,
                   rd.flg_auto,
                   decode(rd.flg_auto,
                          pk_alert_constant.g_yes,
                          decode(rd.revision, 1, l_label_createreview, l_label_editreview),
                          pk_alert_constant.g_no,
                          l_label_review,
                          NULL,
                          '') label_review,
                   rd.review_notes
              FROM pat_allergy pa
             INNER JOIN review_detail rd
                ON (rd.id_record_area = pa.id_pat_allergy AND rd.revision = pa.revision AND
                   rd.flg_context = pk_review.get_allergies_context())
             WHERE pa.id_patient = i_patient
               AND (rd.id_episode IN (SELECT *
                                        FROM TABLE(l_epis)) OR rd.id_episode IS NULL)
               AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_cancelled, g_pat_allergy_flg_passive)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof) >= pa.dt_pat_allergy_tstz OR
                   i_dt_begin IS NULL)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof) <= pa.dt_pat_allergy_tstz OR i_dt_end IS NULL)
            UNION ALL
            SELECT pa.id_allergy,
                   pa.id_pat_allergy,
                   pa.id_episode,
                   l_current_epis_desc AS desc_epis,
                   decode(pa.id_allergy,
                          NULL,
                          pa.desc_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                             FROM allergy a
                            WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                   pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS type_reaction,
                   pa.year_begin AS year_begin,
                   pa.month_begin AS month_begin,
                   pa.day_begin AS day_begin,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) start_date,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) AS dt_pat_allergy,
                   get_flg_is_drug_allergy(i_id_allergy => pa.id_allergy) allergy_type,
                   pa.flg_type,
                   pa.flg_status,
                   decode(pa.flg_status,
                          g_pat_allergy_flg_active,
                          1,
                          g_pat_allergy_flg_passive,
                          2,
                          g_pat_allergy_flg_cancelled,
                          3,
                          4) rank,
                   get_status_string(pa.flg_status,
                                     pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status_string,
                   pa.id_allergy_severity,
                   (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                      FROM allergy_severity s
                     WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                   get_status_color(pa.flg_status) AS status_color,
                   decode(pa.id_allergy, NULL, decode(pa.desc_allergy, NULL, NULL, l_free_text), NULL) AS free_text,
                   decode(pa.notes, NULL, NULL, l_with_notes) AS with_notes,
                   decode(pa.cancel_notes, NULL, NULL, l_with_notes) AS cancelled_with_notes,
                   -- Thiago Brito, 02-11-2009 - Needed for the new episodes screen on Viewer
                   decode(pa.notes, NULL, NULL, l_with_notes) AS title_notes,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pa.id_prof_write, pa.dt_pat_allergy_tstz, i_episode) AS desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) AS nick_name,
                   upper(pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status,
                   decode(nvl(pa.year_begin, 0), 0, pa.year_begin) AS hour_target,
                   nvl(pa.flg_type, 'N/A') AS viewer_category,
                   pa.id_prof_write AS viewer_id_prof,
                   pa.id_episode AS viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) AS viewer_date,
                   pa.notes,
                   get_symptoms(i_lang, pa.id_pat_allergy) symptoms,
                   g_flg_allergy flg_type_rep,
                   g_flg_allergy flg_source_rep,
                   pa.id_cancel_reason,
                   decode(pa.id_cancel_reason,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                             FROM cancel_reason cr
                            WHERE cr.id_cancel_reason = pa.id_cancel_reason)) cancel_reason,
                   pa.cancel_notes,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, rd.id_episode) AS desc_speciality_rev,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS nick_name_rev,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_pat_allergy_rev_tstz,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) AS dt_pat_allergy_rev,
                   pa.revision revision,
                   decode(pa.flg_aproved,
                          g_unawareness_outdated,
                          pa.desc_aproved,
                          pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) approved,
                   rd.revision revision_rep,
                   rd.id_episode id_episode_rev,
                   rd.flg_auto,
                   decode(rd.flg_auto,
                          pk_alert_constant.g_yes,
                          decode(rd.revision, 1, l_label_createreview, l_label_editreview),
                          pk_alert_constant.g_no,
                          l_label_review,
                          NULL,
                          '') label_review,
                   rd.review_notes
              FROM pat_allergy_hist pa
             INNER JOIN review_detail rd
                ON (rd.id_record_area = pa.id_pat_allergy AND rd.revision = pa.revision AND
                   rd.flg_context = pk_review.get_allergies_context())
             WHERE pa.id_patient = i_patient
               AND (rd.id_episode IN (SELECT *
                                        FROM TABLE(l_epis)) OR rd.id_episode IS NULL)
               AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_cancelled, g_pat_allergy_flg_passive)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof) >= pa.dt_pat_allergy_tstz OR
                   i_dt_begin IS NULL)
               AND (pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof) <= pa.dt_pat_allergy_tstz OR i_dt_end IS NULL)
             ORDER BY dt_pat_allergy_rev;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => l_message,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_ALLERGY_LST_REP',
                                                     o_error    => o_error);
    END get_allergy_lst_rep;
    --
    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_filter_desc          Filter description
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_lst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        i_flg_filter  IN VARCHAR2,
        o_allergies   OUT t_tbl_allergies,
        o_filter_desc OUT sys_message.desc_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        --Allergy status list
        l_status_list table_varchar2;
        --   
        l_with_notes CONSTANT sys_message.desc_message%TYPE := '(' ||
                                                               lower(pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => 'COMMON_M008')) || ')';
        l_free_text  CONSTANT sys_message.desc_message%TYPE := '(' ||
                                                               lower(pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => 'TOOLS_T014')) || ')';
    
        l_viewer_cat_desc CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                           i_code_mess => 'COMMON_M036');
    
        --Allergy or Idiosincratica
        l_flg_type_list table_varchar2;
        --Parent list
        l_parent_list               table_number;
        l_allergy_parent_trans_code VARCHAR(200 CHAR) := 'ALLERGY.CODE_ALLERGY.';
    
        l_filter_desc sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_message := 'FILTER OPTIONS';
        CASE i_flg_filter
            WHEN g_allergies_adverse_reactions THEN
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T021');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active,
                                                  g_pat_allergy_flg_cancelled,
                                                  g_pat_allergy_flg_passive);
                l_flg_type_list := table_varchar2(g_flg_type_allergy,
                                                  g_flg_type_adv_react,
                                                  g_flg_type_intolerance,
                                                  g_flg_type_propensity);
                l_parent_list   := NULL;
            
            WHEN g_medication_allergies THEN
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T022');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active,
                                                  g_pat_allergy_flg_cancelled,
                                                  g_pat_allergy_flg_passive);
                l_flg_type_list := table_varchar2(g_flg_type_allergy,
                                                  g_flg_type_adv_react,
                                                  g_flg_type_intolerance,
                                                  g_flg_type_propensity);
                l_parent_list   := table_number(g_drug_id_allergy, g_drug_class_id_allergy, g_drug_com_id_allergy);
            
            WHEN g_active_allergies_adv_react THEN
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T023');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active);
                l_flg_type_list := table_varchar2(g_flg_type_allergy,
                                                  g_flg_type_adv_react,
                                                  g_flg_type_intolerance,
                                                  g_flg_type_propensity,
                                                  g_drug_com_id_allergy);
                l_parent_list   := NULL;
            
            WHEN g_active_medication_allergies THEN
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T024');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active);
                l_flg_type_list := table_varchar2(g_flg_type_allergy,
                                                  g_flg_type_adv_react,
                                                  g_flg_type_intolerance,
                                                  g_flg_type_propensity);
                l_parent_list   := table_number(g_drug_id_allergy, g_drug_class_id_allergy, g_drug_com_id_allergy);
            
            WHEN g_allergies THEN
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T025');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active,
                                                  g_pat_allergy_flg_cancelled,
                                                  g_pat_allergy_flg_passive);
                l_flg_type_list := table_varchar2(g_flg_type_allergy);
                l_parent_list   := NULL;
            
            WHEN g_adverse_reactions THEN
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T026');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active,
                                                  g_pat_allergy_flg_cancelled,
                                                  g_pat_allergy_flg_passive);
                l_flg_type_list := table_varchar2(g_flg_type_adv_react);
                l_parent_list   := NULL;
            ELSE
                l_filter_desc   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T021');
                l_status_list   := table_varchar2(g_pat_allergy_flg_active,
                                                  g_pat_allergy_flg_cancelled,
                                                  g_pat_allergy_flg_passive);
                l_flg_type_list := table_varchar2(g_flg_type_allergy,
                                                  g_flg_type_adv_react,
                                                  g_flg_type_intolerance,
                                                  g_flg_type_propensity);
                l_parent_list   := NULL;
        END CASE;
    
        l_message := 'GET ALL ALLERGIES DATA';
        BEGIN
            SELECT t_rec_allergy(id_allergy            => id_allergy,
                                 id_pat_allergy        => id_pat_allergy,
                                 id_episode            => id_episode,
                                 allergen              => allergen,
                                 type_reaction         => type_reaction,
                                 onset                 => onset,
                                 dt_pat_allergy        => dt_pat_allergy,
                                 flg_type              => flg_type,
                                 flg_status            => flg_status,
                                 status_desc           => status_desc,
                                 rank                  => rank,
                                 status_string         => status_string,
                                 id_allergy_severity   => id_allergy_severity,
                                 severity              => severity,
                                 status_color          => status_color,
                                 free_text             => free_text,
                                 with_notes            => with_notes,
                                 cancelled_with_notes  => cancelled_with_notes,
                                 title_notes           => title_notes,
                                 allergy               => allergy,
                                 desc_speciality       => desc_speciality,
                                 nick_name             => nick_name,
                                 TYPE                  => TYPE,
                                 status                => status,
                                 hour_target           => hour_target,
                                 viewer_category       => viewer_category,
                                 viewer_category_desc  => viewer_category_desc,
                                 viewer_id_prof        => viewer_id_prof,
                                 viewer_id_epis        => viewer_id_epis,
                                 viewer_date           => viewer_date,
                                 notes                 => notes,
                                 reviewed              => reviewed,
                                 symptoms              => symptoms,
                                 flg_type_rep          => flg_type_rep,
                                 flg_source_rep        => flg_source_rep,
                                 id_allergy_parent     => id_allergy_parent,
                                 allergy_parent_desc   => allergy_parent_desc,
                                 severity_desc         => severity_desc,
                                 severity_alert_desc   => severity_alert_desc,
                                 id_symptoms           => id_symptoms,
                                 id_content_symptoms   => id_content_symptoms,
                                 symptoms_desc         => symptoms_desc,
                                 symptoms_alert_desc   => symptoms_alert_desc,
                                 id_drug_ingredient    => id_drug_ingredient,
                                 drug_ingredient_desc  => drug_ingredient_desc,
                                 start_date_app_format => start_date_app_format,
                                 start_date            => start_date,
                                 id_content            => id_content,
                                 id_content_parent     => id_content_parent,
                                 update_time           => update_time)
              BULK COLLECT
              INTO o_allergies
              FROM (SELECT pa.id_allergy,
                           pa.id_pat_allergy,
                           pa.id_episode,
                           decode(pa.id_allergy,
                                  NULL,
                                  pa.desc_allergy,
                                  (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                                     FROM allergy a
                                    WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                           pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS type_reaction,
                           pa.year_begin AS onset,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       pa.dt_pat_allergy_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) AS dt_pat_allergy,
                           pa.flg_type,
                           pa.flg_status,
                           pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang) status_desc,
                           decode(pa.flg_status,
                                  g_pat_allergy_flg_active,
                                  1,
                                  g_pat_allergy_flg_passive,
                                  2,
                                  g_pat_allergy_flg_cancelled,
                                  3,
                                  4) rank,
                           get_status_string(pa.flg_status,
                                             pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status_string,
                           pa.id_allergy_severity,
                           (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                              FROM allergy_severity s
                             WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                           get_status_color(pa.flg_status) AS status_color,
                           decode(pa.id_allergy, NULL, decode(pa.desc_allergy, NULL, NULL, l_free_text), NULL) AS free_text,
                           decode(pa.notes, NULL, NULL, l_with_notes) AS with_notes,
                           decode(pa.cancel_notes, NULL, NULL, l_with_notes) AS cancelled_with_notes,
                           -- Thiago Brito, 02-11-2009 - Needed for the new episodes screen on Viewer
                           decode(pa.notes, NULL, NULL, l_with_notes) AS title_notes,
                           decode(pa.id_allergy,
                                  NULL,
                                  pa.desc_allergy,
                                  (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                                     FROM allergy a
                                    WHERE a.id_allergy = pa.id_allergy)) AS allergy,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pa.id_prof_write,
                                                            pa.dt_pat_allergy_tstz,
                                                            i_episode) AS desc_speciality,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) AS nick_name,
                           pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS TYPE,
                           upper(pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) AS status,
                           decode(nvl(pa.year_begin, 0), 0, pa.year_begin) AS hour_target,
                           nvl(pa.flg_type, 'N/A') AS viewer_category,
                           nvl(pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang), l_viewer_cat_desc) AS viewer_category_desc,
                           pa.id_prof_write AS viewer_id_prof,
                           pa.id_episode AS viewer_id_epis,
                           pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) AS viewer_date,
                           pa.notes,
                           (SELECT COUNT(1)
                              FROM review_detail rd
                             INNER JOIN prof_cat pc
                                ON pc.id_professional = rd.id_professional
                             INNER JOIN category cat
                                ON cat.id_category = pc.id_category
                             WHERE rd.id_episode IN (i_episode)
                               AND rd.id_record_area = pa.id_pat_allergy
                               AND cat.flg_type = pk_alert_constant.g_cat_type_doc
                               AND rd.flg_context = g_allergy_review_context
                               AND rownum = 1) reviewed,
                           get_symptoms(i_lang, pa.id_pat_allergy) symptoms,
                           g_flg_allergy flg_type_rep,
                           g_flg_allergy flg_source_rep,
                           a.id_allergy_parent,
                           pk_translation.get_translation(i_lang      => i_lang,
                                                          i_code_mess => l_allergy_parent_trans_code ||
                                                                         to_char(a.id_allergy_parent)) allergy_parent_desc,
                           pk_translation.get_translation(i_lang, als.code_allergy_severity) severity_desc,
                           pk_translation.get_translation(i_lang, als.code_allergy_severity) severity_alert_desc,
                           
                           NULL id_symptoms,
                           NULL id_content_symptoms,
                           NULL symptoms_desc,
                           NULL symptoms_alert_desc,
                           NULL id_drug_ingredient,
                           NULL drug_ingredient_desc,
                           get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) start_date_app_format,
                           
                           CASE
                                WHEN pa.year_begin IS NOT NULL
                                     AND pa.month_begin IS NOT NULL
                                     AND pa.day_begin IS NOT NULL THEN
                                 to_char(to_timestamp(pa.year_begin || lpad(pa.month_begin, 2, '0') ||
                                                      lpad(pa.day_begin, 2, '0'),
                                                      'YYYYMMDD'),
                                         'YYYYMMDD')
                                ELSE
                                 to_char(pa.year_begin)
                            END start_date,
                           
                           a.id_content           id_content,
                           NULL                   id_content_parent,
                           pa.dt_pat_allergy_tstz update_time
                    
                      FROM pat_allergy pa
                      LEFT JOIN allergy a
                        ON a.id_allergy = pa.id_allergy
                      LEFT JOIN allergy_severity als
                        ON als.id_allergy_severity = pa.id_allergy_severity
                    
                     WHERE pa.id_patient = i_patient
                       AND pa.flg_status IN (SELECT *
                                               FROM TABLE(l_status_list))
                          
                       AND pa.flg_type IN (SELECT *
                                             FROM TABLE(l_flg_type_list))
                          
                       AND (pa.id_pat_allergy IN (SELECT *
                                                    FROM TABLE(i_pat_allergy)) OR i_pat_allergy IS NULL)
                          
                       AND (a.id_allergy_parent IN (SELECT *
                                                      FROM TABLE(l_parent_list)) OR l_parent_list IS NULL)
                    
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => g_pat_allergy_type,
                                                    i_val      => pa.flg_type),
                              rank,
                              allergen ASC);
        EXCEPTION
            WHEN no_data_found THEN
                o_allergies := NULL;
        END;
    
        o_filter_desc := l_filter_desc;
    
        RETURN TRUE;
    END get_allergy_lst;

    FUNCTION get_allergy_lst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        i_flg_filter  IN VARCHAR2,
        o_allergies   OUT pk_types.cursor_type,
        o_filter_desc OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_all t_tbl_allergies := NEW t_tbl_allergies();
        l_message debug_msg;
    BEGIN
        IF NOT get_allergy_lst(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_episode     => i_episode,
                               i_pat_allergy => i_pat_allergy,
                               i_flg_filter  => i_flg_filter,
                               o_allergies   => l_tbl_all,
                               o_filter_desc => o_filter_desc,
                               o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        OPEN o_allergies FOR
            SELECT id_allergy,
                   id_pat_allergy,
                   id_episode,
                   allergen,
                   type_reaction,
                   onset,
                   dt_pat_allergy,
                   flg_type,
                   flg_status,
                   rank,
                   status_string,
                   id_allergy_severity,
                   severity,
                   severity,
                   status_color,
                   free_text,
                   with_notes,
                   cancelled_with_notes,
                   title_notes,
                   allergy,
                   desc_speciality,
                   nick_name,
                   TYPE,
                   status,
                   hour_target,
                   viewer_category,
                   viewer_category_desc,
                   viewer_id_prof,
                   viewer_id_epis,
                   viewer_date,
                   notes,
                   reviewed,
                   symptoms,
                   flg_type_rep,
                   flg_source_rep
              FROM TABLE(l_tbl_all);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => l_message,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_ALLERGY_LIST',
                                                     o_error    => o_error);
    END get_allergy_lst;
    --

    FUNCTION get_allergy_lst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        o_allergies   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_filter_desc sys_message.desc_message%TYPE;
    BEGIN
        IF NOT get_allergy_lst(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_episode     => i_episode,
                               i_pat_allergy => i_pat_allergy,
                               i_flg_filter  => g_allergies_adverse_reactions,
                               o_allergies   => o_allergies,
                               o_filter_desc => l_filter_desc,
                               o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_allergy_lst;
    --

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_unawareness_active   Active unawareness allergies cursor
     * @param    OUT    o_unawareness_outdated Outdated unawareness allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_filter           IN VARCHAR2,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_filter_desc          OUT sys_message.desc_message%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_allergy_lst(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_episode     => i_episode,
                               i_pat_allergy => NULL,
                               i_flg_filter  => i_flg_filter,
                               o_allergies   => o_allergies,
                               o_filter_desc => o_filter_desc,
                               o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT get_unawareness_active(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_patient            => i_patient,
                                      i_episode            => i_episode,
                                      i_flg_filter         => NULL,
                                      i_dt_begin           => NULL,
                                      i_dt_end             => NULL,
                                      o_unawareness_active => o_unawareness_active,
                                      o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT get_unawareness_outdated(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_patient              => i_patient,
                                        i_episode              => i_episode,
                                        i_flg_filter           => NULL,
                                        i_dt_begin             => NULL,
                                        i_dt_end               => NULL,
                                        o_unawareness_outdated => o_unawareness_outdated,
                                        o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_allergy_list;
    --

    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_filter_desc sys_message.desc_message%TYPE;
    BEGIN
    
        IF NOT get_allergy_list(i_lang                 => i_lang,
                                i_prof                 => i_prof,
                                i_patient              => i_patient,
                                i_episode              => i_episode,
                                i_flg_filter           => g_allergies_adverse_reactions,
                                o_allergies            => o_allergies,
                                o_unawareness_active   => o_unawareness_active,
                                o_unawareness_outdated => o_unawareness_outdated,
                                o_filter_desc          => l_filter_desc,
                                o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_allergy_list;
    --

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    IN     i_flg_filter           Flag for filter (Reports only) (g_rep_type_patient, g_rep_type_episode, g_rep_type_visit)
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_unawareness_active   Active unawareness allergies cursor
     * @param    OUT    o_unawareness_outdated Outdated unawareness allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @author   Filipe Machado
    */
    FUNCTION get_allergy_list_rep
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_filter           IN VARCHAR2,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_allergies            OUT pk_types.cursor_type,
        o_allergies_hist       OUT pk_types.cursor_type,
        o_allergies_rev        OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_allergy_lst_rep(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_patient    => i_patient,
                                   i_episode    => i_episode,
                                   i_flg_filter => i_flg_filter,
                                   i_dt_begin   => i_dt_begin,
                                   i_dt_end     => i_dt_end,
                                   
                                   o_allergies      => o_allergies,
                                   o_allergies_hist => o_allergies_hist,
                                   o_allergies_rev  => o_allergies_rev,
                                   
                                   o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT get_unawareness_active(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_patient            => i_patient,
                                      i_episode            => i_episode,
                                      i_flg_filter         => i_flg_filter,
                                      i_dt_begin           => i_dt_begin,
                                      i_dt_end             => i_dt_end,
                                      o_unawareness_active => o_unawareness_active,
                                      o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT get_unawareness_outdated(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_patient              => i_patient,
                                        i_episode              => i_episode,
                                        i_flg_filter           => i_flg_filter,
                                        i_dt_begin             => i_dt_begin,
                                        i_dt_end               => i_dt_end,
                                        o_unawareness_outdated => o_unawareness_outdated,
                                        o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_allergy_list_rep;

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    IN     i_pat_allergy          Patient allergies
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    2010-Oct-26
     * @author   Filipe Machado
    */

    FUNCTION get_allergy_review_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        o_allergies   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT get_allergy_lst(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_episode     => i_episode,
                               i_pat_allergy => i_pat_allergy,
                               o_allergies   => o_allergies,
                               o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_allergy_review_list;

    /**
    * This function returns all allergies that match the given allergy name
     *
    * @param    i_lang             Language id
    * @param    i_prof             Profissional, institution and software id's
    * @param    i_allergy_name     Allergy name to search for
    * @param    o_allergies        Output allergies cursor
    * @param    o_error            Error messages cursor
     *
    * @return   True if sucess, false otherwise
     *
     * @version  2.4.4
    * @since    01-Apr-2009
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_type_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_allergy_name  IN pk_translation.t_desc_translation,
        o_allergies     OUT pk_types.cursor_type,
        o_limit_message OUT sys_message.desc_message%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_ALLERGY_TYPE_SEARCH';
        l_message debug_msg;
    
        l_inst_market institution.id_market%TYPE;
        l_inst        institution.id_institution%TYPE;
        l_soft        software.id_software%TYPE;
    
        l_rows_id table_varchar := table_varchar();
    
        l_allergy_standard sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => pk_allergy.g_allergy_presc_type,
                                                                            i_prof_inst => i_prof.institution,
                                                                            i_prof_soft => i_prof.software);
    BEGIN
        l_message     := 'Getting the professional market';
        l_inst_market := prv_get_inst_market(i_lang, i_prof);
        pk_alertlog.log_debug(l_message);
        get_aism_cfg_vars(i_lang   => i_lang,
                          i_prof   => i_prof,
                          o_market => l_inst_market,
                          o_inst   => l_inst,
                          o_soft   => l_soft);
    
        IF check_allergies_search_limit(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_search_pattern   => i_allergy_name,
                                        i_market           => l_inst_market,
                                        i_institution      => l_inst,
                                        i_software         => l_soft,
                                        i_allergy_standard => l_allergy_standard,
                                        o_allergies        => o_allergies,
                                        o_limit_message    => o_limit_message,
                                        o_error            => o_error)
        THEN
        
            l_message := 'GET_ALLERGY_TYPE_SEARCH - COUNT';
            SELECT /*+opt_estimate (table tf rows=10)*/
             ar.rid
              BULK COLLECT
              INTO l_rows_id
              FROM (SELECT distinct a.rowid AS rid, a.code_allergy
                       FROM allergy a
                      INNER JOIN (SELECT am.*
                                   FROM (SELECT aism.id_allergy, aism.id_allergy_parent
                                           FROM allergy_inst_soft_market aism
                                          WHERE aism.id_market = l_inst_market
                                            AND aism.id_institution = l_inst
                                            AND aism.id_software in (pk_alert_constant.g_soft_all,l_soft)) am
                                  WHERE connect_by_isleaf = 1
                                  START WITH am.id_allergy_parent IS NULL
                                 CONNECT BY PRIOR am.id_allergy = am.id_allergy_parent) al
                         ON a.id_allergy = al.id_allergy
                      WHERE rownum > 0 -- please DON'T REMOVE this condition due to performance issues
                       AND a.flg_active = pk_alert_constant.g_active
                       AND a.flg_available = pk_alert_constant.g_available
                       AND nvl(a.id_allergy_standard, l_allergy_standard) = l_allergy_standard) ar,
                   (SELECT *
                      FROM TABLE(pk_translation.get_search_translation(i_lang, i_allergy_name, 'ALLERGY.CODE_ALLERGY'))) tf
             WHERE tf.code_translation = ar.code_allergy;
        
            l_message := 'GET_ALLERGY_TYPE_SEARCH - OPEN o_allergies CURSOR';
            IF l_rows_id.count() > 0
            THEN
                OPEN o_allergies FOR
                    SELECT /*+ use_nl(tr a) */ -- please DON'T REMOVE this hint due to performance issues
                     a.id_allergy,
                     pk_translation.get_translation(i_lang, a.code_allergy) AS desc_allergy,
                     --AS 20-09-2012 - ALERT-239461 
                     -- The drug classification group results should display first. 
                     -- Followed by drug ingredient results and Medication name results                     
                     CASE a.id_allergy_parent
                         WHEN g_drug_id_allergy THEN -- Drug ingredient
                          2
                         WHEN g_drug_class_id_allergy THEN -- Drug classification
                          1
                         WHEN g_drug_com_id_allergy THEN -- Medication name
                          3
                         ELSE
                          4
                     END ordering
                      FROM allergy a
                     INNER JOIN TABLE(l_rows_id) tr
                        ON a.rowid = tr.column_value
                     ORDER BY ordering, pk_translation.get_translation(i_lang, a.code_allergy);
            ELSE
                OPEN o_allergies FOR
                    SELECT g_other_allergy AS id_allergy,
                           pk_message.get_message(i_lang, 'ALLERGY_M031') AS desc_allergy
                      FROM dual;
            END IF;
        ELSE
            pk_types.open_cursor_if_closed(o_allergies);
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_allergies);
            RETURN FALSE;
        
    END get_allergy_type_search;

    /**
     * This function is used to get the prescription warning of all the allergies
     * passed by parameter
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-21
     * @author   Thiago Brito
    */
    FUNCTION get_prescription_warning
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_allergies IN table_number,
        o_cursor       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_cursor FOR
            SELECT *
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_PRESCRIPTION_WARNING',
                                                     o_error);
    END get_prescription_warning;

    /**
     * This function verifies if the table ALLERGY_INST_SOFT_MARKET has
     * data for the current market.
     *
     * @param    IN    i_market    Market Description (PT; NL; USA; ALL)
     *
     * @return   BOOLEAN
     *
     * @version  2.5.0.5
     * @since    2009-Jul-31
     * @author   Thiago Brito
    */
    FUNCTION get_default_allergy_market(i_market VARCHAR2) RETURN PLS_INTEGER IS
    
        l_market PLS_INTEGER;
        l_count  PLS_INTEGER;
    
        l_none_market PLS_INTEGER := -1;
    
    BEGIN
        BEGIN
        
            SELECT id_market
              INTO l_market
              FROM market m
             WHERE m.desc_market = i_market;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_market := NULL;
        END;
    
        SELECT COUNT(id_market)
          INTO l_count
          FROM allergy_inst_soft_market aism
         WHERE aism.id_market = nvl(l_market, l_none_market);
    
        IF (l_count > 0)
        THEN
            RETURN l_market;
        ELSE
            RETURN NULL; -- THE DEFAULT MARKET WILL BE CONSIDERED
        END IF;
    END get_default_allergy_market;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    IN     i_flg_freq             Indicates if only shows frequent allergies ('Y'-only frequent allergies; 'N'-all allergies)
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.1
     * @since    2011-Abr-12
     * @author   Luís Maia
    */
    FUNCTION get_allergy_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        i_flg_freq       IN allergy_inst_soft_market.flg_freq%TYPE,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_total_number_of_levels PLS_INTEGER := 3;
    
        l_last CONSTANT VARCHAR2(10) := 'zzzzzzzzz';
    
        l_allergy_standard sys_config.value%TYPE;
    
        l_market institution.id_market%TYPE;
        l_inst   institution.id_institution%TYPE;
        l_soft   software.id_software%TYPE;
    BEGIN
        l_message := 'Getting config variables';
        pk_alertlog.log_debug(g_error);
        get_aism_cfg_vars(i_lang => i_lang, i_prof => i_prof, o_market => l_market, o_inst => l_inst, o_soft => l_soft);
    
        l_message := 'OPEN o_allergies';
        IF (i_allergy_parent IS NULL)
        THEN
            -- Allergies - menu level I
            o_select_level := pk_alert_constant.g_no;
        
            l_message := l_message || ' menu level I';
            OPEN o_allergies FOR
                SELECT DISTINCT t.id_allergy,
                                t.id_allergy_parent,
                                t.desc_allergy,
                                t.rank,
                                NULL                   flg_adverse_reaction,
                                pk_alert_constant.g_no select_level
                  FROM (SELECT a.id_allergy,
                               aism.id_allergy_parent,
                               pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy,
                               rank
                        
                          FROM allergy a
                         INNER JOIN allergy_inst_soft_market aism
                            ON (a.id_allergy = aism.id_allergy)
                         WHERE aism.id_allergy_parent IS NULL
                           AND a.flg_active = pk_alert_constant.g_active
                           AND a.flg_available = pk_alert_constant.g_available
                           AND aism.id_market = l_market
                           AND aism.id_institution = l_inst
                           AND aism.id_software  in (pk_alert_constant.g_soft_all, l_soft)
                           AND (aism.flg_freq = pk_alert_constant.g_yes OR i_flg_freq = pk_alert_constant.g_no)
                           AND rownum > 0) t
                UNION
                SELECT g_other_allergy id_allergy,
                       NULL id_allergy_parent,
                       pk_message.get_message(i_lang, 'ALLERGY_M030') desc_allergy,
                       999 rank,
                       NULL flg_adverse_reaction,
                       pk_alert_constant.g_no select_level
                  FROM dual
                 ORDER BY rank;
        
        ELSE
        
            IF (i_allergy_parent <> g_other_allergy)
            THEN
            
                IF (i_level < l_total_number_of_levels)
                THEN
                
                    IF (i_allergy_parent <> g_drug_allergy)
                    THEN
                    
                        o_select_level := pk_alert_constant.g_yes;
                    
                        l_message := l_message || ' menu level II';
                        OPEN o_allergies FOR
                            SELECT *
                              FROM (SELECT DISTINCT t.id_allergy,
                                                    t.id_allergy_parent,
                                                    t.desc_allergy,
                                                    nvl(t.desc_allergy, 'A') desc_allergy_order,
                                                    t.rank,
                                                    NULL flg_adverse_reaction,
                                                    pk_alert_constant.g_yes select_level
                                      FROM (SELECT a.id_allergy,
                                                   aism.id_allergy_parent,
                                                   pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy,
                                                   a.rank
                                              FROM allergy a, allergy_inst_soft_market aism
                                             WHERE a.id_allergy = aism.id_allergy
                                               AND aism.id_allergy_parent = i_allergy_parent
                                               AND a.flg_active = pk_alert_constant.g_active
                                               AND a.flg_available = pk_alert_constant.g_available
                                               AND aism.id_market = l_market
                                               AND aism.id_institution = l_inst
                                               AND aism.id_software  in (pk_alert_constant.g_soft_all, l_soft)
                                               AND (aism.flg_freq = pk_alert_constant.g_yes OR
                                                   i_flg_freq = pk_alert_constant.g_no)
                                               AND rownum > 0) t
                                     WHERE desc_allergy IS NOT NULL
                                     ORDER BY rank, desc_allergy_order ASC);
                    
                    ELSE
                    
                        o_select_level := pk_alert_constant.g_no;
                    
                        l_message := l_message || ' menu level II'; -- Drug Allergies
                        OPEN o_allergies FOR
                            SELECT *
                              FROM (SELECT DISTINCT t.id_allergy,
                                                    t.id_allergy_parent,
                                                    t.desc_allergy,
                                                    nvl(desc_allergy, 'A') desc_allergy_order,
                                                    t.rank,
                                                    NULL flg_adverse_reaction,
                                                    pk_alert_constant.g_no select_level
                                      FROM (SELECT a.id_allergy,
                                                   i_allergy_parent id_allergy_parent,
                                                   a.code_allergy,
                                                   a.rank,
                                                   pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy
                                              FROM allergy a
                                             INNER JOIN allergy_inst_soft_market aism
                                                ON aism.id_allergy = a.id_allergy
                                               AND aism.id_allergy_parent = i_allergy_parent
                                               AND aism.id_market = l_market
                                               AND aism.id_institution = l_inst
                                               AND aism.id_software  in (pk_alert_constant.g_soft_all, l_soft)
                                               AND (aism.flg_freq = pk_alert_constant.g_yes OR
                                                   i_flg_freq = pk_alert_constant.g_no)
                                             WHERE a.flg_active = pk_alert_constant.g_active
                                               AND a.flg_available = pk_alert_constant.g_available
                                               AND rownum > 0) t
                                     WHERE t.desc_allergy IS NOT NULL
                                     ORDER BY rank, desc_allergy_order ASC);
                    
                    END IF;
                
                ELSE
                    l_allergy_standard := pk_sysconfig.get_config(i_code_cf   => pk_allergy.g_allergy_presc_type,
                                                                  i_prof_inst => i_prof.institution,
                                                                  i_prof_soft => i_prof.software);
                
                    IF check_allergies_limit(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_allergy_parent => i_allergy_parent,
                                             i_flg_freq       => i_flg_freq,
                                             i_market         => l_market,
                                             i_inst           => l_inst,
                                             i_soft           => l_soft,
                                             i_standard       => l_allergy_standard,
                                             o_limit_message  => o_limit_message,
                                             o_error          => o_error)
                    THEN
                    
                        -- Allergies - Drug and Drug classification
                    
                        o_select_level := pk_alert_constant.g_yes;
                    
                        l_message := l_message || ' menu level III';
                        OPEN o_allergies FOR
                            SELECT *
                              FROM (SELECT DISTINCT t.id_allergy,
                                                    t.id_allergy_parent,
                                                    t.desc_allergy,
                                                    nvl(t.desc_allergy, 'A') desc_allergy_order,
                                                    t.rank,
                                                    NULL flg_adverse_reaction,
                                                    pk_alert_constant.g_yes select_level
                                      FROM (SELECT a.id_allergy,
                                                   aism.id_allergy_parent,
                                                   pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy,
                                                   a.rank
                                              FROM allergy a, allergy_inst_soft_market aism
                                             WHERE a.id_allergy = aism.id_allergy
                                               AND aism.id_allergy_parent = i_allergy_parent
                                               AND a.flg_active = pk_alert_constant.g_active
                                               AND a.flg_available = pk_alert_constant.g_available
                                               AND aism.id_market = l_market
                                               AND aism.id_institution = l_inst
                                               AND aism.id_software  in (pk_alert_constant.g_soft_all, l_soft)
                                               AND (aism.flg_freq = pk_alert_constant.g_yes OR
                                                   i_flg_freq = pk_alert_constant.g_no)
                                               AND nvl(a.id_allergy_standard, l_allergy_standard) = l_allergy_standard
                                               AND rownum > 0) t
                                     WHERE desc_allergy IS NOT NULL
                                     ORDER BY rank, desc_allergy_order ASC);
                    ELSE
                        pk_types.open_cursor_if_closed(o_allergies);
                    END IF;
                END IF;
            
            ELSE
            
                -- Other allergy / adverse reaction (specify)
            
                o_select_level := pk_alert_constant.g_yes;
            
                l_message := l_message || ' Other allergy / adverse reaction (specify) ';
                OPEN o_allergies FOR
                    SELECT DISTINCT t.id_allergy,
                                    t.id_allergy_parent,
                                    t.desc_allergy,
                                    nvl(t.desc_allergy, 'A') desc_allergy_order,
                                    t.rank,
                                    NULL flg_adverse_reaction,
                                    pk_alert_constant.g_yes select_level
                      FROM (SELECT a.id_allergy,
                                   aism.id_allergy_parent,
                                   pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy,
                                   a.rank
                              FROM allergy a, allergy_inst_soft_market aism
                             WHERE a.id_allergy = aism.id_allergy
                               AND aism.id_allergy_parent = i_allergy_parent
                               AND a.flg_active = pk_alert_constant.g_active
                               AND a.flg_available = pk_alert_constant.g_available
                               AND aism.id_market = l_market
                               AND aism.id_institution = l_inst
                               AND aism.id_software in (pk_alert_constant.g_soft_all, l_soft)
                               AND (aism.flg_freq = pk_alert_constant.g_yes OR i_flg_freq = pk_alert_constant.g_no)) t
                    UNION
                    SELECT g_other_allergy id_allergy,
                           g_other_allergy id_allergy_parent,
                           pk_message.get_message(i_lang, 'ALLERGY_M031') desc_allergy,
                           l_last desc_allergy_order,
                           999 rank,
                           NULL flg_adverse_reaction,
                           pk_alert_constant.g_yes select_level
                      FROM dual
                     ORDER BY rank, desc_allergy_order ASC;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_TYPE_LIST',
                                                     o_error);
        
    END get_allergy_type_list;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL GET_ALLERGY_TYPE_LIST';
        IF (NOT get_allergy_type_list(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_patient     => i_id_patient,
                                      i_id_episode     => i_id_episode,
                                      i_allergy_parent => i_allergy_parent,
                                      i_level          => i_level,
                                      i_flg_freq       => pk_alert_constant.g_no,
                                      o_select_level   => o_select_level,
                                      o_allergies      => o_allergies,
                                      o_limit_message  => o_limit_message,
                                      o_error          => o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_TYPE_LIST',
                                                     o_error);
        
    END get_allergy_type_list;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    IN     i_flg_freq             Indicates if only shows frequent allergies ('Y'-only frequent allergies; 'N'-all allergies)
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.1
     * @since    2011-Abr-12
     * @author   Luís Maia
    */
    FUNCTION get_allergy_type_subset_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        i_flg_freq       IN allergy_inst_soft_market.flg_freq%TYPE,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_allergy_standard sys_config.value%TYPE;
    
        l_market institution.id_market%TYPE;
        l_inst   institution.id_institution%TYPE;
        l_soft   software.id_software%TYPE;
    BEGIN
        l_message := 'Getting config variables';
        pk_alertlog.log_debug(g_error);
        get_aism_cfg_vars(i_lang => i_lang, i_prof => i_prof, o_market => l_market, o_inst => l_inst, o_soft => l_soft);
    
        l_message := 'OPEN o_allergies';
        IF (i_allergy_parent IN (g_drug_id_allergy, g_drug_class_id_allergy, g_drug_com_id_allergy))
        THEN
        
            l_allergy_standard := pk_sysconfig.get_config(i_code_cf   => pk_allergy.g_allergy_presc_type,
                                                          i_prof_inst => i_prof.institution,
                                                          i_prof_soft => i_prof.software);
        
            IF check_allergies_limit(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_allergy_parent => i_allergy_parent,
                                     i_flg_freq       => i_flg_freq,
                                     i_market         => l_market,
                                     i_inst           => l_inst,
                                     i_soft           => l_soft,
                                     i_standard       => l_allergy_standard,
                                     o_limit_message  => o_limit_message,
                                     o_error          => o_error)
            THEN
            
                -- Allergies - Drug and Drug classification
            
                o_select_level := pk_alert_constant.g_yes;
            
                l_message := l_message || ' menu level III';
                OPEN o_allergies FOR
                    SELECT /*+ dynamic_sampling(4)*/
                     *
                      FROM (SELECT DISTINCT a.id_allergy,
                                            aism.id_allergy_parent,
                                            pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy,
                                            a.rank,
                                            pk_alert_constant.g_no flg_adverse_reaction,
                                            pk_alert_constant.g_yes select_level
                              FROM allergy a
                             INNER JOIN allergy_inst_soft_market aism
                                ON (a.id_allergy = aism.id_allergy)
                             WHERE aism.id_allergy_parent = i_allergy_parent
                               AND a.flg_active = pk_alert_constant.g_active
                               AND a.flg_available = pk_alert_constant.g_available
                               AND aism.id_market = l_market
                               AND aism.id_institution = l_inst
                               AND aism.id_software  in (pk_alert_constant.g_soft_all, l_soft)
                               AND (aism.flg_freq = pk_alert_constant.g_yes OR i_flg_freq = pk_alert_constant.g_no)
                               AND nvl(a.id_allergy_standard, l_allergy_standard) = l_allergy_standard
                               AND rownum > 0)
                     WHERE desc_allergy IS NOT NULL
                     ORDER BY desc_allergy ASC;
            ELSE
                pk_types.open_cursor_if_closed(o_allergies);
            END IF;
        ELSE
        
            IF (NOT get_allergy_type_list(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_id_patient     => i_id_patient,
                                          i_id_episode     => i_id_episode,
                                          i_allergy_parent => i_allergy_parent,
                                          i_level          => i_level,
                                          i_flg_freq       => i_flg_freq,
                                          o_select_level   => o_select_level,
                                          o_allergies      => o_allergies,
                                          o_limit_message  => o_limit_message,
                                          o_error          => o_error))
            THEN
            
                RETURN FALSE;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_TYPE_LIST',
                                                     o_error);
        
    END get_allergy_type_subset_list;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_type_subset_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'Getting the default market';
    
        IF (NOT pk_allergy.get_allergy_type_subset_list(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_patient     => i_id_patient,
                                                        i_id_episode     => i_id_episode,
                                                        i_allergy_parent => i_allergy_parent,
                                                        i_level          => i_level,
                                                        i_flg_freq       => pk_alert_constant.g_yes,
                                                        o_select_level   => o_select_level,
                                                        o_allergies      => o_allergies,
                                                        o_limit_message  => o_limit_message,
                                                        o_error          => o_error))
        THEN
        
            RETURN FALSE;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_TYPE_LIST',
                                                     o_error);
        
    END get_allergy_type_subset_list;

    /**
     * This function returns the detail of an allergy.
     * 
     * @param    IN     i_lang             Language ID
     * @param    IN     i_prof             Professional structure
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    IN     i_all        Boolean value
     * @param    OUT    o_allergy_detail   Detail of an allergy
     * @param    IN OUT o_error            Error structure
     *
     * @value    i_all                     {*} True  include all (creation, history, review)
     *                                     {*} False only creation   
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
     *
     * @version  2.5.0.7.5
     * @update   2009-Dec-09
     * @author   Filipe Machado
    */

    FUNCTION get_allergy_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        o_allergy_detail OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_label_created   sys_message.desc_message%TYPE;
        l_label_edited    sys_message.desc_message%TYPE;
        l_label_cancelled sys_message.desc_message%TYPE;
        l_label_review    sys_message.desc_message%TYPE;
    
        l_alergy_review_area review_detail.flg_context%TYPE;
        l_sep                VARCHAR2(3) := '/';
    
    BEGIN
        l_label_created   := pk_message.get_message(i_lang, 'DETAIL_COMMON_M015');
        l_label_edited    := pk_message.get_message(i_lang, 'DETAIL_COMMON_M016');
        l_label_cancelled := pk_message.get_message(i_lang, 'DETAIL_COMMON_M017');
        l_label_review    := pk_message.get_message(i_lang, 'DETAIL_COMMON_M018');
    
        l_alergy_review_area := pk_review.get_allergies_context();
    
        l_message := 'OPEN o_allergy_detail';
        OPEN o_allergy_detail FOR
            SELECT id_pat_allergy,
                   flg_status,
                   dt_pat_allergy,
                   dt_pat_allergy_tstz,
                   prof_name,
                   prof_spec,
                   allergen,
                   flg_type,
                   reaction,
                   year_of_onset,
                   year_begin,
                   month_begin,
                   day_begin,
                   status,
                   severity,
                   symptoms,
                   aproved,
                   notes,
                   id_cancel_reason,
                   cancel_reason,
                   cancel_notes,
                   flg_update,
                   desc_update,
                   revision,
                   flg_edit,
                   desc_edit,
                   flg_review,
                   review_notes,
                   review,
                   flg_auto,
                   id_episode,
                   flg_type_rep,
                   flg_source_rep,
                   record_origin
              FROM ( -- ALLERGY
                    SELECT pa.id_pat_allergy,
                            pa.flg_status,
                            pk_date_utils.date_char_tsz(i_lang,
                                                        pa.dt_pat_allergy_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_pat_allergy,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) prof_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             pa.id_prof_write,
                                                             pa.dt_pat_allergy_tstz,
                                                             pa.id_episode) prof_spec,
                            decode(pa.id_allergy,
                                   NULL,
                                   pa.desc_allergy,
                                   (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                                      FROM allergy a
                                     WHERE a.id_allergy = pa.id_allergy)) AS allergen,
                            pa.flg_type,
                            pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) AS reaction,
                            pa.year_begin AS year_of_onset,
                            pa.year_begin AS year_begin,
                            pa.month_begin AS month_begin,
                            pa.day_begin AS day_begin,
                            pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang) AS status,
                            pa.id_allergy_severity,
                            (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                               FROM allergy_severity s
                              WHERE s.id_allergy_severity = pa.id_allergy_severity) AS severity,
                            get_symptoms(i_lang, pa.id_pat_allergy) symptoms,
                            decode(pa.flg_aproved,
                                   g_unawareness_outdated,
                                   pa.desc_aproved,
                                   pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) aproved,
                            pa.notes,
                            pa.dt_pat_allergy_tstz,
                            pa.id_cancel_reason,
                            decode(pa.id_cancel_reason,
                                   NULL,
                                   NULL,
                                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                                      FROM cancel_reason cr
                                     WHERE cr.id_cancel_reason = pa.id_cancel_reason)) cancel_reason,
                            pa.cancel_notes,
                            decode(pa.flg_status, g_pat_allergy_flg_cancelled, g_documented, pk_alert_constant.g_cancelled) flg_update,
                            CASE
                                 WHEN pa.revision = 1 THEN
                                  decode(pa.flg_status,
                                         g_pat_allergy_flg_cancelled,
                                         l_label_cancelled,
                                         decode(rv.flg_auto,
                                                pk_alert_constant.g_yes,
                                                l_label_created || l_sep || l_label_review,
                                                l_label_created))
                             
                                 ELSE
                                  decode(pa.flg_status,
                                         g_pat_allergy_flg_cancelled,
                                         l_label_cancelled,
                                         decode(rv.flg_auto,
                                                pk_alert_constant.g_yes,
                                                l_label_edited || l_sep || l_label_review,
                                                l_label_edited))
                             END desc_update,
                            pa.revision,
                            pa.flg_edit,
                            decode(pa.flg_edit,
                                   g_unawareness_outdated,
                                   pa.desc_edit,
                                   pk_sysdomain.get_domain(g_pat_allergy_edit, pa.flg_edit, i_lang)) desc_edit,
                            pk_alert_constant.g_no flg_review,
                            NULL review_notes,
                            NULL review,
                            rv.flg_auto,
                            rv.id_episode,
                            g_flg_allergy flg_type_rep,
                            g_flg_allergy flg_source_rep,
                            decode(pa.id_cancel_reason,
                                   NULL,
                                   decode(pa.flg_cda_reconciliation,
                                          g_allergy_from_cda_recon,
                                          pk_message.get_message(i_lang      => i_lang,
                                                                 i_code_mess => g_allergy_desc_record_origin),
                                          NULL),
                                   NULL) record_origin
                      FROM pat_allergy pa
                      LEFT JOIN review_detail rv
                        ON (rv.id_record_area = pa.id_pat_allergy AND pa.id_episode = rv.id_episode AND
                           rv.revision = pa.revision AND rv.flg_auto = pk_alert_constant.get_yes() AND
                           rv.flg_context = l_alergy_review_area)
                     WHERE pa.id_pat_allergy = i_id_pat_allergy
                    
                    UNION
                    -- ALLERGY HISTORY
                    SELECT pah.id_pat_allergy,
                            pah.flg_status,
                            pk_date_utils.date_char_tsz(i_lang,
                                                        pah.dt_pat_allergy_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_pat_allergy,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, pah.id_prof_write) prof_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             pah.id_prof_write,
                                                             pah.dt_pat_allergy_tstz,
                                                             pah.id_episode) prof_spec,
                            decode(pah.id_allergy,
                                   NULL,
                                   pah.desc_allergy,
                                   (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                                      FROM allergy a
                                     WHERE a.id_allergy = pah.id_allergy)) AS allergen,
                            pah.flg_type,
                            pk_sysdomain.get_domain(g_pat_allergy_type, pah.flg_type, i_lang) AS reaction,
                            pah.year_begin AS year_of_onset,
                            pah.year_begin AS year_begin,
                            pah.month_begin AS month_begin,
                            pah.day_begin AS day_begin,
                            pk_sysdomain.get_domain(g_pat_allergy_status, pah.flg_status, i_lang) AS status,
                            pah.id_allergy_severity,
                            (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                               FROM allergy_severity s
                              WHERE s.id_allergy_severity = pah.id_allergy_severity) AS severity,
                            pk_allergy.get_allergy_symptoms_hist_str(i_lang, pah.id_pat_allergy, pah.revision) symptoms,
                            decode(pah.flg_aproved,
                                   g_unawareness_outdated,
                                   pah.desc_aproved,
                                   pk_sysdomain.get_domain(g_pat_allergy_aproved, pah.flg_aproved, i_lang)) aproved,
                            pah.notes,
                            pah.dt_pat_allergy_tstz,
                            pah.id_cancel_reason,
                            decode(pah.id_cancel_reason,
                                   NULL,
                                   NULL,
                                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                                      FROM cancel_reason cr
                                     WHERE cr.id_cancel_reason = pah.id_cancel_reason)) cancel_reason,
                            pah.cancel_notes,
                            decode(pah.flg_status,
                                   g_pat_allergy_flg_cancelled,
                                   g_documented,
                                   pk_alert_constant.g_cancelled) flg_update,
                            CASE
                                WHEN pah.revision = 1 THEN
                                 decode(pah.flg_status,
                                        g_pat_allergy_flg_cancelled,
                                        l_label_cancelled,
                                        decode(rv.flg_auto,
                                               pk_alert_constant.g_yes,
                                               l_label_created || l_sep || l_label_review,
                                               l_label_created))
                            
                                ELSE
                                 decode(pah.flg_status,
                                        g_pat_allergy_flg_cancelled,
                                        l_label_cancelled,
                                        decode(rv.flg_auto,
                                               pk_alert_constant.g_yes,
                                               l_label_edited || l_sep || l_label_review,
                                               l_label_edited))
                            END desc_update,
                            pah.revision,
                            pah.flg_edit,
                            decode(pah.flg_edit,
                                   g_unawareness_outdated,
                                   pah.desc_edit,
                                   pk_sysdomain.get_domain(g_pat_allergy_edit, pah.flg_edit, i_lang)) desc_edit,
                            pk_alert_constant.g_no flg_review,
                            NULL review_notes,
                            NULL review,
                            rv.flg_auto,
                            rv.id_episode,
                            g_flg_allergy flg_type_rep,
                            g_flg_allergy flg_source_rep,
                            decode(pah.id_cancel_reason,
                                   NULL,
                                   decode(pah.flg_cda_reconciliation,
                                          g_allergy_from_cda_recon,
                                          pk_message.get_message(i_lang      => i_lang,
                                                                 i_code_mess => g_allergy_desc_record_origin),
                                          NULL),
                                   NULL) record_origin
                      FROM pat_allergy_hist pah
                      LEFT JOIN review_detail rv
                        ON (rv.id_record_area = pah.id_pat_allergy AND pah.id_episode = rv.id_episode AND
                           (rv.revision = pah.revision AND rv.flg_auto = pk_alert_constant.get_yes()) AND
                           rv.flg_context = l_alergy_review_area)
                     WHERE pah.id_pat_allergy = i_id_pat_allergy
                       AND (rv.flg_auto = pk_alert_constant.g_yes OR rv.flg_auto IS NULL)
                    UNION
                    -- ALLERGY REVIEWED
                    SELECT rd.id_record_area AS id_pat_allergy,
                            NULL AS flg_status,
                            pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_pat_allergy,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS prof_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             rd.id_professional,
                                                             rd.dt_review,
                                                             pal.id_episode) AS prof_spec,
                            NULL AS allergen,
                            NULL AS flg_type,
                            NULL AS reaction,
                            NULL AS year_of_onset,
                            NULL AS year_begin,
                            NULL AS month_begin,
                            NULL AS day_begin,
                            NULL AS status,
                            NULL AS id_allergy_severity,
                            NULL AS severity,
                            NULL AS symptoms,
                            NULL AS aproved,
                            NULL AS notes,
                            rd.dt_review AS dt_pat_allergy_tstz,
                            NULL AS id_cancel_reason,
                            NULL AS cancel_reason,
                            NULL AS cancel_notes,
                            NULL AS flg_update,
                            l_label_review AS desc_update,
                            NULL AS revision,
                            NULL AS flg_edit,
                            NULL AS desc_edit,
                            pk_alert_constant.g_yes flg_review,
                            rd.review_notes review_notes,
                            NULL review,
                            rd.flg_auto,
                            rd.id_episode,
                            g_flg_allergy flg_type_rep,
                            g_flg_allergy flg_source_rep,
                            NULL record_origin
                      FROM review_detail rd
                      JOIN pat_allergy pal
                        ON pal.id_pat_allergy = rd.id_record_area
                     WHERE rd.flg_context = l_alergy_review_area
                       AND rd.id_record_area = i_id_pat_allergy
                       AND rd.flg_auto = pk_alert_constant.g_no)
             ORDER BY dt_pat_allergy_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_DETAIL',
                                                     o_error);
        
    END get_allergy_detail;

    /**
     * This function returns the detail of an allergy.
     * 
     * @param    IN     i_lang             Language ID
     * @param    IN     i_prof             Professional structure
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    OUT    o_allergy_detail   Detail of an allergy
     * @param    IN OUT o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
     *
     * @version  2.5.0.7.5
     * @update   2009-Dec-09
     * @author   Filipe Machado
    */

    FUNCTION get_allergy_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        o_allergy_detail OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_allergy_detail(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_id_pat_allergy => i_id_pat_allergy,
                                  i_episode        => NULL,
                                  o_allergy_detail => o_allergy_detail,
                                  o_error          => o_error);
    END get_allergy_detail;

    /**
     * This function verifies if an allergy is already registered
     * for this patient.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_allergy       Allergy ID
     * @param    IN     i_id_patient       Patient ID
     * @param    OUT    o_cursor           Data cursor
     * @param    OUT    o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-27
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_dup_warning
    (
        i_lang       IN language.id_language%TYPE,
        i_id_allergy IN table_number,
        i_id_patient IN pat_allergy.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message VARCHAR2(200) := pk_message.get_message(i_lang, 'ALLERGY_M046');
    
    BEGIN
    
        OPEN o_cursor FOR
            SELECT pa.id_allergy,
                   (SELECT pat_all.id_pat_allergy
                      FROM pat_allergy pat_all
                     WHERE pat_all.id_allergy = pa.id_allergy
                       AND pat_all.id_patient = i_id_patient
                       AND pat_all.flg_type = g_flg_type_allergy
                       AND pat_all.flg_status <> g_pat_allergy_flg_cancelled
                       AND rownum = 1) AS id_pat_allergy,
                   COUNT(id_pat_allergy) AS num_allergies,
                   decode(COUNT(id_pat_allergy), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_warning,
                   decode(COUNT(id_pat_allergy),
                          0,
                          NULL,
                          REPLACE(l_message,
                                  '@1',
                                  (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                                     FROM allergy a
                                    WHERE a.id_allergy = pa.id_allergy))) AS msg_warning
              FROM pat_allergy pa
             WHERE pa.id_allergy IN (SELECT column_value
                                       FROM TABLE(i_id_allergy))
               AND pa.id_patient = i_id_patient
               AND pa.flg_type = g_flg_type_allergy
               AND pa.flg_status <> g_pat_allergy_flg_cancelled
             GROUP BY pa.id_allergy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_DUP_WARNING',
                                                     o_error);
        
    END get_allergy_dup_warning;

    /**
     * This function return all the symptoms (history) associated with an allergy
     * in string format.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     *
     * @return   VARCHAR2
     *
     * @version  2.4.4
     * @since    2009-Apr-29
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_symptoms_hist_str
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy_hist.id_pat_allergy%TYPE,
        i_revision       IN pat_allergy_hist.revision%TYPE
    ) RETURN VARCHAR2 IS
        l_va_symptoms table_number;
        l_symptom     VARCHAR2(200);
        l_symptoms    VARCHAR2(4000);
    
    BEGIN
        BEGIN
            SELECT DISTINCT pas.id_allergy_symptoms
              BULK COLLECT
              INTO l_va_symptoms
              FROM pat_allergy_symptoms_hist pas
             WHERE pas.id_pat_allergy = i_id_pat_allergy
               AND pas.revision = i_revision;
        
            IF (l_va_symptoms.count > 0)
            THEN
                FOR i IN l_va_symptoms.first .. l_va_symptoms.last
                LOOP
                    SELECT pk_translation.get_translation(i_lang, s.code_allergy_symptoms)
                      INTO l_symptom
                      FROM allergy_symptoms s
                     WHERE s.id_allergy_symptoms = l_va_symptoms(i);
                
                    l_symptoms := l_symptoms || ', ' || l_symptom;
                END LOOP;
            END IF;
        
            IF (l_symptoms IS NOT NULL)
            THEN
                l_symptoms := substr(l_symptoms, 2);
                RETURN l_symptoms;
            ELSE
                RETURN '';
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN '';
        END;
    
    END get_allergy_symptoms_hist_str;

    /**
     * This function return all the symptoms associated with an allergy
     * in string format.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     *
     * @return   VARCHAR2
     *
     * @version  2.4.4
     * @since    2009-Mar-30
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_symptoms_str
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_revision       IN pat_allergy.revision%TYPE
    ) RETURN VARCHAR2 IS
        l_va_symptoms table_number;
        l_symptom     VARCHAR2(200);
        l_symptoms    VARCHAR2(4000);
    
    BEGIN
        BEGIN
            SELECT DISTINCT pas.id_allergy_symptoms
              BULK COLLECT
              INTO l_va_symptoms
              FROM pat_allergy_symptoms pas
             WHERE pas.id_pat_allergy = i_id_pat_allergy
               AND pas.revision = i_revision;
        
            IF (l_va_symptoms.count > 0)
            THEN
                FOR i IN l_va_symptoms.first .. l_va_symptoms.last
                LOOP
                    SELECT pk_translation.get_translation(i_lang, s.code_allergy_symptoms)
                      INTO l_symptom
                      FROM allergy_symptoms s
                     WHERE s.id_allergy_symptoms = l_va_symptoms(i);
                
                    l_symptoms := l_symptoms || ', ' || l_symptom;
                END LOOP;
            END IF;
        
            IF (l_symptoms IS NOT NULL)
            THEN
                l_symptoms := substr(l_symptoms, 2);
                RETURN l_symptoms;
            ELSE
                RETURN '';
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN '';
        END;
    
    END get_allergy_symptoms_str;

    /**
     * This function is an auxiliar function. Its objective is to return
     * the id_unawareness and the respective notes associated with.
     *
     * @param    IN     i_pat_allergy_unaware  Patient Allergy Unawareness ID
     * @param    OUT    o_notes                Notes
     * @param    OUT    o_id_unawareness       Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Oct-01
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_notes
    (
        i_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_notes               OUT pat_allergy_unawareness.notes%TYPE,
        o_id_unawareness      OUT allergy_unawareness.id_allergy_unawareness%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT pau.id_allergy_unawareness, pau.notes
              INTO o_id_unawareness, o_notes
              FROM pat_allergy_unawareness pau
             WHERE pau.id_pat_allergy_unawareness = i_pat_allergy_unaware;
        EXCEPTION
            WHEN OTHERS THEN
                o_id_unawareness := NULL;
                o_notes          := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_unawareness_notes;

    /**
     * This function analysis the previous data registered in the PAT_ANALYSIS
     * table in order to find what of the following options will be
     * available:
     *
     * 1 - No allergy assessment
     * 2 - No known allergies
     * 3 - No known drug allergies
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    OUT    o_choices              Choices cursor
     * @param    OUT    o_error                Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_condition
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_choices OUT t_cur_allergy_unawareness,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_notes pat_allergy_unawareness.notes%TYPE;
    
    BEGIN
    
        RETURN get_unawareness_condition(i_lang, i_patient, NULL, l_notes, o_choices, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_UNAWARENESS_CONDITION/3',
                                                     o_error);
    END get_unawareness_condition;

    /**
     * This function analysis the previous data registered in the PAT_ANALYSIS
     * table in order to find what of the following options will be
     * available:
     *
     * 1 - No allergy assessment
     * 2 - No known allergies
     * 3 - No known drug allergies
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_pat_allergy_unaware  Patient Allergy Unawareness ID
     * @param    OUT    o_choices              Choices cursor
     * @param    OUT    o_notes                Notes
     * @param    OUT    o_error                Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_condition
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_notes               OUT pat_allergy_unawareness.notes%TYPE,
        o_choices             OUT t_cur_allergy_unawareness,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_number_of_allergies PLS_INTEGER := 0;
        l_id_unawareness      PLS_INTEGER := 0;
        l_unawareness_notes   pat_allergy_unawareness.notes%TYPE;
    
    BEGIN
        IF (NOT get_unawareness_notes(i_pat_allergy_unaware, l_unawareness_notes, l_id_unawareness))
        THEN
            RAISE l_exception;
        END IF;
    
        l_message := 'GET_UNAWARENESS_CONDITION';
        -- se não h?alergias registadas para o paciente então
        -- os tres estarão activos
        SELECT COUNT(*)
          INTO l_number_of_allergies
          FROM pat_allergy pa
         WHERE pa.id_patient = i_patient
           AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_passive);
    
        IF (l_number_of_allergies = 0)
        THEN
        
            SELECT COUNT(*)
              INTO l_number_of_allergies
              FROM pat_allergy_unawareness pau
             WHERE pau.id_patient = i_patient
               AND pau.flg_status = g_unawareness_active
               AND pau.id_allergy_unawareness IN (g_no_known_drugs, g_no_known);
        
            IF (l_number_of_allergies > 0)
            THEN
            
                l_message := 'OPEN o_choices (1)^(2|3)';
                OPEN o_choices FOR
                    SELECT au.id_allergy_unawareness,
                           au.code_allergy_unawareness,
                           pk_translation.get_translation(i_lang, au.code_allergy_unawareness) type_unawareness,
                           decode(au.id_allergy_unawareness,
                                  1,
                                  pk_alert_constant.g_yes,
                                  2,
                                  decode((SELECT COUNT(*)
                                           FROM pat_allergy_unawareness pau
                                          WHERE pau.id_patient = i_patient
                                            AND pau.flg_status = g_unawareness_active
                                            AND pau.id_allergy_unawareness = g_no_known),
                                         0,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  3,
                                  decode((SELECT COUNT(*)
                                           FROM pat_allergy_unawareness pau
                                          WHERE pau.id_patient = i_patient
                                            AND pau.flg_status = g_unawareness_active
                                            AND pau.id_allergy_unawareness = g_no_known_drugs),
                                         0,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no)) flg_enabled,
                           decode(au.id_allergy_unawareness,
                                  l_id_unawareness,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_default
                      FROM allergy_unawareness au
                     WHERE au.flg_status = pk_alert_constant.g_active;
            
            ELSE
            
                l_message := 'OPEN o_choices (ALL)';
                OPEN o_choices FOR
                    SELECT au.id_allergy_unawareness,
                           au.code_allergy_unawareness,
                           pk_translation.get_translation(i_lang, au.code_allergy_unawareness) type_unawareness,
                           pk_alert_constant.g_yes flg_enabled,
                           decode(au.id_allergy_unawareness,
                                  l_id_unawareness,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_default
                      FROM allergy_unawareness au
                     WHERE au.flg_status = pk_alert_constant.g_active;
            
            END IF;
        
        ELSE
            l_number_of_allergies := 0;
        
            -- verificar se existem alergias (drug-allergies) registadas
            -- para este paciente!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SELECT COUNT(*)
              INTO l_number_of_allergies
              FROM pat_allergy pa
             WHERE pa.id_patient = i_patient
               AND pa.id_allergy IN
                   (SELECT a.id_allergy
                      FROM allergy_inst_soft_market a
                     WHERE a.id_allergy_parent IN (g_drug_class_id_allergy, g_drug_id_allergy, g_drug_com_id_allergy))
               AND pa.flg_status != g_pat_allergy_flg_cancelled;
        
            IF (l_number_of_allergies > 0)
            THEN
            
                -- se existir devolve somente 1
                l_message := 'OPEN o_choices (1)';
                OPEN o_choices FOR
                    SELECT au.id_allergy_unawareness,
                           au.code_allergy_unawareness,
                           pk_translation.get_translation(i_lang, au.code_allergy_unawareness) type_unawareness,
                           decode(au.id_allergy_unawareness,
                                  1,
                                  pk_alert_constant.g_yes,
                                  2,
                                  pk_alert_constant.g_no,
                                  3,
                                  pk_alert_constant.g_no) flg_enabled,
                           decode(au.id_allergy_unawareness,
                                  l_id_unawareness,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_default
                      FROM allergy_unawareness au
                     WHERE au.flg_status = pk_alert_constant.g_active;
            
            ELSE
            
                -- verificar se existe registo de "nao sao conhecidas alergias a medicamentos"
                -- para este paciente
                SELECT COUNT(*)
                  INTO l_number_of_allergies
                  FROM pat_allergy_unawareness pau
                 WHERE pau.id_patient = i_patient
                   AND pau.flg_status = g_unawareness_active
                   AND pau.id_allergy_unawareness = g_no_known_drugs;
            
                IF (l_number_of_allergies > 0)
                THEN
                
                    -- senao existir devolve 1
                    l_message := 'OPEN o_choices (1)';
                    OPEN o_choices FOR
                        SELECT au.id_allergy_unawareness,
                               au.code_allergy_unawareness,
                               pk_translation.get_translation(i_lang, au.code_allergy_unawareness) type_unawareness,
                               decode(au.id_allergy_unawareness,
                                      1,
                                      pk_alert_constant.g_yes,
                                      2,
                                      pk_alert_constant.g_no,
                                      3,
                                      pk_alert_constant.g_no) flg_enabled,
                               decode(au.id_allergy_unawareness,
                                      l_id_unawareness,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) flg_default
                          FROM allergy_unawareness au
                         WHERE au.flg_status = pk_alert_constant.g_active;
                
                ELSE
                
                    -- senao existir devolve 1 e 3
                    l_message := 'OPEN o_choices (1, 3)';
                    OPEN o_choices FOR
                        SELECT au.id_allergy_unawareness,
                               au.code_allergy_unawareness,
                               pk_translation.get_translation(i_lang, au.code_allergy_unawareness) type_unawareness,
                               decode(au.id_allergy_unawareness,
                                      1,
                                      pk_alert_constant.g_yes,
                                      2,
                                      pk_alert_constant.g_no,
                                      3,
                                      pk_alert_constant.g_yes) flg_enabled,
                               decode(au.id_allergy_unawareness,
                                      l_id_unawareness,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) flg_default
                          FROM allergy_unawareness au
                         WHERE au.flg_status = pk_alert_constant.g_active;
                
                END IF;
            
            END IF;
        
        END IF;
    
        o_notes := l_unawareness_notes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_UNAWARENESS_CONDITION/4',
                                                     o_error);
    END get_unawareness_condition;

    /**
     * This function analysis the previous data registered in the PAT_ANALYSIS
     * table in order to find what of the following options will be
     * available:
     *
     * 1 - No allergy assessment
     * 2 - No known allergies
     * 3 - No known drug allergies
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_pat_allergy_unaware  Patient Allergy Unawareness ID
     * @param    OUT    o_choices              Choices cursor
     * @param    OUT    o_notes                Notes
     * @param    OUT    o_error                Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_condition_edit
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_notes               OUT pat_allergy_unawareness.notes%TYPE,
        o_choices             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_id_unawareness PLS_INTEGER := 0;
    
    BEGIN
    
        IF (NOT get_unawareness_notes(i_pat_allergy_unaware, o_notes, l_id_unawareness))
        THEN
            RAISE l_exception;
        END IF;
    
        OPEN o_choices FOR
            SELECT au.id_allergy_unawareness,
                   au.code_allergy_unawareness,
                   pk_translation.get_translation(i_lang, au.code_allergy_unawareness) type_unawareness,
                   decode(au.id_allergy_unawareness, l_id_unawareness, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_enabled,
                   decode(au.id_allergy_unawareness, l_id_unawareness, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM allergy_unawareness au
             WHERE au.flg_status = pk_alert_constant.g_active;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_UNAWARENESS_CONDITION_EDIT',
                                                     o_error);
    END get_unawareness_condition_edit;

    /**
     * This function will return the following messages:
     *
     * 1 - If you document a given drug as an allergen in
     *     free text mode, the (allergy) decision support
     *     will not be activated when the physician is
     *     prescribing medication. Are you sure you want
     *     to continue?
     *
     * 2 - Any potential allergy will not be identified by the (allergy)
     *     decision support.
     *
     * @param    IN     i_lang             Language ID
     * @param    OUT    o_message_bold     Message 1
     * @param    OUT    o_message          Message 2
     * @param    OUT    o_error            Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_type_allergy_warning
    (
        i_lang         IN language.id_language%TYPE,
        o_message_bold OUT pk_types.cursor_type,
        o_message      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_message_bold';
        OPEN o_message_bold FOR
            SELECT pk_message.get_message(i_lang, 'ALLERGY_M019') message_bold
              FROM dual;
    
        l_message := 'OPEN o_message';
        OPEN o_message FOR
            SELECT pk_message.get_message(i_lang, 'ALLERGY_M020') message
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_TYPE_ALLERGY_WARNING',
                                                     o_error);
    END get_type_allergy_warning;

    /**
     * This function returns all data associated with an allergy.
     * 
     * @param    IN     i_lang              Language ID
     * @param    IN     i_id_pat_allergy    Patient Allergy ID
     * @param    OUT    o_allergy           Allergy
     * @param    OUT    o_allergy_symptoms  Allergy Symptoms
     * @param    OUT    o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat_allergy   IN pat_allergy.id_pat_allergy%TYPE,
        o_allergy          OUT pk_types.cursor_type,
        o_allergy_symptoms OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET_ALLERGY - OPEN o_allergy CURSOR';
        OPEN o_allergy FOR
            SELECT pa.id_pat_allergy,
                   pa.id_allergy,
                   pa.id_patient,
                   pa.id_episode,
                   nvl(pa.desc_allergy,
                       pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || to_char(pa.id_allergy))) desc_allergy,
                   pa.flg_status,
                   pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang) desc_status,
                   pa.notes,
                   pa.day_begin,
                   pa.month_begin,
                   pa.year_begin,
                   pa.dt_first_time_tstz,
                   pa.flg_aproved,
                   nvl(pa.desc_aproved, pk_sysdomain.get_domain(g_pat_allergy_aproved, pa.flg_aproved, i_lang)) desc_aproved,
                   pa.flg_edit,
                   nvl(pa.desc_edit, pk_sysdomain.get_domain(g_pat_allergy_edit, pa.flg_edit, i_lang)) desc_edit,
                   pa.id_cancel_reason,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                          to_char(pa.id_cancel_reason))
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = nvl(pa.id_cancel_reason, 0)) desc_cancel_reason,
                   pa.cancel_notes,
                   pa.id_prof_write,
                   pa.id_allergy_severity,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'ALLERGY_SEVERITY.CODE_ALLERGY_SEVERITY.' ||
                                                          to_char(pa.id_allergy_severity))
                      FROM allergy_severity severity
                     WHERE severity.id_allergy_severity = pa.id_allergy_severity) desc_allergy_severity
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
    
        l_message := 'GET_ALLERGY - OPEN o_allergy_symptoms CURSOR';
        OPEN o_allergy_symptoms FOR
            SELECT pas.id_pat_allergy,
                   pas.id_allergy_symptoms,
                   pk_translation.get_translation(i_lang,
                                                  'ALLERGY_SYMPTOMS.CODE_ALLERGY_SYMPTOMS.' ||
                                                  to_char(pas.id_allergy_symptoms)) desc_symptom
              FROM pat_allergy_symptoms pas, allergy_symptoms sym
             WHERE pas.id_allergy_symptoms = sym.id_allergy_symptoms
               AND pas.id_pat_allergy = i_id_pat_allergy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY',
                                                     o_error);
    END get_allergy;

    /**
     * This function returns all data associated symptoms.
     * 
     * @param    IN     i_lang              Language ID
     * @param    IN     i_id_pat_allergy    Patient Allergy ID
     *
     * @return VARCHAR2
     *
     * @version  2.5.1.2
     * @since    2010-Oct-27
     * @author   Filipe Machado
    */
    FUNCTION get_symptoms
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE
    ) RETURN VARCHAR2 IS
    
        l_concat_str VARCHAR2(1000 CHAR);
        l_separator     CONSTANT VARCHAR(2) := ', ';
        l_len_separator CONSTANT PLS_INTEGER := length(l_separator);
        l_len_str PLS_INTEGER := 0;
    
        CURSOR c_allergy_symptoms(l_id_pat_all pat_allergy.id_pat_allergy%TYPE) IS
            SELECT pk_translation.get_translation(i_lang,
                                                  'ALLERGY_SYMPTOMS.CODE_ALLERGY_SYMPTOMS.' ||
                                                  to_char(pas.id_allergy_symptoms)) desc_symptom
              FROM pat_allergy_symptoms pas, allergy_symptoms sym
             WHERE pas.id_allergy_symptoms = sym.id_allergy_symptoms
               AND pas.id_pat_allergy = l_id_pat_all
             ORDER BY desc_symptom;
    
    BEGIN
    
        --l_message := 'GET_ALLERGY - OPEN o_allergy_symptoms CURSOR';
    
        FOR rec IN c_allergy_symptoms(i_id_pat_allergy)
        LOOP
        
            -- verify if string length will be greater than max buffer length
            IF (l_len_str + length(rec.desc_symptom) + l_len_separator > 1000)
            THEN
            
                -- truncate string length
                l_concat_str := substr(l_concat_str, 1, 997) || '...';
                RETURN l_concat_str;
            ELSE
                -- concatenate task description
                l_concat_str := l_concat_str || rec.desc_symptom || l_separator;
            
                --increment string length
                l_len_str := l_len_str + length(rec.desc_symptom) + l_len_separator;
            END IF;
        
        END LOOP;
    
        -- remove last separator from concatenate string
        l_concat_str := substr(l_concat_str, 0, length(l_concat_str) - l_len_separator);
    
        RETURN l_concat_str;
    
    END get_symptoms;

    /**
     * This function will return the following messages:
     *
     * Are you sure you want to cancel the @
     * allergy / adverse reaction record?
     *
     * The @ will be replaced by the name of the allergy
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_allergy       Allergy ID
     * @param    OUT    o_title            Title
     * @param    OUT    o_message          Message
     * @param    OUT    o_error            Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_cancel_warning
    (
        i_lang       IN language.id_language%TYPE,
        i_id_allergy IN allergy.id_allergy%TYPE,
        o_title      OUT VARCHAR2,
        o_message    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_allergy VARCHAR2(4000) := '';
        l_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ALLERGY_M028');
    
    BEGIN
    
        l_message := 'GET_ALLERGY_CANCEL_WARNING - GETTING THE TITLE';
        o_title   := pk_message.get_message(i_lang, 'ALLERGY_M027');
    
        l_message := 'GET_ALLERGY_CANCEL_WARNING - GETTING THE MESSAGE';
        BEGIN
        
            SELECT pk_translation.get_translation(i_lang, a.code_allergy)
              INTO l_allergy
              FROM allergy a
             WHERE a.id_allergy = i_id_allergy;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_allergy := ' ';
        END;
    
        o_message := REPLACE(l_message, '@', l_allergy);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_CANCEL_WARNING',
                                                     o_error);
    END get_allergy_cancel_warning;

    /**
     * This function will return the following messages:
     *
     * Are you sure you want to cancel the @
     * unawareness record?
     *
     * The @ will be replaced by the name of the allergy
     *
     * @param    IN     i_lang                         Language ID
     * @param    IN     i_id_allergy_unawareness       Allergy ID
     * @param    OUT    o_title                        Title
     * @param    OUT    o_message                      Message
     * @param    OUT    o_error                        Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-27
     * @author   Thiago Brito
    */
    FUNCTION get_unaware_cancel_warning
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_allergy_unawareness IN allergy_unawareness.id_allergy_unawareness%TYPE,
        o_title                  OUT VARCHAR2,
        o_message                OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_allergy VARCHAR2(4000) := '';
        l_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ALLERGY_M048');
    
    BEGIN
    
        l_message := 'GET_ALLERGY_CANCEL_WARNING - GETTING THE TITLE';
        o_title   := pk_message.get_message(i_lang, 'ALLERGY_M047');
    
        l_message := 'GET_ALLERGY_CANCEL_WARNING - GETTING THE MESSAGE';
        BEGIN
        
            SELECT pk_translation.get_translation(i_lang, au.code_allergy_unawareness)
              INTO l_allergy
              FROM allergy_unawareness au
             WHERE au.id_allergy_unawareness = i_id_allergy_unawareness;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_allergy := ' ';
        END;
    
        o_message := REPLACE(l_message, '@', l_allergy);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_UNAWARE_CANCEL_WARNING',
                                                     o_error);
    END get_unaware_cancel_warning;

    /**
     * This function will return the following messages:
     *
     * There is an active @1 prescription.
     * Are you sure you want to continue?
     *
     * The @1 will be replaced by the name of the allergy
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_allergy       Allergy ID
     * @param    OUT    o_message          Message
     * @param    OUT    o_error            Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_warning
    (
        i_lang       IN language.id_language%TYPE,
        i_id_allergy IN allergy.id_allergy%TYPE,
        o_message    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_allergy VARCHAR2(200);
        l_message VARCHAR2(200) := pk_message.get_message(i_lang, 'ALLERGY_M021');
    
    BEGIN
    
        l_message := 'GET_ALLERGY_WARNING - SELECT INTO';
    
        BEGIN
        
            SELECT pk_translation.get_translation(i_lang, a.code_allergy) message
              INTO l_allergy
              FROM allergy a
             WHERE a.id_allergy = i_id_allergy;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_allergy := ' ';
        END;
    
        o_message := REPLACE(l_message, '@1', l_allergy);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ALLERGY_WARNING',
                                                     o_error);
    END get_allergy_warning;

    /**
     * This function was developed in order to keep the table
     * PAT_ALLERGY_HIST up-to-date.
     * All changes performed at the table PAT_ALLERGY has to be
     * mirrored to the PAT_ALLERGY_HIST table.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    IN OUT o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_history
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message              debug_msg;
        l_va_pat_allergy_symps table_number;
        l_next_val             pat_allergy_symptoms_hist.id_pat_allergy_sym_hist%TYPE;
        l_revision             PLS_INTEGER;
    
    BEGIN
        l_message := 'SET_ALLERGY_HISTORY - GETTING THE REVISION';
        BEGIN
        
            SELECT revision
              INTO l_revision
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_revision := 1;
        END;
    
        l_message := 'SET_ALLERGY_HISTORY - INSERT INTO PAT_ALLERGY_HIST';
        INSERT INTO pat_allergy_hist
            (id_pat_allergy_hist,
             id_pat_allergy,
             id_allergy,
             id_patient,
             id_drug_pharma,
             flg_status,
             notes,
             id_prof_write,
             flg_type,
             flg_aproved,
             year_begin,
             month_begin,
             day_begin,
             year_end,
             month_end,
             day_end,
             id_institution,
             id_episode,
             flg_nature,
             dt_pat_allergy_tstz,
             dt_first_time_tstz,
             id_cancel_reason,
             cancel_notes,
             id_allergy_severity,
             desc_allergy,
             flg_edit,
             flg_cancel,
             desc_aproved,
             desc_edit,
             revision,
             dt_resolution,
             id_cdr_call,
             flg_cda_reconciliation)
            SELECT seq_pat_allergy_hist.nextval,
                   id_pat_allergy,
                   id_allergy,
                   id_patient,
                   id_drug_pharma,
                   flg_status,
                   notes,
                   id_prof_write,
                   flg_type,
                   flg_aproved,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   id_institution,
                   id_episode,
                   flg_nature,
                   dt_pat_allergy_tstz,
                   dt_first_time_tstz,
                   id_cancel_reason,
                   cancel_notes,
                   id_allergy_severity,
                   desc_allergy,
                   flg_edit,
                   flg_cancel,
                   desc_aproved,
                   desc_edit,
                   l_revision,
                   dt_resolution,
                   id_cdr_call,
                   flg_cda_reconciliation
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
    
        -- Is important to keep the symptoms historic
    
        SELECT pas.id_allergy_symptoms
          BULK COLLECT
          INTO l_va_pat_allergy_symps
          FROM pat_allergy_symptoms pas
         WHERE pas.id_pat_allergy = i_id_pat_allergy;
    
        IF (l_va_pat_allergy_symps.count > 0)
        THEN
            FOR i IN l_va_pat_allergy_symps.first .. l_va_pat_allergy_symps.last
            LOOP
                SELECT nvl(MAX(pash.id_pat_allergy_sym_hist), 0) + 1
                  INTO l_next_val
                  FROM pat_allergy_symptoms_hist pash;
            
                INSERT INTO pat_allergy_symptoms_hist
                    (id_pat_allergy_sym_hist, id_pat_allergy, id_allergy_symptoms, revision)
                VALUES
                    (l_next_val, i_id_pat_allergy, l_va_pat_allergy_symps(i), l_revision);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy_history;

    /**
     * This function ables the user to add more than one allergy at a time.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            ARRAY/Allergy start's year
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-01
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_year_begin          IN table_number,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_id_pat_allergy      pat_allergy.id_pat_allergy%TYPE := NULL;
        l_id_allergy          allergy.id_allergy%TYPE := NULL;
        l_desc_allergy        pat_allergy.desc_allergy%TYPE := NULL;
        l_notes               pat_allergy.notes%TYPE := NULL;
        l_flg_status          pat_allergy.flg_status%TYPE := NULL;
        l_flg_type            pat_allergy.flg_type%TYPE := NULL;
        l_flg_aproved         pat_allergy.flg_aproved%TYPE := NULL;
        l_desc_aproved        pat_allergy.desc_aproved%TYPE := NULL;
        l_year_begin          pat_allergy.year_begin%TYPE := NULL;
        l_id_allergy_severity pat_allergy.id_allergy_severity%TYPE := NULL;
        l_flg_edit            pat_allergy.flg_edit%TYPE := NULL;
        l_desc_edit           pat_allergy.desc_edit%TYPE := NULL;
        l_id_symptoms         table_number;
    
    BEGIN
        o_id_pat_allergy := table_number();
    
        l_message := 'SET_ALLERGY - LOOP 1';
        FOR i IN i_id_allergy.first .. i_id_allergy.last
        LOOP
            o_id_pat_allergy.extend();
        
            IF (i_id_pat_allergy.exists(i))
            THEN
                l_id_pat_allergy := i_id_pat_allergy(i);
            END IF;
        
            IF (i_id_allergy.exists(i))
            THEN
                l_id_allergy := i_id_allergy(i);
            END IF;
        
            IF (i_desc_allergy.exists(i))
            THEN
                l_desc_allergy := i_desc_allergy(i);
            END IF;
        
            IF (i_notes.exists(i))
            THEN
                l_notes := i_notes(i);
            END IF;
        
            IF (i_flg_status.exists(i))
            THEN
                l_flg_status := i_flg_status(i);
            END IF;
        
            IF (i_flg_type.exists(i))
            THEN
                l_flg_type := i_flg_type(i);
            END IF;
        
            IF (i_flg_aproved.exists(i))
            THEN
                l_flg_aproved := i_flg_aproved(i);
            END IF;
        
            IF (i_desc_aproved.exists(i))
            THEN
                l_desc_aproved := i_desc_aproved(i);
            END IF;
        
            IF (i_year_begin.exists(i))
            THEN
                l_year_begin := i_year_begin(i);
            END IF;
        
            IF (i_id_allergy_severity.exists(i))
            THEN
                l_id_allergy_severity := i_id_allergy_severity(i);
            END IF;
        
            IF (i_desc_edit.exists(i))
            THEN
                IF ((i_desc_edit(i) IS NOT NULL) AND (i_flg_edit(i) = g_flg_edit_other))
                THEN
                    l_desc_edit := i_desc_edit(i);
                ELSE
                    l_desc_edit := NULL;
                END IF;
            ELSE
                l_desc_edit := NULL;
            END IF;
        
            IF (i_flg_edit.exists(i))
            THEN
                IF (l_desc_edit IS NOT NULL)
                THEN
                    l_flg_edit := g_flg_edit_other;
                ELSE
                    l_flg_edit := i_flg_edit(i);
                END IF;
            ELSIF (l_id_pat_allergy IS NOT NULL)
            THEN
                l_flg_edit := g_flg_edit_other;
            END IF;
        
            IF (i_id_symptoms.exists(i))
            THEN
                l_id_symptoms := i_id_symptoms(i);
            END IF;
        
            IF (NOT set_allergy(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                l_id_pat_allergy,
                                l_id_allergy,
                                l_desc_allergy,
                                l_notes,
                                l_flg_status,
                                l_flg_type,
                                l_flg_aproved,
                                l_desc_aproved,
                                l_year_begin,
                                l_id_symptoms,
                                l_id_allergy_severity,
                                l_flg_edit,
                                l_desc_edit,
                                i_cdr_call,
                                o_id_pat_allergy(i),
                                o_error))
            THEN
                RAISE l_exception;
            END IF;
        
            -- whenever an allergy is created/edited stays automatically reviewed  
            IF NOT set_allergy_as_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_id_episode,
                                         i_id_pat_allergy => o_id_pat_allergy(i),
                                         i_review_notes   => NULL,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_message := 'call set_register_by_me_nc';
            IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_episode  => i_id_episode,
                                                     i_pat         => i_id_patient,
                                                     i_id_problem  => o_id_pat_allergy(i),
                                                     i_flg_type    => 'A',
                                                     i_flag_active => pk_alert_constant.g_yes,
                                                     o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY/ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_array;

    FUNCTION set_allergy_intf
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_date_occur          IN table_varchar,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL,
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_id_pat_allergy      pat_allergy.id_pat_allergy%TYPE := NULL;
        l_id_allergy          allergy.id_allergy%TYPE := NULL;
        l_desc_allergy        pat_allergy.desc_allergy%TYPE := NULL;
        l_notes               pat_allergy.notes%TYPE := NULL;
        l_flg_status          pat_allergy.flg_status%TYPE := NULL;
        l_flg_type            pat_allergy.flg_type%TYPE := NULL;
        l_flg_aproved         pat_allergy.flg_aproved%TYPE := NULL;
        l_desc_aproved        pat_allergy.desc_aproved%TYPE := NULL;
        l_year_begin          pat_allergy.year_begin%TYPE := NULL;
        l_month_begin         pat_allergy.month_begin%TYPE := NULL;
        l_day_begin           pat_allergy.day_begin%TYPE := NULL;
        l_id_allergy_severity pat_allergy.id_allergy_severity%TYPE := NULL;
        l_flg_edit            pat_allergy.flg_edit%TYPE := NULL;
        l_desc_edit           pat_allergy.desc_edit%TYPE := NULL;
        l_id_symptoms         table_number;
    
    BEGIN
        o_id_pat_allergy := table_number();
    
        l_message := 'SET_ALLERGY - LOOP 1';
        FOR i IN i_id_allergy.first .. i_id_allergy.last
        LOOP
            o_id_pat_allergy.extend();
        
            IF (i_id_pat_allergy.exists(i))
            THEN
                l_id_pat_allergy := i_id_pat_allergy(i);
            END IF;
        
            IF (i_id_allergy.exists(i))
            THEN
                l_id_allergy := i_id_allergy(i);
            END IF;
        
            IF (i_desc_allergy.exists(i))
            THEN
                l_desc_allergy := i_desc_allergy(i);
            END IF;
        
            IF (i_notes.exists(i))
            THEN
                l_notes := i_notes(i);
            END IF;
        
            IF (i_flg_status.exists(i))
            THEN
                l_flg_status := i_flg_status(i);
            END IF;
        
            IF (i_flg_type.exists(i))
            THEN
                l_flg_type := i_flg_type(i);
            END IF;
        
            l_flg_aproved := NULL;
        
            IF (i_desc_aproved.exists(i))
            THEN
                l_desc_aproved := i_desc_aproved(i);
            END IF;
        
            IF (i_date_occur.exists(i))
            THEN
                l_year_begin  := substr(i_date_occur(i), 1, 4);
                l_month_begin := substr(i_date_occur(i), 5, 2);
                l_day_begin   := substr(i_date_occur(i), 7, 2);
            END IF;
        
            IF (i_id_allergy_severity.exists(i))
            THEN
                l_id_allergy_severity := i_id_allergy_severity(i);
            END IF;
        
            IF (i_desc_edit.exists(i))
            THEN
                IF ((i_desc_edit(i) IS NOT NULL) AND (i_flg_edit(i) = g_flg_edit_other))
                THEN
                    l_desc_edit := i_desc_edit(i);
                ELSE
                    l_desc_edit := NULL;
                END IF;
            ELSE
                l_desc_edit := NULL;
            END IF;
        
            IF (i_flg_edit.exists(i))
            THEN
                IF (l_desc_edit IS NOT NULL)
                THEN
                    l_flg_edit := g_flg_edit_other;
                ELSE
                    l_flg_edit := i_flg_edit(i);
                END IF;
            ELSIF (l_id_pat_allergy IS NOT NULL)
            THEN
                l_flg_edit := g_flg_edit_other;
            END IF;
        
            IF (i_id_symptoms.exists(i))
            THEN
                l_id_symptoms := i_id_symptoms(i);
            END IF;
        
            IF (NOT set_allergy(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                l_id_pat_allergy,
                                l_id_allergy,
                                l_desc_allergy,
                                l_notes,
                                l_flg_status,
                                l_flg_type,
                                l_flg_aproved,
                                l_desc_aproved,
                                l_year_begin,
                                l_month_begin,
                                l_day_begin,
                                l_id_symptoms,
                                l_id_allergy_severity,
                                l_flg_edit,
                                l_desc_edit,
                                i_cdr_call,
                                o_id_pat_allergy(i),
                                o_error))
            THEN
                RAISE l_exception;
            END IF;
        
            -- whenever an allergy is created/edited stays automatically reviewed  
            IF NOT set_allergy_as_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_id_episode,
                                         i_id_pat_allergy => o_id_pat_allergy(i),
                                         i_review_notes   => NULL,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_message := 'call set_register_by_me_nc';
            IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_episode  => i_id_episode,
                                                     i_pat         => i_id_patient,
                                                     i_id_problem  => o_id_pat_allergy(i),
                                                     i_flg_type    => 'A',
                                                     i_flag_active => pk_alert_constant.g_yes,
                                                     o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_INTF',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_intf;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Flag nature
     * @param IN  i_dt_resolution         dt_resolution
     * @param OUT o_id_pat_allergy        ID pat allergy
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_problem_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_flg_nature          IN pat_allergy.flg_nature%TYPE,
        i_dt_resolution       IN pat_allergy.dt_resolution%TYPE,
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_allergy pat_allergy.id_pat_allergy%TYPE;
        l_dt_resolution  pat_allergy.dt_resolution%TYPE;
    
        l_exception EXCEPTION;
    
        l_rowids table_varchar;
    
    BEGIN
    
        IF NOT set_allergy_int(i_lang                   => i_lang,
                               i_prof                   => i_prof,
                               i_id_patient             => i_id_patient,
                               i_id_episode             => i_id_episode,
                               i_id_pat_allergy         => i_id_pat_allergy,
                               i_id_allergy             => i_id_allergy,
                               i_desc_allergy           => i_desc_allergy,
                               i_notes                  => i_notes,
                               i_flg_status             => i_flg_status,
                               i_flg_type               => i_flg_type,
                               i_flg_aproved            => i_flg_aproved,
                               i_desc_aproved           => i_desc_aproved,
                               i_year_begin             => i_year_begin,
                               i_month_begin            => i_month_begin,
                               i_day_begin              => i_day_begin,
                               i_year_end               => NULL,
                               i_month_end              => NULL,
                               i_day_end                => NULL,
                               i_id_symptoms            => i_id_symptoms,
                               i_id_allergy_severity    => i_id_allergy_severity,
                               i_flg_edit               => i_flg_edit,
                               i_desc_edit              => i_desc_edit,
                               i_flg_nature             => NULL,
                               i_dt_pat_allergy         => NULL,
                               i_cdr_call               => NULL,
                               i_flg_cda_reconciliation => 'N',
                               o_id_pat_allergy         => l_id_pat_allergy,
                               o_error                  => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- check if the resolution date changed 
        SELECT dt_resolution
          INTO l_dt_resolution
          FROM pat_allergy pa
         WHERE pa.id_pat_allergy = l_id_pat_allergy;
        -- This function was not completelly changed because we aim
        -- to reused the code already developed for set_pat_allergy.
        --
        -- So, after the insert/update we will update the pat_allergy table
        -- to fill the field flg_nature.
        --
        -- This approach seemed to be the better one since it reduces
        -- the impact of such change in the whole application.
        --IF (i_flg_nature IS NOT NULL)
        --   OR (nvl(i_dt_resolution, ' ') <> l_dt_resolution AND i_flg_nature IS NULL)
        --THEN
    
        ts_pat_allergy.upd(id_pat_allergy_in => l_id_pat_allergy,
                           flg_nature_in     => i_flg_nature,
                           dt_resolution_in  => i_dt_resolution,
                           dt_resolution_nin => FALSE,
                           rows_out          => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              pk_message.get_message(i_lang, 'ALLERGY_M045'),
                                              pk_message.get_message(i_lang, 'ALLERGY_M045'),
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_PROBLEM_NC',
                                              'U',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_PROBLEM_NC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_problem_nc;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Flag nature
     * @param IN  i_dt_resolution         dt_resolution
     * @param OUT o_id_pat_allergy        ID pat allergy
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_problem
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN NUMBER,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_flg_nature          IN pat_allergy.flg_nature%TYPE,
        i_dt_resolution       IN pat_allergy.dt_resolution%TYPE,
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_id_pat_allergy pat_allergy.id_pat_allergy%TYPE;
        l_rowids         table_varchar;
        l_dt_resolution  pat_allergy.dt_resolution%TYPE;
    
    BEGIN
    
        IF NOT set_allergy_problem_nc(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_patient          => i_id_patient,
                                      i_id_episode          => i_id_episode,
                                      i_id_pat_allergy      => i_id_pat_allergy,
                                      i_id_allergy          => i_id_allergy,
                                      i_desc_allergy        => i_desc_allergy,
                                      i_notes               => i_notes,
                                      i_flg_status          => i_flg_status,
                                      i_flg_type            => i_flg_type,
                                      i_flg_aproved         => i_flg_aproved,
                                      i_desc_aproved        => i_desc_aproved,
                                      i_year_begin          => i_year_begin,
                                      i_month_begin         => NULL,
                                      i_day_begin           => NULL,
                                      i_id_symptoms         => i_id_symptoms,
                                      i_id_allergy_severity => i_id_allergy_severity,
                                      i_flg_edit            => i_flg_edit,
                                      i_desc_edit           => i_desc_edit,
                                      i_flg_nature          => i_flg_nature,
                                      i_dt_resolution       => i_dt_resolution,
                                      o_id_pat_allergy      => o_id_pat_allergy,
                                      o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              pk_message.get_message(i_lang, 'ALLERGY_M045'),
                                              pk_message.get_message(i_lang, 'ALLERGY_M045'),
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_PROBLEM',
                                              'U',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_problem;

    /**
    * This function is can be used to INSERT/UPDATE a patient's allergy.
    *
    * @param IN  i_lang                  Language ID
    * @param IN  i_prof                  Professional structure
    * @param IN  i_id_patient            Patient ID
    * @param IN  i_id_episode            Episode ID
    * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
    * @param IN  i_id_allergy            Allergy ID
    * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
    * @param IN  i_notes                 Allergy Notes
    * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
    * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
    * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
    * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
    * @param IN  i_year_begin            Allergy start's year
    * @param IN  i_id_symptoms           Symptoms' date
    * @param IN  i_id_allergy_severity   Severity of the allergy
    * @param IN  i_flg_edit              Edit flag
    * @param IN  i_desc_edit             Description: reason of the edit action
    * @param IN  i_cdr_call              Rule engine call identifier
    * @param IN  i_flg_cda_reconciliation Identifies allergy record origin Y- CDA, N-PFH
    * @param OUT o_error                 Error structure
    * 
    * @return   BOOLEAN
    *
    * @version  2.6.4.0.3
    * @since    2014-May-27
    * @author   Gisela Couto
    */
    FUNCTION set_allergy
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN pat_allergy.id_patient%TYPE,
        i_id_episode             IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy             IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy           IN pat_allergy.desc_allergy%TYPE,
        i_notes                  IN pat_allergy.notes%TYPE,
        i_flg_status             IN pat_allergy.flg_status%TYPE,
        i_flg_type               IN pat_allergy.flg_type%TYPE,
        i_flg_aproved            IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved           IN pat_allergy.desc_aproved%TYPE,
        i_year_begin             IN pat_allergy.year_begin%TYPE,
        i_id_symptoms            IN table_number,
        i_day_begin              IN pat_allergy.day_begin%TYPE,
        i_month_begin            IN pat_allergy.month_begin%TYPE,
        i_id_allergy_severity    IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit               IN pat_allergy.flg_edit%TYPE,
        i_desc_edit              IN pat_allergy.desc_edit%TYPE,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE,
        o_id_pat_allergy         OUT pat_allergy.id_pat_allergy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_message VARCHAR(200);
        l_return  BOOLEAN;
    BEGIN
        l_message := 'PK_ALLERGY.SET_ALLERGY - SET NEW ALLERGY';
        IF NOT (set_allergy_int(i_lang                   => i_lang,
                                i_prof                   => i_prof,
                                i_id_patient             => i_id_patient,
                                i_id_episode             => i_id_episode,
                                i_id_pat_allergy         => i_id_pat_allergy,
                                i_id_allergy             => i_id_allergy,
                                i_desc_allergy           => i_desc_allergy,
                                i_notes                  => i_notes,
                                i_flg_status             => i_flg_status,
                                i_flg_type               => i_flg_type,
                                i_flg_aproved            => i_flg_aproved,
                                i_desc_aproved           => i_desc_aproved,
                                i_year_begin             => i_year_begin,
                                i_month_begin            => i_month_begin,
                                i_day_begin              => i_day_begin,
                                i_year_end               => NULL,
                                i_month_end              => NULL,
                                i_day_end                => NULL,
                                i_id_symptoms            => i_id_symptoms,
                                i_id_allergy_severity    => i_id_allergy_severity,
                                i_flg_edit               => i_flg_edit,
                                i_desc_edit              => i_desc_edit,
                                i_flg_nature             => NULL,
                                i_dt_pat_allergy         => NULL,
                                i_cdr_call               => i_cdr_call,
                                i_flg_cda_reconciliation => i_flg_cda_reconciliation,
                                o_id_pat_allergy         => o_id_pat_allergy,
                                o_error                  => o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        l_message := 'PK_ALLERGY.SET_ALLERGY - SET ALLERGY AS REVIEWED';
        -- whenever an allergy is created/edited stays automatically reviewed  
        IF NOT set_allergy_as_review(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => i_id_episode,
                                     i_id_pat_allergy => o_id_pat_allergy,
                                     i_review_notes   => NULL,
                                     o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_message := 'PK_ALLERGY.SET_ALLERGY - SET ALLERGY REVIEWED BY ME';
        IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_episode  => i_id_episode,
                                                 i_pat         => i_id_patient,
                                                 i_id_problem  => o_id_pat_allergy,
                                                 i_flg_type    => 'A',
                                                 i_flag_active => pk_alert_constant.g_yes,
                                                 o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.0.3.4
     * @since    2010-Nov-24
     * @author   Rui Duarte
    */
    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message VARCHAR(200);
        l_return  BOOLEAN;
    BEGIN
        l_message := 'PK_ALLERGY.SET_ALLERGY';
        l_return  := set_allergy_int(i_lang,
                                     i_prof,
                                     i_id_patient,
                                     i_id_episode,
                                     i_id_pat_allergy,
                                     i_id_allergy,
                                     i_desc_allergy,
                                     i_notes,
                                     i_flg_status,
                                     i_flg_type,
                                     i_flg_aproved,
                                     i_desc_aproved,
                                     i_year_begin,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     i_id_symptoms,
                                     i_id_allergy_severity,
                                     i_flg_edit,
                                     i_desc_edit,
                                     NULL,
                                     NULL,
                                     i_cdr_call,
                                     'N',
                                     o_id_pat_allergy,
                                     o_error);
    
        COMMIT;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy;

    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message VARCHAR(200);
        l_return  BOOLEAN;
    BEGIN
        l_message := 'PK_ALLERGY.SET_ALLERGY';
        l_return  := set_allergy_int(i_lang,
                                     i_prof,
                                     i_id_patient,
                                     i_id_episode,
                                     i_id_pat_allergy,
                                     i_id_allergy,
                                     i_desc_allergy,
                                     i_notes,
                                     i_flg_status,
                                     i_flg_type,
                                     i_flg_aproved,
                                     i_desc_aproved,
                                     i_year_begin,
                                     i_month_begin,
                                     i_day_begin,
                                     NULL,
                                     NULL,
                                     NULL,
                                     i_id_symptoms,
                                     i_id_allergy_severity,
                                     i_flg_edit,
                                     i_desc_edit,
                                     NULL,
                                     NULL,
                                     i_cdr_call,
                                     'N',
                                     o_id_pat_allergy,
                                     o_error);
    
        COMMIT;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_month_begin           Allergy start's month
     * @param IN  i_day_begin             Allergy start's day
     * @param IN  i_year_end              Allergy end year
     * @param IN  i_month_end             Allergy end month
     * @param IN  i_day_end               Allergy end day
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Allergy Nature
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param IN  i_flg_cda_reconciliation Identifies allergy record origin Y- CDA, N-PFH
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_int
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN pat_allergy.id_patient%TYPE,
        i_id_episode             IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy             IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy           IN pat_allergy.desc_allergy%TYPE,
        i_notes                  IN pat_allergy.notes%TYPE,
        i_flg_status             IN pat_allergy.flg_status%TYPE,
        i_flg_type               IN pat_allergy.flg_type%TYPE,
        i_flg_aproved            IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved           IN pat_allergy.desc_aproved%TYPE,
        i_year_begin             IN pat_allergy.year_begin%TYPE,
        i_month_begin            IN pat_allergy.month_begin%TYPE,
        i_day_begin              IN pat_allergy.day_begin%TYPE,
        i_year_end               IN pat_allergy.year_end%TYPE,
        i_month_end              IN pat_allergy.month_end%TYPE,
        i_day_end                IN pat_allergy.day_end%TYPE,
        i_id_symptoms            IN table_number,
        i_id_allergy_severity    IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit               IN pat_allergy.flg_edit%TYPE,
        i_desc_edit              IN pat_allergy.desc_edit%TYPE,
        i_flg_nature             IN pat_allergy.flg_nature%TYPE,
        i_dt_pat_allergy         IN pat_allergy.dt_pat_allergy_tstz%TYPE,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        o_id_pat_allergy         OUT pat_allergy.id_pat_allergy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception      EXCEPTION;
        l_user_exception EXCEPTION;
        l_count              PLS_INTEGER := 0;
        l_next               pat_allergy.id_pat_allergy%TYPE;
        l_sysdate_tstz       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_first_time_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_desc_allergy       pat_allergy.desc_allergy%TYPE := i_desc_allergy;
    
        l_id_patient    NUMBER := NULL;
        l_patient_count PLS_INTEGER := 0;
        l_message       VARCHAR(200);
        l_revision      PLS_INTEGER := 0;
    
        l_rowids table_varchar;
    
    BEGIN
    
        l_message := 'SET_ALLERGY';
    
        IF i_dt_pat_allergy IS NULL
        THEN
            l_sysdate_tstz       := current_timestamp;
            l_dt_first_time_tstz := current_timestamp;
        ELSE
            l_sysdate_tstz       := i_dt_pat_allergy;
            l_dt_first_time_tstz := i_dt_pat_allergy;
        END IF;
    
        IF (i_id_allergy > 0)
        THEN
            l_desc_allergy := NULL;
        END IF;
    
        -- This piece of code are developed to ensure the well behaviour
        -- of this function
        BEGIN
        
            SELECT id_patient
              INTO l_patient_count
              FROM patient p
             WHERE p.id_patient = i_id_patient;
        
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                
                    SELECT e.id_patient
                      INTO l_id_patient
                      FROM episode e
                     WHERE e.id_episode = i_id_episode;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_patient := NULL;
                    
                END;
        END;
    
        -- ------------------------------------------------------------------ --
        -- update the status of unawareness registers
        --
        -- 1 - "Unable to assess allergies" and 2 - "No known allergies" must be
        -- outdated because we are going to register a new allergy
        -- 
        g_error := 'ts_pat_allergy_unawareness.upd';
        ts_pat_allergy_unawareness.upd(flg_status_in  => g_unawareness_outdated,
                                       id_episode_in  => i_id_episode,
                                       id_episode_nin => FALSE,
                                       where_in       => 'id_allergy_unawareness in(' || g_unable_asess || ',' ||
                                                         g_no_known || ') and id_patient = ' || i_id_patient ||
                                                         ' and flg_status = ''' || g_unawareness_active || '''',
                                       rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- Verifies if the allergy is a drug allergy
        IF (is_drug_allergy(i_id_allergy))
        THEN
            -- In this case we have to update the "No known drug allergies"
            -- to OUTDATED
            g_error := 'ts_pat_allergy_unawareness.upd';
            ts_pat_allergy_unawareness.upd(flg_status_in  => g_unawareness_outdated,
                                           id_episode_in  => i_id_episode,
                                           id_episode_nin => FALSE,
                                           where_in       => 'id_allergy_unawareness = ' || g_no_known_drugs ||
                                                             ' and id_patient = ' || i_id_patient ||
                                                             ' and flg_status = ''' || g_unawareness_active || '''',
                                           rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
        --
        -- ------------------------------------------------------------------ --
    
        IF (i_id_pat_allergy IS NOT NULL)
        THEN
            -- UPDATE
            l_message := 'SET_ALLERGY - SET_ALLERGY_HISTORY';
            IF (NOT set_allergy_history(i_lang, i_id_pat_allergy, o_error))
            THEN
                RAISE l_exception;
            END IF;
        
            SELECT revision + 1
              INTO l_revision
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
        
            l_message := 'UPDATE PAT_ALLERGY';
            ts_pat_allergy.upd(id_pat_allergy_in          => i_id_pat_allergy,
                               id_allergy_in              => i_id_allergy,
                               flg_status_in              => i_flg_status,
                               notes_in                   => i_notes,
                               notes_nin                  => FALSE,
                               id_prof_write_in           => i_prof.id,
                               flg_type_in                => i_flg_type,
                               flg_aproved_in             => i_flg_aproved,
                               year_begin_in              => i_year_begin,
                               year_begin_nin             => FALSE,
                               month_begin_in             => i_month_begin,
                               month_begin_nin            => FALSE,
                               day_begin_in               => i_day_begin,
                               day_begin_nin              => FALSE,
                               year_end_in                => i_year_end,
                               year_end_nin               => FALSE,
                               month_end_in               => i_month_end,
                               month_end_nin              => FALSE,
                               day_end_in                 => i_day_end,
                               day_end_nin                => FALSE,
                               id_institution_in          => i_prof.institution,
                               id_episode_in              => i_id_episode,
                               dt_pat_allergy_tstz_in     => l_dt_first_time_tstz,
                               id_allergy_severity_in     => i_id_allergy_severity,
                               desc_allergy_in            => l_desc_allergy,
                               desc_allergy_nin           => FALSE,
                               flg_edit_in                => i_flg_edit,
                               desc_edit_in               => i_desc_edit,
                               desc_edit_nin              => FALSE,
                               desc_aproved_in            => i_desc_aproved,
                               desc_aproved_nin           => TRUE,
                               revision_in                => l_revision,
                               flg_nature_in              => i_flg_nature,
                               flg_nature_nin             => FALSE,
                               id_cdr_call_in             => i_cdr_call,
                               id_cdr_call_nin            => TRUE,
                               flg_cda_reconciliation_in  => i_flg_cda_reconciliation,
                               flg_cda_reconciliation_nin => TRUE,
                               rows_out                   => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF (i_id_symptoms.exists(1))
            THEN
            
                IF (i_id_symptoms.count > 0)
                THEN
                
                    DELETE FROM pat_allergy_symptoms pas
                     WHERE pas.id_pat_allergy = i_id_pat_allergy;
                
                    FORALL i IN i_id_symptoms.first .. i_id_symptoms.last
                        INSERT INTO pat_allergy_symptoms pas
                            (id_pat_allergy, id_allergy_symptoms, revision)
                        VALUES
                            (i_id_pat_allergy, i_id_symptoms(i), l_revision);
                END IF;
            
            END IF;
        
            o_id_pat_allergy := i_id_pat_allergy;
        ELSE
        
            -- INSERT
            -- Verificar se a alergia ja esta registada para o paciente
            IF (i_flg_type = g_flg_type_allergy)
            THEN
            
                SELECT COUNT(id_pat_allergy)
                  INTO l_count
                  FROM pat_allergy pa
                 WHERE pa.id_allergy = i_id_allergy
                   AND pa.id_patient = nvl(l_id_patient, i_id_patient)
                   AND pa.flg_type = g_flg_type_allergy
                   AND pa.flg_status = g_pat_allergy_flg_active;
            
                IF (l_count > 0)
                THEN
                    RAISE l_user_exception;
                END IF;
            
            END IF;
        
            SELECT seq_pat_allergy.nextval
              INTO l_next
              FROM dual;
        
            l_message := 'INSERT PAT ALLERGY';
            ts_pat_allergy.ins(id_pat_allergy_in         => l_next,
                               id_allergy_in             => i_id_allergy,
                               id_patient_in             => nvl(l_id_patient, i_id_patient),
                               flg_status_in             => i_flg_status,
                               notes_in                  => i_notes,
                               id_prof_write_in          => i_prof.id,
                               flg_type_in               => i_flg_type,
                               flg_aproved_in            => i_flg_aproved,
                               year_begin_in             => i_year_begin,
                               month_begin_in            => i_month_begin,
                               day_begin_in              => i_day_begin,
                               year_end_in               => i_year_end,
                               month_end_in              => i_month_end,
                               day_end_in                => i_day_end,
                               id_institution_in         => i_prof.institution,
                               id_episode_in             => i_id_episode,
                               dt_first_time_tstz_in     => l_dt_first_time_tstz,
                               dt_pat_allergy_tstz_in    => l_dt_first_time_tstz,
                               id_cancel_reason_in       => NULL,
                               cancel_notes_in           => NULL,
                               id_allergy_severity_in    => i_id_allergy_severity,
                               desc_allergy_in           => l_desc_allergy,
                               flg_edit_in               => i_flg_edit,
                               flg_cancel_in             => NULL,
                               desc_edit_in              => i_desc_edit,
                               desc_aproved_in           => i_desc_aproved,
                               revision_in               => 1,
                               flg_nature_in             => i_flg_nature,
                               id_cdr_call_in            => i_cdr_call,
                               flg_cda_reconciliation_in => i_flg_cda_reconciliation,
                               rows_out                  => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF (i_id_symptoms.exists(1))
            THEN
            
                IF (i_id_symptoms.count > 0)
                THEN
                    FORALL i IN i_id_symptoms.first .. i_id_symptoms.last
                        INSERT INTO pat_allergy_symptoms pas
                            (id_pat_allergy, id_allergy_symptoms, revision)
                        VALUES
                            (l_next, i_id_symptoms(i), 1);
                END IF;
            
            END IF;
        
            o_id_pat_allergy := l_next;
        
        END IF;
    
        l_message := 'SET_ALLERGY - CALL TO PK_VISIT.SET_FIRST_OBS';
        IF (NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                       i_id_episode          => NULL,
                                       i_pat                 => nvl(l_id_patient, i_id_patient),
                                       i_prof                => i_prof,
                                       i_prof_cat_type       => NULL,
                                       i_dt_last_interaction => l_sysdate_tstz,
                                       i_dt_first_obs        => l_sysdate_tstz,
                                       o_error               => o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_user_exception THEN
            l_message := pk_message.get_message(i_lang, 'ALLERGY_M045');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              l_message,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY',
                                              'U',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_int;

    /**
     * This functions sets a patient allergy as active
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy ID
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_as_active
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN table_number,
        i_episode        IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_rowids table_varchar;
    
    BEGIN
        l_message := 'SET_ALLERGY_AS_ACTIVE';
    
        FOR i IN 1 .. i_id_pat_allergy.count
        LOOP
        
            IF (NOT set_allergy_history(i_lang, i_id_pat_allergy(i), o_error))
            THEN
                RAISE l_exception;
            END IF;
        
            l_message := 'UPDATE PAT_ALLERGY';
            ts_pat_allergy.upd(id_pat_allergy_in      => i_id_pat_allergy(i),
                               flg_status_in          => g_pat_allergy_flg_active,
                               cancel_notes_in        => NULL,
                               id_cancel_reason_in    => NULL,
                               id_prof_write_in       => i_prof.id,
                               flg_edit_in            => g_flg_edit_other,
                               dt_pat_allergy_tstz_in => current_timestamp,
                               revision_in            => set_next_revision(i_lang, i_prof, i_id_pat_allergy(i)),
                               id_episode_in          => i_episode,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- whenever an allergy is created/edited stays automatically reviewed  
            IF NOT set_allergy_as_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_episode,
                                         i_id_pat_allergy => i_id_pat_allergy(i),
                                         i_review_notes   => NULL,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_AS_ACTIVE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy_as_active;

    /**
     * This functions sets a patient allergy as inactive
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy ID
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_as_inactive
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN table_number,
        i_episode        IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_rowids table_varchar;
    
    BEGIN
        l_message := 'SET_ALLERGY_AS_INACTIVE';
    
        FOR i IN 1 .. i_id_pat_allergy.count
        LOOP
        
            IF (NOT set_allergy_history(i_lang, i_id_pat_allergy(i), o_error))
            THEN
                RAISE l_exception;
            END IF;
        
            l_message := 'UPDATE PAT_ALLERGY';
            ts_pat_allergy.upd(id_pat_allergy_in      => i_id_pat_allergy(i),
                               flg_status_in          => g_pat_allergy_flg_passive,
                               cancel_notes_in        => NULL,
                               id_cancel_reason_in    => NULL,
                               id_prof_write_in       => i_prof.id,
                               flg_edit_in            => g_flg_edit_other,
                               revision_in            => set_next_revision(i_lang, i_prof, i_id_pat_allergy(i)),
                               dt_pat_allergy_tstz_in => current_timestamp,
                               id_episode_in          => i_episode,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- whenever an allergy is created/edited stays automatically reviewed  
            IF NOT set_allergy_as_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_episode,
                                         i_id_pat_allergy => i_id_pat_allergy(i),
                                         i_review_notes   => NULL,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_AS_INACTIVE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy_as_inactive;
    /**
     * This functions sets a patient allergy as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy ID
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Oct-22
     * @author   Thiago Brito
    */

    FUNCTION set_allergy_as_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
    
        l_alergy_review_area review_detail.flg_context%TYPE;
    
    BEGIN
        l_alergy_review_area := pk_review.get_allergies_context();
    
        l_message := 'SET_ALLERGY_AS_REVIEW';
        IF (NOT pk_review.set_review(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_record_area => i_id_pat_allergy,
                                     i_flg_context    => l_alergy_review_area,
                                     i_dt_review      => current_timestamp,
                                     i_review_notes   => i_review_notes,
                                     i_episode        => i_episode,
                                     i_flg_auto       => pk_alert_constant.g_yes,
                                     i_revision       => get_revision(i_lang, i_prof, i_id_pat_allergy),
                                     o_error          => o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_AS_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_as_review;

    /**
     * This function sets one or several patient allergies as "reviewed"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy's ID's
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.1.2
     * @since    19-Oct-2010
     * @author   Filipe Machado
    */
    FUNCTION set_allergy_as_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_pat_allergy IN table_number,
        i_review_notes   IN review_detail.review_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
    
        l_alergy_review_area review_detail.flg_context%TYPE;
    
    BEGIN
        l_alergy_review_area := pk_review.get_allergies_context();
    
        FOR i IN 1 .. i_id_pat_allergy.count
        LOOP
            l_message := 'SET_ALLERGY_AS_REVIEW';
            IF (NOT pk_review.set_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_id_record_area => i_id_pat_allergy(i),
                                         i_flg_context    => l_alergy_review_area,
                                         i_dt_review      => current_timestamp,
                                         i_review_notes   => i_review_notes,
                                         i_episode        => i_episode,
                                         i_flg_auto       => pk_alert_constant.g_no,
                                         i_revision       => get_revision(i_lang, i_prof, i_id_pat_allergy(i)),
                                         o_error          => o_error))
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_AS_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_as_review;

    FUNCTION set_allergy_unawareness
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_unawareness     IN allergy_unawareness.id_allergy_unawareness%TYPE,
        i_pat_unawareness IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_notes           IN pat_allergy.notes%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
        l_dummy pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE;
    BEGIN
        g_error := 'set_allergy_unawareness_no_com';
        pk_alertlog.log_debug(g_error);
    
        IF NOT set_allergy_unawareness_no_com(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_episode         => i_episode,
                                              i_patient         => i_patient,
                                              i_unawareness     => i_unawareness,
                                              i_pat_unawareness => i_pat_unawareness,
                                              o_pat_unawareness => l_dummy,
                                              i_notes           => i_notes,
                                              o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy_unawareness;

    /**
     * This function is used to register an allergy unawareness.
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional ID
     * @param IN   i_episode           Episode ID
     * @param IN   i_patient           Patient ID
     * @param IN   i_pat_unawareness   Pat Allergy Unawareness ID
     * @param IN   i_notes             Notes
     * @param OUT  o_error             Error structure
     * 
     * @return BOOLEAN
     * 
     * @version  2.4.4
     * @since    2009-Mar-30
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_unawareness_no_com
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_unawareness     IN allergy_unawareness.id_allergy_unawareness%TYPE,
        i_pat_unawareness IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_notes           IN pat_allergy.notes%TYPE,
        o_pat_unawareness OUT pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_id_pau_next pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE;
        l_rowids      table_varchar := table_varchar();
    
    BEGIN
    
        IF (i_unawareness = g_unable_asess)
        THEN
        
            -- Both "No known allergies" and "No known drug allergies"
            -- must be updated OUTDATED for the same episode
            g_error := 'ts_pat_allergy_unawareness.upd';
            ts_pat_allergy_unawareness.upd(flg_status_in => g_unawareness_outdated,
                                           where_in      => 'id_allergy_unawareness in (' || g_no_known || ',' ||
                                                            g_no_known_drugs || ',' || g_unable_asess ||
                                                            ') and id_patient = ' || i_patient || ' and id_episode = ' ||
                                                            i_episode || ' and flg_status <> ''' ||
                                                            g_unawareness_cancelled || '''',
                                           rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSIF ((i_unawareness = g_no_known) OR (i_unawareness = g_no_known_drugs))
        THEN
            -- Only "Unable to assess allergies" must be updated to OUTDATED
            g_error := 'ts_pat_allergy_unawareness.upd';
            ts_pat_allergy_unawareness.upd(flg_status_in => g_unawareness_outdated,
                                           where_in      => '(id_allergy_unawareness not in(' || g_no_known || ',' ||
                                                            g_no_known_drugs || ') or id_allergy_unawareness = ' ||
                                                            i_unawareness || ') and id_patient = ' || i_patient ||
                                                            ' and flg_status <> ''' || g_unawareness_cancelled || '''',
                                           rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        l_id_pau_next := ts_pat_allergy_unawareness.next_key;
    
        IF i_pat_unawareness IS NOT NULL
        THEN
            g_error := 'ts_pat_allergy_unawareness.upd';
            ts_pat_allergy_unawareness.upd(flg_status_in => g_unawareness_outdated,
                                           where_in      => 'id_pat_allergy_unawareness = ' || i_pat_unawareness,
                                           rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        g_error := 'ts_pat_allergy_unawareness.ins';
        ts_pat_allergy_unawareness.ins(id_pat_allergy_unawareness_in => l_id_pau_next,
                                       id_allergy_unawareness_in     => i_unawareness,
                                       id_professional_in            => i_prof.id,
                                       id_patient_in                 => i_patient,
                                       id_episode_in                 => i_episode,
                                       notes_in                      => i_notes,
                                       dt_creation_in                => current_timestamp,
                                       flg_status_in                 => g_unawareness_active,
                                       rows_out                      => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_pat_unawareness := l_id_pau_next;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY_UNAWARENESS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_allergy_unawareness_no_com;

    /**
     * This function verifies weather the patient has an previous allergy
     * registered or not .
     * It returns 1 if the patient HAS NO allergy and 0 if the patient already
     * has an allergy registered.
     * 
     * 1 - No allergy
     * 0 - The patient has at leat one allergy
     *
     * @param IN   i_patient  Patient ID
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-31
     * @author   Thiago Brito
    */
    FUNCTION exists_no_recorded_allergy(i_patient IN patient.id_patient%TYPE) RETURN PLS_INTEGER IS
    
        l_return PLS_INTEGER := 0;
    
    BEGIN
    
        SELECT decode(COUNT(pa.id_pat_allergy), 0, 1, 0)
          INTO l_return
          FROM pat_allergy pa
         WHERE pa.id_patient = i_patient
           AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_passive);
    
        RETURN l_return;
    
    END exists_no_recorded_allergy;

    /**
     * This function verifies if the patient has non-drug allergy only. This
     * function returns 1 if the patient has only non-drug allergy. If the patient
     * has no allergy or if he/she has one or more drug allergy registered then
     * the function returns 0.
     *
     * 1 - Only non-drug allergy
     * 0 - The patient has drug allergy or has no allergy
     *
     * @param IN   i_patient  Patient ID
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-31
     * @author   Thiago Brito
    */
    FUNCTION exists_non_drug_allergy(i_patient IN patient.id_patient%TYPE) RETURN PLS_INTEGER IS
    
        l_return PLS_INTEGER := 0;
    
    BEGIN
    
        IF (exists_no_recorded_allergy(i_patient) = 1)
        THEN
            -- The patient has no allergy
            RETURN l_return;
        
        ELSE
        
            IF (exists_drug_allergy(i_patient) = 1)
            THEN
                -- The patient has at least one drug allergy registered
                RETURN l_return;
            ELSE
                SELECT decode(COUNT(id_pat_allergy), 0, 0, 1)
                  INTO l_return
                  FROM pat_allergy pa
                 WHERE pa.id_allergy IN
                       (SELECT a.id_allergy
                          FROM allergy_inst_soft_market a
                         WHERE a.id_allergy_parent IN
                               (g_drug_id_allergy, g_drug_class_id_allergy, g_drug_com_id_allergy));
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END exists_non_drug_allergy;

    /**
     * This function verifies if the patient has any drug allergy (only). It
     * returns 1 if the patient has at least one drug allergy and 0 if he/she
     * has no allergy or at least one non-drug allergy registered.
     *
     * 1 - Drug allergy (only)
     * 0 - No allergy or at least one non-drug allergy
     *
     * @param IN   i_patient  Patient ID
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-31
     * @author   Thiago Brito
    */
    FUNCTION exists_drug_allergy(i_patient IN patient.id_patient%TYPE) RETURN PLS_INTEGER IS
    
        l_return PLS_INTEGER := 0;
    
    BEGIN
    
        IF (exists_no_recorded_allergy(i_patient) = 1)
        THEN
            -- The patient has no allergy
            RETURN l_return;
        ELSE
        
            SELECT decode(COUNT(id_pat_allergy), 0, 1, 0)
              INTO l_return
              FROM pat_allergy pa
             WHERE pa.id_allergy IN
                   (SELECT a.id_allergy
                      FROM allergy_inst_soft_market a
                     WHERE a.id_allergy_parent IN (g_drug_id_allergy, g_drug_class_id_allergy, g_drug_com_id_allergy));
        
        END IF;
    
        RETURN l_return;
    
    END exists_drug_allergy;

    /**
     * This function returns the actions used to:
     *
     * 1) Add a New allergy
     * 2) Add a New record of allergy unawareness
     *
     * @param IN   i_lang     Language ID
     * @param IN   i_patient  Patient ID
     * @param OUT  o_cursor   Add actions cursor
     * @param OUT  o_error    Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_add_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message              debug_msg;
        k_drug_alergy_shortcut action.flg_status%TYPE := 'S';
        l_drug_allergy_short   sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'ALLERGY_DRUG_SHORT_AVAILABLE',
                                                                                i_prof_inst => i_prof.institution,
                                                                                i_prof_soft => i_prof.software);
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT id_action,
                   id_parent,
                   LEVEL,
                   to_state,
                   pk_message.get_message(i_lang, code_action) desc_action,
                   icon,
                   flg_default action_type,
                   flg_status AS action_statement,
                   internal_name,
                   decode(exists_no_recorded_allergy(i_patient),
                          1,
                          pk_alert_constant.g_yes,
                          decode(exists_non_drug_allergy(i_patient),
                                 1,
                                 decode(id_action, g_new_allergy_adr, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                                 decode(exists_drug_allergy(i_patient),
                                        1,
                                        decode(id_action,
                                               g_new_allergy_adr,
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no)))) flg_enable
              FROM action a
             WHERE subject = 'ALLERGY.PLUS_BUTTON'
               AND ((a.flg_status <> k_drug_alergy_shortcut AND l_drug_allergy_short = pk_alert_constant.g_no) OR
                   l_drug_allergy_short <> pk_alert_constant.g_no)
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ADD_ACTIONS',
                                                     o_error);
        
    END get_add_actions;

    /**
     * This function returns the following values:
     *
     * 1) Active
     * 2) Passive
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Status messages cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT *
              FROM sys_domain sd
             WHERE sd.code_domain = g_pat_allergy_status
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val IN (g_pat_allergy_flg_active, g_pat_allergy_flg_passive)
             ORDER BY sd.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_STATUS_LIST',
                                                     o_error);
        
    END get_status_list;

    /**
     * This function returns the following values:
     *
     * 1) Allergy
     * 2) Adverse reaction
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Type messages cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_type_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT *
              FROM sys_domain sd
             WHERE sd.code_domain = g_pat_allergy_type
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_TYPE_LIST',
                                                     o_error);
        
    END get_type_list;

    /**
     * This function returns all symptoms registered in the data base
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Symptoms cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_symptoms_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT id_allergy_symptoms, code_allergy_symptoms, rank, symptoms
              FROM (SELECT s.id_allergy_symptoms,
                           s.code_allergy_symptoms,
                           decode(s.id_allergy_symptoms, 13, 1, 0) rank,
                           pk_translation.get_translation(i_lang, s.code_allergy_symptoms) symptoms
                      FROM allergy_symptoms s
                     WHERE s.flg_status = pk_alert_constant.g_active)
             WHERE symptoms IS NOT NULL
             ORDER BY rank, symptoms;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_SYMPTOMS_LIST',
                                                     o_error);
        
    END get_symptoms_list;

    /**
     * This function returns the following values:
     *
     * 1) Clinically documented
     * 2) Patient
     * 3) Escorter
     * 4) Family member
     * 5) Other
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  "Reported by" list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_font_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT *
              FROM sys_domain sd
             WHERE sd.code_domain = g_pat_allergy_aproved
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank, sd.desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_FONT_LIST',
                                                     o_error);
        
    END get_font_list;

    /**
     * This function returns the list of "severities" registered in the DB
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Severity cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_severity_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT s.id_allergy_severity,
                   s.code_allergy_severity,
                   pk_translation.get_translation(i_lang, s.code_allergy_severity) severity
              FROM allergy_severity s
             WHERE s.flg_status = pk_alert_constant.g_active;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_SEVERITY_LIST',
                                                     o_error);
        
    END get_severity_list;

    /**
     * This function returns the following values:
     *
     * 1) Cancel
     * 2) Edit
     * 3) Show as active
     * 4) Show as inactive
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Actions cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_actions_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT id_action,
                   id_parent,
                   LEVEL,
                   to_state,
                   pk_message.get_message(i_lang, code_action) desc_action,
                   icon,
                   flg_default action_type,
                   flg_status AS action_statement,
                   internal_name
              FROM action a
             WHERE subject = 'ALLERGY'
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ACTIONS_LIST',
                                                     o_error);
        
    END get_actions_list;

    /**
     * This function returs a list of editing reasons
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Edit reasons list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_edit_reason_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT *
              FROM sys_domain sd
             WHERE sd.code_domain = g_pat_allergy_edit
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = pk_alert_constant.g_yes
             ORDER BY sd.rank, sd.desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_EDIT_REASON_LIST',
                                                     o_error);
        
    END get_edit_reason_list;

    /**
     * This function returns the following values:
     *
     * 1) Entered by error
     * 2) Wrong patient
     * 3) Other
     *
     * @param IN   i_lang    Language ID
     * @param IN   i_prof    Profissional
     * @param OUT  o_cursor  Edit reasons list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_cancel_reason_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_cancel_reason_area VARCHAR2(200) := 'ALLERGY.CANCEL_REASON';
    
    BEGIN
        l_message := 'OPEN o_cursor';
        IF (NOT pk_cancel_reason.get_cancel_reason_list(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_area    => l_cancel_reason_area,
                                                        o_reasons => o_cursor,
                                                        o_error   => o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_CANCEL_REASON_LIST',
                                                     o_error);
        
    END get_cancel_reason_list;

    /**
     * This function returns the following values:
     *
     * 1) Entered by error
     * 2) Wrong patient
     * 3) Other
     *
     * @param IN   i_lang    Language ID
     * @param IN   i_prof    Profissional
     * @param OUT  o_cursor  Edit reasons list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_cancel_unaware_reason_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_cancel_reason_area VARCHAR2(200) := 'UNAWARENESS.CANCEL_REASON';
    
    BEGIN
        l_message := 'OPEN o_cursor';
        IF (NOT pk_cancel_reason.get_cancel_reason_list(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_area    => l_cancel_reason_area,
                                                        o_reasons => o_cursor,
                                                        o_error   => o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_CANCEL_UNAWARE_REASON_LIST',
                                                     o_error);
        
    END get_cancel_unaware_reason_list;

    /**
     * This function returns the status message string for the allergy.
     * This function cannot be used by outside this package. This function
     * was not developed to access data base data directly. This function 
     * only build the string according to the i_flg_status and i_desc_status
     * parameters.
     *
     * @param  IN i_flg_status         Flag status
     * @param  IN i_desc_status        Status description (already translated)
     *
     * @return VARCHAR2
     *
     * @version   2.4.4
     * @since     2009-Apr-02
     * @author    Thiago Brito
    */
    FUNCTION get_status_string
    (
        i_flg_status  IN VARCHAR2,
        i_desc_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_shortcut      PLS_INTEGER := NULL;
        l_display_type  VARCHAR2(2) := 'T';
        l_date          VARCHAR2(200) := NULL; -- [<year> <month> <day> <hour> <minute> <second>]
        l_text          VARCHAR2(200);
        l_icon_name     VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200); -- [?x?<red>  <green>  <blue>]
        l_message_style VARCHAR2(200) := NULL;
        l_message_color VARCHAR2(200) := NULL;
        l_icon_color    VARCHAR2(200) := NULL;
        l_date_server   TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        l_text := i_desc_status;
    
        CASE i_flg_status
            WHEN 'A' THEN
                -- ACTIVO
                l_back_color    := pk_alert_constant.g_color_red; -- VERMELHO
                l_icon_color    := pk_alert_constant.g_color_red;
                l_message_style := g_font_p;
            WHEN 'P' THEN
                -- PASSIVO
                l_back_color    := pk_alert_constant.g_color_orange; -- LARANJA
                l_icon_color    := pk_alert_constant.g_color_orange;
                l_message_style := g_font_p;
            ELSE
                -- RESOLVIDO
                l_back_color    := g_color_beige;
                l_icon_color    := g_color_beige;
                l_message_style := g_font_o;
        END CASE;
    
        RETURN l_shortcut || '|' || l_display_type || '|' || l_date || '|' || l_text || '|' || l_icon_name || '|' || l_back_color || '|' || l_message_style || '|' || l_message_color || '|' || l_icon_color || '|' || l_date_server;
    
    END get_status_string;

    /**
     * This function return the color's code according to the
     * allergy's status.
     *
     * @param i_flg_status
     *
     * @return VARCHAR2
     *
     * @version   2.4.4
     * @since     2009-Apr-08
     * @author    Thiago Brito
    */
    FUNCTION get_status_color(i_flg_status IN VARCHAR2) RETURN VARCHAR2 IS
    
    BEGIN
    
        CASE i_flg_status
            WHEN 'A' THEN
                -- ACTIVO
                RETURN pk_alert_constant.g_color_red; -- VERMELHO
            WHEN 'P' THEN
                -- PASSIVO
                RETURN pk_alert_constant.g_color_orange; -- LARANJA
            ELSE
                -- RESOLVIDO
                RETURN g_color_beige;
        END CASE;
    
    END get_status_color;

    /*************************************************************************\
    * Name :                 get_count_and_first                              *
    * Description:           VIEWER API -> Returns ALLERGY total              *
    *                                      and first record                   *
    *                                                                         *
    * @param i_lang          Input - Language ID                              *
    * @param i_prof          Input - Professional array                       *
    * @param i_patient       Input - Patient ID                               *
    * @param o_num_occur     Output - Total patient allergies                 *
    * @param o_desc_first    Output - First allergy description               *
    * @param o_dt_first      Output - First allergy date,                     *
    *                                 according the sort criteria parameters  *
    *                                                                         *
    * @author                Nuno Miguel Ferreira                             *
    * @version               1.0                                              *
    * @since                 2008/11/13                                       *
    \*************************************************************************/
    FUNCTION get_count_and_first
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        o_num_occur  OUT NUMBER,
        o_desc_first OUT VARCHAR2,
        o_code       OUT VARCHAR2,
        o_dt_first   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_fmt     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_list  pk_types.cursor_type;
        l_count NUMBER := 0;
    
        l_id               pat_allergy.id_pat_allergy%TYPE;
        l_code_description translation.code_translation%TYPE;
        l_description      pk_translation.t_desc_translation;
        l_title            sys_domain.desc_val%TYPE;
        l_dt_begin         TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_fmt     VARCHAR2(1);
        l_dt_req           VARCHAR2(1000 CHAR);
        l_flg_status       pat_allergy.flg_status%TYPE;
        l_flg_type         pat_allergy.flg_type%TYPE;
        l_desc_status      VARCHAR2(200);
        l_rank             NUMBER;
        l_dt_diff          NUMBER;
        l_task_title       sys_message.desc_message%TYPE;
    
    BEGIN
        l_message := 'GET ORDERED LIST';
        IF get_ordered_list(i_lang         => i_lang,
                            i_prof         => i_prof,
                            i_patient      => i_patient,
                            i_translate    => pk_alert_constant.g_no,
                            o_ordered_list => l_list,
                            o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_title,
                         l_dt_begin,
                         l_dt_begin_fmt,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_dt_diff,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
                l_count := l_count + 1;
            END LOOP;
        
            -- Output values
            o_num_occur  := l_count;
            o_desc_first := l_description;
            o_code       := l_code_description;
            o_dt_first   := l_dt_begin;
            o_dt_fmt     := l_dt_begin_fmt;
        
            RETURN TRUE;
        ELSE
            --o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name ||
            --           '.GET_COUNT_AND_FIRST / ' || l_message || ' / ' || SQLERRM;
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_COUNT_AND_FIRST',
                                                     o_error);
    END get_count_and_first;

    /*************************************************************************\
    * Name :                 get_ordered_list                                 *
    * Description:           VIEWER API -> Returns ALLERGIES ordered list     *
    *                                                                         *
    * @param i_lang          Input - Language ID                              *
    * @param i_prof          Input - Professional array                       *
    * @param i_patient       Input - Patient ID                               *
    * @param o_ordered_list  Output - Patient allergies list,                 *
    *                                 according the sort criteria parameters  *
    *                                                                         *
    * @author                Nuno Miguel Ferreira                             *
    * @version               1.0                                              *
    * @since                 2008/11/13                                       *
    \*************************************************************************/
    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_area         gen_area.code%TYPE := 'ALLERGY';
        l_id_execution NUMBER;
        l_values       table_varchar;
        l_rank_value   gen_area_rank.rank_value%TYPE;
        l_rank_order   gen_area_rank.rank_order%TYPE;
    
        TYPE records_tmp IS TABLE OF gen_area_rank_tmp%ROWTYPE INDEX BY PLS_INTEGER;
        l_records records_tmp;
    
        l_msg_common_m036 sys_message.desc_message%TYPE;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T024');
    
    BEGIN
        -- Get COMMON_M036 Message
        l_msg_common_m036 := pk_message.get_message(i_lang, 'COMMON_M036');
    
        SELECT seq_gen_area_rank.nextval
          INTO l_id_execution
          FROM dual;
    
        --insert in temporary table
        l_message := 'INSERT ON TEMP TABLE';
        SELECT
        -- id execution
         l_id_execution,
         -- varchar criteria
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         -- number criteria
         pa.id_pat_allergy numb1,
         nvl(pk_sysdomain.get_rank(i_lang, g_pat_allergy_status, pa.flg_status), 0) numb2,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         -- timestamp criteria
         to_date(to_char(nvl(pa.year_begin, 1), '0000') || to_char(nvl(pa.month_begin, 1), '00') ||
                 to_char(nvl(pa.day_begin, 1), '00'),
                 'YYYYMMDD') dt_tstz1,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         -- rank
         NULL
          BULK COLLECT
          INTO l_records
          FROM pat_allergy pa, allergy a
         WHERE pa.id_patient = i_patient
           AND a.flg_without IS NULL
           AND a.id_allergy(+) = pa.id_allergy
           AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved);
    
        l_message := 'FORALL';
        FORALL indx IN 1 .. l_records.count
            INSERT INTO gen_area_rank_tmp
            VALUES l_records
                (indx);
    
        --classifies each record
        l_message := 'GEN_AREA_RANK_TMP';
        FOR rec IN (SELECT numb1, numb2, dt_tstz1
                      FROM gen_area_rank_tmp
                     WHERE id_execution = l_id_execution)
        LOOP
            l_values := table_varchar();
        
            --fills the arrays
            l_message := 'EXTEND';
            l_values.extend(g_num_variables);
        
            --fills the arrays
            l_values(1) := nvl(to_char(rec.numb2), 'NULL');
            l_values(2) := nvl(pk_date_utils.date_send_tsz(i_lang, rec.dt_tstz1, i_prof), 'NULL');
            FOR idx IN 3 .. g_num_variables
            LOOP
                l_values(idx) := 'NULL';
            END LOOP;
        
            l_message := 'GET RANK';
            IF NOT pk_gen_area_rank.get_rank(i_institution => i_prof.institution,
                                             i_area        => l_area,
                                             i_values      => l_values,
                                             o_rank_value  => l_rank_value,
                                             o_rank_order  => l_rank_order)
            THEN
                RETURN FALSE;
            END IF;
        
            --updates temporary table with the classification multiplied by the number of records
            l_message := 'UPDATE GEN_AREA_RANK_TMP';
            UPDATE gen_area_rank_tmp
               SET rank  = l_rank_value,
                   numb3 = l_rank_order,
                   numb4 = l_rank_order * pk_date_utils.get_timestamp_diff(current_timestamp, nvl(dt_tstz1, dt_tstz2))
             WHERE id_execution = l_id_execution
               AND numb1 = rec.numb1;
        
        END LOOP;
    
        -- Output cursor
        l_message := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT pa.id_pat_allergy id,
                   decode(pa.id_allergy, NULL, pa.desc_allergy, 'ALLERGY.CODE_ALLERGY.' || pa.id_allergy) code_description,
                   decode(pa.id_allergy,
                          NULL,
                          pa.desc_allergy,
                          decode(pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || pa.id_allergy),
                                 NULL,
                                 'ALLERGY.CODE_ALLERGY.' || pa.id_allergy,
                                 pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || pa.id_allergy))) description,
                   CASE
                        WHEN i_translate = pk_alert_constant.g_no THEN
                         NULL
                        ELSE
                         nvl(pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang), l_msg_common_m036)
                    END title,
                   pk_date_utils.get_string_tstz(i_lang,
                                                 i_prof,
                                                 nvl2(pa.year_begin,
                                                      to_char(nvl(pa.year_begin, 1), 'FM0000') ||
                                                      to_char(nvl(pa.month_begin, 1), 'FM00') ||
                                                      to_char(nvl(pa.day_begin, 1), 'FM00') || '000000',
                                                      NULL),
                                                 NULL) dt_begin,
                   nvl2(year_begin, nvl2(month_begin, nvl2(day_begin, 'D', 'M'), 'Y'), NULL) dt_begin_fmt,
                   CASE nvl2(year_begin, nvl2(month_begin, nvl2(day_begin, 'D', 'M'), 'Y'), NULL)
                       WHEN 'D' THEN
                        pk_date_utils.dt_chr(i_lang,
                                             to_date(to_char(pa.year_begin, '0000') || to_char(pa.month_begin, '00') ||
                                                     to_char(pa.day_begin, '00'),
                                                     'YYYYMMDD'),
                                             i_prof)
                       WHEN 'M' THEN
                        pk_date_utils.get_month_year(i_lang,
                                                     i_prof,
                                                     to_date(to_char(pa.year_begin, '0000') ||
                                                             to_char(pa.month_begin, '00') ||
                                                             to_char(nvl(pa.day_begin, 1), '00'),
                                                             'YYYYMMDD'))
                       WHEN 'Y' THEN
                        to_char(pa.year_begin, '0000')
                       ELSE
                        NULL
                   END AS dt_req,
                   pa.flg_status,
                   pa.flg_type,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        pk_alert_constant.g_display_type_text,
                                                        pa.flg_status,
                                                        g_pat_allergy_status,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        CASE pa.flg_status
                                                            WHEN g_pat_allergy_flg_active THEN
                                                             pk_alert_constant.g_color_red
                                                            WHEN g_pat_allergy_flg_passive THEN
                                                             pk_alert_constant.g_color_orange
                                                            WHEN g_pat_allergy_flg_cancelled THEN
                                                             pk_alert_constant.g_color_null
                                                        END,
                                                        NULL,
                                                        CASE pa.flg_status
                                                            WHEN g_pat_allergy_flg_cancelled THEN
                                                             'ViewerCancelState'
                                                            ELSE
                                                             'ViewerState'
                                                        END,
                                                        NULL,
                                                        pk_alert_constant.g_yes,
                                                        NULL) desc_status,
                   gart.rank rank,
                   gart.numb4 dt_diff,
                   l_task_title task_title
              FROM pat_allergy pa, gen_area_rank_tmp gart
             WHERE gart.id_execution = l_id_execution
               AND gart.numb1 = pa.id_pat_allergy
             ORDER BY rank ASC, (numb3 * numb4) ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_ORDERED_LIST',
                                                     o_error);
    END get_ordered_list;

    /**
     * This function verifies if the patient has an active allergy in his
     * personal health record. It is used to give a warning to the user
     * when he/she is registering an "unable to access allergy".
     *
     * @param IN   i_lang       Language ID
     * @param IN   i_prof       Professional (id, institution, software)
     * @param IN   i_patient    Patient ID
     * @param OUT  o_msg        Message string
     * @param OUT  o_error      Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.4
     * @since    2009-Jul-13
     * @author   Thiago Brito 
    */
    FUNCTION get_popup_unable_to_assess
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_msg     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_allergies PLS_INTEGER := 0;
    
    BEGIN
    
        SELECT COUNT(pa.id_pat_allergy)
          INTO l_count_allergies
          FROM pat_allergy pa
         WHERE pa.id_patient = i_patient
           AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved)
           AND pa.flg_type = g_flg_type_allergy;
    
        IF (l_count_allergies > 0)
        THEN
            o_msg := pk_message.get_message(i_lang, 'ALLERGY_M055');
            RETURN FALSE;
        ELSE
            o_msg := NULL;
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_POPUP_UNABLE_TO_ACCESS',
                                                     o_error);
    END get_popup_unable_to_assess;

    /**
     * This function verifies if the patient has an active drug allergy in his
     * personal health record. It is used to give a warning to the user
     * when he/she is registering an "unkown drug allergy".
     *
     * @param IN   i_lang       Language ID
     * @param IN   i_prof       Professional (id, institution, software)
     * @param IN   i_patient    Patient ID
     * @param OUT  o_msg        Message string
     * @param OUT  o_error      Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.4
     * @since    2009-Jul-13
     * @author   Thiago Brito 
    */
    FUNCTION get_popup_unkown_drug_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_msg     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_drug_allergies PLS_INTEGER := 0;
    
    BEGIN
    
        SELECT COUNT(pa.id_pat_allergy)
          INTO l_count_drug_allergies
          FROM pat_allergy pa
         WHERE pa.id_patient = i_patient
           AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved)
           AND pa.id_allergy IN
               (SELECT a.id_allergy
                  FROM allergy_inst_soft_market a
                 WHERE a.id_allergy_parent IN (g_drug_class_id_allergy, g_drug_id_allergy, g_drug_com_id_allergy))
           AND pa.flg_type = g_flg_type_allergy;
    
        IF (l_count_drug_allergies > 0)
        THEN
            o_msg := pk_message.get_message(i_lang, 'ALLERGY_M056');
            RETURN FALSE;
        ELSE
            o_msg := NULL;
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_POPUP_UNKOWN_DRUG_ALLERGY',
                                                     o_error);
    END get_popup_unkown_drug_allergy;

    /**
     * This function verifies some inconsistencies through the registration
     * process of unawareness.
     *
     * @param IN   i_lang           Language ID
     * @param IN   i_prof           Professional (id, institution, software)
     * @param IN   i_patient        Patient ID
     * @param IN   i_unawareness    Unawareness ID (1: Unable to assess allergies;
     *                                              2: No known allergies;
     *                                              3: No known drug allergies)
     * @param OUT  o_msg            Message string
     * @param OUT  o_error          Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.4
     * @since    2009-Jul-13
     * @author   Thiago Brito 
    */
    FUNCTION get_popup_unawareness
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_unawareness IN allergy_unawareness.id_allergy_unawareness%TYPE,
        o_msg         OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_allergy_unawareness table_number;
    
    BEGIN
        o_msg := table_varchar();
    
        SELECT pau.id_allergy_unawareness
          BULK COLLECT
          INTO l_id_allergy_unawareness
          FROM pat_allergy_unawareness pau
         WHERE pau.flg_status = g_unawareness_active
           AND pau.id_patient = i_patient;
    
        o_msg.extend(l_id_allergy_unawareness.count);
    
        FOR i IN 1 .. l_id_allergy_unawareness.count
        LOOP
            CASE l_id_allergy_unawareness(i)
            
                WHEN g_unable_asess THEN
                    o_msg(i) := pk_message.get_message(i_lang, 'ALLERGY_M057');
                
                WHEN g_no_known THEN
                    o_msg(i) := pk_message.get_message(i_lang, 'ALLERGY_M058');
                
                WHEN g_no_known_drugs THEN
                    o_msg(i) := pk_message.get_message(i_lang, 'ALLERGY_M059');
                
                ELSE
                    RETURN TRUE;
            END CASE;
        END LOOP;
    
        IF o_msg.count > 0
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_POPUP_UNAWARENESS',
                                                     o_error);
    END get_popup_unawareness;

    /**
     * This function verifies some inconsistencies through the registration
     * process of an unawareness
     *
     * @param IN   i_lang           Language ID
     * @param IN   i_prof           Professional (id, institution, software)
     * @param IN   i_patient        Patient ID
     * @param IN   i_unawareness    Unawareness ID (1: Unable to assess allergies;
     *                                              2: No known allergies;
     *                                              3: No known drug allergies)
     * @param OUT  o_msg            Message string
     * @param OUT  o_error          Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.4
     * @since    2009-Jul-13
     * @author   Thiago Brito 
    */
    FUNCTION get_popup_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_unawareness IN allergy_unawareness.id_allergy_unawareness%TYPE,
        o_msg         OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i            PLS_INTEGER := 1;
        l_msg        VARCHAR2(4000);
        l_msg_unawar table_varchar := table_varchar();
        l_msg_wrn    table_varchar;
    BEGIN
    
        l_msg_wrn := table_varchar();
        o_msg     := table_varchar();
    
        -- verifies the relation between "unable to assess allergies"
        -- and previous allergies registered for the patient
        IF (NOT get_popup_unable_to_assess(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_patient => i_patient,
                                           o_msg     => l_msg,
                                           o_error   => o_error))
        THEN
            l_msg_wrn.extend;
            l_msg_wrn(i) := l_msg;
            l_msg := NULL;
            i := i + 1;
        END IF;
    
        -- verifies the relation between "no known drug allergies"
        -- and previous drug allergies registered for the patient
        IF (NOT get_popup_unkown_drug_allergy(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => i_patient,
                                              o_msg     => l_msg,
                                              o_error   => o_error))
        THEN
            l_msg_wrn.extend;
            l_msg_wrn(i) := l_msg;
            l_msg := NULL;
            i := i + 1;
        END IF;
    
        -- verifies some inconsistencies between the registration
        -- process of unawareness
        IF (NOT get_popup_unawareness(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_patient     => i_patient,
                                      i_unawareness => i_unawareness,
                                      o_msg         => l_msg_unawar,
                                      o_error       => o_error))
        THEN
        
            l_msg_wrn := l_msg_wrn MULTISET UNION DISTINCT l_msg_unawar;
        
        END IF;
    
        IF i > 2
        THEN
            o_msg.extend;
            o_msg(1) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_M055');
        ELSIF i > 1
        THEN
            o_msg.extend;
            o_msg(1) := l_msg_wrn(1);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_POPUP_WARNING',
                                                     o_error);
    END get_popup_warning;

    /** This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_episode              Episode ID
     * @param    IN     i_pat_allergy          Patient allergy ID
     * @param    IN     i_flg_cat              Flag category
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    2010-Nov-02
     * @author   Filipe Machado
    */

    FUNCTION has_reviewed_by_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_flg_cat     IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_res NUMBER;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_res
          FROM review_detail rd
         INNER JOIN prof_cat pc
            ON pc.id_professional = rd.id_professional
         INNER JOIN category cat
            ON cat.id_category = pc.id_category
         WHERE rd.id_episode IN (i_episode)
           AND rd.id_record_area = i_pat_allergy
           AND cat.flg_type = i_flg_cat
           AND rd.flg_context = g_allergy_review_context
           AND rownum = 1;
    
        IF l_res = 1
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END has_reviewed_by_episode;

    /** This function get the status of the review on the header
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    OUT    o_status               Cursor with all information
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @author   Filipe Machado
    */

    FUNCTION get_review_header_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_status  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_allergies_all IS
            SELECT pa.*
              FROM pat_allergy pa
             WHERE pa.id_patient = i_patient
               AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved);
    
        l_epis_all      table_number := table_number();
        l_all_count     NUMBER := 0;
        l_rev_phy_count NUMBER := 0;
        l_rev_nur_count NUMBER := 0;
        l_phy_status    VARCHAR2(100 CHAR);
        l_nur_status    VARCHAR2(100 CHAR);
        l_last_review   VARCHAR2(100 CHAR);
    
        l_record_area review_detail.id_record_area%TYPE;
        l_prof        review_detail.id_professional%TYPE;
        l_episode     review_detail.id_episode%TYPE;
        l_dt_review   review_detail.dt_review%TYPE;
    
        l_flg_totally_reviewed VARCHAR2(1) := pk_alert_constant.g_no;
    
        l_prof_category category.flg_type%TYPE;
    BEGIN
    
        -- get all episodes that belongs to the patient    
        l_epis_all    := get_all_episodes(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
        l_last_review := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_M063');
    
        FOR rec IN c_allergies_all
        LOOP
        
            IF has_reviewed_by_episode(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_episode     => i_episode,
                                       i_pat_allergy => rec.id_pat_allergy,
                                       i_flg_cat     => pk_alert_constant.g_cat_type_doc) = pk_alert_constant.g_yes
            THEN
                l_rev_phy_count := l_rev_phy_count + 1;
            END IF;
        
            IF has_reviewed_by_episode(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_episode     => i_episode,
                                       i_pat_allergy => rec.id_pat_allergy,
                                       i_flg_cat     => pk_alert_constant.g_cat_type_nurse) = pk_alert_constant.g_yes
            THEN
                l_rev_nur_count := l_rev_nur_count + 1;
            END IF;
        
            NULL;
        
            l_all_count := l_all_count + 1;
        
        END LOOP;
    
        IF l_all_count = 0
        THEN
            l_phy_status := '';
            l_nur_status := '';
        ELSIF l_rev_phy_count = l_all_count
        THEN
            l_phy_status           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T019');
            l_flg_totally_reviewed := pk_alert_constant.g_yes;
        ELSIF l_rev_phy_count > 0
        THEN
            l_phy_status := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T018');
        ELSIF l_rev_phy_count = 0
        THEN
            l_phy_status := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T017');
        END IF;
    
        -- get last review of an allergy of this patient 
        BEGIN
        
            SELECT *
              INTO l_record_area, l_prof, l_episode, l_dt_review
              FROM (SELECT rd.id_record_area, rd.id_professional, rd.id_episode, rd.dt_review date_rev
                      FROM review_detail rd
                     INNER JOIN pat_allergy paa
                        ON (paa.id_pat_allergy = rd.id_record_area)
                     WHERE rd.id_episode IN (SELECT *
                                               FROM TABLE(l_epis_all))
                       AND rd.flg_context = g_allergy_review_context
                       AND paa.flg_status NOT IN (g_pat_allergy_flg_resolved)
                    UNION ALL
                    SELECT rd.id_record_area, rd.id_professional, rd.id_episode, rd.dt_review date_rev
                      FROM review_detail rd
                     INNER JOIN pat_allergy_hist paa
                        ON (paa.id_pat_allergy = rd.id_record_area)
                     WHERE rd.id_episode IN (SELECT *
                                               FROM TABLE(l_epis_all))
                       AND rd.flg_context = g_allergy_review_context
                       AND paa.flg_status NOT IN (g_pat_allergy_flg_resolved)
                     ORDER BY date_rev DESC)
             WHERE rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_record_area := NULL;
                l_prof        := NULL;
                l_episode     := NULL;
                l_dt_review   := NULL;
        END;
    
        IF l_rev_nur_count > 0
        THEN
            l_prof_category := pk_prof_utils.get_category(i_lang => i_lang,
                                                          i_prof => profissional(l_prof,
                                                                                 i_prof.institution,
                                                                                 i_prof.software));
            IF l_prof_category = pk_alert_constant.g_cat_type_nurse
            THEN
                l_nur_status := ' (' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_T020') || ')';
            END IF;
        END IF;
    
        OPEN o_status FOR
            SELECT l_phy_status phy_status,
                   l_nur_status nur_status,
                   l_flg_totally_reviewed flg_totally_reviewed,
                   l_last_review last_review_label,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, l_prof, l_dt_review, l_episode) prof_spec,
                   pk_date_utils.date_char_tsz(i_lang, l_dt_review, i_prof.institution, i_prof.software) dt_register
              FROM dual;
    
        RETURN TRUE;
    
    END get_review_header_status;

    --

    PROCEDURE upd_viewer_ehr_ea IS
        l_patients table_number;
        l_error    t_error_out;
    BEGIN
    
        SELECT id_patient
          BULK COLLECT
          INTO l_patients
          FROM viewer_ehr_ea vee;
    
        IF NOT upd_viewer_ehr_ea_pat(i_lang              => pk_data_gov_admin.g_log_lang,
                                     i_table_id_patients => l_patients,
                                     o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
    END upd_viewer_ehr_ea;

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_TABLE_ID_PATIENTS      Table of id patients to be clean.
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         ANA COELHO
    * @version                        1.0
    * @since                          28-APR-2011
    **********************************************************************************************/
    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_occur   table_number := table_number();
        l_desc_first  table_varchar := table_varchar();
        l_code_first  table_varchar := table_varchar();
        l_dt_first    table_varchar := table_varchar();
        l_viewer_area VARCHAR2(4000);
        l_episode     table_number := table_number();
        l_dt_fmt      table_varchar := table_varchar();
    BEGIN
        g_error := 'START UPD_VIEWER_EHR_EA_PAT';
        l_num_occur.extend(i_table_id_patients.count);
        l_desc_first.extend(i_table_id_patients.count);
        l_code_first.extend(i_table_id_patients.count);
        l_dt_first.extend(i_table_id_patients.count);
        l_episode.extend(i_table_id_patients.count);
        l_dt_fmt.extend(i_table_id_patients.count);
    
        FOR i IN i_table_id_patients.first .. i_table_id_patients.last
        LOOP
            g_error := 'CALL GET_COUNT_AND_FIRST ' || i_table_id_patients(i);
            IF NOT
                get_count_and_first(i_lang       => pk_problems.get_language(NULL, i_table_id_patients(i)),
                                    i_prof       => profissional(-1,
                                                                 pk_problems.get_institution(NULL, i_table_id_patients(i)),
                                                                 pk_problems.get_software(NULL, i_table_id_patients(i))),
                                    i_patient    => i_table_id_patients(i),
                                    o_num_occur  => l_num_occur(i),
                                    o_desc_first => l_desc_first(i),
                                    o_code       => l_code_first(i),
                                    o_dt_first   => l_dt_first(i),
                                    o_dt_fmt     => l_dt_fmt(i),
                                    o_error      => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
        g_error := 'FORALL';
        FORALL i IN i_table_id_patients.first .. i_table_id_patients.last
            UPDATE viewer_ehr_ea
               SET num_allergy    = l_num_occur(i),
                   desc_allergy   = l_desc_first(i),
                   dt_allergy     = l_dt_first(i),
                   code_allergy   = l_code_first(i),
                   dt_allergy_fmt = l_dt_fmt(i)
             WHERE id_patient = i_table_id_patients(i) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject
             LIMIT unlimited;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'UPDATE VIEWER_EHR_EA',
                                              g_package_owner,
                                              g_package_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    /**
     * This function is used to build cancel description text
     *
     * @param IN   i_lang           Language ID
     * @param IN   i_prof           Professional (id, institution, software)
     * @param IN   i_pat_allergy    Array with pat_allergy identifiers
     * @param OUT  o_msg            Message string
     * @param OUT  o_error          Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.6.1
     * @since    2011-FEV-04
     * @author   Rui Duarte
    */
    FUNCTION get_cancel_allergy_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_pat_allergy IN table_number,
        o_allergies   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_status_desc     sys_message.code_message%TYPE := 'ALLERGY_M035';
        l_prop_separator  VARCHAR2(2) := ': ';
        l_value_separator VARCHAR2(2) := ', ';
        l_message         debug_msg;
    BEGIN
        l_message := 'OPEN O_ALLERGIES';
        OPEN o_allergies FOR
            SELECT allergy_desc, id_pat_allergy
              FROM (SELECT (pk_sysdomain.get_domain(g_pat_allergy_type, pa.flg_type, i_lang) || l_prop_separator ||
                           nvl(pa.desc_allergy, pk_translation.get_translation(i_lang, a.code_allergy)) ||
                           l_value_separator || pk_message.get_message(i_lang, l_status_desc) || l_prop_separator ||
                           pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang)) allergy_desc,
                           nvl(pa.desc_allergy, pk_translation.get_translation(i_lang, a.code_allergy)) allergy_order,
                           pa.id_pat_allergy
                      FROM pat_allergy pa
                      LEFT JOIN allergy a
                        ON a.id_allergy = pa.id_allergy
                     WHERE pa.id_pat_allergy IN (SELECT *
                                                   FROM TABLE(i_pat_allergy))
                     ORDER BY allergy_order);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_CANCEL_ALLERGY_DESC',
                                                     o_error);
    END get_cancel_allergy_desc;

    /********************************************************************************************
    * Returns table function t_tbl_allergies that contains all information about patient allergies like : 
    * codes, descriptions, allergy severities and related symptoms
    * @param i_lang                     Language
    * @param i_prof                     Professional information
    * @param i_flg_filter               Used to filter data - 'A' -> filters by allergy
    *
    * @returns table function t_tbl_allergies
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          29-Jul-2014
    **********************************************************************************************/
    FUNCTION tf_allergy
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_flg_filter IN VARCHAR2
    ) RETURN t_tbl_allergies IS
        tbl_allergy t_tbl_allergies;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'GET_ALLERGIES';
        filter_desc VARCHAR(200 CHAR);
        l_exception EXCEPTION;
        l_ferror t_error_out;
        l_error  VARCHAR2(200 CHAR);
    BEGIN
        l_error := 'CALL GET_ALLERGY_LST';
        IF NOT get_allergy_lst(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_episode     => 0,
                               i_pat_allergy => NULL,
                               i_flg_filter  => i_flg_filter,
                               o_allergies   => tbl_allergy,
                               o_filter_desc => filter_desc,
                               o_error       => l_ferror)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN tbl_allergy;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_ferror);
            RETURN NULL;
        
    END tf_allergy;
    --

    /**
     * This function is used to get the list of allergy per patient
     * and return: - the SNOWMED codes and descriptions of the allergy top parent,
     * the allergy severities and the allergy symptoms.
     * -the RXNorm code and description of the ingredients of the medication associated to the allergies
     *
     * DEPENDENCIES: REPORTS
     *
     * @param  i_lang  IN                      Language ID
     * @param  i_prof  IN                      Professional structure
     * @param  i_patient  IN                   Patient ID
     * @param  i_episode  IN                   Episode ID
     * @param  o_allergies  OUT                Allergies cursor
     * @param  o_error  OUT                    Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.0.5
     * @since    29-Abr-2011
     * @author   Sofia Mendes
    */
    FUNCTION get_allergy_list_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_allergies  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_source_map_set          CONSTANT xmap_set.id_map_set%TYPE := 1;
        l_target_map_set          CONSTANT xmap_set.id_map_set%TYPE := 2;
        l_target_mcs_src          CONSTANT mcs_source.id_mcs_source%TYPE := 1;
        l_medication_allergy_type CONSTANT allergy.id_allergy%TYPE := 8899;
        l_tab_hist t_table_epis_hid_hist := t_table_epis_hid_hist();
    
        CURSOR c_allergies IS
            SELECT pa.id_allergy,
                   pa.id_pat_allergy,
                   pa.id_episode,
                   pa.flg_type,
                   pa.flg_status,
                   pk_sysdomain.get_domain(g_pat_allergy_status, pa.flg_status, i_lang) AS status_descr,
                   pa.year_begin AS onset,
                   als.id_content severity_id_content,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) start_date_app_format,
                   CASE
                        WHEN pa.year_begin IS NOT NULL
                             AND pa.month_begin IS NOT NULL
                             AND pa.day_begin IS NOT NULL THEN
                         to_char(to_timestamp(pa.year_begin || lpad(pa.month_begin, 2, '0') || lpad(pa.day_begin, 2, '0'),
                                              'YYYYMMDD'),
                                 'YYYYMMDD')
                        ELSE
                         to_char(pa.year_begin)
                    END start_date,
                   pk_translation.get_translation(i_lang, als.code_allergy_severity) severity_desc,
                   decode(pa.id_allergy, NULL, pa.desc_allergy, pk_translation.get_translation(i_lang, al.code_allergy)) AS allergy_desc
              FROM pat_allergy pa
              JOIN allergy al
                ON al.id_allergy = pa.id_allergy
              LEFT JOIN allergy_severity als
                ON als.id_allergy_severity = pa.id_allergy_severity
             WHERE (i_patient IS NULL OR pa.id_patient = i_patient)
               AND (i_id_episode IS NULL OR (pa.id_episode IS NOT NULL AND pa.id_episode = i_id_episode));
    
        l_allergies_info          c_allergies%ROWTYPE;
        l_tab_allergies_cdas      t_tab_allergies_cdas := t_tab_allergies_cdas();
        l_allergy_type_id_content allergy.id_content%TYPE;
        l_id_contents             table_varchar := table_varchar();
        l_symptoms_id_contents    table_varchar := table_varchar();
        l_table_mapping_conc      t_table_mapping_conc := t_table_mapping_conc();
        l_table_mapping_conc_sym  t_table_mapping_conc := t_table_mapping_conc();
        l_allergy_type_code       xmap_relationship.target_coordinated_expr%TYPE;
        l_allergy_type_desc       pk_translation.t_desc_translation;
        l_severity_code           xmap_relationship.target_coordinated_expr%TYPE;
        l_severity_desc           pk_translation.t_desc_translation;
        l_symptoms_codes          table_varchar;
        l_symptoms_desc           table_varchar;
        l_allergy_type_id         allergy.id_allergy%TYPE;
    
        l_rec_allergies_cdas t_rec_allergies_cdas;
    
        l_medication_info      table_table_varchar;
        l_drug_ingredient_code pk_translation.t_desc_translation;
        l_drug_ingredient_desc pk_translation.t_desc_translation;
        l_symptoms_alert_descs table_varchar := table_varchar();
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'get_allergy_list_cda: i_patient: ' || i_patient || ' i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        OPEN c_allergies;
        LOOP
            g_error := 'FETCH MAPPING CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_allergies
                INTO l_allergies_info;
            EXIT WHEN c_allergies%NOTFOUND;
        
            --get all the id_contents to be mapped to the SNOWMED coding
            g_error := 'GET THE ALERGY TYPE. id_allergy: ' || l_allergies_info.id_allergy;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT t2.id_allergy, t2.id_content
                  INTO l_allergy_type_id, l_allergy_type_id_content
                  FROM (SELECT rownum rn2, t.*
                          FROM (SELECT rownum rn, a.*
                                  FROM allergy a
                                CONNECT BY PRIOR a.id_allergy_parent = a.id_allergy
                                 START WITH a.id_allergy = l_allergies_info.id_allergy
                                 ORDER BY LEVEL DESC) t) t2
                 WHERE rn2 = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_allergy_type_id         := NULL;
                    l_allergy_type_id_content := NULL;
            END;
        
            g_error := 'GET THE ALERGY SYMPTOMS ID CONTENTS. id_pat_allergy: ' || l_allergies_info.id_pat_allergy;
            pk_alertlog.log_debug(g_error);
            SELECT als.id_content,
                   pk_translation.get_translation(i_lang,
                                                  'ALLERGY_SYMPTOMS.CODE_ALLERGY_SYMPTOMS.' ||
                                                  to_char(pas.id_allergy_symptoms)) desc_symptom
              BULK COLLECT
              INTO l_symptoms_id_contents, l_symptoms_alert_descs
              FROM pat_allergy_symptoms pas
              JOIN allergy_symptoms als
                ON pas.id_allergy_symptoms = als.id_allergy_symptoms
             WHERE pas.id_pat_allergy = l_allergies_info.id_pat_allergy
               AND als.id_allergy_symptoms NOT IN (13, 5) -- the 'Other' and 'Unknown' should not be returned to the report
             ORDER BY desc_symptom;
        
            IF (l_allergy_type_id_content IS NOT NULL)
            THEN
                l_id_contents.extend();
                l_id_contents(l_id_contents.last) := l_allergy_type_id_content;
            END IF;
        
            IF (l_allergies_info.severity_id_content IS NOT NULL)
            THEN
                l_id_contents.extend();
                l_id_contents(l_id_contents.last) := l_allergies_info.severity_id_content;
            END IF;
        
            --get the SNOWMED mapping codes and descriptions
            g_error := 'CALL pk_mapping_sets.tf_get_mapping_concepts';
            pk_alertlog.log_debug(g_error);
            l_table_mapping_conc := pk_mapping_sets.tf_get_mapping_concepts(i_lang,
                                                                            l_id_contents,
                                                                            l_source_map_set,
                                                                            l_target_map_set,
                                                                            l_target_mcs_src);
        
            g_error := 'CALL pk_mapping_sets.tf_get_mapping_concepts';
            pk_alertlog.log_debug(g_error);
            l_table_mapping_conc_sym := pk_mapping_sets.tf_get_mapping_concepts(i_lang,
                                                                                l_symptoms_id_contents,
                                                                                l_source_map_set,
                                                                                l_target_map_set,
                                                                                l_target_mcs_src);
        
            --GET the allergy type SNOWMED CODE
            IF (l_allergy_type_id_content IS NOT NULL)
            THEN
                g_error := 'GET the allergy type SNOWMED CODE: l_allergy_type_id_content: ' ||
                           l_allergy_type_id_content;
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT ta.target_coordinated_expr, ta.target_map_concept_desc
                      INTO l_allergy_type_code, l_allergy_type_desc
                      FROM (SELECT t.target_coordinated_expr, t.target_map_concept_desc
                              FROM TABLE(l_table_mapping_conc) t
                             WHERE t.source_coordinated_expr = l_allergy_type_id_content
                             ORDER BY t.map_priority) ta
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_allergy_type_code := NULL;
                        l_allergy_type_desc := NULL;
                END;
            END IF;
        
            --GET the severity SNOWMED CODE
            IF (l_allergies_info.severity_id_content IS NOT NULL)
            THEN
                g_error := 'GET the severity SNOWMED CODE: l_allergies_info.severity_id_content: ' ||
                           l_allergies_info.severity_id_content;
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT ta.target_coordinated_expr, ta.target_map_concept_desc
                      INTO l_severity_code, l_severity_desc
                      FROM (SELECT t.target_coordinated_expr, t.target_map_concept_desc
                              FROM TABLE(l_table_mapping_conc) t
                             WHERE t.source_coordinated_expr = l_allergies_info.severity_id_content
                             ORDER BY t.map_priority) ta
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_severity_code := NULL;
                        l_severity_desc := NULL;
                END;
            END IF;
        
            --GET the symptoms SNOWMED CODEs
            g_error := 'GET the symptoms SNOWMED CODEs';
            pk_alertlog.log_debug(g_error);
            IF (l_symptoms_id_contents IS NOT NULL OR l_symptoms_id_contents.exists(1))
            THEN
                BEGIN
                    SELECT tt2.target_coordinated_expr, tt2.target_map_concept_desc
                      BULK COLLECT
                      INTO l_symptoms_codes, l_symptoms_desc
                      FROM (SELECT /*+opt_estimate(table,st,scale_rows=0.1)*/
                             column_value, rownum rn
                              FROM TABLE(l_symptoms_id_contents) st) tt
                      LEFT JOIN (SELECT /*+opt_estimate(table,st2,scale_rows=0.1)*/
                                  st2.target_coordinated_expr, st2.target_map_concept_desc, st2.source_coordinated_expr
                                   FROM TABLE(l_table_mapping_conc_sym) st2) tt2
                        ON tt2.source_coordinated_expr = tt.column_value
                     ORDER BY tt.rn;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_symptoms_codes := NULL;
                        l_symptoms_desc  := NULL;
                END;
            END IF;
        
            l_drug_ingredient_code := NULL;
            l_drug_ingredient_desc := NULL;
            IF (l_allergy_type_id = l_medication_allergy_type)
            THEN
                g_error := 'CALL PK_API_PFH_CLINDOC_IN.GET_ALLERGY_RXNORM. i_id_allergy: ' ||
                           l_allergies_info.id_allergy;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_api_pfh_clindoc_in.get_allergy_rxnorm(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_allergy => l_allergies_info.id_allergy,
                                                                o_info       => l_medication_info,
                                                                o_error      => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                g_error := 'GET MEDICATION INFO';
                pk_alertlog.log_debug(g_error);
                IF (l_medication_info IS NOT NULL AND l_medication_info.exists(1))
                THEN
                    IF (l_medication_info(1).exists(2))
                    THEN
                        l_drug_ingredient_code := l_medication_info(1) (2);
                    END IF;
                    IF (l_medication_info(1).exists(3))
                    THEN
                        l_drug_ingredient_desc := l_medication_info(1) (3);
                    END IF;
                END IF;
            END IF;
        
            g_error := 'CONSTRUCT t_rec_allergies_cdas';
            pk_alertlog.log_debug(g_error);
            l_tab_allergies_cdas.extend();
            l_tab_allergies_cdas(l_tab_allergies_cdas.last) := t_rec_allergies_cdas(id_pat_allergy              => l_allergies_info.id_pat_allergy,
                                                                                    id_allergy                  => l_allergies_info.id_allergy,
                                                                                    flg_type                    => l_allergies_info.flg_type,
                                                                                    flg_status                  => l_allergies_info.flg_status,
                                                                                    status_desc                 => l_allergies_info.status_descr,
                                                                                    onset                       => l_allergies_info.onset,
                                                                                    allergy_type_code           => l_allergy_type_code,
                                                                                    allergy_type_desc           => l_allergy_type_desc,
                                                                                    allergy_type_flg_coding     => g_snowmed,
                                                                                    severity_code               => l_severity_code,
                                                                                    severity_desc               => l_severity_desc,
                                                                                    severity_alert_desc         => l_allergies_info.severity_desc,
                                                                                    severity_flg_coding         => g_snowmed,
                                                                                    symptoms_code               => l_symptoms_codes,
                                                                                    symptoms_desc               => l_symptoms_desc,
                                                                                    symptoms_alert_desc         => l_symptoms_alert_descs,
                                                                                    symptoms_flg_coding         => g_snowmed,
                                                                                    drug_ingredient_code        => l_drug_ingredient_code,
                                                                                    drug_ingredient_desc        => l_drug_ingredient_desc,
                                                                                    allergy_alert_desc          => l_allergies_info.allergy_desc,
                                                                                    drug_ingredient_flg_coding  => g_rxnorm,
                                                                                    flg_medication_allergy_type => CASE
                                                                                                                       WHEN l_allergy_type_id = l_medication_allergy_type THEN
                                                                                                                        pk_alert_constant.g_yes
                                                                                                                       ELSE
                                                                                                                        pk_alert_constant.g_no
                                                                                                                   END,
                                                                                    start_date_app_format       => l_allergies_info.start_date_app_format,
                                                                                    start_date                  => l_allergies_info.start_date);
        
        END LOOP;
    
        /*IF (l_tab_allergies_cdas IS NOT NULL AND l_tab_allergies_cdas.exists(1))
        THEN*/
        g_error := 'OPEN O_ALLERGIES';
        pk_alertlog.log_debug(g_error);
        OPEN o_allergies FOR
            SELECT t.id_pat_allergy,
                   t.id_allergy,
                   t.flg_type,
                   t.flg_status,
                   t.status_desc,
                   to_char(t.onset) onset,
                   t.allergy_type_code,
                   t.allergy_type_desc,
                   t.allergy_type_flg_coding,
                   t.severity_code,
                   t.severity_desc,
                   t.severity_alert_desc,
                   t.severity_flg_coding,
                   t.symptoms_code,
                   t.symptoms_desc,
                   t.symptoms_alert_desc,
                   t.symptoms_flg_coding,
                   t.drug_ingredient_code,
                   t.drug_ingredient_desc,
                   t.allergy_alert_desc,
                   t.drug_ingredient_flg_coding,
                   t.flg_medication_allergy_type,
                   t.start_date_app_format,
                   t.start_date
              FROM TABLE(l_tab_allergies_cdas) t;
        /*ELSE
            g_error := 'OPEN O_ALLERGIES WITHOUT DATA';
            pk_alertlog.log_debug(g_error);
            pk_types.open_my_cursor(o_allergies);
        END IF;*/
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ALLERGY_LIST_CDA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_allergies);
            RETURN FALSE;
    END get_allergy_list_cda;

    /********************************************************************************************
    * Returns information about patient allergies like : codes, descriptions, allergy severities and associated symptoms
    * @param i_lang                     Language
    * @param i_patient                  Patient Identification
    * @param i_scope                    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_scope                 Scope unique identifier | When scope is 'P' - id patient, 'E' - id_episode , 'V' - id_visit 
    * @param o_allergies_cda            t_tbl_allergies type returned with all information
    * @param o_error                    An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          29-Jul-2014
    **********************************************************************************************/
    FUNCTION get_allergy_list_rec_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_scope         IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_allergies_cda OUT t_tbl_allergies,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episodes                  table_number := table_number();
        l_id_episode                episode.id_episode%TYPE;
        l_ferror                    t_error_out;
        l_func_name                 VARCHAR2(200 CHAR) := 'GET_ALLERGY_LIST_REC_CDA';
        l_allergies                 t_tbl_allergies;
        l_allerg_result             t_tbl_allergies;
        l_desc                      sys_message.desc_message%TYPE;
        l_symptoms_codes            table_varchar;
        l_symptoms_desc             table_varchar;
        l_symptoms_id               table_varchar;
        l_symptoms_trans_code       VARCHAR2(200 CHAR) := 'ALLERGY_SYMPTOMS.CODE_ALLERGY_SYMPTOMS.';
        l_allergy_parent_trans_code VARCHAR(200 CHAR) := 'ALLERGY.CODE_ALLERGY.';
    
        l_id_content_parent VARCHAR2(200);
    
        l_drug_ingredient_code pk_translation.t_desc_translation;
        l_drug_ingredient_desc pk_translation.t_desc_translation;
        l_type_allergy_code    pk_translation.t_desc_translation;
        l_type_allergy_desc    pk_translation.t_desc_translation;
        l_id_content           VARCHAR2(200);
    
        l_medication_info table_table_varchar;
    
        l_internal_error EXCEPTION;
        l_error VARCHAR(1000 CHAR);
    
    BEGIN
    
        l_error := 'FIND PATIENT EPISODES - BASED ON SCOPE PASSED';
        IF i_scope = g_scope_patient
        THEN
            l_error    := 'CALL PK_PATIENT.GET_EPISODE_LIST - USING PATIENT SCOPE';
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_patient,
                                                      i_id_episode        => NULL,
                                                      i_id_visit          => NULL,
                                                      i_flg_visit_or_epis => i_scope);
        ELSIF i_scope = g_scope_visit
        THEN
            l_error    := 'CALL PK_PATIENT.GET_EPISODE_LIST - USING VISIT SCOPE';
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_patient,
                                                      i_id_episode        => NULL,
                                                      i_id_visit          => i_id_scope,
                                                      i_flg_visit_or_epis => i_scope);
        ELSE
            l_error    := 'CALL PK_PATIENT.GET_EPISODE_LIST - USING EPISODE SCOPE';
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_patient,
                                                      i_id_episode        => i_id_scope,
                                                      i_id_visit          => NULL,
                                                      i_flg_visit_or_epis => i_scope);
        END IF;
    
        IF l_episodes.exists(1)
        THEN
            l_error := 'SELECT AND FILTER ALL PATIENT ALLERGIES USING TF_ALLERGY FUNCTION RESULTS';
        
            BEGIN
                SELECT t_rec_allergy(id_allergy            => id_allergy,
                                     id_pat_allergy        => id_pat_allergy,
                                     id_episode            => id_episode,
                                     allergen              => allergen,
                                     type_reaction         => type_reaction,
                                     onset                 => onset,
                                     dt_pat_allergy        => dt_pat_allergy,
                                     flg_type              => flg_type,
                                     flg_status            => flg_status,
                                     status_desc           => status_desc,
                                     rank                  => rank,
                                     status_string         => status_string,
                                     id_allergy_severity   => id_allergy_severity,
                                     severity              => severity,
                                     status_color          => status_color,
                                     free_text             => free_text,
                                     with_notes            => with_notes,
                                     cancelled_with_notes  => cancelled_with_notes,
                                     title_notes           => title_notes,
                                     allergy               => allergy,
                                     desc_speciality       => desc_speciality,
                                     nick_name             => nick_name,
                                     TYPE                  => TYPE,
                                     status                => status,
                                     hour_target           => hour_target,
                                     viewer_category       => viewer_category,
                                     viewer_category_desc  => viewer_category_desc,
                                     viewer_id_prof        => viewer_id_prof,
                                     viewer_id_epis        => viewer_id_epis,
                                     viewer_date           => viewer_date,
                                     notes                 => notes,
                                     reviewed              => reviewed,
                                     symptoms              => symptoms,
                                     flg_type_rep          => flg_type_rep,
                                     flg_source_rep        => flg_source_rep,
                                     id_allergy_parent     => id_allergy_parent,
                                     allergy_parent_desc   => allergy_parent_desc,
                                     severity_desc         => severity_desc,
                                     severity_alert_desc   => severity_alert_desc,
                                     id_symptoms           => id_symptoms,
                                     id_content_symptoms   => id_content_symptoms,
                                     symptoms_desc         => symptoms_desc,
                                     symptoms_alert_desc   => symptoms_alert_desc,
                                     id_drug_ingredient    => id_drug_ingredient,
                                     drug_ingredient_desc  => drug_ingredient_desc,
                                     start_date_app_format => start_date_app_format,
                                     start_date            => start_date,
                                     id_content            => id_content,
                                     id_content_parent     => id_content_parent,
                                     update_time           => update_time)
                  BULK COLLECT
                  INTO l_allergies
                  FROM (SELECT *
                          FROM TABLE(tf_allergy(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_patient    => i_patient,
                                                i_flg_filter => g_flg_type_allergy))) pa
                 WHERE pa.flg_status <> g_pat_allergy_flg_cancelled
                   AND pa.id_episode IN (SELECT *
                                           FROM TABLE(l_episodes))
                 ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                i_code_dom => g_pat_allergy_type,
                                                i_val      => pa.flg_type),
                          pa.rank,
                          pa.allergen ASC;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_allergies := NULL;
            END;
            IF l_allergies.exists(1)
            THEN
                -- Step used to find complexed fields like : symptoms, drug_ingredient identifier and id_contents
                FOR i IN l_allergies.first .. l_allergies.last
                LOOP
                    BEGIN
                        --get allergy symptoms
                        l_error := 'GET ALLERGY SYMPTOMS';
                        SELECT asympt.id_content,
                               pk_translation.get_translation(i_lang,
                                                              l_symptoms_trans_code || to_char(pas.id_allergy_symptoms)) desc_symptom,
                               pas.id_allergy_symptoms
                          BULK COLLECT
                          INTO l_symptoms_codes, l_symptoms_desc, l_symptoms_id
                          FROM pat_allergy_symptoms pas
                          LEFT JOIN allergy_symptoms asympt
                            ON asympt.id_allergy_symptoms = pas.id_allergy_symptoms
                         WHERE pas.id_pat_allergy = l_allergies(i).id_pat_allergy;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_error          := 'ALLERGY SYMPTOMS - NO DATA FOUND';
                            l_symptoms_codes := table_varchar();
                            l_symptoms_desc  := table_varchar();
                            l_symptoms_id    := table_varchar();
                    END;
                
                    l_error := 'VERIFY IF ID_ALERGY_PARENT AN DRUG ALLERGY';
                    IF l_allergies(i)
                     .id_allergy_parent IN (g_drug_class_id_allergy, g_drug_id_allergy, g_drug_com_id_allergy)
                    THEN
                        l_error := 'GET ID CONTENT PARENT BY DRUG ALLERGY CLASS';
                        SELECT a.id_content
                          INTO l_id_content_parent
                          FROM allergy a
                         WHERE a.id_allergy = g_drug_allergy;
                    
                        l_error := 'CALL PK_API_PFH_CLINDOC_IN.GET_ALLERGY_RXNORM TO GET DRUG ING INFO';
                        IF NOT pk_api_pfh_clindoc_in.get_allergy_rxnorm(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_id_allergy => l_allergies(i).id_allergy,
                                                                        o_info       => l_medication_info,
                                                                        o_error      => l_ferror)
                        
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                        l_error := 'VERIFY IF INFORMATION EXISTS FROM PK_API_PFH_CLINDOC_IN.GET_ALLERGY_RXNORM';
                        IF (l_medication_info.exists(1))
                        THEN
                            IF (l_medication_info(1).exists(2))
                            THEN
                                l_drug_ingredient_code := l_medication_info(1) (2);
                                l_id_content           := l_medication_info(1) (2);
                            END IF;
                            IF (l_medication_info(1).exists(3))
                            THEN
                                l_drug_ingredient_desc := l_medication_info(1) (3);
                                l_type_allergy_desc    := pk_translation.get_translation(i_lang      => i_lang,
                                                                                         i_code_mess => l_allergy_parent_trans_code ||
                                                                                                        g_drug_allergy);
                            END IF;
                        END IF;
                    
                    ELSE
                        l_error      := 'GET ID CONTENT PARENT INFORMATION AND TYPE ALLERGY DESC INFO';
                        l_id_content := l_allergies(i).id_content;
                        IF l_allergies(i).id_allergy_parent IS NOT NULL
                        THEN
                            SELECT a.id_content
                              INTO l_id_content_parent
                              FROM allergy a
                             WHERE a.id_allergy = l_allergies(i).id_allergy_parent;
                            l_type_allergy_desc := pk_translation.get_translation(i_lang      => i_lang,
                                                                                  i_code_mess => l_allergy_parent_trans_code || l_allergies(i).id_allergy_parent);
                        ELSE
                            l_id_content_parent := NULL;
                            l_type_allergy_desc := NULL;
                        END IF;
                    END IF;
                
                    l_error := 'SAVE SYMPTOMS INFORMATION, DRUG INGREDIENT AND ID CONTENT INFORMATION TO ID_ALLERGY - ' || l_allergies(i).id_allergy;
                    l_allergies(i).id_symptoms := l_symptoms_id;
                    l_allergies(i).id_content_symptoms := l_symptoms_codes;
                    l_allergies(i).symptoms_desc := l_symptoms_desc;
                    l_allergies(i).symptoms_alert_desc := NULL;
                    l_allergies(i).id_drug_ingredient := l_drug_ingredient_code;
                    l_allergies(i).drug_ingredient_desc := l_drug_ingredient_desc;
                    l_allergies(i).id_content := l_id_content;
                    l_allergies(i).id_content_parent := l_id_content_parent;
                
                END LOOP;
            END IF;
        END IF;
    
        o_allergies_cda := l_allergies;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_ferror);
            RETURN FALSE;
    END get_allergy_list_rec_cda;

    /**
    * List associations between allergies and medication products.
    * Used for the CDA report.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_allergies    allergy identifiers list
    * @param o_allg_prod    data cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/17
    */
    FUNCTION get_products
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_allergies IN table_number,
        o_allg_prod OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PRODUCTS';
    BEGIN
        g_error := 'OPEN o_allg_prod';
        OPEN o_allg_prod FOR
            SELECT a.id_allergy, a.id_product, a.id_ingredients, a.id_ing_group
              FROM allergy a
             WHERE a.id_allergy IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     t.column_value id_allergy
                                      FROM TABLE(i_allergies) t);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_allg_prod);
            RETURN FALSE;
    END get_products;

    /**
    * Get an allergy's records in the EHR (including severity).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/12/02
    */
    FUNCTION get_allergy_sever
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_cdr_api_out IS
        l_ret       t_coll_cdr_api_out := t_coll_cdr_api_out();
        l_allergies table_number;
    
        CURSOR c_ehr_allergy IS
            SELECT pa.id_pat_allergy, pa.id_allergy, pa.dt_pat_allergy_tstz, pa.id_allergy_severity
              FROM pat_allergy pa
             WHERE pa.id_patient = i_patient
               AND pa.id_allergy IS NOT NULL
               AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_passive);
    
        TYPE t_coll_ehr_allergy IS TABLE OF c_ehr_allergy%ROWTYPE;
        l_ehr_allergies t_coll_ehr_allergy;
    BEGIN
        -- retrieve allergies registered in ehr
        OPEN c_ehr_allergy;
        FETCH c_ehr_allergy BULK COLLECT
            INTO l_ehr_allergies;
        CLOSE c_ehr_allergy;
    
        IF l_ehr_allergies IS NULL
           OR l_ehr_allergies.count < 1
        THEN
            NULL;
        ELSE
            FOR i IN l_ehr_allergies.first .. l_ehr_allergies.last
            LOOP
                -- get associated ingredient allergies
                l_allergies := get_allergy_ingr_list(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_allergy => l_ehr_allergies(i).id_allergy);
            
                -- append all related allergies to output
                FOR j IN 1 .. l_allergies.count
                LOOP
                    l_ret.extend;
                    l_ret(l_ret.last) := t_rec_cdr_api_out(id_record           => l_ehr_allergies(i).id_pat_allergy,
                                                           id_element          => l_allergies(j),
                                                           dt_record           => l_ehr_allergies(i).dt_pat_allergy_tstz,
                                                           id_allergy_severity => l_ehr_allergies(i).id_allergy_severity,
                                                           id_task_request     => l_ehr_allergies(i).id_allergy);
                END LOOP;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_allergy_sever;

    /**
    * This function splits a product allergy into its ingredients (when applicable)
    *
    * @param  i_lang    Language ID
    * @param  i_prof    Professional structure
    * @param  i_allergy Allergy ID
    *
    * @return allergy list (one per ingredient) plus the product allergy
    *
    * @version  2.6.2
    * @since    19-Jan-2012
    * @author   Jos?Silva
    */
    FUNCTION get_allergy_ingr_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_allergy IN allergy.id_allergy%TYPE
    ) RETURN table_number IS
        l_ret           table_number := table_number();
        l_ingredients   table_varchar;
        l_ing_allergies table_number;
        l_rec_allergy   allergy%ROWTYPE;
    
        -- inner function that checks if it was registered an allergy to a product 
        FUNCTION is_product_allergy(i_allergy IN allergy%ROWTYPE) RETURN BOOLEAN IS
            l_ret BOOLEAN;
        BEGIN
            IF i_allergy.id_product IS NOT NULL
            THEN
                l_ret := TRUE;
            ELSE
                l_ret := FALSE;
            END IF;
        
            RETURN l_ret;
        END is_product_allergy;
    
    BEGIN
    
        SELECT id_allergy, id_product
          INTO l_rec_allergy.id_allergy, l_rec_allergy.id_product
          FROM allergy a
         WHERE a.id_allergy = i_allergy;
    
        l_ing_allergies := table_number();
    
        IF is_product_allergy(l_rec_allergy)
        THEN
        
            pk_api_pfh_clindoc_in.get_ingredients_by_products(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_products => table_varchar(l_rec_allergy.id_product),
                                                              o_id_ingreds  => l_ingredients);
        
            SELECT /*+opt_estimate(table ing rows=10)*/
             a.id_allergy
              BULK COLLECT
              INTO l_ing_allergies
              FROM TABLE(l_ingredients) ing
              JOIN allergy a
                ON a.id_ingredients = ing.column_value
             WHERE a.flg_available = pk_alert_constant.g_yes
               AND a.flg_active = pk_alert_constant.g_active;
        END IF;
    
        l_ret.extend;
        l_ret(1) := i_allergy;
    
        FOR j IN 1 .. l_ing_allergies.count
        LOOP
            l_ret.extend;
            l_ret(l_ret.last) := l_ing_allergies(j);
        END LOOP;
    
        RETURN l_ret;
    END get_allergy_ingr_list;

    /********************************************************************************************
    * Checks the limit for displaying allergies when browsing in the different categories
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional, software and institution IDs
    * @param i_allergy_parent        Allergy parent ID
    * @param i_flg_freq              Frequent allergy flag
    * @param i_market                Market ID
    * @param i_inst                  Institution ID
    * @param i_soft                  Software ID
    * @param i_standard              Standard ID
    * @param o_limit_message         Returned message if limit is exceeded
    * @param o_error                 Error Message
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sérgio Dias
    * @version                  2.6.1.0.1
    * @since                    06-May-2011
    *
    *********************************************************************************************/
    FUNCTION check_allergies_limit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_flg_freq       IN allergy_inst_soft_market.flg_freq%TYPE,
        i_market         IN market.id_market%TYPE,
        i_inst           IN institution.id_institution%TYPE,
        i_soft           IN software.id_software%TYPE,
        i_standard       IN sys_config.value%TYPE,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_result NUMBER;
    
        l_limit NUMBER;
        --extract configuration of max value to display
        l_db_limit sys_config.value%TYPE;
    BEGIN
        BEGIN
            --convert DB value to number
            g_error := 'GET SYS_CONFIG VALUE: g_allergy_search_limit';
            pk_alertlog.log_debug(g_error);
        
            l_db_limit := pk_sysconfig.get_config(i_code_cf   => g_allergy_search_limit,
                                                  i_prof_inst => i_prof.institution,
                                                  i_prof_soft => i_prof.software);
        
            l_limit := to_number(l_db_limit);
        EXCEPTION
            WHEN OTHERS THEN
                --if any problem happens, use the fail-safe value
                l_limit := g_default_limit;
        END;
    
        --count total values available
        g_error := 'COUNT TOTAL ALLERGY RESULTS';
        pk_alertlog.log_debug(g_error);
    
        SELECT COUNT(1)
          INTO l_result
          FROM (SELECT distinct a.id_allergy --pk_translation.get_translation(i_lang, a.code_allergy) desc_allergy
                  FROM allergy a, allergy_inst_soft_market aism
                 WHERE a.id_allergy = aism.id_allergy
                   AND aism.id_allergy_parent = i_allergy_parent
                   AND a.flg_active = pk_alert_constant.g_active
                   AND aism.id_market = i_market
                   AND aism.id_institution = i_inst
                   AND aism.id_software  in (pk_alert_constant.g_soft_all, i_soft)
                   AND (aism.flg_freq = pk_alert_constant.g_yes OR i_flg_freq = pk_alert_constant.g_no)
                   AND nvl(a.id_allergy_standard, i_standard) = i_standard
                   AND rownum > 0)
        -- WHERE desc_allergy IS NOT NULL
        ;
    
        IF l_result > l_limit
        THEN
            g_error := 'BUILD LIMIT EXCEEDED MESSAGE';
            pk_alertlog.log_debug(g_error);
        
            o_limit_message := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                              i_code_mess => g_allergies_limit_exceeded),
                                       '@1',
                                       l_limit);
            RETURN FALSE;
        ELSE
            o_limit_message := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CHECK_ALLERGIES_LIMIT',
                                                     o_error    => o_error);
    END check_allergies_limit;

    /********************************************************************************************
    * Checks the limit for displaying allergies when using the text search in the allergies screen
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional, software and institution IDs
    * @param i_search_pattern        Text value to be searched
    * @param i_market                Market ID
    * @param i_standard              Standard ID
    * @param o_limit_message         Returned message if limit is exceeded
    * @param o_error                 Error Message
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sérgio Dias
    * @version                  2.6.1.0.1
    * @since                    06-May-2011
    *
    *********************************************************************************************/
    FUNCTION check_allergies_search_limit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_search_pattern   IN pk_translation.t_desc_translation,
        i_market           IN market.id_market%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_software         IN software.id_software%TYPE,
        i_allergy_standard IN allergy.id_allergy_standard%TYPE,
        o_allergies        OUT pk_types.cursor_type,
        o_limit_message    OUT sys_message.desc_message%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_result NUMBER;
    
        l_limit    NUMBER;
        l_db_limit sys_config.value%TYPE;
    
        l_user_exception EXCEPTION;
    BEGIN
        BEGIN
            g_error := 'GET SYS_CONFIG VALUE: g_allergy_search_limit';
            pk_alertlog.log_debug(g_error);
        
            l_db_limit := pk_sysconfig.get_config(i_code_cf   => g_allergy_search_limit,
                                                  i_prof_inst => i_prof.institution,
                                                  i_prof_soft => i_prof.software);
        
            l_limit := to_number(l_db_limit);
        EXCEPTION
            WHEN OTHERS THEN
                l_limit := g_default_limit;
        END;
    
        g_error := 'COUNT TOTAL ALLERGIES VALUES (TEXT)';
        pk_alertlog.log_debug(g_error);
    
        SELECT /*+opt_estimate (table tf rows=10)*/
         COUNT(1)
          INTO l_result
          FROM (SELECT a.rowid AS rid, a.code_allergy
                   FROM allergy a
                  INNER JOIN (SELECT am.*
                               FROM (SELECT aism.id_allergy, aism.id_allergy_parent
                                       FROM allergy_inst_soft_market aism
                                      WHERE aism.id_market = i_market
                                        AND aism.id_institution = i_institution
                                        AND aism.id_software = i_software) am
                              WHERE connect_by_isleaf = 1
                              START WITH am.id_allergy_parent IS NULL
                             CONNECT BY PRIOR am.id_allergy = am.id_allergy_parent) al
                     ON a.id_allergy = al.id_allergy
                  WHERE rownum > 0 -- please DON'T REMOVE this condition due to performance issues
                   AND a.flg_active = pk_alert_constant.g_active
                   AND nvl(a.id_allergy_standard, i_allergy_standard) = i_allergy_standard) ar,
               (SELECT *
                  FROM TABLE(pk_translation.get_search_translation(i_lang, i_search_pattern, 'ALLERGY.CODE_ALLERGY'))) tf
         WHERE tf.code_translation = ar.code_allergy;
    
        IF l_result > l_limit
        THEN
            RAISE l_user_exception;
        ELSE
            o_limit_message := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_user_exception THEN
            g_error := 'BUILD LIMIT EXCEEDED MESSAGE';
            pk_alertlog.log_debug(g_error);
        
            o_limit_message := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                              i_code_mess => g_allergies_limit_exceeded),
                                       '@1',
                                       l_limit);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              o_limit_message,
                                              o_limit_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_ALLERGIES_SEARCH_LIMIT',
                                              'U',
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CHECK_ALLERGIES_SEARCH_LIMIT',
                                                     o_error    => o_error);
    END check_allergies_search_limit;

    /**
     * This function ables the user to add more than one allergy at a time.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_day_begin             ARRAY/Allergy start's day
     * @param IN  i_month_begin           ARRAY/Allergy start's month
     * @param IN  i_year_begin            ARRAY/Allergy start's year          
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.1.0.1
     * @since    2011-May-11
     * @author   Sergio Dias
    */
    FUNCTION set_allergy_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_day_begin           IN table_number,
        i_month_begin         IN table_number,
        i_year_begin          IN table_number,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_id_pat_allergy      pat_allergy.id_pat_allergy%TYPE := NULL;
        l_id_allergy          allergy.id_allergy%TYPE := NULL;
        l_desc_allergy        pat_allergy.desc_allergy%TYPE := NULL;
        l_notes               pat_allergy.notes%TYPE := NULL;
        l_flg_status          pat_allergy.flg_status%TYPE := NULL;
        l_flg_type            pat_allergy.flg_type%TYPE := NULL;
        l_flg_aproved         pat_allergy.flg_aproved%TYPE := NULL;
        l_desc_aproved        pat_allergy.desc_aproved%TYPE := NULL;
        l_year_begin          pat_allergy.year_begin%TYPE := NULL;
        l_month_begin         pat_allergy.month_begin%TYPE := NULL;
        l_day_begin           pat_allergy.day_begin%TYPE := NULL;
        l_id_allergy_severity pat_allergy.id_allergy_severity%TYPE := NULL;
        l_flg_edit            pat_allergy.flg_edit%TYPE := NULL;
        l_desc_edit           pat_allergy.desc_edit%TYPE := NULL;
        l_id_symptoms         table_number;
    
    BEGIN
        o_id_pat_allergy := table_number();
    
        l_message := 'SET_ALLERGY - LOOP 1';
        FOR i IN i_id_allergy.first .. i_id_allergy.last
        LOOP
            o_id_pat_allergy.extend();
        
            IF (i_id_pat_allergy.exists(i))
            THEN
                l_id_pat_allergy := i_id_pat_allergy(i);
            END IF;
        
            IF (i_id_allergy.exists(i))
            THEN
                l_id_allergy := i_id_allergy(i);
            END IF;
        
            IF (i_desc_allergy.exists(i))
            THEN
                l_desc_allergy := i_desc_allergy(i);
            END IF;
        
            IF (i_notes.exists(i))
            THEN
                l_notes := i_notes(i);
            END IF;
        
            IF (i_flg_status.exists(i))
            THEN
                l_flg_status := i_flg_status(i);
            END IF;
        
            IF (i_flg_type.exists(i))
            THEN
                l_flg_type := i_flg_type(i);
            END IF;
        
            IF (i_flg_aproved.exists(i))
            THEN
                l_flg_aproved := i_flg_aproved(i);
            END IF;
        
            IF (i_desc_aproved.exists(i))
            THEN
                l_desc_aproved := i_desc_aproved(i);
            END IF;
        
            IF (i_year_begin.exists(i))
            THEN
                l_year_begin := i_year_begin(i);
            END IF;
        
            IF (i_month_begin.exists(i))
            THEN
                l_month_begin := i_month_begin(i);
            END IF;
        
            IF (i_day_begin.exists(i))
            THEN
                l_day_begin := i_day_begin(i);
            END IF;
        
            IF (i_id_allergy_severity.exists(i))
            THEN
                l_id_allergy_severity := i_id_allergy_severity(i);
            END IF;
        
            IF (i_desc_edit.exists(i))
            THEN
                IF ((i_desc_edit(i) IS NOT NULL) AND (i_flg_edit(i) = g_flg_edit_other))
                THEN
                    l_desc_edit := i_desc_edit(i);
                ELSE
                    l_desc_edit := NULL;
                END IF;
            ELSE
                l_desc_edit := NULL;
            END IF;
        
            IF (i_flg_edit.exists(i))
            THEN
                IF (l_desc_edit IS NOT NULL)
                THEN
                    l_flg_edit := g_flg_edit_other;
                ELSE
                    l_flg_edit := i_flg_edit(i);
                END IF;
            ELSIF (l_id_pat_allergy IS NOT NULL)
            THEN
                l_flg_edit := g_flg_edit_other;
            END IF;
        
            IF (i_id_symptoms.exists(i))
            THEN
                l_id_symptoms := i_id_symptoms(i);
            END IF;
        
            IF (NOT set_allergy(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                l_id_pat_allergy,
                                l_id_allergy,
                                l_desc_allergy,
                                l_notes,
                                l_flg_status,
                                l_flg_type,
                                l_flg_aproved,
                                l_desc_aproved,
                                l_day_begin,
                                l_month_begin,
                                l_year_begin,
                                l_id_symptoms,
                                l_id_allergy_severity,
                                l_flg_edit,
                                l_desc_edit,
                                i_cdr_call,
                                pk_alert_constant.g_no,
                                o_id_pat_allergy(i),
                                o_error))
            THEN
                RETURN FALSE;
            END IF;
        
            -- whenever an allergy is created/edited stays automatically reviewed  
            IF NOT set_allergy_as_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_id_episode,
                                         i_id_pat_allergy => o_id_pat_allergy(i),
                                         i_review_notes   => NULL,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_message := 'call set_register_by_me_nc';
            IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_episode  => i_id_episode,
                                                     i_pat         => i_id_patient,
                                                     i_id_problem  => o_id_pat_allergy(i),
                                                     i_flg_type    => 'A',
                                                     i_flag_active => pk_alert_constant.g_yes,
                                                     o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY/ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_array;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_day_begin             Allergy start's day
     * @param IN  i_month_begin           Allergy start's month
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.1.0.1
     * @since    2011-May-11
     * @author   Sergio Dias
    */
    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_commit              IN VARCHAR2 DEFAULT 'Y',
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message VARCHAR(200);
        l_return  BOOLEAN;
    BEGIN
        l_message := 'PK_ALLERGY.SET_ALLERGY';
        l_return  := set_allergy_int(i_lang,
                                     i_prof,
                                     i_id_patient,
                                     i_id_episode,
                                     i_id_pat_allergy,
                                     i_id_allergy,
                                     i_desc_allergy,
                                     i_notes,
                                     i_flg_status,
                                     i_flg_type,
                                     i_flg_aproved,
                                     i_desc_aproved,
                                     i_year_begin,
                                     i_month_begin,
                                     i_day_begin,
                                     NULL,
                                     NULL,
                                     NULL,
                                     i_id_symptoms,
                                     i_id_allergy_severity,
                                     i_flg_edit,
                                     i_desc_edit,
                                     NULL,
                                     NULL,
                                     i_cdr_call,
                                     'N',
                                     o_id_pat_allergy,
                                     o_error);
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_allergy         allergy identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          19/07/2012
    */
    FUNCTION get_desc_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_desc_type      IN VARCHAR2
    ) RETURN CLOB IS
        l_ret          CLOB;
        l_desc_allergy CLOB;
        l_desc_status  sys_domain.desc_val%TYPE;
        l_notes        pat_history_diagnosis.notes%TYPE;
        l_symptoms     CLOB;
        l_severity     VARCHAR2(2000);
        l_date_begin   VARCHAR2(200 CHAR);
        CURSOR c_desc IS
            SELECT decode(pa.id_allergy, NULL, pa.desc_allergy, pk_translation.get_translation(i_lang, a.code_allergy)) l_desc_allergy,
                   pk_sysdomain.get_domain(pk_allergy.g_pat_allergy_status, pa.flg_status, i_lang) l_desc_status,
                   decode(pa.flg_status, pk_allergy.g_pat_allergy_flg_cancelled, pa.cancel_notes, pa.notes) l_notes,
                   pk_allergy.get_symptoms(i_lang, id_pat_allergy) l_symptoms,
                   (SELECT pk_translation.get_translation(i_lang, s.code_allergy_severity)
                      FROM allergy_severity s
                     WHERE s.id_allergy_severity = pa.id_allergy_severity) severity,
                   pk_allergy.get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin)
              FROM pat_allergy pa
              LEFT JOIN allergy a
                ON a.id_allergy = pa.id_allergy
            
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
    
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_desc_allergy, l_desc_status, l_notes, l_symptoms, l_severity, l_date_begin;
        CLOSE c_desc;
    
        IF i_desc_type = 'D'
        THEN
            l_ret := l_desc_allergy || --
                     CASE
                         WHEN l_date_begin IS NOT NULL THEN
                          pk_prog_notes_constants.g_comma || l_date_begin
                         ELSE
                          NULL
                     END || --
                     CASE
                         WHEN l_symptoms IS NOT NULL THEN
                          ' ' ||
                          pk_string_utils.surround(i_string => l_symptoms, i_pattern => pk_string_utils.g_pattern_parenthesis)
                         ELSE
                          NULL
                     END || --
                     CASE
                         WHEN l_severity IS NOT NULL THEN
                          pk_prog_notes_constants.g_comma || l_severity
                         ELSE
                          NULL
                     END || --
                     CASE
                         WHEN l_notes IS NOT NULL THEN
                          pk_prog_notes_constants.g_comma || l_notes
                         ELSE
                          NULL
                     END;
        ELSE
        
            l_ret := l_desc_allergy || pk_prog_notes_constants.g_comma || l_desc_status || --
                     CASE
                         WHEN l_notes IS NOT NULL THEN
                          pk_prog_notes_constants.g_comma || l_notes
                         ELSE
                          NULL
                     END || --
                     CASE
                         WHEN l_symptoms IS NOT NULL THEN
                          ' ' ||
                          pk_string_utils.surround(i_string => l_symptoms, i_pattern => pk_string_utils.g_pattern_parenthesis)
                         ELSE
                          NULL
                     END;
        
        END IF;
        l_ret := pk_string_utils.trim_empty_lines(i_text => l_ret);
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_allergy;
    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_allergy_unaware         allergy identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          19/07/2012
    */
    FUNCTION get_desc_allergy_unaware
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_desc_type              IN VARCHAR2
    ) RETURN CLOB IS
        l_ret          CLOB;
        l_desc_allergy CLOB;
        l_notes        pat_history_diagnosis.notes%TYPE;
        CURSOR c_desc IS
            SELECT pk_translation.get_translation(i_lang, a.code_unawareness_type) l_desc_allergy,
                   decode(pa.flg_status, pk_allergy.g_unawareness_cancelled, pa.cancel_notes, pa.notes) l_notes
              FROM pat_allergy_unawareness pa
              LEFT JOIN allergy_unawareness a
                ON a.id_allergy_unawareness = pa.id_allergy_unawareness
             WHERE pa.id_pat_allergy_unawareness = i_id_pat_allergy_unaware;
    
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_desc_allergy, l_notes;
        CLOSE c_desc;
    
        l_ret := l_desc_allergy || --
                 CASE
                     WHEN l_notes IS NOT NULL THEN
                      pk_prog_notes_constants.g_comma || l_notes
                     ELSE
                      NULL
                 END;
    
        l_ret := pk_string_utils.trim_empty_lines(i_text => l_ret);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_allergy_unaware;

    /**
    * Get count allergie unawareness.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier 
    *
    * @return               -1 if there are no know allergie, 0 if no allergies , > 0 number of allergies
    *
    * @author               Elisabete Bugalho
    * @version              2.6.3.5
    * @since                2013/05/21
    */
    FUNCTION get_count_allergy_unawareness
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN PLS_INTEGER IS
        l_number_of_allergies PLS_INTEGER;
        l_unawareness         PLS_INTEGER;
    BEGIN
        l_number_of_allergies := get_count_allergy(1, i_patient, o_error);
        IF l_number_of_allergies = 0
        THEN
        
            SELECT COUNT(1)
              INTO l_unawareness
              FROM pat_allergy_unawareness pau
             WHERE pau.id_patient = i_patient
               AND pau.id_allergy_unawareness IN (g_no_known)
               AND pau.flg_status = g_unawareness_active;
        
            IF l_unawareness > 0
            THEN
                l_number_of_allergies := -1;
            END IF;
        
        END IF;
        RETURN l_number_of_allergies;
    
    END get_count_allergy_unawareness;

    /********************************************************************************************
    * Allergies associated to a given list of episodes
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           episode id        
    * @param o_allergy           array with info allergy
    *
    * @param o_error             Error message
    * @return                    true or false on success or error
    *
    * @author                    Sofia Mendes (code separated from pk_episode.get_summary_s function)
    * @since                     21/03/2013  
    ********************************************************************************************/
    FUNCTION get_allergies
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN table_number,
        i_patient IN patient.id_patient%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(13 CHAR) := 'GET_ALLERGIES';
        l_message debug_msg;
    BEGIN
        --ALERGIAS
        l_message := 'CURSOR O_ALLERGY';
        pk_alertlog.log_info(text => l_message, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_allergy FOR
            SELECT DISTINCT pk_translation.get_translation(i_lang, tt.code_allergy) || ' (' ||
                            pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', tt.flg_status, i_lang) || ')' desc_info,
                            tt.id_episode,
                            pk_prof_utils.get_detail_signature(i_lang,
                                                               i_prof,
                                                               id_episode,
                                                               dt_pat_allergy_tstz,
                                                               id_prof_write) signature
              FROM (SELECT t.code_allergy, t.flg_status, t.id_episode, t.dt_pat_allergy_tstz, t.id_prof_write
                      FROM (SELECT a.code_allergy, pa.flg_status, pa.id_episode, pa.dt_pat_allergy_tstz, pa.id_prof_write
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                      *
                                                       FROM TABLE(i_episode) t)
                               AND pa.flg_status != pk_alert_constant.g_cancelled
                               AND a.id_allergy = pa.id_allergy
                            UNION ALL
                            SELECT a.code_allergy, pa.flg_status, pa.id_episode, rd.dt_review, pa.id_prof_write
                              FROM pat_allergy pa, allergy a, review_detail rd
                             WHERE pa.id_patient = i_patient
                               AND rd.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                      *
                                                       FROM TABLE(i_episode) t)
                               AND pa.flg_status != pk_alert_constant.g_cancelled
                               AND a.id_allergy = pa.id_allergy
                               AND pa.id_pat_allergy = rd.id_record_area
                               AND rd.flg_context = pk_review.get_allergies_context
                               AND rd.flg_auto = pk_alert_constant.g_no
                               AND pa.id_pat_allergy NOT IN
                                   (SELECT pa.id_pat_allergy
                                      FROM pat_allergy pa
                                     WHERE pa.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                              *
                                                               FROM TABLE(i_episode) t)
                                       AND pa.flg_status != pk_alert_constant.g_cancelled)) t
                     ORDER BY dt_pat_allergy_tstz) tt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_allergies;

    /**
    * Get an allergy's records in the EHR (including severity).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               collection
    *
    * @author               Mário Mineiro
    * @version               2.6.3
    * @since                2014/01/13
    */
    FUNCTION get_allergy_cds
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_cdr_api_out IS
        l_ret       t_coll_cdr_api_out := t_coll_cdr_api_out();
        l_allergies table_number;
    
        CURSOR c_ehr_allergy IS
            SELECT pa.id_pat_allergy, pa.id_allergy, pa.dt_pat_allergy_tstz, pa.id_allergy_severity
              FROM pat_allergy pa
             WHERE pa.id_patient = i_patient
                  
               AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_passive)
               AND pa.id_allergy IN
                   (SELECT a.id_allergy
                      FROM allergy a
                     WHERE market = (SELECT desc_market
                                       FROM market
                                      WHERE id_market = nvl(pk_utils.get_institution_market(i_lang, i_prof.institution),
                                                            g_default_market))
                       AND id_allergy_standard =
                           pk_sysconfig.get_config(i_code_cf   => pk_allergy.g_allergy_presc_type,
                                                   i_prof_inst => i_prof.institution,
                                                   i_prof_soft => i_prof.software)
                          -- should show all allergy of patient even not active
                          --AND flg_available = pk_alert_constant.g_yes
                          --AND flg_active = pk_alert_constant.g_active
                       AND (a.id_product IS NOT NULL OR a.id_ingredients IS NOT NULL OR a.id_ing_group IS NOT NULL))
            
            ;
    
        TYPE t_coll_ehr_allergy IS TABLE OF c_ehr_allergy%ROWTYPE;
        l_ehr_allergies t_coll_ehr_allergy;
        l_inst_market   institution.id_market%TYPE;
    BEGIN
        g_error       := 'Getting get_allergy_cds';
        l_inst_market := prv_get_inst_market(i_lang, i_prof);
    
        -- retrieve allergies registered in ehr
        OPEN c_ehr_allergy;
        FETCH c_ehr_allergy BULK COLLECT
            INTO l_ehr_allergies;
        CLOSE c_ehr_allergy;
    
        IF l_ehr_allergies IS NULL
           OR l_ehr_allergies.count < 1
        THEN
            NULL;
        ELSE
            FOR i IN l_ehr_allergies.first .. l_ehr_allergies.last
            LOOP
            
                l_ret.extend;
                l_ret(l_ret.last) := t_rec_cdr_api_out(id_record           => l_ehr_allergies(i).id_pat_allergy,
                                                       id_element          => l_ehr_allergies(i).id_allergy,
                                                       dt_record           => l_ehr_allergies(i).dt_pat_allergy_tstz,
                                                       id_allergy_severity => l_ehr_allergies(i).id_allergy_severity,
                                                       id_task_request     => l_ehr_allergies(i).id_allergy);
            
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_allergy_cds;

    /**
    * check if an allergy is from medication return 1 or 0
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_allergy   allergy identifier
    *
    * @return               number 1 or 0
    *
    * @author               Mário Mineiro
    * @version               2.6.3
    * @since                2014/01/13
    */
    FUNCTION check_allergy_med_cds
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_allergy IN allergy.id_allergy%TYPE
    ) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM allergy a
         WHERE a.id_allergy = i_id_allergy
           AND (a.id_product IS NOT NULL OR a.id_ingredients IS NOT NULL OR a.id_ing_group IS NOT NULL);
    
        RETURN l_count;
    
    END check_allergy_med_cds;

    /********************************************************************************************
    * Converts allergy concepts from/to some code.  
    * @param i_lang                     Language
    * @param i_source_codes             Codes to be mapped
    * @param i_source_coding_scheme     Type code (rxnorm - 6, snomed - 2)
    * @param i_target_coding_scheme     Allergy context (101 - id allergy, 103 - allergy type, 105 - reactions, 106 - severity)
    * @param o_target_codes             All Codes returned
    * @param o_target_display_names     All Code descriptions returned
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-May-2014
    **********************************************************************************************/
    FUNCTION get_allergy_info_cs_cda
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_target_coding_scheme    IN VARCHAR2,
        i_target_coordinated_expr IN table_varchar,
        i_id_med_context          IN VARCHAR2 DEFAULT NULL,
        o_target_codes            OUT table_varchar,
        o_target_display_name     OUT table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message    VARCHAR(1000);
        l_func_name  VARCHAR(1000) := 'GET_ALLERGY_INFO_CS_CDA';
        l_flg_avail  VARCHAR2(1) := 'Y';
        l_flg_active VARCHAR2(1) := 'A';
        l_error      VARCHAR2(1000);
    
        l_market institution.id_market%TYPE;
        l_inst   institution.id_institution%TYPE;
        l_soft   software.id_software%TYPE;
    
        l_allergy_type_code VARCHAR2(100);
        l_alg_type      CONSTANT VARCHAR2(1) := 'A';
        l_code_alg_type CONSTANT sys_domain.code_domain%TYPE := pk_allergy.g_pat_allergy_type;
    
        l_med_context_product    CONSTANT VARCHAR2(1 CHAR) := 'P';
        l_med_context_ingredient CONSTANT VARCHAR2(1 CHAR) := 'I';
        l_med_context_group      CONSTANT VARCHAR2(1 CHAR) := 'G';
    
        l_id_med_context VARCHAR2(1 CHAR);
    
        l_allergy_info VARCHAR2(100);
        l_flag_type    VARCHAR2(100);
    
    BEGIN
    
        get_aism_cfg_vars(i_lang => i_lang, i_prof => i_prof, o_market => l_market, o_inst => l_inst, o_soft => l_soft);
    
        CASE
            WHEN i_target_coding_scheme = g_cs_id_allergy THEN
                l_error := 'PROCESS ALLERGY ID';
            
                l_id_med_context := nvl(i_id_med_context, l_med_context_product);
            
                SELECT allergy_info.id_allergy,
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => allergy_info.code_allergy)
                  BULK COLLECT
                  INTO o_target_codes, o_target_display_name
                  FROM (SELECT to_char(a.id_allergy) id_allergy,
                               a.code_allergy,
                               row_number() over(ORDER BY decode(aism.flg_freq, pk_alert_constant.g_yes, 1, 2))
                          FROM allergy a
                         INNER JOIN allergy_inst_soft_market aism
                            ON (a.id_allergy = aism.id_allergy)
                         WHERE a.flg_active = pk_alert_constant.g_active
                           AND ((l_id_med_context = l_med_context_product AND
                               a.id_product IN (SELECT column_value
                                                    FROM TABLE(i_target_coordinated_expr))) OR
                               (l_id_med_context = l_med_context_ingredient AND
                               a.id_ingredients IN (SELECT column_value
                                                        FROM TABLE(i_target_coordinated_expr))) OR
                               (l_id_med_context = l_med_context_group AND
                               a.id_ing_group IN (SELECT column_value
                                                      FROM TABLE(i_target_coordinated_expr))))
                           AND aism.id_market = l_market
                           AND aism.id_institution = l_inst
                           AND aism.id_software = l_soft) allergy_info;
            
            WHEN i_target_coding_scheme = g_cs_id_allergy_type THEN
                l_error := 'PROCESS ALLERGY TYPE';
            
                SELECT allergy_info.id_allergy || '|' || allergy_info.flg_type,
                       pk_sysdomain.get_domain(i_code_dom => allergy_info.code_sys_dom,
                                               i_val      => allergy_info.flg_type,
                                               i_lang     => i_lang) || ': ' ||
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => allergy_info.code_allergy)
                  BULK COLLECT
                  INTO o_target_codes, o_target_display_name
                  FROM (SELECT to_char(a.id_allergy) id_allergy,
                               a.code_allergy,
                               target_tbl.flg_type,
                               target_tbl.code_sys_dom,
                               row_number() over(ORDER BY decode(aism.flg_freq, pk_alert_constant.g_yes, 1, 2))
                          FROM allergy a
                         INNER JOIN allergy_inst_soft_market aism
                            ON (a.id_allergy = aism.id_allergy)
                         INNER JOIN (SELECT nvl(regexp_substr(t.column_value, '[^|]+', 1, 1), t.column_value) type_code,
                                           nvl(regexp_substr(t.column_value, '[^.]+', 1, 5), l_alg_type) flg_type,
                                           nvl(regexp_substr(t.column_value, '[^.]+', 1, 3) || '.' ||
                                               regexp_substr(t.column_value, '[^.]+', 1, 4),
                                               l_code_alg_type) code_sys_dom
                                      FROM TABLE(i_target_coordinated_expr) t) target_tbl
                            ON target_tbl.type_code = a.id_content
                         WHERE a.flg_active = pk_alert_constant.g_active
                           AND aism.id_market = l_market
                           AND aism.id_institution = l_inst
                           AND aism.id_software = l_soft) allergy_info;
            
            WHEN i_target_coding_scheme = g_cs_id_allergy_reaction THEN
                l_error := 'PROCESS ALLERGY REACTION';
            
                SELECT to_char(a.id_allergy_symptoms),
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => a.code_allergy_symptoms)
                  BULK COLLECT
                  INTO o_target_codes, o_target_display_name
                  FROM allergy_symptoms a
                 WHERE a.flg_status = pk_alert_constant.g_active
                   AND a.id_content IN (SELECT *
                                          FROM TABLE(i_target_coordinated_expr));
            
            WHEN i_target_coding_scheme = g_cs_id_allergy_severity THEN
                l_error := 'ALLERGY SEVERITY';
            
                SELECT to_char(a.id_allergy_severity),
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => a.code_allergy_severity)
                  BULK COLLECT
                  INTO o_target_codes, o_target_display_name
                  FROM allergy_severity a
                 WHERE a.flg_status = pk_alert_constant.g_active
                   AND a.id_content IN (SELECT *
                                          FROM TABLE(i_target_coordinated_expr));
            
            ELSE
                l_error               := 'TARGET CODING SCHEME DOESN''T EXISTS';
                o_target_codes        := NULL;
                o_target_display_name := NULL;
        END CASE;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_allergy_info_cs_cda;

    /********************************************************************************************
    * Get drug allergy parents
    *
    * @return Array with drug allergy parents
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.4
    * @since                          02-Jul-2014
    **********************************************************************************************/
    FUNCTION tf_drug_allergy_prts_cda RETURN table_varchar IS
        l_grandpa        CONSTANT allergy.id_content%TYPE := 'TMP13.6440';
        l_sys_domain     CONSTANT VARCHAR2(1000 CHAR) := 'SYS_DOMAIN';
        l_pat_allerg_typ CONSTANT VARCHAR2(1000 CHAR) := 'PAT_ALLERGY.FLG_TYPE';
        l_ret table_varchar;
    BEGIN
        SELECT xr.source_coordinated_expr drug_allergy_parents
          BULK COLLECT
          INTO l_ret
          FROM xmap_relationship xr
         WHERE xr.source_coordinated_expr LIKE l_grandpa || '|%'
        UNION ALL
        SELECT a.id_content || '|' || l_sys_domain || '.' || l_pat_allerg_typ || '.' || sd.val
          FROM allergy a
         CROSS JOIN sys_domain sd
         WHERE a.id_allergy_parent = (SELECT a1.id_allergy
                                        FROM allergy a1
                                       WHERE a1.id_content = l_grandpa)
           AND a.flg_available = pk_alert_constant.g_yes
           AND sd.code_domain = l_pat_allerg_typ
           AND sd.domain_owner = pk_sysdomain.k_default_schema
           AND sd.id_language = 2
           AND sd.flg_available = pk_alert_constant.g_yes
        UNION ALL
        SELECT a.id_allergy || '|' || sd.val
          FROM allergy a
         CROSS JOIN sys_domain sd
         WHERE a.id_content = l_grandpa
           AND a.flg_available = pk_alert_constant.g_yes
           AND sd.code_domain = l_pat_allerg_typ
           AND sd.domain_owner = pk_sysdomain.k_default_schema
           AND sd.id_language = 2
           AND sd.flg_available = pk_alert_constant.g_yes
        UNION ALL
        SELECT a.id_allergy || '|' || sd.val
          FROM allergy a
         CROSS JOIN sys_domain sd
         WHERE a.id_allergy_parent = (SELECT a1.id_allergy
                                        FROM allergy a1
                                       WHERE a1.id_content = l_grandpa)
           AND a.flg_available = pk_alert_constant.g_yes
           AND sd.code_domain = l_pat_allerg_typ
           AND sd.id_language = 2
           AND sd.domain_owner = pk_sysdomain.k_default_schema
           AND sd.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_varchar();
    END tf_drug_allergy_prts_cda;
    /********************************************************************************************
    * get_viewer_allergy 
    *             
    * @param i_lang       language idenfier
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Paulo Teixeira  
    * @version                        2.6.5
    * @since                          2016-02-10
    **********************************************************************************************/
    FUNCTION get_viewer_allergy
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN pk_types.cursor_type IS
        ret     pk_types.cursor_type;
        l_count NUMBER(12) := 0;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM pat_allergy_unawareness pau
         WHERE pau.id_patient = i_id_patient
           AND pau.id_episode = i_id_episode
           AND pau.id_allergy_unawareness IN (g_unable_asess, g_no_known_drugs, g_no_known)
           AND pau.flg_status = g_unawareness_active
           AND rownum = 1;
    
        IF l_count = 0
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM pat_allergy pa
             WHERE pa.id_patient = i_id_patient
               AND pa.id_episode = i_id_episode
               AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved)
               AND rownum = 1;
        
            IF l_count = 0
            THEN
                SELECT COUNT(1)
                  INTO l_count
                  FROM pat_allergy pa
                
                  JOIN review_detail rd
                    ON rd.id_episode = i_id_episode
                   AND rd.id_record_area = pa.id_pat_allergy
                   AND rd.flg_context = g_allergy_review_context
                
                 WHERE pa.id_patient = i_id_patient
                   AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved)
                   AND rownum = 1;
            END IF;
        END IF;
    
        OPEN ret FOR
            SELECT CASE
                        WHEN l_count = 0 THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END AS flg_show_allergy
              FROM dual;
    
        RETURN ret;
    EXCEPTION
        WHEN OTHERS THEN
            OPEN ret FOR
                SELECT pk_alert_constant.g_no AS flg_show_allergy
                  FROM dual;
    END get_viewer_allergy;

    /********************************************************************************************
    * Get allergies viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/
    FUNCTION get_viewer_allergy_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_count    NUMBER(12) := 0;
        l_episodes table_number;
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    BEGIN
        SELECT *
          BULK COLLECT
          INTO l_episodes
          FROM TABLE(pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_id_patient,
                                          i_episode    => i_id_episode,
                                          i_flg_filter => i_scope_type));
        SELECT COUNT(1)
          INTO l_count
          FROM pat_allergy_unawareness pau
         WHERE pau.id_episode IN (SELECT column_value /*+opt_estimate (table t rows=0.00000000001)*/
                                    FROM TABLE(l_episodes) t)
           AND pau.id_allergy_unawareness IN (g_unable_asess)
           AND pau.flg_status = g_unawareness_active
           AND rownum = 1;
    
        IF l_count = 0
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM (SELECT pau.id_pat_allergy_unawareness id
                      FROM pat_allergy_unawareness pau
                     WHERE (pau.id_episode IN (SELECT column_value /*+opt_estimate (table t rows=0.00000000001)*/
                                                 FROM TABLE(l_episodes) t) OR
                           (pau.id_episode IS NULL AND pau.id_patient = i_id_patient))
                       AND pau.id_allergy_unawareness IN (g_no_known_drugs, g_no_known)
                       AND pau.flg_status = g_unawareness_active
                    UNION
                    SELECT pa.id_pat_allergy
                      FROM pat_allergy pa
                     WHERE pa.id_episode IN (SELECT column_value /*+opt_estimate (table t rows=0.00000000001)*/
                                               FROM TABLE(l_episodes) t)
                       AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved)
                    UNION
                    SELECT pa.id_pat_allergy
                      FROM pat_allergy pa
                      JOIN review_detail rd
                        ON rd.id_episode IN (SELECT column_value /*+opt_estimate (table t rows=0.00000000001)*/
                                               FROM TABLE(l_episodes) t)
                       AND rd.id_record_area = pa.id_pat_allergy
                       AND rd.flg_context = g_allergy_review_context
                    
                     WHERE pa.id_patient = i_id_patient
                       AND pa.flg_status NOT IN (g_pat_allergy_flg_cancelled, g_pat_allergy_flg_resolved));
        
            IF l_count > 0
            THEN
                l_status := pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            l_status := pk_viewer_checklist.g_checklist_ongoing;
        END IF;
    
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_viewer_allergy_checklist;

    /********************************************************************************************
    * Get allergies for hand-off
    *             
    * @param i_lang                     language idenfier
    * @param i_id_patient               patient idenfier
    * @param o_allergies                cursor with allergies 
    * @param o_error                    t_error_out type error
    *
    * @return                           true/false
    * 
    * @author                           Elisabete Bugalho
    * @version                          2.7.1
    * @since                            29-03-2017
    **********************************************************************************************/

    FUNCTION get_pat_allergies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_flg_show_msg IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_allergies    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR(1000) := 'GET_PAT_ALLERGIES';
        l_value     VARCHAR2(4000 CHAR);
        l_allergy   table_varchar;
    BEGIN
    
        g_error := 'CALL tf_allergy';
    
        IF i_flg_show_msg != pk_alert_constant.g_no
        THEN
            SELECT pk_utils.concat_table(CAST(COLLECT(desc_allergy) AS table_varchar), '; ') desc_allergy
              INTO l_value
              FROM (SELECT pk_utils.concat_table(CAST(COLLECT(pa.allergen) AS table_varchar), '; ') desc_allergy,
                           type_reaction
                      FROM TABLE(tf_allergy(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_patient    => i_patient,
                                            i_flg_filter => g_flg_type_allergy)) pa
                     WHERE pa.flg_status = g_pat_allergy_flg_active
                     GROUP BY type_reaction);
        ELSE
        
            SELECT pk_utils.concat_table(CAST(COLLECT(type_reaction || ': ' || desc_allergy) AS table_varchar), '; ') desc_allergy
              INTO l_value
              FROM (SELECT pk_utils.concat_table(CAST(COLLECT(pa.allergen) AS table_varchar), '; ') desc_allergy,
                           type_reaction
                      FROM TABLE(tf_allergy(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_patient    => i_patient,
                                            i_flg_filter => g_flg_type_allergy)) pa
                     WHERE pa.flg_status = g_pat_allergy_flg_active
                     GROUP BY type_reaction);
        END IF;
        g_error := 'OPEN o_allergies';
        OPEN o_allergies FOR
            SELECT nvl2(l_value,
                        upper(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ALLERGY_LIST_T001') || ':'),
                        '') title,
                   l_value VALUE
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END get_pat_allergies;

    /********************************************************************************************
    * Create default no know allergy for new patient
    *             
    * @param i_lang                     language idenfier
    * @param i_prof                     Professional structure
    * @param i_id_patient               patient idenfier
    * @param o_error                    t_error_out type error
    *
    * @return                           true/false
    * 
    * @author                           Amanda Lee
    * @version                          2.7.1
    * @since                            04-10-2017
    **********************************************************************************************/

    FUNCTION create_default_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR(50) := 'CREATE_DEFAULT_ALLERGY';
        l_choices             t_cur_allergy_unawareness;
        l_coll_choices        t_coll_allergy_unawareness;
        l_flg_enabled         VARCHAR2(2 CHAR) := pk_alert_constant.get_no;
        l_number_of_allergies PLS_INTEGER := 0;
        l_dummy               pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE;
    BEGIN
    
        g_error := 'Check allergy exist or not';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_number_of_allergies
          FROM pat_allergy pa
         WHERE pa.id_patient = i_patient
           AND pa.flg_status IN (g_pat_allergy_flg_active, g_pat_allergy_flg_passive);
    
        IF (l_number_of_allergies = 0)
        THEN
            g_error := 'Check no known allergy already exist or not';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(*)
              INTO l_number_of_allergies
              FROM pat_allergy_unawareness pau
             WHERE pau.id_patient = i_patient
               AND pau.flg_status = g_unawareness_active
               AND pau.id_allergy_unawareness IN (g_no_known);
            IF (l_number_of_allergies = 0)
            THEN
                l_flg_enabled := pk_alert_constant.g_yes;
            END IF;
        END IF;
        pk_alertlog.log_debug('l_flg_enabled=' || l_flg_enabled);
    
        IF l_flg_enabled = pk_alert_constant.g_yes
        THEN
            IF set_allergy_unawareness_no_com(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_episode         => i_episode,
                                              i_patient         => i_patient,
                                              i_unawareness     => g_no_known,
                                              i_pat_unawareness => NULL,
                                              i_notes           => NULL,
                                              o_pat_unawareness => l_dummy,
                                              o_error           => o_error)
            THEN
                pk_alertlog.log_debug('set_allergy_unawareness = true');
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END create_default_allergy;

    /**
     * This function ables the user to add more than one allergy at a time. EMR-846
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_day_begin             ARRAY/Allergy start's day
     * @param IN  i_month_begin           ARRAY/Allergy start's month
     * @param IN  i_year_begin            ARRAY/Allergy start's year          
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param IN  i_cdr_call              ARRAY/Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.7.3
     * @since    2018-Apr-02
     * @author   Alexander Camilo
    */
    FUNCTION set_allergy_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_day_begin           IN table_number,
        i_month_begin         IN table_number,
        i_year_begin          IN table_number,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN table_number,
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_exception EXCEPTION;
        l_id_pat_allergy      pat_allergy.id_pat_allergy%TYPE := NULL;
        l_id_allergy          allergy.id_allergy%TYPE := NULL;
        l_desc_allergy        pat_allergy.desc_allergy%TYPE := NULL;
        l_notes               pat_allergy.notes%TYPE := NULL;
        l_flg_status          pat_allergy.flg_status%TYPE := NULL;
        l_flg_type            pat_allergy.flg_type%TYPE := NULL;
        l_flg_aproved         pat_allergy.flg_aproved%TYPE := NULL;
        l_desc_aproved        pat_allergy.desc_aproved%TYPE := NULL;
        l_year_begin          pat_allergy.year_begin%TYPE := NULL;
        l_month_begin         pat_allergy.month_begin%TYPE := NULL;
        l_day_begin           pat_allergy.day_begin%TYPE := NULL;
        l_id_allergy_severity pat_allergy.id_allergy_severity%TYPE := NULL;
        l_flg_edit            pat_allergy.flg_edit%TYPE := NULL;
        l_desc_edit           pat_allergy.desc_edit%TYPE := NULL;
        l_id_symptoms         table_number;
        l_cdr_call            cdr_call.id_cdr_call%TYPE := NULL;
    
    BEGIN
        o_id_pat_allergy := table_number();
    
        l_message := 'SET_ALLERGY - LOOP 1';
        FOR i IN i_id_allergy.first .. i_id_allergy.last
        LOOP
            o_id_pat_allergy.extend();
        
            IF (i_id_pat_allergy.exists(i))
            THEN
                l_id_pat_allergy := i_id_pat_allergy(i);
            END IF;
        
            IF (i_id_allergy.exists(i))
            THEN
                l_id_allergy := i_id_allergy(i);
            END IF;
        
            IF (i_desc_allergy.exists(i))
            THEN
                l_desc_allergy := i_desc_allergy(i);
            END IF;
        
            IF (i_notes.exists(i))
            THEN
                l_notes := i_notes(i);
            END IF;
        
            IF (i_flg_status.exists(i))
            THEN
                l_flg_status := i_flg_status(i);
            END IF;
        
            IF (i_flg_type.exists(i))
            THEN
                l_flg_type := i_flg_type(i);
            END IF;
        
            IF (i_flg_aproved.exists(i))
            THEN
                l_flg_aproved := i_flg_aproved(i);
            END IF;
        
            IF (i_desc_aproved.exists(i))
            THEN
                l_desc_aproved := i_desc_aproved(i);
            END IF;
        
            IF (i_year_begin.exists(i))
            THEN
                l_year_begin := i_year_begin(i);
            END IF;
        
            IF (i_month_begin.exists(i))
            THEN
                l_month_begin := i_month_begin(i);
            END IF;
        
            IF (i_day_begin.exists(i))
            THEN
                l_day_begin := i_day_begin(i);
            END IF;
        
            IF (i_id_allergy_severity.exists(i))
            THEN
                l_id_allergy_severity := i_id_allergy_severity(i);
            END IF;
        
            IF (i_desc_edit.exists(i))
            THEN
                IF ((i_desc_edit(i) IS NOT NULL) AND (i_flg_edit(i) = g_flg_edit_other))
                THEN
                    l_desc_edit := i_desc_edit(i);
                ELSE
                    l_desc_edit := NULL;
                END IF;
            ELSE
                l_desc_edit := NULL;
            END IF;
        
            IF (i_flg_edit.exists(i))
            THEN
                IF (l_desc_edit IS NOT NULL)
                THEN
                    l_flg_edit := g_flg_edit_other;
                ELSE
                    l_flg_edit := i_flg_edit(i);
                END IF;
            ELSIF (l_id_pat_allergy IS NOT NULL)
            THEN
                l_flg_edit := g_flg_edit_other;
            END IF;
        
            IF (i_id_symptoms.exists(i))
            THEN
                l_id_symptoms := i_id_symptoms(i);
            END IF;
        
            IF (i_cdr_call.exists(i))
            THEN
                l_cdr_call := i_cdr_call(i);
            END IF;
        
            IF (NOT set_allergy(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                l_id_pat_allergy,
                                l_id_allergy,
                                l_desc_allergy,
                                l_notes,
                                l_flg_status,
                                l_flg_type,
                                l_flg_aproved,
                                l_desc_aproved,
                                l_day_begin,
                                l_month_begin,
                                l_year_begin,
                                l_id_symptoms,
                                l_id_allergy_severity,
                                l_flg_edit,
                                l_desc_edit,
                                l_cdr_call,
                                pk_alert_constant.g_no,
                                o_id_pat_allergy(i),
                                o_error))
            THEN
                RETURN FALSE;
            END IF;
        
            -- whenever an allergy is created/edited stays automatically reviewed  
            IF NOT set_allergy_as_review(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_id_episode,
                                         i_id_pat_allergy => o_id_pat_allergy(i),
                                         i_review_notes   => NULL,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_message := 'call set_register_by_me_nc';
            IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_episode  => i_id_episode,
                                                     i_pat         => i_id_patient,
                                                     i_id_problem  => o_id_pat_allergy(i),
                                                     i_flg_type    => 'A',
                                                     i_flag_active => pk_alert_constant.g_yes,
                                                     o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ALLERGY/ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_allergy_array;

    /********************************************************************************************
    * Get allergy unawareness for patient
    *             
    * @param i_lang                     language idenfier
    * @param i_id_patient               patient idenfier
    * @param o_allergies                cursor with allergies unawareness
    * @param o_error                    t_error_out type error
    *
    * @return                           true/false
    * 
    * @author                           Adriana Ramos
    * @since                            05/07/2018
    **********************************************************************************************/

    FUNCTION get_pat_allergy_unawareness
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_allergies OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR(1000) := 'GET_PAT_ALLERGY_UNAWARENESS';
    BEGIN
    
        g_error := 'OPEN o_allergies';
        OPEN o_allergies FOR
            SELECT pk_translation.get_translation(i_lang, au.code_allergy_unawareness) desc_allergy_unawareness
              FROM pat_allergy_unawareness pau
              JOIN allergy_unawareness au
                ON pau.id_allergy_unawareness = au.id_allergy_unawareness
             WHERE pau.flg_status = g_unawareness_active
               AND pau.id_patient = i_patient
             ORDER BY pau.id_allergy_unawareness;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END get_pat_allergy_unawareness;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(g_package_name);
END pk_allergy;
/