/*-- Last Change Revision: $Rev: 2027496 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_prescription IS

    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

    /**######################################################
      Private functions
    ######################################################**/

    /**######################################################
      End of Private functions
    ######################################################**/

    FUNCTION get_current_timestamp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        o_timezone VARCHAR2(500);
    BEGIN
        IF pk_date_utils.get_timezone(i_lang, i_prof, NULL, o_timezone, o_error)
        THEN
            o_error := o_error;
            RETURN current_timestamp;
        END IF;
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := get_current_timestamp(i_lang, i_prof, o_error);
    END;

   
    ----------------------------- FUNÇÕES NOVAS: PRESCRIÇÃO -----------------------------------------------------
/********************************************************************************************
     * Cancel the prescription of one drug (not the entire prescription).
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_presc_pharm            id_prescription_pharm (drug prescription ID)
     * @param i_emb                    Drug ID
     * @param i_flg_type               Type of prescription
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error   
     *
     * @value i_flg_type               {*} 'E' Outside prescription
                                       {*} 'I' Internal prescription
                                       {*} 'R' Reported prescription
                                       {*} ''  cancel on the prescription screen
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/11
    **********************************************************************************************/

    FUNCTION cancel_pharm_prescr
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_presc_pharm   IN prescription_pharm.id_prescription_pharm%TYPE,
        i_emb           IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT cancel_pharm_prescr(i_lang          => i_lang,
                                   i_episode       => i_episode,
                                   i_presc_pharm   => i_presc_pharm,
                                   i_emb           => i_emb,
                                   i_flg_type      => i_flg_type,
                                   i_prof          => i_prof,
                                   i_prof_cat_type => i_prof_cat_type,
                                   i_commit        => 'Y',
                                   o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CANCEL_PHARM_PRESCR',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_pharm_prescr;
    --

    FUNCTION cancel_pharm_prescr
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_presc_pharm   IN prescription_pharm.id_prescription_pharm%TYPE,
        i_emb           IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_commit        IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- Verificar se existem relatos da prescrição que se está a cancelar
        CURSOR c_reported(l_presc_pharm IN prescription.id_prescription%TYPE) IS
            SELECT 'Y'
              FROM pat_medication_list
             WHERE id_prescription_pharm = l_presc_pharm;
    
        -- Se se está a cancelar no ecrã de listagem de fármacos(mais frequentes ou pesquisa), não se sabe qual o ID da prescrição      
        CURSOR c_presc2 IS
            SELECT pp.id_prescription_pharm, p.id_prescription
              FROM prescription_pharm pp, prescription p
             WHERE p.id_episode = i_episode
               AND p.flg_status = g_flg_temp
               AND pp.id_prescription = p.id_prescription
               AND ((pp.emb_id = i_emb AND i_flg_type = g_flg_ext) OR (pp.id_drug = i_emb AND i_flg_type = g_flg_int) OR
                   (pp.id_dietary_drug = i_emb AND i_flg_type = g_flg_dietary_ext) OR
                   (pp.id_manipulated = i_emb AND i_flg_type = g_flg_manip_ext));
    
        CURSOR c_prescription(l_prescription IN prescription.id_prescription%TYPE) IS
            SELECT COUNT(1) num
              FROM prescription_pharm pp, prescription p
             WHERE p.id_prescription = l_prescription
               AND p.id_prescription = pp.id_prescription;
    
        CURSOR c_id_presc IS
            SELECT id_prescription
              FROM prescription_pharm pp
             WHERE pp.id_prescription_pharm = i_presc_pharm;
    
        CURSOR c_drug_req2 IS
            SELECT drd.id_drug_req_det, dr.id_drug_req
              FROM drug_req dr, drug_req_det drd
             WHERE dr.id_episode = i_episode
               AND dr.flg_status = g_flg_temp
               AND drd.id_drug_req = dr.id_drug_req
               AND drd.id_drug = i_emb;
    
        CURSOR c_drug_req(l_drug_req IN drug_req.id_drug_req%TYPE) IS
            SELECT COUNT(1) num
              FROM drug_req dr, drug_req_det drd
             WHERE dr.id_drug_req = l_drug_req
               AND dr.id_drug_req = drd.id_drug_req;
    
        CURSOR c_id_drug_req IS
            SELECT id_drug_req
              FROM drug_req_det drd
             WHERE drd.id_drug_req_det = i_presc_pharm;
    
        l_exist              VARCHAR2(1);
        l_pat                patient.id_patient%TYPE;
        l_presc1             VARCHAR2(1);
        l_status             prescription.flg_status%TYPE;
        l_prescription_pharm prescription_pharm.id_prescription_pharm%TYPE;
        l_presc_pharm        prescription_pharm.id_prescription_pharm%TYPE;
        l_prescription       prescription.id_prescription%TYPE;
        l_drug_req_det       drug_req_det.id_drug_req_det%TYPE;
        l_drug_req           drug_req.id_drug_req%TYPE;
        l_count              NUMBER;
        l_reported           VARCHAR2(1);
        l_interac_med        VARCHAR2(1);
        l_related_presc      table_number;
        l_related_med        table_number;
        l_type               table_varchar := table_varchar();
        l_id_pat             NUMBER;
        i                    NUMBER := 1;
    
        l_rowids_1 table_varchar;
        l_error    VARCHAR2(2000);
        e_process_event EXCEPTION;
    
        l_flg_ci              drug_presc_det.flg_ci%TYPE;
        l_flg_cheaper         drug_presc_det.flg_cheaper%TYPE;
        l_flg_justif          drug_presc_det.flg_justif%TYPE;
        l_flg_interac_allergy drug_presc_det.flg_interac_allergy%TYPE;
    
        l_rowids      table_varchar;
        l_flg_att_aux prescription_pharm.flg_attention%TYPE;
    BEGIN
    
        g_sysdate_tstz := get_current_timestamp(i_lang, i_prof, o_error);
    
        l_related_presc := table_number();
        l_related_med   := table_number();
    
        IF i_flg_type != g_flg_reported
        THEN
            IF i_flg_type = g_flg_int
            THEN
            
                g_error := 'IF I_PRESC_PHARM IS NOT NULL';
                IF i_presc_pharm IS NULL
                THEN
                    -- cancela uma prescrição que pode ter relato          
                    g_error := 'OPEN c_drug_req2';
                    OPEN c_drug_req2;
                    FETCH c_drug_req2
                        INTO l_drug_req_det, l_drug_req;
                    CLOSE c_drug_req2;
                ELSE
                    g_error := 'OPEN c_id_drug_req';
                    OPEN c_id_drug_req;
                    FETCH c_id_drug_req
                        INTO l_drug_req;
                    CLOSE c_id_drug_req;
                
                END IF;
            
                l_drug_req_det := nvl(l_drug_req_det, i_presc_pharm);
            
                g_error := 'OPEN C_REPORTED'; --verificar se existem relatos desta prescrição 
                OPEN c_reported(l_drug_req_det);
                FETCH c_reported
                    INTO l_reported;
                g_found := c_reported%FOUND;
                CLOSE c_reported;
            
                IF g_found
                THEN
                
                    DELETE presc_interactions_hist
                     WHERE id_pat_medic_list_dest IN
                           (SELECT id_pat_medication_list
                              FROM pat_medication_list
                             WHERE id_drug_req_det = l_drug_req_det);
                
                    --existem relatos, então apaga o relato      
                    g_error := 'DELETE PRESC_INTERACTIONS - ID_PAT_MEDIC_LIST_DEST';
                    DELETE presc_interactions
                     WHERE id_pat_medic_list_dest IN
                           (SELECT id_pat_medication_list
                              FROM pat_medication_list
                             WHERE id_drug_req_det = l_drug_req_det);
                
                    g_error := 'DELETE PAT_MEDICATION_HIST_LIST 1';
                    DELETE pat_medication_hist_list
                     WHERE id_drug_req_det = l_drug_req_det;
                
                    g_error := 'DELETE PAT_MEDICATION_LIST 1';
                    DELETE pat_medication_list
                     WHERE id_drug_req_det = l_drug_req_det;
                
                END IF; --G_FOUND
            
                g_error := 'OPEN C_PRESCRIPTION'; -- Obter o nº de medicamentos prescritos; se for 1, elimina PRESCRIPTION.
                OPEN c_drug_req(l_drug_req);
                FETCH c_drug_req
                    INTO l_count;
                CLOSE c_drug_req;
            
                DELETE presc_interactions_hist
                 WHERE id_drug_req_det_source = l_drug_req_det
                    OR id_drug_req_det_dest = l_drug_req_det;
            
                DELETE presc_interactions
                 WHERE id_drug_req_det_source = l_drug_req_det
                    OR id_drug_req_det_dest = l_drug_req_det;
            
                g_error := 'DELETE PRESC_PAT_PROBLEM';
                DELETE presc_pat_problem_hist
                 WHERE id_drug_req_det = l_drug_req_det;
            
                g_error := 'DELETE PRESC_PAT_PROBLEM';
                DELETE presc_pat_problem
                 WHERE id_drug_req_det = l_drug_req_det;
            
                DELETE presc_adverse_dosage_hist
                 WHERE id_drug_req_det = l_drug_req_det;
            
                DELETE presc_adverse_dosage
                 WHERE id_drug_req_det = l_drug_req_det;
            
                g_error := 'DELETE PRESC_ATTENTION_DET';
                DELETE presc_attention_det
                 WHERE id_drug_req_det = l_drug_req_det;
            
                g_error := 'DELETE drug_req_det';
                DELETE drug_req_det
                 WHERE id_drug_req_det = l_drug_req_det;
            
                /*g_error := 'set_care_plan_task_req_med';
                IF NOT pk_care_plans.set_care_plan_task_req_med(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_flg_task_type => 'MF',
                                                                i_req           => i_presc_pharm,
                                                                o_error         => o_error)
                THEN
                    IF i_commit IS NULL
                       OR i_commit = g_yes
                    THEN
                        pk_utils.undo_changes;
                    END IF;
                    pk_alertlog.log_debug(g_error);
                    RETURN FALSE;
                END IF;*/
            
                IF l_count = 1
                THEN
                    -- *********************************
                    -- PT 26/09/2008 2.4.3.d
                    g_error := 'DELETE drug_req: ' || l_drug_req_det || ' ; ' || l_drug_req;
                    ts_drug_req.del(id_drug_req_in => l_drug_req, rows_out => l_rowids_1);
                
                    t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'DRUG_REQ',
                                                  i_rowids     => l_rowids_1,
                                                  o_error      => o_error);
                    -- *********************************
                END IF;
            ELSE
            
                g_error := 'IF I_PRESC_PHARM IS NOT NULL';
                IF i_presc_pharm IS NULL
                THEN
                    -- cancela uma prescrição que pode ter relato          
                    g_error := 'OPEN C_PRESC2'; -- Obter o ID da prescrição que se está a cancelar
                    OPEN c_presc2;
                    FETCH c_presc2
                        INTO l_prescription_pharm, l_prescription;
                    CLOSE c_presc2;
                ELSE
                    g_error := 'OPEN c_id_presc'; -- Obter o ID da prescrição que se está a cancelar
                    OPEN c_id_presc;
                    FETCH c_id_presc
                        INTO l_prescription;
                    CLOSE c_id_presc;
                
                END IF;
            
                l_prescription_pharm := nvl(l_prescription_pharm, i_presc_pharm);
            
                g_error := 'OPEN C_REPORTED'; --verificar se existem relatos desta prescrição 
                OPEN c_reported(l_prescription_pharm);
                FETCH c_reported
                    INTO l_reported;
                g_found := c_reported%FOUND;
                CLOSE c_reported;
            
                IF g_found
                THEN
                
                    DELETE presc_interactions_hist
                     WHERE id_pat_medic_list_dest IN
                           (SELECT id_pat_medication_list
                              FROM pat_medication_list
                             WHERE id_prescription_pharm = l_prescription_pharm);
                
                    --existem relatos, então apaga o relato      
                    g_error := 'DELETE PRESC_INTERACTIONS - ID_PAT_MEDIC_LIST_DEST';
                    DELETE presc_interactions
                     WHERE id_pat_medic_list_dest IN
                           (SELECT id_pat_medication_list
                              FROM pat_medication_list
                             WHERE id_prescription_pharm = l_prescription_pharm);
                
                    g_error := 'DELETE PAT_MEDICATION_HIST_LIST 1';
                    DELETE pat_medication_hist_list
                     WHERE id_prescription_pharm = l_prescription_pharm;
                
                    g_error := 'DELETE PAT_MEDICATION_LIST 1';
                    DELETE pat_medication_list
                     WHERE id_prescription_pharm = l_prescription_pharm;
                END IF; --G_FOUND
            
                g_error := 'OPEN C_PRESCRIPTION';
                -- Obter o nº de medicamentos prescritos; se for 1, elimina PRESCRIPTION.
                OPEN c_prescription(l_prescription);
                FETCH c_prescription
                    INTO l_count;
                CLOSE c_prescription;
            
                DELETE presc_pat_problem_hist
                 WHERE id_prescription_pharm = l_prescription_pharm;
            
                g_error := 'DELETE PRESC_PAT_PROBLEM';
                DELETE presc_pat_problem
                 WHERE id_prescription_pharm = l_prescription_pharm;
            
                g_error := 'DELETE PRESC_INTERACTIONS - ID_PRESC_PHARM';
                DELETE presc_interactions_hist
                 WHERE id_presc_pharm_source = l_prescription_pharm
                    OR id_presc_pharm_dest = l_prescription_pharm;
            
                g_error := 'DELETE PRESC_INTERACTIONS - ID_PRESC_PHARM';
                DELETE presc_interactions
                 WHERE id_presc_pharm_source = l_prescription_pharm
                    OR id_presc_pharm_dest = l_prescription_pharm;
            
                DELETE presc_adverse_dosage_hist
                 WHERE id_prescription_pharm = l_prescription_pharm;
            
                DELETE presc_adverse_dosage
                 WHERE id_prescription_pharm = l_prescription_pharm;
            
                g_error := 'DELETE PRESCRIPTION_PHARM_DET';
                DELETE prescription_pharm_det
                 WHERE id_prescription_pharm = l_prescription_pharm;
            
                g_error := 'DELETE PRESC_ATTENTION_DET';
                DELETE presc_attention_det
                 WHERE id_prescription_pharm = l_prescription_pharm;
            
                g_error := 'DELETE PRESCRIPTION_PHARM';
                ts_prescription_pharm.del(id_prescription_pharm_in => l_prescription_pharm, rows_out => l_rowids);
            
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PRESCRIPTION_PHARM',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                /*g_error := 'set_care_plan_task_req_med';
                IF NOT pk_care_plans.set_care_plan_task_req_med(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_flg_task_type => 'ME',
                                                                i_req           => i_presc_pharm,
                                                                o_error         => o_error)
                THEN
                    IF i_commit IS NULL
                       OR i_commit = g_yes
                    THEN
                        pk_utils.undo_changes;
                    END IF;
                    pk_alertlog.log_debug(g_error);
                    RETURN FALSE;
                END IF;*/
            
                l_rowids_1 := table_varchar();
            
                IF l_count = 1
                THEN
                    --se o único medicamento daquela prescrição é o que se está a cancelar, então apaga a prescrição
                    g_error := 'DELETE PRESCRIPTION: ' || l_prescription_pharm || ' ; ' || l_prescription;
                
                    ts_prescription.del(id_prescription_in => l_prescription, rows_out => l_rowids_1);
                
                    t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PRESCRIPTION',
                                                  i_rowids     => l_rowids_1,
                                                  o_error      => o_error);
                END IF; --L_COUNT 
            
                --  END IF; --I_PRESC_PHARM 
            END IF;
        ELSIF i_flg_type = g_flg_reported
        THEN
            -- cancelar relatos de medicação
            g_error := 'DELETE PAT_MEDICATION_HIST_LIST 2';
            DELETE pat_medication_hist_list
             WHERE id_pat_medication_list = i_presc_pharm;
        
            g_error := 'DELETE PAT_MEDICATION_LIST 2';
            DELETE pat_medication_list
             WHERE id_pat_medication_list = i_presc_pharm;
        END IF; --I_FLG_TYPE   
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CANCEL_PHARM_PRESCR',
                                              o_error);
            IF i_commit IS NULL
               OR i_commit = g_yes
            THEN
                pk_utils.undo_changes;
            END IF;
            RETURN FALSE;
    END;
    /********************************************************************************************
     * Get the parent GROUP_ID.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_group_id               "Child GROUP_ID"
     *
     * @return                         number -> GROUP_ID
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/07
    **********************************************************************************************/

    FUNCTION get_id_parent
    (
        i_lang     IN language.id_language%TYPE,
        i_group_id IN NUMBER
    ) RETURN NUMBER IS
    
        CURSOR c_parent_id IS
            SELECT ic.cft_id_parent
              FROM inf_cft ic
             WHERE ic.cft_id = i_group_id;
    
        l_parent_id NUMBER;
    
    BEGIN
    
        g_error := 'OPEN c_parent_id';
        OPEN c_parent_id;
        FETCH c_parent_id
            INTO l_parent_id;
        CLOSE c_parent_id;
    
        RETURN l_parent_id;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    ----------------------------------------------------------------------------------------------------------
    /** @headcom
    * Public Function.  Obter preço de uma embalagem.   
    * Não é chamada pelo Flash.
    *
    * @param      I_EMB             ID da embalagem
    * @param      I_TYPE            Tipo de preço: 
                 0 - PVP
                                             1 - Preço de Referência
                                             2 - Preço de Referência para Pensionistas
    *
    * @return     varchar2
    * @author     SS
    * @version    0.1
    * @since      2006/03/14
    */

    FUNCTION get_price
    (
        i_emb  IN inf_emb.emb_id%TYPE,
        i_type IN VARCHAR2
    ) RETURN NUMBER IS
    
        CURSOR c_pvp IS
            SELECT ip.preco
              FROM inf_preco ip
             WHERE ip.emb_id = i_emb
               AND ip.tipo_preco_id BETWEEN 1 AND 9 --PVP
               AND ip.data_preco = (SELECT MAX(ip1.data_preco)
                                      FROM inf_preco ip1
                                     WHERE ip1.emb_id = ip.emb_id
                                       AND ip1.tipo_preco_id BETWEEN 1 AND 9); --PVP
    
        CURSOR c_pref IS
            SELECT ip.preco
              FROM inf_preco ip
             WHERE ip.emb_id = i_emb
               AND ip.tipo_preco_id BETWEEN 101 AND 109 --Preço de referência
               AND ip.data_preco = (SELECT MAX(ip1.data_preco)
                                      FROM inf_preco ip1
                                     WHERE ip1.emb_id = ip.emb_id
                                       AND ip1.tipo_preco_id BETWEEN 101 AND 109); --Preço de referência
    
        CURSOR c_prpen IS
            SELECT ip.preco
              FROM inf_preco ip
             WHERE ip.emb_id = i_emb
               AND ip.tipo_preco_id BETWEEN 201 AND 209 --Preço de referência para pensionistas
               AND ip.data_preco = (SELECT MAX(ip1.data_preco)
                                      FROM inf_preco ip1
                                     WHERE ip1.emb_id = ip.emb_id
                                       AND ip1.tipo_preco_id BETWEEN 201 AND 209); --Preço de referência para pensionistas
    
        l_price NUMBER;
    
    BEGIN
    
        IF i_type = 0
        THEN
            g_error := 'OPEN C_PVP';
            OPEN c_pvp;
            FETCH c_pvp
                INTO l_price;
            CLOSE c_pvp;
        
        ELSIF i_type = 1
        THEN
            g_error := 'OPEN C_PREF';
            OPEN c_pref;
            FETCH c_pref
                INTO l_price;
            CLOSE c_pref;
        
        ELSE
            g_error := 'OPEN C_PRPEN';
            OPEN c_prpen;
            FETCH c_prpen
                INTO l_price;
            CLOSE c_prpen;
        END IF;
    
        RETURN l_price;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
