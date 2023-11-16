/*-- Last Change Revision: $Rev: 2027361 $*/
/*-- Last Change by:  $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_medication_previous IS

    -- ***************************************************************************************
    -- PRIVATE PACKAGE VARIABLES
    -- ***************************************************************************************
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    /********************************************************************************************
    * Create dosage string.
    *
    * @param i_lang              language
    * @param i_qty               prescribed quantity
    * @param i_unit_qty          quantity unit measure id
    * @param i_freq              prescribed frequency
    * @param i_unit_freq         frequency unit measure id
    * @param i_duration          prescribed duration
    * @param i_unit_dur          duration unit_measure id
    * @param i_dt_begin          prescription data begin
    * @param i_dt_end            prescription data end
    * @param i_prof              professional array 
    *
    * @return                Return VARCHAR2  
    *
    * @author                Patrícia Neto
    * @version               0.1
    * @since                 2007/12/08
    ********************************************************************************************/
    FUNCTION get_dosage_format
    (
        i_lang      IN language.id_language%TYPE,
        i_qty       IN NUMBER,
        i_unit_qty  IN NUMBER,
        i_freq      IN NUMBER,
        i_unit_freq IN NUMBER,
        i_duration  IN NUMBER,
        i_unit_dur  IN NUMBER,
        i_dt_begin  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof      IN profissional
    ) RETURN VARCHAR2 IS
        o_dosage VARCHAR2(4000);
    
        l_dosage VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'o_dosage';
    
        SELECT decode(i_qty,
                      NULL,
                      NULL,
                      i_qty || ' ' || pk_translation.get_translation(i_lang, g_code_unit_measure || i_unit_qty)) ||
               decode(i_qty,
                      NULL,
                      decode(i_freq,
                             NULL,
                             NULL,
                             i_freq || ' ' || pk_translation.get_translation(i_lang, g_code_unit_measure || i_unit_freq)),
                      decode(i_freq,
                             NULL,
                             NULL,
                             ' / ' || i_freq || '/' || i_freq || ' ' ||
                             pk_translation.get_translation(i_lang, g_code_unit_measure || i_unit_freq))) ||
               decode(i_qty || i_freq,
                      NULL,
                      decode(i_duration,
                             NULL,
                             NULL,
                             i_duration || ' ' ||
                             pk_translation.get_translation(i_lang, g_code_unit_measure || i_unit_dur)),
                      decode(i_duration,
                             NULL,
                             NULL,
                             ' / ' || i_duration || ' ' ||
                             pk_translation.get_translation(i_lang, g_code_unit_measure || i_unit_dur))) ||
               decode(i_qty || i_freq || i_duration,
                      NULL,
                      decode(i_dt_begin,
                             NULL,
                             NULL,
                             pk_translation.get_translation(i_lang, g_trans_advanc_in_013) || ': ' ||
                             pk_date_utils.date_hour_chr_extend_tsz(i_lang, i_dt_begin, i_prof)),
                      decode(i_dt_begin,
                             NULL,
                             NULL,
                             '; ' || pk_translation.get_translation(i_lang, g_trans_advanc_in_013) || ': ' ||
                             pk_date_utils.date_hour_chr_extend_tsz(i_lang, i_dt_begin, i_prof))) ||
               decode(i_qty || i_freq || i_duration || i_dt_begin,
                      NULL,
                      decode(i_dt_end,
                             NULL,
                             NULL,
                             pk_message.get_message(i_lang, g_presc_rec_t009) || ': ' ||
                             pk_date_utils.date_hour_chr_extend_tsz(i_lang, i_dt_end, i_prof)),
                      decode(i_dt_end,
                             NULL,
                             NULL,
                             '; ' || pk_message.get_message(i_lang, g_presc_rec_t009) || ': ' ||
                             pk_date_utils.date_hour_chr_extend_tsz(i_lang, i_dt_end, i_prof)))
          INTO o_dosage
          FROM dual;
    
        RETURN o_dosage;
    
    END;

    /********************************************************************************************
    * Create/modify reported medication
    *
    * @param    I_LANG                     language
    * @param    I_EPISODE                  episode id
    * @param    I_PATIENT                  patient id
    * @param    I_PROF                     professional array
    * @param    I_PRESC_PHARM              prescription id (id_prescription_pharm)
    * @param    I_ID_PAT_MEDIC             reported medication id (id_pat_medication_list)
    * @param    I_EMB                      package id
    * @param    I_MED                      medication id
    * @param    I_PROD_MED                 free text medication id
    * @param    I_FLG_STATUS               status: A - current; P - not current; C - canceled
    * @param    I_DT_BEGIN                 reported medication data bagin
    * @param    I_NOTES                    notes
    * @param    I_FLG_TYPE                 type: Flag: E - extern; I - internal medication
    * @param    I_PROF_CAT_TYPE            professional category
    * @param    I_QTY                      medication quantity
    * @param    I_ID_UNIT_MEASURE_QTY      medication quantity unit measure id
    * @param    I_FREQ                     medication frequency
    * @param    I_ID_UNIT_MEASURE_FREQ     medication frequency unit measure id 
    * @param    I_DURATION                 medication duration
    * @param    I_ID_UNIT_MEASURE_FDUR     medication duration unit measure id
    * @param    I_EPIS_DOC                 epis documentation id
    * @param    I_FLG_NO_MED               'Y', se NO HOME MEDICATION está seleccionado e 'N', se ''NO HOME MEDICATION'' não está seleccionado
    * @param    I_ADV_REACTIONS            cursor with adverse reactions
    * @param    I_MED_DESTINATION          cursor with medication destination
    * @param    O_ID_PAT_MEDIC_LIST        created reported medication id
    * @param    O_ERROR                    error
    *
    * @return                Return BOOLEAN  
    *
    * @author                SS
    * @version               0.1
    * @since                 2006/06/12
    *
    * @author alter          Patrícia Neto
    * @since                 2007/OUT/16
    *
    ********************************************************************************************/

    FUNCTION set_pat_medication
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_presc_pharm    IN table_number,
        i_drug_req_det   IN table_number,
        i_drug_presc_det IN table_number,
        i_id_pat_medic   IN table_number,
        i_emb            IN table_varchar,
        --i_med                   IN table_number,
        i_med                   IN table_varchar,
        i_drug                  IN table_varchar,
        i_med_id_type           IN table_varchar,
        i_prod_med              IN table_varchar,
        i_flg_status            IN table_varchar,
        i_dt_begin              IN table_varchar,
        i_notes                 IN table_varchar,
        i_flg_type              IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_qty                   IN table_number,
        i_id_unit_measure_qty   IN table_number,
        i_freq                  IN table_number,
        i_id_unit_measure_freq  IN table_number,
        i_duration              IN table_number,
        i_id_unit_measure_dur   IN table_number,
        i_dt_start_pat_med_tstz IN table_varchar,
        i_dt_end_pat_med_tstz   IN table_varchar,
        i_epis_doc              IN NUMBER,
        i_vers                  IN table_varchar,
        i_flg_no_med            IN pat_medication_list.flg_no_med%TYPE,
        i_adv_reactions         IN table_varchar,
        i_med_destination       IN table_varchar,
        i_flg_take_type         IN table_varchar DEFAULT NULL,
        i_id_presc_directions   IN presc_directions.id_presc_directions%TYPE DEFAULT NULL,
        i_id_cdr_call           IN table_number DEFAULT NULL, --cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_id_pat_medic_list     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_med_id table_varchar;
    
        CURSOR c_presc_pharm(l_presc_pharm IN prescription_pharm.id_prescription_pharm%TYPE) IS
            SELECT pml.*
              FROM pat_medication_list pml
             WHERE pml.id_prescription_pharm = l_presc_pharm
               AND pml.id_patient = i_patient
               AND pml.id_episode = i_episode;
        r_presc_pharm pat_medication_list%ROWTYPE;
    
        CURSOR c_drug_req_det(l_drug_req_det IN drug_req_det.id_drug_req_det%TYPE) IS
            SELECT pml.*
              FROM pat_medication_list pml
             WHERE pml.id_drug_req_det = l_drug_req_det
               AND pml.id_patient = i_patient;
        r_drug_req_det pat_medication_list%ROWTYPE;
    
        CURSOR c_drug_presc_det(l_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE) IS
            SELECT pml.*
              FROM pat_medication_list pml
             WHERE pml.id_drug_presc_det = l_drug_presc_det
               AND pml.id_patient = i_patient;
    
        r_drug_presc_det pat_medication_list%ROWTYPE;
    
        CURSOR c_pat_med
        (
            l_drug     IN pat_medication_list.id_drug%TYPE,
            l_med      IN pat_medication_list.med_id%TYPE,
            l_prod_med IN pat_medication_list.id_prod_med%TYPE
        ) IS
            SELECT pml.*
              FROM pat_medication_list pml
             WHERE pml.id_patient = i_patient
               AND (pml.id_drug = l_drug OR pml.med_id = l_med OR pml.id_prod_med = l_prod_med);
    
        r_pat_med pat_medication_list%ROWTYPE;
    
        l_year_begin        pat_medication_list.year_begin%TYPE;
        l_month_begin       pat_medication_list.month_begin%TYPE;
        l_day_begin         pat_medication_list.day_begin%TYPE;
        l_next              pat_medication_list.id_pat_medication_list%TYPE;
        l_error             VARCHAR2(4000);
        r_presc             pat_medication_list%ROWTYPE;
        l_flg_status_aux    pat_medication_list.flg_status%TYPE;
        l_status_det_ti_log VARCHAR2(2);
    
        --
        l_flg_status pk_medication_types.pml_flg_status_t;
        l_id_pml     NUMBER(24);
    
        --logging
        l_log_str VARCHAR2(1000) := '';
    
        --denormalization
        l_rowids table_varchar;
    
        -- INPATIENT LMAIA 21-07-2008
        l_next_med_hist_list pat_medication_hist_list.id_pat_medication_hist_list%TYPE;
    
        l_emb_id_aux           VARCHAR2(11);
        l_id_other_product_aux NUMBER(24);
        l_vers_aux             VARCHAR2(10);
        l_version              VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_id_cdr_call table_number;
    BEGIN
    
        IF nvl(cardinality(i_id_cdr_call), 0) >= 1
        THEN
            l_id_cdr_call := i_id_cdr_call;
        ELSE
            l_id_cdr_call := table_number(NULL);
        END IF;
    
        SELECT MAX(id_pat_medication_list)
          INTO l_id_pml
          FROM pat_medication_list;
        --Tem que ser assim, pois o flash manda sempre no array med_id
        SELECT me.med_id
          BULK COLLECT
          INTO l_med_id
          FROM me_med me
         WHERE me.emb_id IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.00001) */
                               FROM TABLE(i_med) t)
           AND me.vers = l_version;
    
        IF l_med_id.first IS NULL
        THEN
            FOR i IN 1 .. i_drug.count
            LOOP
                l_med_id.extend;
            END LOOP;
        END IF;
    
        g_sysdate_tstz_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        pk_medication_core.print_medication_logs('BEGIN SET_PAT_MEDICATION: ' || i_emb(1),
                                                 pk_medication_core.c_log_debug);
        ----
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_med.count
        LOOP
        
            l_log_str := 'SET_PAT_MEDICATION:(i_patient = ' || i_patient || ', i_presc_pharm = ' || i_presc_pharm(i) ||
                         ', i_drug_req_det = ' || i_drug_req_det(i) || ', i_drug_presc_det = ' || i_drug_presc_det(i) ||
                         ', i_id_pat_medic = ' || i_id_pat_medic(i) || ', i_emb = ' || i_emb(i) || ', i_med = ' ||
                         i_med(i) || ', i_drug = ' || i_drug(i) || ', i_med_id_type = ' || i_med_id_type(i) || ')';
            pk_medication_core.print_medication_logs(l_log_str, pk_medication_core.c_log_debug);
            --
        
            IF i_flg_status(i) IS NULL
            THEN
                --activo por defeito
                l_flg_status := 'A';
            ELSE
                l_flg_status := i_flg_status(i);
            END IF;
        
            --é relato de medicação (não é relato de prescrição)
        
            g_error := 'GET DT_BEGIN' || i || '; ' || i_dt_begin(i);
            IF i_dt_begin(i) IS NOT NULL
            THEN
                --decompôr a data em ano, mês e dia.
                l_year_begin  := to_number(substr(i_dt_begin(i), 1, instr(i_dt_begin(i), '/') - 1));
                l_month_begin := to_number(substr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1),
                                                  1,
                                                  instr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1), '/') - 1));
                l_day_begin   := to_number(substr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1),
                                                  instr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1), '/') + 1));
            END IF;
        
            g_error := 'GET SEQ_PAT_MEDICATION_LIST.NEXTVAL';
            SELECT seq_pat_medication_list.nextval
              INTO l_next
              FROM dual;
        
            g_error := 'GET PAT_MEDICATION_HIST_LIST.NEXTVAL';
            SELECT seq_pat_medication_hist_list.nextval
              INTO l_next_med_hist_list
              FROM dual;
        
            IF (i_presc_pharm(i) IS NULL AND i_drug_req_det(i) IS NULL AND i_drug_presc_det(i) IS NULL)
            THEN
                g_error := 'OPEN C_PAT_MED; EMB_ID:' || i_emb(i);
                OPEN c_pat_med(i_drug(i), l_med_id(i) /*i_med(i)*/, i_prod_med(i));
                FETCH c_pat_med
                    INTO r_pat_med;
                g_found := c_pat_med%FOUND;
                CLOSE c_pat_med;
            
                IF g_found
                THEN
                
                    ------------------------------------------------------------------------------------------------------------------------------    
                    ts_pat_medication_hist_list.ins(id_pat_medication_hist_list_in => l_next_med_hist_list,
                                                    id_pat_medication_list_in      => r_pat_med.id_pat_medication_list,
                                                    dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                    id_episode_in                  => r_pat_med.id_episode,
                                                    id_patient_in                  => r_pat_med.id_patient,
                                                    id_institution_in              => r_pat_med.id_institution,
                                                    id_software_in                 => r_pat_med.id_software,
                                                    notes_in                       => i_notes(i),
                                                    med_id_in                      => i_med(i),
                                                    id_drug_in                     => i_drug(i),
                                                    id_prod_med_in                 => i_prod_med(i),
                                                    flg_status_in                  => i_flg_status(i),
                                                    id_professional_in             => r_pat_med.id_professional,
                                                    flg_presc_in                   => r_pat_med.flg_presc,
                                                    quantity_in                    => i_qty(i),
                                                    id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                    freq_in                        => i_freq(i),
                                                    id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                    duration_in                    => i_duration(i),
                                                    id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                    dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    i_dt_start_pat_med_tstz(i),
                                                                                                                    NULL),
                                                    dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    i_dt_end_pat_med_tstz(i),
                                                                                                                    NULL),
                                                    id_epis_documentation_in       => r_pat_med.id_epis_documentation,
                                                    med_id_type_in                 => r_pat_med.med_id_type,
                                                    continue_in                    => r_pat_med.continue,
                                                    vers_in                        => r_pat_med.vers,
                                                    dosage_in                      => r_pat_med.dosage,
                                                    flg_no_med_in                  => r_pat_med.flg_no_med,
                                                    notes_advers_react_in          => nvl(i_adv_reactions(i),
                                                                                          r_pat_med.notes_advers_react),
                                                    notes_med_destination_in       => nvl(i_med_destination(i),
                                                                                          r_pat_med.notes_med_destination),
                                                    flg_take_type_in               => r_pat_med.flg_take_type,
                                                    rows_out                       => l_rowids);
                
                    UPDATE pat_medication_hist_list pmhl
                       SET pmhl.id_presc_directions = i_id_presc_directions
                     WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                    ------------------------------------------------------------------------------------------------------------------------------  
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_MEDICATION_HIST_LIST',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    --se este medicamento já foi relatado
                    IF (r_pat_med.flg_status != i_flg_status(i) OR nvl(r_pat_med.quantity, -1) != nvl(i_qty(i), -1) OR
                       nvl(r_pat_med.id_unit_measure_qty, -1) != nvl(i_id_unit_measure_qty(i), -1) OR
                       nvl(r_pat_med.freq, -1) != nvl(i_freq(i), -1) OR
                       nvl(r_pat_med.id_unit_measure_freq, -1) != nvl(i_id_unit_measure_freq(i), -1) OR
                       nvl(r_pat_med.duration, -1) != nvl(i_duration(i), -1) OR
                       nvl(r_pat_med.id_unit_measure_dur, -1) != nvl(i_id_unit_measure_dur(i), -1) OR
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, r_pat_med.dt_end_pat_med_tstz, NULL) !=
                       nvl(i_dt_end_pat_med_tstz(i),
                            pk_date_utils.get_timestamp_str(i_lang, i_prof, current_timestamp, NULL)) OR
                       r_pat_med.dt_end_pat_med_tstz IS NULL AND i_dt_end_pat_med_tstz(i) IS NOT NULL OR
                       r_pat_med.continue IS NOT NULL)
                    THEN
                        --houve alteração de estado ou posologia 
                    
                        IF i_flg_status(i) = g_flg_inactive
                        THEN
                            --se o estado é I, então o médico enganou-se na escolha do medicamento: apaga o registo 
                            g_error := 'DELETE PAT_MEDICATION_LIST';
                            --DELETE pat_medication_list
                            --WHERE id_pat_medication_list = r_pat_med.id_pat_medication_list;
                        
                            ts_pat_medication_list.del(id_pat_medication_list_in => r_pat_med.id_pat_medication_list,
                                                       rows_out                  => l_rowids);
                        
                            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'PAT_MEDICATION_LIST',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        
                        ELSE
                        
                            --did not generate new ts for pat_medication_hist_list because there are objects with name too long
                            UPDATE pat_medication_hist_list pmhl
                               SET pmhl.id_presc_directions = r_pat_med.id_presc_directions
                             WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                        
                            SELECT decode(i_flg_status(i), g_flg_inactive, g_pat_med_list_can, l_flg_status)
                              INTO l_flg_status_aux
                              FROM dual;
                        
                            g_error := 'UPDATE PAT_MEDICATION_LIST 1';
                            ts_pat_medication_list.upd(id_pat_medication_list_in      => r_pat_med.id_pat_medication_list,
                                                       dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                       id_episode_in                  => i_episode,
                                                       id_professional_in             => i_prof.id,
                                                       id_institution_in              => i_prof.institution,
                                                       id_software_in                 => i_prof.software,
                                                       quantity_in                    => i_qty(i),
                                                       id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                       freq_in                        => i_freq(i),
                                                       id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                       duration_in                    => i_duration(i),
                                                       id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                       dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                       i_prof,
                                                                                                                       i_dt_start_pat_med_tstz(i),
                                                                                                                       NULL),
                                                       dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                       i_prof,
                                                                                                                       i_dt_end_pat_med_tstz(i),
                                                                                                                       NULL),
                                                       flg_status_in                  => l_flg_status_aux,
                                                       continue_in                    => NULL,
                                                       continue_nin                   => FALSE,
                                                       dosage_in                      => get_dosage_format(i_lang,
                                                                                                           i_qty(i),
                                                                                                           i_id_unit_measure_qty(i),
                                                                                                           i_freq(i),
                                                                                                           i_id_unit_measure_freq(i),
                                                                                                           i_duration(i),
                                                                                                           i_id_unit_measure_dur(i),
                                                                                                           NULL,
                                                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         i_dt_end_pat_med_tstz(i),
                                                                                                                                         NULL),
                                                                                                           i_prof),
                                                       flg_no_med_in                  => i_flg_no_med,
                                                       notes_advers_react_in          => i_adv_reactions(i),
                                                       notes_med_destination_in       => i_med_destination(i),
                                                       notes_in                       => i_notes(i),
                                                       flg_take_type_in               => i_flg_take_type(i),
                                                       id_cdr_call_in                 => l_id_cdr_call(1),
                                                       rows_out                       => l_rowids);
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'PAT_MEDICATION_LIST',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        
                            --did not generate new ts for pat_medication_list because there are objects with name too long
                            UPDATE pat_medication_list pml
                               SET pml.id_presc_directions = i_id_presc_directions
                             WHERE pml.id_pat_medication_list = r_pat_med.id_pat_medication_list;
                        
                        END IF; --I_FLG_STATUS
                    
                    ELSE
                        --não houve alteração do estado ou posologia
                    
                        g_error := 'UPDATE PAT_MEDICATION_LIST 3'; --actualizar os valores das outras caraterísticas 
                        ts_pat_medication_list.upd(id_pat_medication_list_in => r_pat_med.id_pat_medication_list,
                                                   year_begin_in             => l_year_begin,
                                                   month_begin_in            => l_month_begin,
                                                   day_begin_in              => l_day_begin,
                                                   notes_in                  => i_notes(i),
                                                   id_epis_documentation_in  => i_epis_doc,
                                                   id_episode_in             => i_episode,
                                                   id_professional_in        => i_prof.id,
                                                   id_institution_in         => i_prof.institution,
                                                   id_software_in            => i_prof.software,
                                                   flg_no_med_in             => i_flg_no_med,
                                                   notes_advers_react_in     => i_adv_reactions(i),
                                                   notes_med_destination_in  => i_med_destination(i),
                                                   flg_take_type_in          => i_flg_take_type(i),
                                                   id_cdr_call_in            => l_id_cdr_call(1),
                                                   rows_out                  => l_rowids);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = r_pat_med.id_pat_medication_list;
                    
                    END IF; --R_PAT_MED.FLG_STATUS      
                
                    SELECT flg_status
                      INTO l_flg_status_aux
                      FROM pat_medication_list pml
                     WHERE pml.id_pat_medication_list = r_pat_med.id_pat_medication_list;
                
                    --Transferência de informação entre episódios da mesma visita
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_episode,
                                            l_flg_status_aux,
                                            r_pat_med.id_pat_medication_list,
                                            pk_medication_core.g_ti_log_mr,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                ELSE
                    --se este medicamento ainda não foi relatado
                
                    IF i_flg_type(i) = g_flg_type_ext
                    THEN
                    
                        SELECT decode(l_med_id(i) /*i_med(i)*/, NULL, 'Y', 'N')
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        ts_pat_medication_list.ins(id_pat_medication_list_in      => l_next,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_patient_in                  => i_patient,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   med_id_in                      => l_med_id(i) /*i_med(i)*/,
                                                   year_begin_in                  => l_year_begin,
                                                   month_begin_in                 => l_month_begin,
                                                   day_begin_in                   => l_day_begin,
                                                   notes_in                       => i_notes(i),
                                                   flg_status_in                  => l_flg_status,
                                                   id_professional_in             => i_prof.id,
                                                   flg_presc_in                   => l_flg_status_aux,
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   med_id_type_in                 => i_med_id_type(i),
                                                   vers_in                        => i_vers(i),
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = l_next;
                    
                        ------------------------------------------------------------------------------------------------------------------------------    
                        ts_pat_medication_hist_list.ins(id_pat_medication_hist_list_in => l_next_med_hist_list,
                                                        id_pat_medication_list_in      => l_next,
                                                        dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                        id_episode_in                  => i_episode,
                                                        id_patient_in                  => i_patient,
                                                        id_institution_in              => i_prof.institution,
                                                        id_software_in                 => i_prof.software,
                                                        notes_in                       => i_notes(i),
                                                        med_id_in                      => i_prod_med(i),
                                                        id_drug_in                     => NULL,
                                                        id_prod_med_in                 => NULL,
                                                        prod_med_decr_in               => NULL,
                                                        year_begin_in                  => l_year_begin,
                                                        month_begin_in                 => l_month_begin,
                                                        day_begin_in                   => l_day_begin,
                                                        flg_status_in                  => l_flg_status,
                                                        id_professional_in             => i_prof.id,
                                                        flg_presc_in                   => l_flg_status_aux,
                                                        quantity_in                    => i_qty(i),
                                                        id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                        freq_in                        => i_freq(i),
                                                        id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                        duration_in                    => i_duration(i),
                                                        id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                        dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                        i_prof,
                                                                                                                        i_dt_start_pat_med_tstz(i),
                                                                                                                        NULL),
                                                        dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                        i_prof,
                                                                                                                        i_dt_end_pat_med_tstz(i),
                                                                                                                        NULL),
                                                        id_epis_documentation_in       => i_epis_doc,
                                                        med_id_type_in                 => i_med_id_type(i),
                                                        continue_in                    => NULL,
                                                        vers_in                        => i_vers(i),
                                                        dosage_in                      => get_dosage_format(i_lang,
                                                                                                            i_qty(i),
                                                                                                            i_id_unit_measure_qty(i),
                                                                                                            i_freq(i),
                                                                                                            i_id_unit_measure_freq(i),
                                                                                                            i_duration(i),
                                                                                                            i_id_unit_measure_dur(i),
                                                                                                            NULL,
                                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          i_dt_end_pat_med_tstz(i),
                                                                                                                                          NULL),
                                                                                                            i_prof),
                                                        flg_no_med_in                  => i_flg_no_med,
                                                        notes_advers_react_in          => i_adv_reactions(i),
                                                        notes_med_destination_in       => i_med_destination(i),
                                                        flg_take_type_in               => i_flg_take_type(i),
                                                        rows_out                       => l_rowids);
                    
                        UPDATE pat_medication_hist_list pmhl
                           SET pmhl.id_presc_directions = i_id_presc_directions
                         WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                    
                        ------------------------------------------------------------------------------------------------------------------------------  
                    
                    ELSIF i_flg_type(i) IN (g_flg_type_int, g_flg_type_adm)
                    THEN
                    
                        SELECT decode(l_med_id(i) /*i_med(i)*/, NULL, 'Y', 'N')
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        g_error := 'INSERT INTO PAT_MEDICATION_LIST 2';
                        ts_pat_medication_list.ins(id_pat_medication_list_in      => l_next,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_patient_in                  => i_patient,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   id_drug_in                     => i_drug(i),
                                                   year_begin_in                  => l_year_begin,
                                                   month_begin_in                 => l_month_begin,
                                                   day_begin_in                   => l_day_begin,
                                                   notes_in                       => i_notes(i),
                                                   flg_status_in                  => l_flg_status,
                                                   id_professional_in             => i_prof.id,
                                                   flg_presc_in                   => l_flg_status_aux,
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   med_id_type_in                 => i_med_id_type(i),
                                                   vers_in                        => i_vers(i),
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = l_next;
                    
                        ------------------------------------------------------------------------------------------------------------------------------    
                        ts_pat_medication_hist_list.ins(id_pat_medication_hist_list_in => l_next_med_hist_list,
                                                        id_pat_medication_list_in      => l_next,
                                                        dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                        id_episode_in                  => i_episode,
                                                        id_patient_in                  => i_patient,
                                                        id_institution_in              => i_prof.institution,
                                                        id_software_in                 => i_prof.software,
                                                        notes_in                       => i_notes(i),
                                                        med_id_in                      => i_prod_med(i),
                                                        id_drug_in                     => NULL,
                                                        id_prod_med_in                 => NULL,
                                                        prod_med_decr_in               => NULL,
                                                        year_begin_in                  => l_year_begin,
                                                        month_begin_in                 => l_month_begin,
                                                        day_begin_in                   => l_day_begin,
                                                        flg_status_in                  => l_flg_status,
                                                        id_professional_in             => i_prof.id,
                                                        flg_presc_in                   => l_flg_status_aux,
                                                        quantity_in                    => i_qty(i),
                                                        id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                        freq_in                        => i_freq(i),
                                                        id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                        duration_in                    => i_duration(i),
                                                        id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                        dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                        i_prof,
                                                                                                                        i_dt_start_pat_med_tstz(i),
                                                                                                                        NULL),
                                                        dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                        i_prof,
                                                                                                                        i_dt_end_pat_med_tstz(i),
                                                                                                                        NULL),
                                                        id_epis_documentation_in       => i_epis_doc,
                                                        med_id_type_in                 => i_med_id_type(i),
                                                        continue_in                    => NULL,
                                                        vers_in                        => i_vers(i),
                                                        dosage_in                      => get_dosage_format(i_lang,
                                                                                                            i_qty(i),
                                                                                                            i_id_unit_measure_qty(i),
                                                                                                            i_freq(i),
                                                                                                            i_id_unit_measure_freq(i),
                                                                                                            i_duration(i),
                                                                                                            i_id_unit_measure_dur(i),
                                                                                                            NULL,
                                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          i_dt_end_pat_med_tstz(i),
                                                                                                                                          NULL),
                                                                                                            i_prof),
                                                        flg_no_med_in                  => i_flg_no_med,
                                                        notes_advers_react_in          => i_adv_reactions(i),
                                                        notes_med_destination_in       => i_med_destination(i),
                                                        flg_take_type_in               => i_flg_take_type(i),
                                                        rows_out                       => l_rowids);
                    
                        UPDATE pat_medication_hist_list pmhl
                           SET pmhl.id_presc_directions = i_id_presc_directions
                         WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                        ------------------------------------------------------------------------------------------------------------------------------           
                    
                    ELSIF i_prod_med(i) IS NOT NULL
                    THEN
                    
                        SELECT decode(l_med_id(i) /*i_med(i)*/, NULL, 'Y', 'N')
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        g_error := 'INSERT INTO PAT_MEDICATION_LIST 2.2';
                        ts_pat_medication_list.ins(id_pat_medication_list_in      => l_next,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_patient_in                  => i_patient,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   id_prod_med_in                 => i_prod_med(i),
                                                   year_begin_in                  => l_year_begin,
                                                   month_begin_in                 => l_month_begin,
                                                   day_begin_in                   => l_day_begin,
                                                   notes_in                       => i_notes(i),
                                                   flg_status_in                  => l_flg_status,
                                                   id_professional_in             => i_prof.id,
                                                   flg_presc_in                   => l_flg_status_aux,
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   med_id_type_in                 => i_med_id_type(i),
                                                   vers_in                        => i_vers(i),
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = l_next;
                    
                        ------------------------------------------------------------------------------------------------------------------------------    
                        ts_pat_medication_hist_list.ins(id_pat_medication_hist_list_in => l_next_med_hist_list,
                                                        id_pat_medication_list_in      => l_next,
                                                        dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                        id_episode_in                  => i_episode,
                                                        id_patient_in                  => i_patient,
                                                        id_institution_in              => i_prof.institution,
                                                        id_software_in                 => i_prof.software,
                                                        notes_in                       => i_notes(i),
                                                        med_id_in                      => i_prod_med(i),
                                                        id_drug_in                     => NULL,
                                                        id_prod_med_in                 => NULL,
                                                        prod_med_decr_in               => NULL,
                                                        year_begin_in                  => l_year_begin,
                                                        month_begin_in                 => l_month_begin,
                                                        day_begin_in                   => l_day_begin,
                                                        flg_status_in                  => l_flg_status,
                                                        id_professional_in             => i_prof.id,
                                                        flg_presc_in                   => l_flg_status_aux,
                                                        quantity_in                    => i_qty(i),
                                                        id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                        freq_in                        => i_freq(i),
                                                        id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                        duration_in                    => i_duration(i),
                                                        id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                        dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                        i_prof,
                                                                                                                        i_dt_start_pat_med_tstz(i),
                                                                                                                        NULL),
                                                        dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                        i_prof,
                                                                                                                        i_dt_end_pat_med_tstz(i),
                                                                                                                        NULL),
                                                        id_epis_documentation_in       => i_epis_doc,
                                                        med_id_type_in                 => i_med_id_type(i),
                                                        continue_in                    => NULL,
                                                        vers_in                        => i_vers(i),
                                                        dosage_in                      => get_dosage_format(i_lang,
                                                                                                            i_qty(i),
                                                                                                            i_id_unit_measure_qty(i),
                                                                                                            i_freq(i),
                                                                                                            i_id_unit_measure_freq(i),
                                                                                                            i_duration(i),
                                                                                                            i_id_unit_measure_dur(i),
                                                                                                            NULL,
                                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          i_dt_end_pat_med_tstz(i),
                                                                                                                                          NULL),
                                                                                                            i_prof),
                                                        flg_no_med_in                  => i_flg_no_med,
                                                        notes_advers_react_in          => i_adv_reactions(i),
                                                        notes_med_destination_in       => i_med_destination(i),
                                                        flg_take_type_in               => i_flg_take_type(i),
                                                        rows_out                       => l_rowids);
                    
                        UPDATE pat_medication_hist_list pmhl
                           SET pmhl.id_presc_directions = i_id_presc_directions
                         WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                        ------------------------------------------------------------------------------------------------------------------------------    
                    
                    END IF; --I_FLG_TYPE
                
                    --insert initial flag for ti_log table.
                    pk_alertlog.log_debug('was not reported yet.');
                    BEGIN
                        SELECT decode(l_flg_status, 'A', 'AX', 'PX')
                          INTO l_status_det_ti_log
                          FROM dual;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_status_det_ti_log := 'AX';
                    END;
                
                    --Transferência de informação entre episódios da mesma visita
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_episode,
                                            l_status_det_ti_log,
                                            l_next,
                                            pk_medication_core.g_ti_log_mr,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF; --G_FOUND
            
            ELSE
            
                IF i_presc_pharm(i) IS NOT NULL
                THEN
                    g_error := 'OPEN C_PRESC_PHARM; I_PRESC_PHARM:' || i_presc_pharm(i);
                    OPEN c_presc_pharm(i_presc_pharm(i));
                    FETCH c_presc_pharm
                        INTO r_presc_pharm;
                    g_found := c_presc_pharm%FOUND;
                    CLOSE c_presc_pharm;
                
                    r_presc := r_presc_pharm;
                
                ELSIF i_drug_req_det(i) IS NOT NULL
                THEN
                    g_error := 'OPEN C_drug_req_det; I_drug_req_det:' || i_drug_req_det(i);
                    OPEN c_drug_req_det(i_drug_req_det(i));
                    FETCH c_drug_req_det
                        INTO r_drug_req_det;
                    g_found := c_drug_req_det%FOUND;
                    CLOSE c_drug_req_det;
                
                    r_presc := r_drug_req_det;
                
                ELSE
                    g_error := 'OPEN c_drug_presc_det; l_drug_presc_det:' || i_drug_presc_det(i);
                    OPEN c_drug_presc_det(i_drug_presc_det(i));
                    FETCH c_drug_presc_det
                        INTO r_drug_presc_det;
                    g_found := c_drug_presc_det%FOUND;
                    CLOSE c_drug_presc_det;
                
                    r_presc := r_drug_presc_det;
                
                END IF;
            
                IF g_found
                THEN
                    --já foi relatado
                    IF r_presc.flg_status != i_flg_status(i)
                    THEN
                        g_error := 'GET PAT_MEDICATION_HIST_LIST.NEXTVAL';
                        SELECT seq_pat_medication_hist_list.nextval
                          INTO l_next_med_hist_list
                          FROM dual;
                    
                        IF i_presc_pharm(i) IS NOT NULL
                        THEN
                            g_error := 'INSERT INTO PAT_MEDICATION_HIST_LIST 2'; --inserir na tabela de histórico
                            ts_pat_medication_hist_list.ins(id_pat_medication_hist_list_in => l_next_med_hist_list,
                                                            id_pat_medication_list_in      => r_presc.id_pat_medication_list,
                                                            dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                            id_episode_in                  => r_presc.id_episode,
                                                            id_patient_in                  => r_presc.id_patient,
                                                            id_institution_in              => r_presc.id_institution,
                                                            id_software_in                 => r_presc.id_software,
                                                            notes_in                       => r_presc.notes,
                                                            emb_id_in                      => r_presc.emb_id,
                                                            year_begin_in                  => r_presc.year_begin,
                                                            month_begin_in                 => r_presc.month_begin,
                                                            day_begin_in                   => r_presc.day_begin,
                                                            flg_status_in                  => r_presc.flg_status,
                                                            id_professional_in             => r_presc.id_professional,
                                                            flg_presc_in                   => r_presc.flg_presc,
                                                            id_prescription_pharm_in       => r_presc.id_prescription_pharm,
                                                            quantity_in                    => r_presc.quantity,
                                                            id_unit_measure_qty_in         => r_presc.id_unit_measure_qty,
                                                            freq_in                        => r_presc.freq,
                                                            id_unit_measure_freq_in        => r_presc.id_unit_measure_freq,
                                                            duration_in                    => r_presc.duration,
                                                            id_unit_measure_dur_in         => r_presc.id_unit_measure_dur,
                                                            dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                            i_prof,
                                                                                                                            nvl(i_dt_start_pat_med_tstz(i),
                                                                                                                                r_presc.dt_start_pat_med_tstz),
                                                                                                                            NULL),
                                                            dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                            i_prof,
                                                                                                                            nvl(i_dt_end_pat_med_tstz(i),
                                                                                                                                r_presc.dt_end_pat_med_tstz),
                                                                                                                            NULL),
                                                            id_epis_documentation_in       => r_presc.id_epis_documentation,
                                                            continue_in                    => r_presc.continue,
                                                            vers_in                        => r_presc.vers,
                                                            dosage_in                      => r_presc.dosage,
                                                            flg_no_med_in                  => r_presc.flg_no_med,
                                                            notes_advers_react_in          => r_presc.notes_advers_react,
                                                            notes_med_destination_in       => r_presc.notes_med_destination,
                                                            flg_take_type_in               => r_presc.flg_take_type,
                                                            rows_out                       => l_rowids);
                        
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'PAT_MEDICATION_HIST_LIST',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        
                            --did not generate new ts for pat_medication_hist_list because there are objects with name too long
                            UPDATE pat_medication_hist_list pmhl
                               SET pmhl.id_presc_directions = r_presc.id_presc_directions
                             WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                        
                        ELSE
                            g_error := 'INSERT INTO PAT_MEDICATION_HIST_LIST 3'; --inserir na tabela de histórico
                            ts_pat_medication_hist_list.ins(id_pat_medication_hist_list_in => l_next_med_hist_list,
                                                            id_pat_medication_list_in      => r_presc.id_pat_medication_list,
                                                            dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                            id_episode_in                  => r_presc.id_episode,
                                                            id_patient_in                  => r_presc.id_patient,
                                                            id_institution_in              => r_presc.id_institution,
                                                            id_software_in                 => r_presc.id_software,
                                                            notes_in                       => r_presc.notes,
                                                            id_drug_in                     => r_presc.id_drug,
                                                            year_begin_in                  => r_presc.year_begin,
                                                            month_begin_in                 => r_presc.month_begin,
                                                            day_begin_in                   => r_presc.day_begin,
                                                            flg_status_in                  => r_presc.flg_status,
                                                            id_professional_in             => r_presc.id_professional,
                                                            flg_presc_in                   => r_presc.flg_presc,
                                                            id_drug_req_det_in             => r_presc.id_drug_req_det,
                                                            id_drug_presc_det_in           => r_presc.id_drug_presc_det,
                                                            quantity_in                    => r_presc.quantity,
                                                            id_unit_measure_qty_in         => r_presc.id_unit_measure_qty,
                                                            freq_in                        => r_presc.freq,
                                                            id_unit_measure_freq_in        => r_presc.id_unit_measure_freq,
                                                            duration_in                    => r_presc.duration,
                                                            id_unit_measure_dur_in         => r_presc.id_unit_measure_dur,
                                                            dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                            i_prof,
                                                                                                                            nvl(i_dt_start_pat_med_tstz(i),
                                                                                                                                r_presc.dt_start_pat_med_tstz),
                                                                                                                            NULL),
                                                            dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                            i_prof,
                                                                                                                            nvl(i_dt_end_pat_med_tstz(i),
                                                                                                                                r_presc.dt_end_pat_med_tstz),
                                                                                                                            NULL),
                                                            id_epis_documentation_in       => r_presc.id_epis_documentation,
                                                            vers_in                        => r_presc.vers,
                                                            dosage_in                      => r_presc.dosage,
                                                            flg_no_med_in                  => r_presc.flg_no_med,
                                                            notes_advers_react_in          => r_presc.notes_advers_react,
                                                            notes_med_destination_in       => r_presc.notes_med_destination,
                                                            flg_take_type_in               => r_presc.flg_take_type,
                                                            rows_out                       => l_rowids);
                        
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'PAT_MEDICATION_HIST_LIST',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        
                            --did not generate new ts for pat_medication_hist_list because there are objects with name too long
                            UPDATE pat_medication_hist_list pmhl
                               SET pmhl.id_presc_directions = r_presc.id_presc_directions
                             WHERE pmhl.id_pat_medication_hist_list = l_next_med_hist_list;
                        
                        END IF;
                    
                        SELECT decode(i_flg_status(i), g_flg_inactive, g_pat_med_list_can, l_flg_status)
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        g_error := 'UPDATE PAT_MEDICATION_LIST 7';
                        ts_pat_medication_list.upd(id_pat_medication_list_in      => r_presc.id_pat_medication_list,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_prescription_pharm_in       => i_presc_pharm(i),
                                                   id_drug_req_det_in             => i_drug_req_det(i),
                                                   id_drug_presc_det_in           => i_drug_presc_det(i),
                                                   id_professional_in             => i_prof.id,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   flg_status_in                  => l_flg_status_aux,
                                                   continue_in                    => NULL,
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = r_presc.id_pat_medication_list;
                    
                    ELSE
                    
                        g_error := 'UPDATE PAT_MEDICATION_LIST 8';
                        ts_pat_medication_list.upd(id_pat_medication_list_in => r_presc.id_pat_medication_list,
                                                   year_begin_in             => l_year_begin,
                                                   month_begin_in            => l_month_begin,
                                                   day_begin_in              => l_day_begin,
                                                   notes_in                  => i_notes(i),
                                                   id_epis_documentation_in  => i_epis_doc,
                                                   id_episode_in             => i_episode,
                                                   id_professional_in        => i_prof.id,
                                                   id_institution_in         => i_prof.institution,
                                                   id_software_in            => i_prof.software,
                                                   flg_no_med_in             => i_flg_no_med,
                                                   notes_advers_react_in     => i_adv_reactions(i),
                                                   notes_med_destination_in  => i_med_destination(i),
                                                   flg_take_type_in          => i_flg_take_type(i),
                                                   id_cdr_call_in            => l_id_cdr_call(1),
                                                   rows_out                  => l_rowids);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = r_presc.id_pat_medication_list;
                    
                    END IF; --R_PRESC_PHARM.FLG_STATUS      
                
                    SELECT flg_status
                      INTO l_flg_status_aux
                      FROM pat_medication_list pml
                     WHERE pml.id_pat_medication_list = r_presc.id_pat_medication_list;
                
                    --Transferência de informação entre episódios da mesma visita
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_episode,
                                            l_flg_status_aux,
                                            r_presc.id_pat_medication_list,
                                            pk_medication_core.g_ti_log_mr,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                ELSE
                    --G_FOUND  ainda não foi relatado
                
                    g_error := 'GET SEQ_PAT_MEDICATION_LIST.NEXTVAL';
                    SELECT seq_pat_medication_list.nextval
                      INTO l_next
                      FROM dual;
                
                    IF i_flg_type(i) IN (g_flg_type_ext, pk_medication_current.g_flg_chronic_medication)
                    THEN
                    
                        SELECT pp.emb_id, pp.id_other_product, pp.vers
                          INTO l_emb_id_aux, l_id_other_product_aux, l_vers_aux
                          FROM prescription_pharm pp
                         WHERE pp.id_prescription_pharm = i_presc_pharm(i);
                    
                        SELECT decode(i_emb(i), NULL, 'Y', 'N')
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        g_error := 'INSERT INTO PAT_MEDICATION_LIST 3';
                        ts_pat_medication_list.ins(id_pat_medication_list_in      => l_next,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_patient_in                  => i_patient,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   emb_id_in                      => l_emb_id_aux,
                                                   med_id_in                      => l_id_other_product_aux,
                                                   year_begin_in                  => l_year_begin,
                                                   month_begin_in                 => l_month_begin,
                                                   day_begin_in                   => l_day_begin,
                                                   notes_in                       => i_notes(i),
                                                   flg_status_in                  => l_flg_status,
                                                   id_professional_in             => i_prof.id,
                                                   flg_presc_in                   => l_flg_status_aux,
                                                   id_prescription_pharm_in       => i_presc_pharm(i),
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   vers_in                        => nvl(i_vers(i), l_vers_aux),
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = l_next;
                    
                    ELSIF i_flg_type(i) IN (g_flg_manip_ext, g_flg_dietary_ext)
                    THEN
                    
                        SELECT decode(l_med_id(i) /*i_med(i)*/, NULL, 'Y', 'N')
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        g_error := 'INSERT INTO PAT_MEDICATION_LIST 4';
                        ts_pat_medication_list.ins(id_pat_medication_list_in      => l_next,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_patient_in                  => i_patient,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   year_begin_in                  => l_year_begin,
                                                   month_begin_in                 => l_month_begin,
                                                   day_begin_in                   => l_day_begin,
                                                   notes_in                       => i_notes(i),
                                                   flg_status_in                  => l_flg_status,
                                                   id_professional_in             => i_prof.id,
                                                   flg_presc_in                   => l_flg_status_aux,
                                                   id_prescription_pharm_in       => i_presc_pharm(i),
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   vers_in                        => i_vers(i),
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = l_next;
                    
                    ELSIF i_flg_type(i) IN (g_flg_type_int, g_flg_type_adm)
                    THEN
                    
                        SELECT decode(i_drug(i), NULL, 'Y', 'N')
                          INTO l_flg_status_aux
                          FROM dual;
                    
                        g_error := 'INSERT INTO PAT_MEDICATION_LIST 5';
                        ts_pat_medication_list.ins(id_pat_medication_list_in      => l_next,
                                                   dt_pat_medication_list_tstz_in => g_sysdate_tstz,
                                                   id_episode_in                  => i_episode,
                                                   id_patient_in                  => i_patient,
                                                   id_institution_in              => i_prof.institution,
                                                   id_software_in                 => i_prof.software,
                                                   id_drug_in                     => i_drug(i),
                                                   year_begin_in                  => l_year_begin,
                                                   month_begin_in                 => l_month_begin,
                                                   day_begin_in                   => l_day_begin,
                                                   notes_in                       => i_notes(i),
                                                   flg_status_in                  => l_flg_status,
                                                   id_professional_in             => i_prof.id,
                                                   flg_presc_in                   => l_flg_status_aux,
                                                   id_drug_req_det_in             => i_drug_req_det(i),
                                                   id_drug_presc_det_in           => i_drug_presc_det(i),
                                                   quantity_in                    => i_qty(i),
                                                   id_unit_measure_qty_in         => i_id_unit_measure_qty(i),
                                                   freq_in                        => i_freq(i),
                                                   id_unit_measure_freq_in        => i_id_unit_measure_freq(i),
                                                   duration_in                    => i_duration(i),
                                                   id_unit_measure_dur_in         => i_id_unit_measure_dur(i),
                                                   dt_start_pat_med_tstz_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_start_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   dt_end_pat_med_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_end_pat_med_tstz(i),
                                                                                                                   NULL),
                                                   id_epis_documentation_in       => i_epis_doc,
                                                   vers_in                        => i_vers(i),
                                                   dosage_in                      => get_dosage_format(i_lang,
                                                                                                       i_qty(i),
                                                                                                       i_id_unit_measure_qty(i),
                                                                                                       i_freq(i),
                                                                                                       i_id_unit_measure_freq(i),
                                                                                                       i_duration(i),
                                                                                                       i_id_unit_measure_dur(i),
                                                                                                       NULL,
                                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     i_dt_end_pat_med_tstz(i),
                                                                                                                                     NULL),
                                                                                                       i_prof),
                                                   flg_no_med_in                  => i_flg_no_med,
                                                   notes_advers_react_in          => i_adv_reactions(i),
                                                   notes_med_destination_in       => i_med_destination(i),
                                                   flg_take_type_in               => i_flg_take_type(i),
                                                   id_cdr_call_in                 => l_id_cdr_call(1),
                                                   rows_out                       => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_MEDICATION_LIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        --did not generate new ts for pat_medication_list because there are objects with name too long
                        UPDATE pat_medication_list pml
                           SET pml.id_presc_directions = i_id_presc_directions
                         WHERE pml.id_pat_medication_list = l_next;
                    
                    END IF; --I_FLG_TYPE
                
                    pk_alertlog.log_debug('was not reported yet - 2.');
                    BEGIN
                        SELECT decode(l_flg_status, 'A', 'AX', 'PX')
                          INTO l_status_det_ti_log
                          FROM dual;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_status_det_ti_log := 'AX';
                    END;
                    --Transferência de informação entre episódios da mesma visita
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_episode,
                                            l_flg_status,
                                            l_next,
                                            pk_medication_core.g_ti_log_mr,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF; --G_FOUND      
            END IF;
        
            --o_id_pat_medic_list := l_next;
        
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => i_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
        END LOOP;
    
        --ALERT-169123 - Sets the review information. When creating report, the review status will go always to Partially reviewed
        IF NOT set_review_detail(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_episode      => i_episode,
                                 i_action       => g_set_part_reviewed, --Set as Partially reviewed
                                 i_review_notes => NULL,
                                 i_dt_review    => NULL, --will be actual time
                                 o_error        => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        OPEN o_id_pat_medic_list FOR
            SELECT id_pat_medication_list
              FROM pat_medication_list
             WHERE id_pat_medication_list > l_id_pml
               AND id_patient = i_patient
               AND id_episode = i_episode;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_PREVIOUS',
                                              i_function => 'SET_PAT_MEDICATION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_id_pat_medic_list);
            RETURN FALSE;
    END set_pat_medication;
    --

    /********************************************************************************************
    * Create reported medication in text free mode
    *
    * @param    I_LANG                 language
    * @param    I_EPISODE              episode id
    * @param    I_PATIENT              patient id
    * @param    I_PROF                 professional array
    * @param    I_PROD_MED_DECR        free text reported medication
    * @param    I_FLG_STATUS           STATUS: A - current; P - not current; C - canceled
    * @param    I_DT_BEGIN             data begining
    * @param    I_NOTES                notes
    * @param    I_PROF_CAT_TYPE        professional category
    * @param    I_QTY                  reported medication quantity
    * @param    I_ID_UNIT_MEASURE_QTY  reported medication quantity unit measure id
    * @param    I_FREQ                 reported medication frequency
    * @param    I_ID_UNIT_MEASURE_FREQ reported medication frequency unit measure id
    * @param    I_DURATION             reported medication duration
    * @param    I_ID_UNIT_MEASURE_FDUR reported medication  duration id
    * @param    I_FLG_SHOW             FLG, 'Y' ou 'N', depending if shows message   
    * @param    I_EPIS_DOC             epis documentation id
    * @param    I_FLG_NO_MED           'Y', se NO HOME MEDICATION está seleccionado e 'N', se ''NO HOME MEDICATION'' não está seleccionado
    * @param    O_PROF_MED             created reported medication
    * @param    O_ERROR                error
    *
    * @return                Return BOOLEAN  
    *
    * @author                Patrícia Neto
    * @version               0.1
    * @since                 2007/OUT/16
    *
    ********************************************************************************************/

    FUNCTION set_outros_produtos
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_patient               IN patient.id_patient%TYPE,
        i_prof                  IN profissional,
        i_prod_med_decr         IN table_varchar,
        i_med_id_type           IN table_varchar,
        i_flg_status            IN table_varchar,
        i_dt_begin              IN table_varchar,
        i_notes                 IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_qty                   IN table_number,
        i_id_unit_measure_qty   IN table_number,
        i_freq                  IN table_number,
        i_id_unit_measure_freq  IN table_number,
        i_duration              IN table_number,
        i_id_unit_measure_dur   IN table_number,
        i_dt_start_pat_med_tstz IN table_varchar,
        i_dt_end_pat_med_tstz   IN table_varchar,
        i_flg_show              IN VARCHAR2,
        i_epis_doc              IN NUMBER,
        i_vers                  IN table_varchar,
        i_flg_no_med            IN pat_medication_list.flg_no_med%TYPE,
        i_flg_take_type         IN table_varchar DEFAULT NULL,
        i_id_presc_directions   IN presc_directions.id_presc_directions%TYPE DEFAULT NULL,
        i_id_cdr_call           IN table_number DEFAULT NULL, --cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_prod_med              OUT pk_types.cursor_type,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_year_begin             pat_medication_list.year_begin%TYPE;
        l_month_begin            pat_medication_list.month_begin%TYPE;
        l_day_begin              pat_medication_list.day_begin%TYPE;
        l_id_prod_med            pat_medication_list.id_prod_med%TYPE;
        l_id_pat_medication_list pat_medication_list.id_pat_medication_list%TYPE;
        l_med                    table_varchar := table_varchar();
        l_error                  VARCHAR2(4000);
        l_continue               BOOLEAN := TRUE;
        l_status_det_ti_log      VARCHAR2(2);
        l_pat_med_list_arr       table_number := table_number();
    
        version me_med.vers%TYPE;
    
        --logging
        l_log_str VARCHAR2(1000) := '';
    
        l_id_cdr_call table_number;
    BEGIN
    
        IF nvl(cardinality(i_id_cdr_call), 0) >= 1
        THEN
            l_id_cdr_call := i_id_cdr_call;
        ELSE
            l_id_cdr_call := table_number(NULL);
        END IF;
    
        version := pk_sysconfig.get_config(g_presc_type, i_prof);
    
        FOR i IN 1 .. i_prod_med_decr.count
        LOOP
            IF i_flg_status(i) IS NOT NULL
               AND i_flg_status(i) != g_pat_med_list_can
            THEN
                l_med.extend;
                l_med(i) := i_prod_med_decr(i);
            END IF;
        
        END LOOP;
    
        IF l_med IS NOT NULL
           AND i_flg_show = g_yes
        THEN
            o_flg_show := g_yes;
            o_msg      := pk_message.get_message(i_lang, g_presc_rec_m014); --Qualquer artigo prescrito dentro do grupo Outros produtos 
            -- não será acompanhado de impressão de código de barras na receita médica. 
            -- Os artigos prescritos nesta área não serão válidos para efeitos de comparticipação.
            o_msg_title := pk_message.get_message(i_lang, g_presc_rec_m015); --Aviso
            o_button    := 'NC'; -- VOLTAR ATRÁS/ CONTINUAR
            l_continue  := FALSE;
        
        END IF;
    
        IF l_continue
        THEN
        
            FOR i IN 1 .. l_med.count
            LOOP
            
                l_log_str := 'SET_OUTROS_PRODUTOS:(i_patient = ' || i_patient || ', i_prod_med_decr = ' ||
                             i_prod_med_decr(i) || ', i_med_id_type = ' || i_med_id_type(i) || ')';
                pk_medication_core.print_medication_logs(l_log_str, pk_medication_core.c_log_debug);
                --
            
                g_error := 'GET DT_BEGIN' || i || '; ' || i_dt_begin(i);
                IF i_dt_begin(i) IS NOT NULL
                THEN
                    --decompôr a data em ano, mês e dia.
                    l_year_begin  := to_number(substr(i_dt_begin(i), 1, instr(i_dt_begin(i), '/') - 1));
                    l_month_begin := to_number(substr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1),
                                                      1,
                                                      instr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1), '/') - 1));
                    l_day_begin   := to_number(substr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1),
                                                      instr(substr(i_dt_begin(i), instr(i_dt_begin(i), '/') + 1), '/') + 1));
                END IF;
            
                -- se este medicamento ainda não foi relatado
            
                g_error := 'GET SEQ_ID_PROD_MED NEXTVAL';
                SELECT MAX(nvl(to_number(id_prod_med), 0)) + 1
                  INTO l_id_prod_med
                  FROM pat_medication_list;
            
                g_error := 'GET SEQ l_id_pat_medication_list NEXTVAL';
                SELECT seq_pat_medication_list.nextval
                  INTO l_id_pat_medication_list
                  FROM dual;
            
                g_error := 'INSERT INTO PAT_MEDICATION_LIST';
                INSERT INTO pat_medication_list
                    (id_pat_medication_list,
                     dt_pat_medication_list_tstz,
                     id_episode,
                     id_patient,
                     id_institution,
                     id_software,
                     id_prod_med,
                     prod_med_decr,
                     year_begin,
                     month_begin,
                     day_begin,
                     notes,
                     flg_status,
                     id_professional,
                     flg_presc,
                     quantity,
                     id_unit_measure_qty,
                     freq,
                     id_unit_measure_freq,
                     duration,
                     id_unit_measure_dur,
                     dt_start_pat_med_tstz,
                     dt_end_pat_med_tstz,
                     id_epis_documentation,
                     med_id_type,
                     vers,
                     dosage,
                     flg_no_med,
                     id_presc_directions,
                     id_cdr_call)
                VALUES
                    (l_id_pat_medication_list,
                     g_sysdate_tstz,
                     i_episode,
                     i_patient,
                     i_prof.institution,
                     i_prof.software,
                     l_id_prod_med,
                     i_prod_med_decr(i),
                     l_year_begin,
                     l_month_begin,
                     l_day_begin,
                     i_notes(i),
                     i_flg_status(i),
                     i_prof.id,
                     g_no,
                     i_qty(i),
                     i_id_unit_measure_qty(i),
                     i_freq(i),
                     i_id_unit_measure_freq(i),
                     i_duration(i),
                     i_id_unit_measure_dur(i),
                     pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start_pat_med_tstz(i), NULL),
                     pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_pat_med_tstz(i), NULL),
                     i_epis_doc,
                     i_med_id_type(i),
                     version,
                     get_dosage_format(i_lang,
                                       i_qty(i),
                                       i_id_unit_measure_qty(i),
                                       i_freq(i),
                                       i_id_unit_measure_freq(i),
                                       i_duration(i),
                                       i_id_unit_measure_dur(i),
                                       NULL,
                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_pat_med_tstz(i), NULL),
                                       i_prof),
                     i_flg_no_med,
                     i_id_presc_directions,
                     l_id_cdr_call(1));
            
                --insert initial flag for ti_log table.
                pk_alertlog.log_debug('was not reported yet.');
                BEGIN
                    SELECT decode(i_flg_status(i), 'A', 'AX', 'PX')
                      INTO l_status_det_ti_log
                      FROM dual;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_status_det_ti_log := 'AX';
                END;
            
                --Transferência de informação entre episódios da mesma visita
                IF NOT t_ti_log.ins_log(i_lang,
                                        i_prof,
                                        i_episode,
                                        l_status_det_ti_log,
                                        l_id_pat_medication_list,
                                        pk_medication_core.g_ti_log_mr,
                                        o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
                g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => i_episode,
                                              i_pat                 => i_patient,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => i_prof_cat_type,
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
                l_pat_med_list_arr.extend;
                l_pat_med_list_arr(i) := l_id_pat_medication_list;
            END LOOP;
        END IF;
    
        --ALERT-169123 - Sets the review information. When creating report, the review status will go always to Partially reviewed
        IF NOT set_review_detail(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_episode      => i_episode,
                                 i_action       => g_set_part_reviewed, --Set as Partially reviewed
                                 i_review_notes => NULL,
                                 i_dt_review    => NULL, --will be actual time
                                 o_error        => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        g_error := 'OPEN O_CURSOR O_PROD_MED';
        OPEN o_prod_med FOR
            SELECT l_pat_med_list_arr id_pat_medication_list, i_prod_med_decr prod_med_decr, i_flg_status flg_status
              FROM dual;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_PREVIOUS',
                                              i_function => 'SET_OUTROS_PRODUTOS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_prod_med);
            RETURN FALSE;
    END set_outros_produtos;

    /********************************************************************************************
    * Set the changes in the previous medications rows states (current/not current)
    *
    * @ param i_lang                       language
    * @ param i_prof                       professional array
    * @ param i_id_patient                 patient id
    * @ param i_id_episode                 episode id
    * @ param i_id_pat_medic               reported medication id (id_pat_medication_list)
    * @ param i_flg_status                 status: A - current; P - not current; C - canceled
    * @ param o_error                      error message
    *
    * @return                TRUE if success and FALSE otherwise   
    *
    * @author                Orlando Antunes
    * @version               0.1
    * @since                 2008/04/29
    *
    * @author                José Brito
    * @version               2.6.0.5
    * @since                 2011/01/17
    ********************************************************************************************/
    FUNCTION set_pat_medication_states
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_pat_medic IN table_number,
        i_flg_status   IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_PAT_MEDICATION_STATES';
        l_internal_error EXCEPTION;
    BEGIN
    
        IF NOT call_set_pat_medication_states(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_patient   => i_id_patient,
                                              i_id_episode   => i_id_episode,
                                              i_id_pat_medic => i_id_pat_medic,
                                              i_flg_status   => i_flg_status,
                                              o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_medication_states;

    /********************************************************************************************
    * Set the changes in the previous medications rows states (current/not current)
    *
    * @ param i_lang                       language
    * @ param i_prof                       professional array
    * @ param i_id_patient                 patient id
    * @ param i_id_episode                 episode id
    * @ param i_id_pat_medic               reported medication id (id_pat_medication_list)
    * @ param i_flg_status                 status: A - current; P - not current; C - canceled
    * @ param o_error                      error message
    *
    * @return                TRUE if success and FALSE otherwise   
    *
    * @author                Orlando Antunes
    * @version               0.1
    * @since                 2008/04/29
    *
    * @author                José Brito
    * @version               2.6.0.5
    * @since                 2011/01/17
    ********************************************************************************************/
    FUNCTION call_set_pat_medication_states
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        --id pat_medication_list
        i_id_pat_medic IN table_number,
        --pat_medication_list.flg_status
        i_flg_status IN table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_med(l_id_pat_medic IN pat_medication_list.id_pat_medication_list%TYPE) IS
            SELECT pml.*
              FROM pat_medication_list pml
             WHERE pml.id_pat_medication_list = l_id_pat_medic;
    
        r_pat_med pat_medication_list%ROWTYPE;
    
    BEGIN
    
        ----
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_pat_medic.count
        LOOP
        
            pk_medication_core.print_medication_logs('SET_PREVIOUS_MEDICATION_STATE:(i_id_patient = ' || i_id_patient ||
                                                     ', i_id_pat_medic = ' || i_id_pat_medic(i) || ', i_flg_status = ' ||
                                                     i_flg_status(i) || ')',
                                                     pk_medication_core.c_log_debug);
        
            g_error := 'OPEN C_PAT_MED; EMB_ID:' || i_id_pat_medic(i);
            OPEN c_pat_med(i_id_pat_medic(i));
            FETCH c_pat_med
                INTO r_pat_med;
            g_found := c_pat_med%FOUND;
            CLOSE c_pat_med;
        
            --guarda na tabela de histórico 
            g_error := 'INSERT INTO PAT_MEDICATION_HIST_LIST';
            INSERT INTO pat_medication_hist_list
                (id_pat_medication_hist_list,
                 id_pat_medication_list,
                 dt_pat_medication_list_tstz,
                 id_episode,
                 id_patient,
                 id_institution,
                 id_software,
                 med_id,
                 id_drug,
                 id_prod_med,
                 prod_med_decr,
                 year_begin,
                 month_begin,
                 day_begin,
                 flg_status,
                 id_professional,
                 flg_presc,
                 quantity,
                 id_unit_measure_qty,
                 freq,
                 id_unit_measure_freq,
                 duration,
                 id_unit_measure_dur,
                 dt_start_pat_med_tstz,
                 dt_end_pat_med_tstz,
                 id_epis_documentation,
                 med_id_type,
                 CONTINUE,
                 vers,
                 dosage,
                 flg_no_med)
            VALUES
                (seq_pat_medication_hist_list.nextval,
                 r_pat_med.id_pat_medication_list,
                 r_pat_med.dt_pat_medication_list_tstz,
                 r_pat_med.id_episode,
                 r_pat_med.id_patient,
                 r_pat_med.id_institution,
                 r_pat_med.id_software,
                 r_pat_med.med_id,
                 r_pat_med.id_drug,
                 r_pat_med.id_prod_med,
                 r_pat_med.prod_med_decr,
                 r_pat_med.year_begin,
                 r_pat_med.month_begin,
                 r_pat_med.day_begin,
                 r_pat_med.flg_status,
                 r_pat_med.id_professional,
                 r_pat_med.flg_presc,
                 r_pat_med.quantity,
                 r_pat_med.id_unit_measure_qty,
                 r_pat_med.freq,
                 r_pat_med.id_unit_measure_freq,
                 r_pat_med.duration,
                 r_pat_med.id_unit_measure_dur,
                 pk_date_utils.get_string_tstz(i_lang, i_prof, r_pat_med.dt_start_pat_med_tstz, NULL),
                 pk_date_utils.get_string_tstz(i_lang, i_prof, r_pat_med.dt_end_pat_med_tstz, NULL),
                 r_pat_med.id_epis_documentation,
                 r_pat_med.med_id_type,
                 r_pat_med.continue,
                 r_pat_med.vers,
                 r_pat_med.dosage,
                 r_pat_med.flg_no_med);
        
            --e altera o estado     
            g_error := 'UPDATE PAT_MEDICATION_LIST 1';
            UPDATE pat_medication_list
               SET flg_status = decode(i_flg_status(i), g_flg_inactive, g_pat_med_list_can, i_flg_status(i))
             WHERE id_pat_medication_list = i_id_pat_medic(i);
        END LOOP;
    
        --Checklist - 16
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_PREVIOUS',
                                              i_function => 'SET_PAT_MEDICATION_STATES',
                                              o_error    => o_error);
            RETURN FALSE;
    END call_set_pat_medication_states;

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
    FUNCTION set_review_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN drug_prescription.id_episode%TYPE,
        i_action       IN VARCHAR2 DEFAULT NULL,
        i_review_notes IN VARCHAR2 DEFAULT NULL,
        i_dt_review    IN VARCHAR2 DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_review             TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_already_part          VARCHAR2(1) := pk_alert_constant.g_no;
        l_reported_med_context  review_detail.flg_context%TYPE := pk_review.get_reported_med_context();
        l_med_reconcile_context review_detail.flg_context%TYPE := pk_review.get_med_reconcile_context();
    
        l_current_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
        --
        --l_discharge_date       discharge.dt_med_tstz%TYPE;
        --l_flg_discharge_status epis_info.flg_dsch_status%TYPE;
    
    BEGIN
        g_error := 'SET TIMESTAMP';
        IF i_dt_review IS NULL
        THEN
            l_dt_review := current_timestamp;
        ELSE
            l_dt_review := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_review, NULL);
        END IF;
    
        --IF NOT pk_discharge.get_discharge_date(i_lang                 => i_lang,
        --                                       i_prof                 => i_prof,
        --                                       i_id_episode           => i_episode,
        --                                       o_discharge_date       => l_discharge_date,
        --                                       o_flg_discharge_status => l_flg_discharge_status,
        --                                       o_error                => o_error)
        --THEN
        --    raise_application_error(-20001, o_error.ora_sqlerrm);
        --END IF;
    
        --Set reviewed - creates new record in review_detail - keeps the history of the notes
        IF i_action = g_set_reviewed
           OR i_action IS NULL --default behavior
        THEN
        
            g_error := 'set_review - reviewed';
            IF NOT pk_review.set_review(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_id_record_area     => i_episode,
                                        i_flg_context        => l_reported_med_context,
                                        i_dt_review          => l_dt_review,
                                        i_review_notes       => i_review_notes,
                                        i_episode            => i_episode, --same as id_record_area. This way, we can say it is fully reviewed
                                        i_flg_auto           => 'N',
                                        i_revision           => NULL,
                                        i_flg_problem_review => 'N',
                                        o_error              => o_error)
            THEN
                raise_application_error(-20002, o_error.ora_sqlerrm);
            END IF;
        
        ELSIF i_action IN (g_set_not_reviewed, g_set_part_reviewed)
        THEN
        
            --Check if already in partially reviewed state
            BEGIN
                SELECT pk_alert_constant.g_yes
                  INTO l_already_part
                  FROM review_detail rd
                 WHERE rd.id_record_area = i_episode
                   AND rd.flg_context = l_reported_med_context
                   AND rd.id_episode IS NULL --If null, is partially reviewed
                   AND rd.dt_review = (SELECT MAX(rd2.dt_review)
                                         FROM review_detail rd2
                                        WHERE rd2.id_record_area = i_episode
                                          AND rd2.flg_context = l_reported_med_context);
            EXCEPTION
                WHEN no_data_found THEN
                    l_already_part := pk_alert_constant.g_no;
            END;
        
            IF l_already_part = pk_alert_constant.g_no --Only insert new records if not in partially reviewed state
            THEN
                g_error := 'set_review - not/partially reviewed';
                IF NOT pk_review.set_review(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_record_area     => i_episode,
                                            i_flg_context        => l_reported_med_context,
                                            i_dt_review          => l_dt_review,
                                            i_review_notes       => i_review_notes,
                                            i_episode            => NULL, --not the same as id_record_area. This way, we can say it is partially reviewed
                                            i_flg_auto           => 'N',
                                            i_revision           => NULL,
                                            i_flg_problem_review => 'N',
                                            o_error              => o_error)
                THEN
                    raise_application_error(-20003, o_error.ora_sqlerrm);
                END IF;
            
                --IF l_flg_discharge_status <> 'A' --Only if not dischaged, can change the reconciliation
                --THEN
            
                g_error := 'set_review - set also the reconciliation to partially reviewed';
                --set reconcile status to partially reconciled
                IF NOT pk_prescription.set_reconcile_detail(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => i_episode,
                                                            i_action          => pk_prescription.g_set_part_reconciled,
                                                            i_reconcile_notes => NULL,
                                                            i_dt_reconcile    => NULL,
                                                            o_error           => o_error)
                THEN
                    raise_application_error(-20003, o_error.ora_sqlerrm);
                END IF;
                --END IF;
            
            ELSE
                g_error := 'set_review - update last review date';
                --update last review date
                UPDATE review_detail rd
                   SET rd.dt_review = l_current_timestamp
                 WHERE rd.id_record_area = i_episode
                   AND rd.flg_context = l_reported_med_context
                   AND rd.dt_review = (SELECT MAX(rd2.dt_review)
                                         FROM review_detail rd2
                                        WHERE rd2.id_record_area = i_episode
                                          AND rd2.flg_context = l_reported_med_context);
            
                --IF l_flg_discharge_status <> 'A' --Only if not dischaged, can change the reconciliation
                --THEN
                g_error := 'set_review - update last reconcile date, if partially reconciled';
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
                --END IF;
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
                                                     i_package  => 'PK_MEDICATION_PREVIOUS',
                                                     i_function => 'SET_REVIEW_DETAIL',
                                                     o_error    => o_error);
            RETURN FALSE;
    END set_review_detail;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