/********************************************************************************************
     * Get the patiente R.E.C.M.
     *
     * @param i_lang                   Preferred language ID for this professional                 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient                             
     *
     * @return                         patiente R.E.C.M.
     *
     * @author                         Nuno Antunes
     * @version                        0.1
     * @since                          2010/07/07
    **********************************************************************************************/
    FUNCTION get_patient_recm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_recm VARCHAR2(2);
    
    BEGIN
    
        BEGIN
            SELECT flg_recm
              INTO l_recm
              FROM (SELECT r.flg_recm, vpr.expiration_date
                      FROM v_pat_recm vpr
                      LEFT JOIN recm r
                        ON r.id_recm = vpr.id_recm
                     WHERE vpr.id_patient = i_id_patient
                     ORDER BY 2 DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_recm := '';
        END;
    
        RETURN l_recm;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20002,
                                    pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                    'PK_PRESCRIPTION.GET_PATIENT_RECM / ' || g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_patient_recm;

    /*******************************************************************************************************************************************
    * Description: Sets the review detail. Removed the review option and added the Conclude Previous medicatio list - Meaningful use           *
    *                                                                                                                                          *
    * @param I_LANG                   LANGUAGE                                                                                                 *
    * @param I_PROF                   PROFESSIONAL ARRAY                                                                                       *
    * @param I_EPISODE                EPISODE                                                                                                  *
    * @param I_ACTION                 ACTION TO BE TAKEN: partial or completly reviewed                                                        *
    * @param I_REVIEW_NOTES           REVIEW NOTES                                                                                             *
    * @param I_DT_NOTES               REVIEW DATE                                                                                              *
    *                                                                                                                                          *
    * @return                         BOOLEAN                                                                                                  *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Pedro Morais                                                                                             *
    * @version                        1.0                                                                                                      *
    * @since                          2011-03-30                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION set_reconcile_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN drug_prescription.id_episode%TYPE,
        i_action          IN VARCHAR2 DEFAULT NULL,
        i_reconcile_notes IN VARCHAR2 DEFAULT NULL,
        i_dt_reconcile    IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_reconcile          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_no_reconcile_record   BOOLEAN := FALSE; --No record for reconciliation in table
        l_med_reconcile_context review_detail.flg_context%TYPE := pk_review.get_med_reconcile_context();
        l_id_episode            review_detail.id_episode%TYPE;
    
        l_current_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        g_error := 'SET TIMESTAMP';
        IF i_dt_reconcile IS NULL
        THEN
            l_dt_reconcile := current_timestamp;
        ELSE
            l_dt_reconcile := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_reconcile, NULL);
        END IF;
    
        --Set reviewed - creates new record in review_detail - keeps the history of the notes
        IF i_action = g_set_reconciled
           OR i_action IS NULL --default behavior
        THEN
            g_error := 'set_reconcile - reconciled';
            IF NOT pk_review.set_review(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_id_record_area     => i_episode,
                                        i_flg_context        => l_med_reconcile_context,
                                        i_dt_review          => l_dt_reconcile,
                                        i_review_notes       => i_reconcile_notes,
                                        i_episode            => i_episode, --same as id_record_area. This way, we can say it is fully reviewed
                                        i_flg_auto           => 'N',
                                        i_revision           => NULL,
                                        i_flg_problem_review => 'N',
                                        o_error              => o_error)
            THEN
                raise_application_error(-20002, o_error.ora_sqlerrm);
            END IF;
        
            g_error := 'set_review from set_reconcile - reconciled and reviewed';
            IF NOT pk_medication_previous.set_review_detail(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_episode      => i_episode,
                                                            i_action       => pk_medication_previous.g_set_reviewed,
                                                            i_review_notes => i_reconcile_notes,
                                                            i_dt_review    => i_dt_reconcile,
                                                            o_error        => o_error)
            THEN
                raise_application_error(-20002, o_error.ora_sqlerrm);
            END IF;
        
        ELSIF i_action IN (g_set_not_reconciled, g_set_part_reconciled)
        THEN
        
            g_error := 'set_reconcile - Check if already in partially reconciled state';
            --Check if already in partially reconciled state
            BEGIN
                SELECT rd.id_episode -- pk_alert_constant.g_yes
                  INTO l_id_episode --l_already_part
                  FROM review_detail rd
                 WHERE rd.id_record_area = i_episode
                   AND rd.flg_context = l_med_reconcile_context
                      --AND rd.id_episode IS NULL --If null, is partially reviewed
                   AND rd.dt_review = (SELECT MAX(rd2.dt_review)
                                         FROM review_detail rd2
                                        WHERE rd2.id_record_area = i_episode
                                          AND rd2.flg_context = l_med_reconcile_context);
            EXCEPTION
                WHEN no_data_found THEN
                    l_no_reconcile_record := TRUE;
            END;
        
            IF NOT l_no_reconcile_record -- no reconciliation record ever, for this episode
               AND l_id_episode IS NOT NULL --last "reconciliation" record is a reconciliation, otherwise is a "partially reconciliation"
            --l_already_part = pk_alert_constant.g_no --Only inssert new records if not in partially reviewd state
            THEN
            
                g_error := 'set_reconcile - not/partially reconciled';
                IF NOT pk_review.set_review(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_record_area     => i_episode,
                                            i_flg_context        => l_med_reconcile_context,
                                            i_dt_review          => l_dt_reconcile,
                                            i_review_notes       => i_reconcile_notes,
                                            i_episode            => NULL, --not the same as id_record_area. This way, we can say it is partially reviewed
                                            i_flg_auto           => 'N',
                                            i_revision           => NULL,
                                            i_flg_problem_review => 'N',
                                            o_error              => o_error)
                THEN
                    raise_application_error(-20003, o_error.ora_sqlerrm);
                END IF;
            
            ELSE
            
                g_error := 'set_reconcile - update last reconcile date, if partially reconciled';
                --update last reconcile date
                UPDATE review_detail rd
                   SET rd.dt_review = l_current_timestamp
                 WHERE rd.id_record_area = i_episode
                   AND rd.flg_context = l_med_reconcile_context
                   AND rd.id_episode IS NULL --This only updates if the last reconciliation record is a partially reconciled
                   AND rd.dt_review = (SELECT MAX(rd2.dt_review)
                                         FROM review_detail rd2
                                        WHERE rd2.id_record_area = i_episode
                                          AND rd2.flg_context = l_med_reconcile_context);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => 'PK_PRESCRIPTION',
                                                     i_function => 'SET_RECONCILE_DETAIL',
                                                     o_error    => o_error);
            RETURN FALSE;
    END set_reconcile_detail;
    
    /********************************************************************************************
     * Check if this drug was already prescribed in this episode.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_emb                  Drug ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_flg_show               Indicate if there's a message to show to the user
     * @param o_msg                    Message
     * @param o_msg_title              Message title
     * @param o_button                 Buttons to show
     * @param o_error                  Error   
     *
     * @return                         Y - if i_group_id has "child" records; N - otherwise
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/09
    **********************************************************************************************/

    FUNCTION exist_ext_prescription
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_emb       IN table_varchar,
        i_prof      IN profissional,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_visit     episode.id_visit%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
    
        l_version VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_presc(l_pharm IN prescription_pharm.emb_id%TYPE) IS
            SELECT 'Y'
              FROM prescription p, prescription_pharm pp, me_med m
             WHERE p.id_episode = i_episode
               AND p.flg_status = g_flg_temp
               AND pp.id_prescription = p.id_prescription
               AND m.emb_id = pp.emb_id
               AND pp.emb_id = l_pharm
               AND l_version = m.vers;
    
        l_string_req VARCHAR2(2000);
        l_desc_exam  VARCHAR2(2000);
        l_first_req  BOOLEAN := TRUE;
        l_exist      VARCHAR2(1);
        g_error      VARCHAR2(2000);
    
    BEGIN
    
        g_error := 'pk_medication_core.get_visit_from_epis';
        IF NOT pk_medication_core.get_visit_from_epis(i_lang, i_prof, i_episode, l_id_visit, l_id_epis_type, o_error)
        
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        o_flg_show  := 'N';
        o_button    := 'NC';
        o_msg_title := pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M003');
    
        g_error := 'LOOP';
        FOR i IN 1 .. i_emb.count
        LOOP
            -- Loop sobre o array de IDs de fármacos  
        
            g_error := 'OPEN C_PRESC';
            OPEN c_presc(i_emb(i));
            FETCH c_presc
                INTO l_exist;
            g_found := c_presc%FOUND; --existe prescrição da embalagem
            CLOSE c_presc;
        
            g_error := 'EXIST PRESCRIPTION';
            IF g_found
            THEN
                o_flg_show := 'Y';
                o_msg      := pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M002');
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PRESCRIPTION',
                                                     'EXIST_EXT_PRESCRIPTION',
                                                     o_error);
    END;
    
    /********************************************************************************************
    * This function checks if a drug being prescribed is marked as chronic medication
    * and can issue a warning if parametrized
    *
    * @param i_lang         in Language ID
    * @param i_episode      IN episode.id_episode
    * @param i_patient      IN patient.id_patient
    * @param i_emb          IN table_varchar,
    * @param i_prof         IN profissional
    * @param o_flg_show     OUT VARCHAR2
    * @param o_msg          OUT VARCHAR2
    * @param o_msg_title    OUT VARCHAR2
    * @param o_button       OUT VARCHAR2      
    * @param o_chronic_med  OUT VARCHAR2
    * @param o_error        out t_error_out
    *
    * @return                Return Boolean - Success / Fail
    *
    * @raises
    *
    * @author                Nuno Antunes
    * @version               V.2.5.0.7.8
    * @since                 2010/05/31
    ********************************************************************************************/
    FUNCTION is_chronic_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_emb         IN table_varchar,
        i_prof        IN profissional,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_chronic_med OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_visit     episode.id_visit%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
    
        l_version VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_presc(l_pharm IN prescription_pharm.emb_id%TYPE) IS
            SELECT 'Y'
              FROM (SELECT pp.emb_id AS id_drug, MAX(pp.id_prescription_pharm) AS id_prescription_pharm
                      FROM prescription p, prescription_pharm pp, episode e, me_med me
                     WHERE e.id_visit < l_id_visit
                       AND e.id_patient = i_patient
                       AND p.id_episode = e.id_episode
                       AND pp.id_prescription = p.id_prescription
                       AND pp.flg_chronic_medication = g_yes
                       AND pp.flg_status = pk_medication_core.g_chron_med_active
                       AND p.flg_status = pk_medication_core.g_presc_ext_p
                       AND pp.emb_id = l_pharm
                       AND me.emb_id = pp.emb_id
                     GROUP BY pp.emb_id) t_temp
             WHERE NOT EXISTS (SELECT pp2.id_prescription_pharm
                      FROM prescription_pharm pp2, prescription p2
                     WHERE pp2.id_prescription_pharm > t_temp.id_prescription_pharm
                       AND pp2.emb_id = t_temp.id_drug
                       AND pp2.flg_status = pk_medication_core.g_chron_med_inactive
                       AND pp2.flg_chronic_medication = g_yes
                       AND p2.id_prescription = pp2.id_prescription
                       AND p2.id_patient = i_patient
                       AND p2.flg_status = pk_medication_core.g_presc_ext_p);
    
        l_string_req VARCHAR2(2000);
        l_desc_exam  VARCHAR2(2000);
        l_first_req  BOOLEAN := TRUE;
        l_exist      VARCHAR2(1);
        g_error      VARCHAR2(2000);
        l_med_descr  VARCHAR2(2000);
    
        g_prescription_version         VARCHAR2(100) := pk_sysconfig.get_config(g_presc_type, i_prof);
        chronic_med_presc_show_warning VARCHAR2(1 CHAR) := pk_sysconfig.get_config('CHRONIC_MED_PRESC_SHOW_WARNING',
                                                                                   i_prof);
    
    BEGIN
    
        g_error := 'pk_medication_core.get_visit_from_epis';
        IF NOT pk_medication_core.get_visit_from_epis(i_lang, i_prof, i_episode, l_id_visit, l_id_epis_type, o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        o_flg_show    := 'N';
        o_button      := 'CHRONIC_MED';
        o_msg_title   := pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M035');
        o_chronic_med := 'N';
    
        g_error := 'LOOP';
        FOR i IN 1 .. i_emb.count
        LOOP
            -- Loop sobre o array de IDs de fármacos  
        
            g_error := 'OPEN C_PRESC';
            OPEN c_presc(i_emb(i));
            FETCH c_presc
                INTO l_exist;
            g_found := c_presc%FOUND; --existe prescrição da embalagem
            CLOSE c_presc;
        
            g_error := 'IS CHRONIC MEDICATION';
            IF g_found
            THEN
                o_chronic_med := 'Y';
            
                IF chronic_med_presc_show_warning = 'Y'
                THEN
                    SELECT me.med_descr_formated
                      INTO l_med_descr
                      FROM me_med me
                     WHERE me.emb_id = i_emb(i)
                       AND me.vers = g_prescription_version;
                
                    o_flg_show := 'Y';
                    /*o_msg      := '<b>' || l_med_descr || '</b><br><br>' ||
                    pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M050');*/
                    o_msg := '<b>' || l_med_descr || '</b><br>';
                END IF;
            END IF;
        
        END LOOP;
    
        IF g_found
        THEN
            o_msg := o_msg || '<br>' || pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M050');
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PRESCRIPTION',
                                                     'IS_CHRONIC_MEDICATION',
                                                     o_error);
    END;
    
    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        i_commit              IN VARCHAR2 DEFAULT NULL,
        --
        i_id_other_prod_list    IN table_number,
        i_other_prod_name_list  IN table_varchar,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_number_null  table_number := table_number();
        l_varchar_null table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_emb.count
        LOOP
        
            l_number_null.extend;
            l_varchar_null.extend;
        
        END LOOP;
    
        g_error := 'CALL_CREATE_EXT_PRESC';
        IF NOT create_ext_presc(i_lang                  => i_lang,
                                i_episode               => i_episode,
                                i_patient               => i_patient,
                                i_prof                  => i_prof,
                                i_emb                   => i_emb,
                                i_qty                   => i_qty,
                                i_generico              => i_generico,
                                i_dosage                => i_dosage,
                                i_prof_cat_type         => i_prof_cat_type,
                                i_test                  => i_test,
                                i_pat_medication_list   => i_pat_medication_list,
                                i_id_other_prod_list    => i_id_other_prod_list,
                                i_other_prod_name_list  => i_other_prod_name_list,
                                i_qty_inst              => l_number_null,
                                i_unit_qty_inst         => l_number_null,
                                i_freq                  => l_number_null,
                                i_unit_freq             => l_number_null,
                                i_duration              => l_number_null,
                                i_unit_duration         => l_number_null,
                                i_commit                => i_commit,
                                o_flg_show              => o_flg_show,
                                o_msg                   => o_msg,
                                o_msg_title             => o_msg_title,
                                o_button                => o_button,
                                o_id_prescription_pharm => o_id_prescription_pharm,
                                o_error                 => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CREATE_EXT_PRESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_ext_presc;

    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        --
        i_qty_inst      IN table_number,
        i_unit_qty_inst IN table_number,
        i_freq          IN table_number,
        i_unit_freq     IN table_number,
        i_duration      IN table_number,
        i_unit_duration IN table_number,
        --
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_number_null  table_number := table_number();
        l_varchar_null table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_emb.count
        LOOP
        
            l_number_null.extend;
            l_varchar_null.extend;
        
        END LOOP;
    
        g_error := 'CALL_CREATE_EXT_PRESC';
        IF NOT create_ext_presc(i_lang                  => i_lang,
                                i_episode               => i_episode,
                                i_patient               => i_patient,
                                i_prof                  => i_prof,
                                i_emb                   => i_emb,
                                i_qty                   => i_qty,
                                i_generico              => i_generico,
                                i_dosage                => i_dosage,
                                i_prof_cat_type         => i_prof_cat_type,
                                i_test                  => i_test,
                                i_pat_medication_list   => i_pat_medication_list,
                                i_id_other_prod_list    => l_number_null,
                                i_other_prod_name_list  => l_varchar_null,
                                i_qty_inst              => i_qty_inst,
                                i_unit_qty_inst         => i_unit_qty_inst,
                                i_freq                  => i_freq,
                                i_unit_freq             => i_unit_freq,
                                i_duration              => i_duration,
                                i_unit_duration         => i_unit_duration,
                                o_flg_show              => o_flg_show,
                                o_msg                   => o_msg,
                                o_msg_title             => o_msg_title,
                                o_button                => o_button,
                                o_id_prescription_pharm => o_id_prescription_pharm,
                                o_error                 => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CREATE_EXT_PRESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_ext_presc;

    /********************************************************************************************
     * Create a prescription.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_patient                Patient ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_emb                    Array: Drug ID
     * @param i_qty                    Array: number of prescribed packages
     * @param i_generico               Array: indicates if the physician allows a generic substitute
     * @param i_dosage                 Array: dosage (PT: posologia)
     * @param i_prof_cat_type          Professional's category type
     * @param i_test                   indicates if is necessary to test if this drug was already prescribed in this episode    
     * @param o_flg_show               Indicate if there's a message to show to the user
     * @param o_msg                    Message
     * @param o_msg_title              Message title
     * @param o_button                 Buttons to show
     * @param o_id_prescription_pharm  PRESCRIPTION_PHARM_ID created   
     * @param o_error                  Error   
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/09
    **********************************************************************************************/

    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        --
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_number_null  table_number := table_number();
        l_varchar_null table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_emb.count
        LOOP
        
            l_number_null.extend;
            l_varchar_null.extend;
        
        END LOOP;
    
        g_error := 'CALL_CREATE_EXT_PRESC';
        IF NOT create_ext_presc(i_lang                  => i_lang,
                                i_episode               => i_episode,
                                i_patient               => i_patient,
                                i_prof                  => i_prof,
                                i_emb                   => i_emb,
                                i_qty                   => i_qty,
                                i_generico              => i_generico,
                                i_dosage                => i_dosage,
                                i_prof_cat_type         => i_prof_cat_type,
                                i_test                  => i_test,
                                i_pat_medication_list   => i_pat_medication_list,
                                i_id_other_prod_list    => l_number_null,
                                i_other_prod_name_list  => l_varchar_null,
                                i_qty_inst              => l_number_null,
                                i_unit_qty_inst         => l_number_null,
                                i_freq                  => l_number_null,
                                i_unit_freq             => l_number_null,
                                i_duration              => l_number_null,
                                i_unit_duration         => l_number_null,
                                o_flg_show              => o_flg_show,
                                o_msg                   => o_msg,
                                o_msg_title             => o_msg_title,
                                o_button                => o_button,
                                o_id_prescription_pharm => o_id_prescription_pharm,
                                o_error                 => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CREATE_EXT_PRESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_ext_presc;
    --

    /********************************************************************************************
     * Create a prescription.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_patient                Patient ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_emb                    Array: Drug ID
     * @param i_qty                    Array: number of prescribed packages
     * @param i_generico               Array: indicates if the physician allows a generic substitute
     * @param i_dosage                 Array: dosage (PT: posologia)
     * @param i_prof_cat_type          Professional's category type
     * @param i_test                   indicates if is necessary to test if this drug was already prescribed in this episode    
     * @ param i_pat_medication_list   
     * @ param i_id_other_prod_list    other product/drug ID's array
     * @ param i_other_prod_name_list  other product/drug name's array
     * @param o_flg_show               Indicate if there's a message to show to the user
     * @param o_msg                    Message
     * @param o_msg_title              Message title
     * @param o_button                 Buttons to show
     * @param o_id_prescription_pharm  PRESCRIPTION_PHARM_ID created   
     * @param o_error                  Error   
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/09
     *
     * @author                         Orlando Antunes
     * @version                        0.2
     * @since                          2008/05/29
    **********************************************************************************************/
    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        --
        i_id_other_prod_list   IN table_number,
        i_other_prod_name_list IN table_varchar,
        -- Para as instruções parametrizadas por defeito
        i_qty_inst      IN table_number,
        i_unit_qty_inst IN table_number,
        i_freq          IN table_number,
        i_unit_freq     IN table_number,
        i_duration      IN table_number,
        i_unit_duration IN table_number,
        --
        i_commit IN VARCHAR2 DEFAULT NULL,
        --
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next       prescription.id_prescription%TYPE;
        l_next_pharm prescription_pharm.id_prescription_pharm%TYPE;
        l_presc      prescription.id_prescription%TYPE;
        l_dci        VARCHAR2(255);
        l_form_farm  VARCHAR2(255);
        l_vias       VARCHAR2(255) := NULL;
        l_count      NUMBER;
        l_diploma    VARCHAR2(255) := NULL;
        l_continue   BOOLEAN := TRUE;
        l_error      VARCHAR2(4000);
        l_type       VARCHAR2(1) := NULL;
    
        l_attention       VARCHAR2(2) := NULL;
        l_cheaper         VARCHAR2(1);
        l_ci              VARCHAR2(1);
        l_justif          VARCHAR2(1);
        l_interac_med     VARCHAR2(1);
        l_interac_allergy VARCHAR2(1);
        l_commit          VARCHAR2(1);
        l_flg_status_aux  prescription.flg_status%TYPE;
    
        l_pvp NUMBER;
        l_pr  NUMBER;
        l_prp NUMBER;
        --i_pat_medication_list
        l_pat_medication_list NUMBER;
    
        l_version VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_qty_dispense NUMBER := pk_sysconfig.get_config('PRESCRIPTION_DISPENSE_QTY_DEFAULT_VALUE', i_prof);
    
        CURSOR c_presc IS
            SELECT p.id_prescription
              FROM prescription p
             WHERE p.id_episode = i_episode
               AND p.flg_status = g_flg_temp
               AND p.flg_type = g_flg_ext;
    
        CURSOR c_dci(l_emb IN VARCHAR2) IS
            SELECT m.dci_id, m.form_farm_id, m.price_pvp, m.price_ref, m.price_pens
              FROM me_med m
             WHERE m.emb_id = l_emb
               AND l_version = m.vers;
    
        CURSOR c_vias(l_emb IN VARCHAR2) IS
            SELECT route_id
              FROM me_med_route mr
             WHERE mr.emb_id = l_emb
               AND l_version = mr.vers;
    
        CURSOR c_diploma(l_emb IN VARCHAR2) IS
            SELECT pp.regulation_id
              FROM prescription_pharm pp, me_med_regulation mr
             WHERE pp.id_prescription = l_presc
               AND mr.regulation_id = pp.regulation_id
               AND mr.emb_id = l_emb
               AND l_version = mr.vers
               AND mr.vers = pp.vers
               AND rownum <= 1
             ORDER BY mr.compart DESC;
    
        CURSOR c_price(l_emb IN VARCHAR2) IS
            SELECT 'Y'
              FROM me_med m
             WHERE 'Y' =
                   decode(m.tipo_prod_id,
                          g_prod_diabetes,
                          (SELECT 'Y'
                             FROM me_med m2, emb_dep_clin_serv edcs2
                            WHERE m2.form_farm_id = m.form_farm_id
                              AND m2.tipo_prod_id = g_prod_diabetes
                              AND m2.dci_id = m.dci_id
                              AND m2.n_units = m.n_units
                              AND (m2.qt_dos_comp = m.qt_dos_comp OR m.qt_dos_comp IS NULL)
                              AND m2.price_pvp < m.price_pvp
                              AND l_version = m2.vers
                              AND m2.flg_comerc = g_yes
                              AND m2.flg_available = g_yes
                              AND nvl(m2.disp_id, 0) NOT IN
                                  (g_msrm_e, g_msrm_ra, g_msrm_r_ea, g_msrm_r_ec, g_emb_hosp, g_disp_in_v)
                              AND edcs2.emb_id = m2.emb_id
                              AND edcs2.vers = m2.vers
                              AND edcs2.id_institution = i_prof.institution
                              AND edcs2.id_software = i_prof.software
                              AND edcs2.flg_type = g_flg_pesq
                              AND rownum <= 1),
                          (SELECT 'Y'
                             FROM me_med m2, emb_dep_clin_serv edcs2
                            WHERE m2.tipo_prod_id != g_prod_diabetes
                              AND ((m.grupo_hom_id != g_grupo_0 AND m2.grupo_hom_id = m.grupo_hom_id) OR
                                  (m.grupo_hom_id = g_grupo_0 AND m2.dci_id = m.dci_id AND
                                  m2.form_farm_id = m.form_farm_id AND m2.n_units = m.n_units AND
                                  m2.dosagem = m.dosagem AND (m2.qt_dos_comp = m.qt_dos_comp OR m.qt_dos_comp IS NULL) AND
                                  (m2.qt_per_unit = m.qt_per_unit OR m.qt_per_unit IS NULL)))
                              AND m2.price_pvp < m.price_pvp
                              AND l_version = m2.vers
                              AND m2.flg_comerc = g_yes
                              AND m2.flg_available = g_yes
                              AND nvl(m2.disp_id, 0) NOT IN
                                  (g_msrm_e, g_msrm_ra, g_msrm_r_ea, g_msrm_r_ec, g_emb_hosp, g_disp_in_v)
                              AND edcs2.emb_id = m2.emb_id
                              AND edcs2.vers = m2.vers
                              AND edcs2.id_institution = i_prof.institution
                              AND edcs2.id_software = i_prof.software
                              AND edcs2.flg_type = g_flg_pesq
                              AND rownum <= 1))
               AND m.emb_id = l_emb
               AND l_version = m.vers;
    
        -- Cursor que devolve se o id do relato que estamos a tentar administrar 
        -- pertence ou não ao universo da instituição
        CURSOR c_exist_drug
        (
            l_emb           IN VARCHAR2,
            l_id_other_prod IN NUMBER
        ) IS
            SELECT me.emb_id
              FROM me_med me, emb_dep_clin_serv edcs
             WHERE me.emb_id = l_emb
               AND me.vers = l_version
               AND me.flg_comerc = g_yes
               AND edcs.emb_id = me.emb_id
               AND edcs.vers = me.vers
               AND decode(edcs.id_software, 0, i_prof.software, edcs.id_software) = i_prof.software
               AND (decode(edcs.id_institution, 0, i_prof.institution, edcs.id_institution) = i_prof.institution OR
                   ((edcs.id_dep_clin_serv IN
                   (SELECT pdcs.id_dep_clin_serv
                         FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department dep
                        WHERE pdcs.id_professional = i_prof.id
                          AND pdcs.flg_status = g_selected
                          AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                          AND dep.id_department = dcs.id_department
                          AND dep.id_institution = i_prof.institution) OR edcs.id_professional = i_prof.id)))
            UNION ALL
            --Prescrição de outros produtos 
            SELECT to_char(op.id_other_product) emb_id
              FROM other_product op, other_product_soft_inst opsi
             WHERE op.id_other_product = l_id_other_prod
               AND op.flg_available = g_yes
               AND op.vers = opsi.vers
               AND op.vers = l_version
               AND (op.flg_type = 'E' OR op.flg_type IS NULL)
               AND opsi.id_other_product = op.id_other_product
               AND decode(opsi.id_software, 0, i_prof.software, opsi.id_software) = i_prof.software
               AND decode(opsi.id_institution, 0, i_prof.institution, opsi.id_institution) = i_prof.institution;
    
        r_exist_drug c_exist_drug%ROWTYPE;
    
        l_id_other_prod_list   prescription_pharm.id_other_product%TYPE;
        l_other_prod_name_list prescription_pharm.desc_other_product%TYPE;
    
        l_rowids_1 table_varchar;
        e_process_event EXCEPTION;
    
        l_rowids table_varchar;
    
        -- chronic medication
    
        chronic_medication_active VARCHAR2(1 CHAR) := pk_sysconfig.get_config('SHOW_PRESCRIPTION_CHRONIC', i_prof);
    
        o_chronic_med VARCHAR2(1);
    
        -- chronic medication   
    
    BEGIN
    
        g_sysdate_tstz := get_current_timestamp(i_lang, i_prof, o_error);
    
        IF i_test = 'Y'
        THEN
            -- Verificar se o fármaco já tinha sido prescrito neste episódio 
            g_error := 'CALL TO EXIST_EXT_PRESCRIPTION';
            pk_alertlog.log_debug(g_error);
            IF NOT exist_ext_prescription(i_lang      => i_lang,
                                          i_episode   => i_episode,
                                          i_emb       => i_emb,
                                          i_prof      => i_prof,
                                          o_flg_show  => o_flg_show,
                                          o_msg       => o_msg,
                                          o_msg_title => o_msg_title,
                                          o_button    => o_button,
                                          o_error     => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
            IF o_flg_show = 'Y'
            THEN
                l_continue := FALSE;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_emb.count
        LOOP
            g_error := 'open c_exist_drug';
            pk_alertlog.log_debug(g_error);
            OPEN c_exist_drug(i_emb(i), i_id_other_prod_list(i));
            FETCH c_exist_drug
                INTO r_exist_drug;
            g_found := c_exist_drug%FOUND;
            CLOSE c_exist_drug;
        
            IF g_found
            THEN
                o_flg_show := g_no;
            ELSE
                g_error     := 'DOES NOT EXIST MEDICATION';
                o_flg_show  := g_yes;
                o_msg       := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M045');
                o_msg_title := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M015');
                o_button    := 'C829664Lido';
                l_continue  := FALSE;
            END IF;
            EXIT WHEN l_continue = FALSE;
        END LOOP;
    
        IF l_continue
        THEN
            g_error := 'OPEN C_PRESC';
            OPEN c_presc;
            FETCH c_presc
                INTO l_presc;
            g_found := c_presc%FOUND;
            CLOSE c_presc;
        
            IF NOT g_found
            THEN
                -- se ainda não foi feita nenhuma prescrição neste episódio que não esteja impressa
            
                -- *********************************
                -- PT 29/09/2008 2.4.3.d
                g_error := 'GET NEXT PRESCRIPTION ID';
                pk_alertlog.log_debug(g_error);
                l_next := ts_prescription.next_key('SEQ_PRESCRIPTION');
            
                g_error := 'INSERT INTO PRESCRIPTION';
                pk_alertlog.log_debug(g_error);
                ts_prescription.ins(id_prescription_in      => l_next,
                                    dt_prescription_tstz_in => g_sysdate_tstz,
                                    id_episode_in           => i_episode,
                                    id_patient_in           => i_patient,
                                    id_professional_in      => i_prof.id,
                                    id_institution_in       => i_prof.institution,
                                    id_software_in          => i_prof.software,
                                    flg_status_in           => g_flg_temp,
                                    flg_type_in             => g_flg_ext,
                                    rows_out                => l_rowids_1);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PRESCRIPTION',
                                              i_rowids     => l_rowids_1,
                                              o_error      => o_error);
                -- *********************************
            
                l_presc := l_next;
            END IF; --G_FOUND
        
            pk_alertlog.log_debug('L_CHEAPER: ' || l_cheaper);
        
            FOR i IN 1 .. i_emb.count
            LOOP
                --prescrição de outros medicamentos
                IF i_emb(i) = '-2'
                THEN
                
                    IF i_other_prod_name_list IS NULL
                    THEN
                        --Temporário
                        l_id_other_prod_list   := 1;
                        l_other_prod_name_list := 'Fraldas';
                    ELSE
                        l_id_other_prod_list   := i_id_other_prod_list(i);
                        l_other_prod_name_list := i_other_prod_name_list(i);
                    END IF;
                
                    g_error := 'ts_prescription_pharm.next_key';
                    SELECT ts_prescription_pharm.next_key
                      INTO l_next_pharm
                      FROM dual;
                
                    g_error := 'INSERT INTO PRESCRIPTION_PHARM: I=' || i || '; I_EMB=' || i_emb(i) || 'I_QTY=' ||
                               nvl(i_qty(i), l_qty_dispense);
                    pk_alertlog.log_debug(g_error);
                    ts_prescription_pharm.ins(id_prescription_pharm_in      => l_next_pharm,
                                              dt_prescription_pharm_tstz_in => g_sysdate_tstz,
                                              id_prescription_in            => l_presc,
                                              emb_id_in                     => NULL,
                                              qty_in                        => nvl(i_qty(i), l_qty_dispense),
                                              id_unit_measure_in            => 76119, --76119
                                              generico_in                   => i_generico(i),
                                              dosage_in                     => i_dosage(i),
                                              route_id_in                   => l_vias,
                                              regulation_id_in              => l_diploma,
                                              flg_ci_in                     => g_no,
                                              flg_cheaper_in                => g_no,
                                              flg_justif_in                 => g_no,
                                              flg_interac_med_in            => g_no,
                                              flg_interac_allergy_in        => g_no,
                                              pvp_in                        => l_pvp,
                                              p_ref_in                      => l_pr,
                                              p_ref_pen_in                  => l_prp,
                                              vers_in                       => l_version,
                                              id_pat_medication_list_in     => NULL,
                                              id_other_product_in           => l_id_other_prod_list,
                                              desc_other_product_in         => l_other_prod_name_list,
                                              qty_inst_in                   => i_qty_inst(i),
                                              unit_measure_inst_in          => i_unit_qty_inst(i),
                                              frequency_in                  => i_freq(i),
                                              id_unit_measure_freq_in       => i_unit_freq(i),
                                              duration_in                   => i_duration(i),
                                              id_unit_measure_dur_in        => i_unit_duration(i),
                                              rows_out                      => l_rowids);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PRESCRIPTION_PHARM',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                ELSE
                
                    g_error := 'OPEN C_DCI; EMB_ID:' || i_emb(i);
                    OPEN c_dci(i_emb(i));
                    FETCH c_dci
                        INTO l_dci, l_form_farm, l_pvp, l_pr, l_prp;
                    CLOSE c_dci;
                
                    g_error := 'OPEN C_VIAS; EMB_ID:' || i_emb(i);
                    OPEN c_vias(i_emb(i));
                    FETCH c_vias
                        INTO l_vias;
                    CLOSE c_vias;
                
                    g_error := 'OPEN c_price; i_emb = ' || i_emb(i);
                    OPEN c_price(i_emb(i));
                    FETCH c_price
                        INTO l_cheaper;
                    g_found := c_price%FOUND;
                    CLOSE c_price;
                
                    IF NOT g_found
                    THEN
                        l_cheaper := g_no;
                    END IF;
                
                    pk_alertlog.log_debug('L_CHEAPER: ' || l_cheaper);
                
                    g_error := 'GET DIPLOMA';
                    OPEN c_diploma(i_emb(i));
                    FETCH c_diploma
                        INTO l_diploma;
                    CLOSE c_diploma;
                
                    g_error := 'ts_prescription_pharm.next_key';
                    SELECT ts_prescription_pharm.next_key
                      INTO l_next_pharm
                      FROM dual;
                
                    --validação i_pat_medication_list
                    IF i_pat_medication_list IS NULL
                    THEN
                        l_pat_medication_list := NULL;
                    ELSE
                        l_pat_medication_list := i_pat_medication_list(i);
                    END IF;
                
                    g_error := 'INSERT INTO PRESCRIPTION_PHARM: I=' || i || '; I_EMB=' || i_emb(i) || 'I_QTY=' ||
                               nvl(i_qty(i), l_qty_dispense);
                    pk_alertlog.log_debug(g_error);
                    ts_prescription_pharm.ins(id_prescription_pharm_in      => l_next_pharm,
                                              dt_prescription_pharm_tstz_in => g_sysdate_tstz,
                                              id_prescription_in            => l_presc,
                                              emb_id_in                     => i_emb(i), --NULL
                                              qty_in                        => nvl(i_qty(i), l_qty_dispense),
                                              id_unit_measure_in            => 76119, --76119
                                              generico_in                   => i_generico(i),
                                              dosage_in                     => i_dosage(i),
                                              route_id_in                   => l_vias,
                                              regulation_id_in              => l_diploma,
                                              flg_ci_in                     => g_no,
                                              flg_cheaper_in                => l_cheaper,
                                              flg_justif_in                 => g_no,
                                              flg_interac_med_in            => g_no,
                                              flg_interac_allergy_in        => g_no,
                                              pvp_in                        => l_pvp,
                                              p_ref_in                      => l_pr,
                                              p_ref_pen_in                  => l_prp,
                                              vers_in                       => l_version,
                                              id_pat_medication_list_in     => l_pat_medication_list,
                                              qty_inst_in                   => i_qty_inst(i),
                                              unit_measure_inst_in          => i_unit_qty_inst(i),
                                              frequency_in                  => i_freq(i),
                                              id_unit_measure_freq_in       => i_unit_freq(i),
                                              duration_in                   => i_duration(i),
                                              id_unit_measure_dur_in        => i_unit_duration(i),
                                              id_other_product_in           => i_id_other_prod_list(i),
                                              desc_other_product_in         => i_other_prod_name_list(i),
                                              flg_attention_in              => l_attention,
                                              rows_out                      => l_rowids);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PRESCRIPTION_PHARM',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    g_error                 := 'CO_SIGN DEFINE VALUES';
                    l_co_sign.flg_co_sign   := g_flg_co_sign;
                    l_co_sign.dt_order      := SYSDATE;
                    l_co_sign.id_prof_order := i_prof.id;
                
                    g_error := 'CO_SIGN CALL TO pk_prescription_int.update_co_sign';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_prescription_int.update_co_sign(i_lang,
                                                              i_prof,
                                                              i_prof_cat_type,
                                                              'PRESCRIPTION_PHARM',
                                                              l_next_pharm,
                                                              l_co_sign,
                                                              o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'get l_flg_status_aux for information transfer';
                    pk_alertlog.log_debug(g_error);
                
                    --Transferência de informação entre episódios da mesma visita
                    g_error := 'insert into t_ti_log';
                    pk_alertlog.log_debug(g_error);
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_episode,
                                            'TX',
                                            l_next_pharm,
                                            pk_medication_core.g_ti_log_me,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF;
                o_id_prescription_pharm := l_next_pharm;
            
            END LOOP; -- I_EMB
        
            g_error := 'CALL TO PK_VISIT.UPD_EPIS_INFO_DRUG';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.upd_epis_info_drug(i_lang               => i_lang,
                                               i_id_episode         => i_episode,
                                               i_id_prof            => i_prof,
                                               i_dt_first_drug_prsc => pk_date_utils.date_send_tsz(i_lang,
                                                                                                   g_sysdate_tstz,
                                                                                                   i_prof),
                                               i_dt_first_drug_take => NULL,
                                               i_prof_cat_type      => i_prof_cat_type,
                                               o_error              => o_error)
            THEN
                o_error := o_error;
                IF i_commit IS NULL
                   OR i_commit = g_yes
                THEN
                    pk_utils.undo_changes;
                END IF;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                IF i_commit IS NULL
                   OR i_commit = g_yes
                THEN
                    pk_utils.undo_changes;
                END IF;
                RETURN FALSE;
            END IF;
        
            -- chronic medication
        
            IF (chronic_medication_active = 'Y')
            THEN
                -- Verificar se o fármaco já tinha sido prescrito neste episódio 
                g_error := 'CALL TO IS_CHRONIC_MEDICATION';
                pk_alertlog.log_debug(g_error);
                IF NOT is_chronic_medication(i_lang        => i_lang,
                                             i_episode     => i_episode,
                                             i_patient     => i_patient,
                                             i_emb         => i_emb,
                                             i_prof        => i_prof,
                                             o_flg_show    => o_flg_show,
                                             o_msg         => o_msg,
                                             o_msg_title   => o_msg_title,
                                             o_button      => o_button,
                                             o_chronic_med => o_chronic_med,
                                             o_error       => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
                IF o_chronic_med = 'Y'
                THEN
                    UPDATE prescription_pharm pp
                       SET pp.flg_chronic_medication = g_yes
                     WHERE pp.id_prescription_pharm = o_id_prescription_pharm;
                END IF;
            END IF;
        
            -- chronic medication   
        
            IF i_commit IS NULL
               OR i_commit = g_yes
            THEN
                COMMIT;
            END IF;
        
        END IF; --L_CONTINUE
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CREATE_EXT_PRESC',
                                              o_error);
            IF i_commit IS NULL
               OR i_commit = g_yes
            THEN
                pk_utils.undo_changes;
            END IF;
            RETURN FALSE;
    END;
    

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    -- Log startup
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_presc_type_int := 'I';

    g_presc_fin := 'F';

    g_presc_req  := 'R';
    g_presc_pend := 'D';
    g_presc_fin  := 'F';
    g_presc_can  := 'C';
    g_presc_par  := 'P';
    g_presc_intr := 'P';
    g_presc_exe  := 'E';

    g_presc_det_req  := 'R';
    g_presc_det_pend := 'D';
    g_presc_det_exe  := 'E';
    g_presc_det_fin  := 'F';
    g_presc_det_can  := 'C';
    g_presc_det_intr := 'I';

    g_flg_time_epis := 'E';
    g_flg_time_next := 'N';
    g_flg_time_betw := 'B';

    g_presc_take_sos  := 'S';
    g_presc_take_nor  := 'N';
    g_presc_take_uni  := 'U';
    g_presc_take_cont := 'C';
    g_presc_take_eter := 'A';

    g_presc_plan_stat_adm  := 'A';
    g_presc_plan_stat_nadm := 'N';
    g_presc_plan_stat_pend := 'D';
    g_presc_plan_stat_req  := 'R';
    g_presc_plan_stat_can  := 'C';

    g_domain_take := 'DRUG_PRESC_DET.FLG_TAKE_TYPE';
    g_domain_time := 'DRUG_PRESCRIPTION.FLG_TIME';

    g_drug_justif := 'Y';
    g_drug_interv := 'M';

    g_flg_doctor := 'D';
    g_flg_phys   := 'F';
    g_flg_tec    := 'T';

    g_drug_det_status := 'DRUG_PRESC_DET.FLG_STATUS';

    -- NOVAS VARIÁVEIS GLOBAIS PARA A FERRAMENTA DE PRESCRIÇÃO

    g_flg_freq := 'M';
    g_flg_pesq := 'P';
    g_no       := 'N';
    g_yes      := 'Y';

    g_flg_ext      := 'E';
    g_descr_ext    := 'OFICINA';
    g_flg_int      := 'I';
    g_descr_int    := 'HOSPITAL';
    g_flg_other    := 'P';
    g_flg_reported := 'R';
    g_flg_adm      := 'A';

    g_flg_manip_ext   := 'ME';
    g_flg_manip_int   := 'MI';
    g_flg_dietary_ext := 'DE';
    g_flg_dietary_int := 'DI';

    g_pharma_class_avail := 'Y';
    g_drug_available     := 'Y';

    g_descr_otc := 'OTC';

    g_flg_temp  := 'T';
    g_flg_print := 'P';

    g_flg_first  := 'P';
    g_flg_second := 'S';

    g_domain_print_type   := 'PRESC_PRINT.FLG_TYPE';
    g_domain_reprint_type := 'PRESC_REPRINT.FLG_TYPE';
    /*  G_PRINT_N := 'N';--receita não renovável
      G_PRINT_R := 'R';--receita renovável
      G_PRINT_E := 'E';--prescrição electrónica
    */
    g_inst_type_cs := 'C';
    g_inst_type_hs := 'H';
    g_inst_type_cp := 'P';

    g_pharma_avail := 'Y';

    g_flg_req     := 'R';
    g_flg_pend    := 'D';
    g_flg_rejeita := 'J';

    g_att_yes  := 'Y';
    g_att_no   := 'N';
    g_att_read := 'R';

    g_price_pvp := 0;
    g_price_pr  := 1;
    g_price_prp := 2;

    
    g_flg_active   := 'A';
    g_flg_inactive := 'I';

    g_flg_ci              := 'CI';
    g_flg_cheaper         := 'B';
    g_flg_justif          := 'J';
    g_flg_interac_med     := 'IM';
    g_flg_interac_allergy := 'IA';

    g_flg_generico := 'G';

    g_problem_ci    := 'C';
    g_problem_assoc := 'A';
    g_drug_req      := 'R';

    --VALORES DA BD INFARMED
    g_mnsrm     := 1;
    g_msrm_e    := 4;
    g_msrm_ra   := 10;
    g_msrm_rb   := 11; --já não é utilizado
    g_msrm_rc   := -1; --12 já não é utilizado
    g_msrm_r_ea := 13;
    g_msrm_r_ec := 15;
    g_emb_hosp  := 20;
    g_disp_in_v := 100;

    g_prod_diabetes := 13;
    g_grupo_0       := 'GH0000';

    g_drug := 'M';

    g_selected := 'S';

    --Fluids
    g_stat_pend         := 'D';
    g_stat_req          := 'R';
    g_stat_intr         := 'I';
    g_stat_canc         := 'C';
    g_presc_det_bolus   := 'B';
    g_stat_fin          := 'F';
    g_flg_new_fluid     := 'N';
    g_stat_exec         := 'E';
    g_flg_take_type_sos := 'S';
    g_flg_co_sign       := 'N';
    g_stat_adm          := 'A';

    -- drug_req
    g_drug_req_req     := 'R';
    g_drug_req_pend    := 'D';
    g_drug_req_exe     := 'E';
    g_drug_req_rejeita := 'J';
    g_drug_req_parc    := 'P';

    g_chronic_cancel_rea_area := 'CHRONIC THERAPY';

END;
/
