/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_discharge_inst IS

    /********************************************************************************************
    * This function returns true if i_discharge_dest has associated institutions
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  ID_DISCHARGE_DEST   
    *
    * @return                   TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION has_disch_dest_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge_dest IN discharge_dest.id_discharge_dest%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ddi_count NUMBER;
    
        CURSOR c_disch_dest_inst IS
            SELECT 1
              FROM disch_dest_inst ddi
             WHERE ddi.id_discharge_dest = i_discharge_dest
               AND ddi.flg_active = g_yes
               AND ddi.id_institution IN (i_prof.institution, 0)
               AND ddi.id_software IN (i_prof.software, 0)
               AND rownum = 1;
    
    BEGIN
    
        IF i_discharge_dest IS NULL
        THEN
            RETURN g_no;
        END IF;
    
        g_error := 'OPEN c_disch_dest_inst';
        OPEN c_disch_dest_inst;
        FETCH c_disch_dest_inst
            INTO l_ddi_count;
        g_found := c_disch_dest_inst%FOUND;
        CLOSE c_disch_dest_inst;
    
        IF g_found
           AND l_ddi_count > 0
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_no;
    END;

    /********************************************************************************************
    * Returns Y or N depending if the discharge is a transference discharge or no
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       ID_DISCHARGE
    *
    * @return                   TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    16/03/2010
    ********************************************************************************************/
    FUNCTION check_is_transf_discharge
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error             t_error_out;
        l_flg_inst_transfer discharge_detail.flg_inst_transfer%TYPE;
    
        CURSOR c_discharge IS
            SELECT dd.flg_inst_transfer
              FROM discharge_detail dd
             WHERE dd.id_discharge = i_discharge;
    
    BEGIN
        IF i_discharge IS NULL
        THEN
            RETURN g_no;
        END IF;
    
        g_error := 'OPEN C_DISCHARGE';
        OPEN c_discharge;
        FETCH c_discharge
            INTO l_flg_inst_transfer;
        g_found := c_discharge%FOUND;
        CLOSE c_discharge;
    
        IF g_found
           AND l_flg_inst_transfer IS NOT NULL
        THEN
            -- se for 'N' podia fazer uma validação extra para verificar se existem DTI para a discharge
            RETURN l_flg_inst_transfer;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISCHARGE_INST',
                                              'ASSOC_DISCH_DEST_WITH_INST',
                                              l_error);
            RETURN g_no;
    END;

    /********************************************************************************************
    * Function to associate a discharge_dest with institution_ext (for backoffice association)
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  discharge_dest.id_discharge_dest
    * @param IN   i_institution_ext institution_ext.id_institution_ext
    * @param IN   i_software        software.id_software
    * @param IN   i_institution     institution.id_institution
    *
    * @return                       TRUE if association ok, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION assoc_disch_dest_with_inst -- for backoffice 
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_dest  IN discharge_dest.id_discharge_dest%TYPE,
        i_institution_ext IN institution_ext.id_institution_ext%TYPE,
        i_software        IN software.id_software%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        o_disch_dest_inst OUT disch_dest_inst.id_disch_dest_inst%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
    
    BEGIN
    
        -- all input fields are necessary and cannot be null
        IF i_discharge_dest IS NOT NULL
           AND i_institution_ext IS NOT NULL
           AND i_software IS NOT NULL
           AND i_institution IS NOT NULL
        THEN
            g_error := 'SET DISCH_DEST_INST';
            ts_disch_dest_inst.ins(id_disch_dest_inst_out => o_disch_dest_inst,
                                   id_discharge_dest_in   => i_discharge_dest,
                                   id_institution_ext_in  => i_institution_ext,
                                   id_software_in         => i_software,
                                   id_institution_in      => i_institution,
                                   flg_active_in          => g_yes,
                                   rows_out               => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DISCH_DEST_INST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'ASSOC_DISCH_DEST_WITH_INST',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function return possible actions when selected a discharge destination with available institutions
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  ID_DISCHARGE_DEST  - either i_discharge_dest or i_disch_reas_dest must not be null
    * @param IN   i_disch_reas_dest ID_DISCH_REAS_DEST
    *
    * @param OUT  o_disch_options   returns the options list when chosing a discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION get_disch_dest_options
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_dest  IN discharge_dest.id_discharge_dest%TYPE,
        i_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE, -- connection table between discharge_reason & discharge_dest
        o_disch_options   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_discharge_dest     discharge_dest.id_discharge_dest%TYPE;
        l_create_permissions VARCHAR2(1 CHAR) := g_no;
    
        CURSOR c_discharge_dest IS
            SELECT drd.id_discharge_dest
              FROM disch_reas_dest drd
             WHERE drd.id_disch_reas_dest = i_disch_reas_dest
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.flg_active = pk_alert_constant.g_active;
    
    BEGIN
        ---------------------------------------
        IF i_discharge_dest IS NULL
           AND i_disch_reas_dest IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        ---------------------------------------
        IF i_discharge_dest IS NULL
           AND i_disch_reas_dest IS NOT NULL
        THEN
            g_error := 'OPEN C_DISCHARGE_DEST';
            OPEN c_discharge_dest;
            FETCH c_discharge_dest
                INTO l_discharge_dest;
            g_found := c_discharge_dest%FOUND;
            CLOSE c_discharge_dest;
        
            IF NOT g_found
               OR l_discharge_dest IS NULL
            THEN
                RETURN FALSE;
            END IF;
        ELSIF i_discharge_dest IS NOT NULL
        THEN
            l_discharge_dest := i_discharge_dest;
        END IF;
    
        ---------------------------------------
        IF prof_has_create_permissions(i_lang, i_prof)
        THEN
            l_create_permissions := g_yes;
        END IF;
    
        ---------------------------------------
        IF has_disch_dest_inst(i_lang, i_prof, l_discharge_dest) = g_yes
        THEN
            g_error := 'OPEN o_disch_options';
            OPEN o_disch_options FOR
                SELECT 1 rank,
                       'I' option_val,
                       pk_message.get_message(i_lang, g_dest_option_create_list) option_desc, -- 'Instituição'
                       g_yes has_child,
                       g_no allow_active_disch
                  FROM dual
                UNION ALL
                SELECT 2 rank,
                       'U' option_val,
                       pk_message.get_message(i_lang, g_dest_option_direct) option_desc, -- 'Indefinido'
                       g_no has_child,
                       g_yes allow_active_disch
                  FROM dual
                UNION ALL
                SELECT 3 rank,
                       'T' option_val,
                       pk_message.get_message(i_lang, g_dest_option_other_prof_list) option_desc, -- 'A definir por terceiros'
                       g_no has_child,
                       g_no allow_active_disch
                  FROM dual
                 WHERE l_create_permissions = g_yes;
            RETURN TRUE;
        ELSE
            pk_types.open_my_cursor(o_disch_options);
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_disch_options);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_DISCH_DEST_OPTIONS',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns the list of available institution for the specific discharge destination
    * this function is necessary when selected the option "A definir por terceiros" where only the id_discharge is available
    * -- Function for the social worker
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       ID_DISCHARGE
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    16/03/2010
    ********************************************************************************************/
    FUNCTION get_institution_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_dti_notes OUT discharge_detail.dti_notes%TYPE,
        o_dest_inst OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_disch_reas_dest disch_reas_dest.id_disch_reas_dest%TYPE;
        l_professional    professional.id_professional%TYPE;
        l_institution     institution.id_institution%TYPE;
        l_software        software.id_software%TYPE;
    
        CURSOR c_discharge_dest IS
            SELECT drd.id_disch_reas_dest,
                   d.id_prof_med,
                   e.id_institution,
                   pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
              FROM discharge d, disch_reas_dest drd, episode e
             WHERE d.id_discharge = i_discharge
               AND d.id_disch_reas_dest = drd.id_disch_reas_dest
               AND d.id_episode = e.id_episode;
    
        CURSOR c_dti_notes IS
            SELECT dd.dti_notes
              FROM discharge_detail dd
             WHERE dd.id_discharge = i_discharge;
    
    BEGIN
        IF i_discharge IS NULL
        THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN FALSE;
        END IF;
        ---------------------------------------
        -- obtain disch_reas_dest and the professional that requested the discharge
        g_error := 'OPEN C_DISCHARGE_DEST';
        OPEN c_discharge_dest;
        FETCH c_discharge_dest
            INTO l_disch_reas_dest, l_professional, l_institution, l_software;
        g_found := c_discharge_dest%FOUND;
        CLOSE c_discharge_dest;
    
        IF NOT g_found
           OR l_disch_reas_dest IS NULL
        THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN FALSE;
        END IF;
    
        ---------------------------------------
        -- obtain dti_notes
        g_error := 'OPEN C_DTI_NOTES';
        OPEN c_dti_notes;
        FETCH c_dti_notes
            INTO o_dti_notes;
        g_found := c_dti_notes%FOUND;
        CLOSE c_dti_notes;
    
        IF NOT g_found
        THEN
            o_dti_notes := NULL;
        END IF;
    
        ---------------------------------------
        g_error := 'CALL GET_DISCH_DEST_INST';
        IF NOT get_institution_list(i_lang            => i_lang,
                                    i_prof            => profissional(nvl(l_professional, i_prof.id),
                                                                      nvl(l_institution, i_prof.institution),
                                                                      nvl(l_software, i_prof.software)),
                                    i_discharge_dest  => NULL,
                                    i_disch_reas_dest => l_disch_reas_dest,
                                    o_dest_inst       => o_dest_inst,
                                    o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_INSTITUTION_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns the list of available institution for the specific discharge destination
    * this function must exist because when it's called the discharge is not yet created
    * -- Function for the physician
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  ID_DISCHARGE_DEST  - either i_discharge_dest or i_disch_reas_dest must not be null
    * @param IN   i_disch_reas_dest ID_DISCH_REAS_DEST
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION get_institution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_dest  IN discharge_dest.id_discharge_dest%TYPE,
        i_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE, -- connection table between discharge_reason & discharge_dest
        o_dest_inst       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_discharge_dest discharge_dest.id_discharge_dest%TYPE;
    
        CURSOR c_discharge_dest IS
            SELECT drd.id_discharge_dest
              FROM disch_reas_dest drd
             WHERE drd.id_disch_reas_dest = i_disch_reas_dest
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.flg_active = pk_alert_constant.g_active;
    
    BEGIN
        ---------------------------------------
        IF i_discharge_dest IS NULL
           AND i_disch_reas_dest IS NULL
        THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN FALSE;
        END IF;
    
        ---------------------------------------
        IF i_discharge_dest IS NULL
           AND i_disch_reas_dest IS NOT NULL
        THEN
            g_error := 'OPEN C_DISCHARGE_DEST';
            OPEN c_discharge_dest;
            FETCH c_discharge_dest
                INTO l_discharge_dest;
            g_found := c_discharge_dest%FOUND;
            CLOSE c_discharge_dest;
        
            IF NOT g_found
               OR l_discharge_dest IS NULL
            THEN
                -- in situations where ID_DISCHARGE_DEST of an DISCH_REAS_DEST is null (shouldn’t happen)
                -- then consider the function worked fine
                pk_types.open_my_cursor(o_dest_inst);
                RETURN TRUE;
            END IF;
        ELSIF i_discharge_dest IS NOT NULL
        THEN
            l_discharge_dest := i_discharge_dest;
        END IF;
    
        ---------------------------------------
        g_error := 'OPEN O_DEST_INST';
        OPEN o_dest_inst FOR
        ----------------------------
            SELECT ddi.id_disch_dest_inst, ie.institution_name, ie.work_phone
              FROM disch_dest_inst ddi, institution_ext ie
             WHERE ddi.id_discharge_dest = l_discharge_dest
               AND ddi.id_institution_ext = ie.id_institution_ext
               AND ddi.flg_active = g_yes
               AND ie.flg_available = g_yes
               AND ddi.id_institution IN (i_prof.institution, 0)
               AND ddi.id_software IN (i_prof.software, 0)
            UNION ALL
            ----------------------------
            SELECT -1 id_disch_dest_inst, -- Outra
                   pk_message.get_message(i_lang, 'DISCHARGE_T073') institution_name,
                   NULL work_phone
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_INSTITUTION_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns the list of ramaining institutions not selected in the first instance
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION get_inst_remaining_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_dti_notes OUT discharge_detail.dti_notes%TYPE,
        o_dest_inst OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_dti_notes IS
            SELECT dd.dti_notes
              FROM discharge_detail dd
             WHERE dd.id_discharge = i_discharge;
    
    BEGIN
        IF i_discharge IS NULL
        THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN FALSE;
        END IF;
    
        ---------------------------------------
        -- obtain dti_notes
        g_error := 'OPEN C_DTI_NOTES';
        OPEN c_dti_notes;
        FETCH c_dti_notes
            INTO o_dti_notes;
        g_found := c_dti_notes%FOUND;
        CLOSE c_dti_notes;
    
        IF NOT g_found
        THEN
            o_dti_notes := NULL;
        END IF;
    
        g_error := 'OPEN O_DEST_INST';
        OPEN o_dest_inst FOR
        -------------------------------- remaining
            SELECT ddi.id_disch_dest_inst, ie.institution_name, ie.work_phone
              FROM discharge d, disch_reas_dest drd, disch_dest_inst ddi, episode e, institution_ext ie
             WHERE d.id_discharge = i_discharge
               AND d.id_episode = e.id_episode
               AND d.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_dest = ddi.id_discharge_dest
               AND ddi.id_institution = e.id_institution
               AND ddi.id_software = pk_episode.get_soft_by_epis_type(e.id_epis_type, ddi.id_institution)
               AND ddi.id_institution_ext = ie.id_institution_ext
               AND ddi.flg_active = g_yes
               AND ie.flg_available = g_yes
               AND ddi.id_disch_dest_inst NOT IN
                   (SELECT dti2.id_disch_dest_inst
                      FROM disch_transf_inst dti2
                     WHERE dti2.id_discharge = d.id_discharge)
            UNION ALL
            ---------------------------- Outra
            SELECT -1 id_disch_dest_inst,
                   pk_message.get_message(i_lang, 'DISCHARGE_T073') institution_name,
                   NULL work_phone
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_INST_REMAINING_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns the list of ramaining institutions not selected in the first instance
    * with indication if they where suggested by the social worker
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    16/03/2010
    ********************************************************************************************/
    FUNCTION get_inst_suggested_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_dti_notes OUT discharge_detail.dti_notes%TYPE,
        o_dest_inst OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_dti_notes IS
            SELECT dd.dti_notes
              FROM discharge_detail dd
             WHERE dd.id_discharge = i_discharge;
    
    BEGIN
        IF i_discharge IS NULL
        THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN FALSE;
        END IF;
    
        ---------------------------------------
        -- obtain dti_notes
        g_error := 'OPEN C_DTI_NOTES';
        OPEN c_dti_notes;
        FETCH c_dti_notes
            INTO o_dti_notes;
        g_found := c_dti_notes%FOUND;
        CLOSE c_dti_notes;
    
        IF NOT g_found
        THEN
            o_dti_notes := NULL;
        END IF;
    
        g_error := 'OPEN O_DEST_INST';
        OPEN o_dest_inst FOR
        -------------------------------- suggested
            SELECT decode(dti.flg_type,
                          g_transf_type_free_text,
                          dti.id_disch_dest_inst -- -1
                          * dti.id_disch_transf_inst,
                          dti.id_disch_dest_inst) id_disch_dest_inst,
                   --dti.id_disch_dest_inst,
                   g_yes is_suggested,
                   decode(ie.id_institution_ext, NULL, dti.free_text_inst, ie.institution_name) institution_name,
                   nvl(ie.work_phone, '--') work_phone
              FROM discharge d, disch_transf_inst dti, disch_dest_inst ddi, institution_ext ie
             WHERE d.id_discharge = i_discharge
               AND dti.id_discharge = d.id_discharge
               AND dti.flg_status = g_transf_status_suggested
               AND dti.id_disch_dest_inst = ddi.id_disch_dest_inst(+) -- the suggested institution may be a free_text_inst
               AND ddi.id_institution_ext = ie.id_institution_ext(+)
            UNION ALL
            ---------------------------- remaining
            SELECT ddi.id_disch_dest_inst, g_no is_suggested, ie.institution_name, ie.work_phone
              FROM discharge d, disch_reas_dest drd, disch_dest_inst ddi, episode e, institution_ext ie
             WHERE d.id_discharge = i_discharge
               AND d.id_episode = e.id_episode
               AND d.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_dest = ddi.id_discharge_dest
               AND ddi.id_institution = e.id_institution
               AND ddi.id_software = pk_episode.get_soft_by_epis_type(e.id_epis_type, ddi.id_institution)
               AND ddi.id_institution_ext = ie.id_institution_ext
               AND ddi.flg_active = g_yes
               AND ie.flg_available = g_yes
               AND ddi.id_disch_dest_inst NOT IN
                   (SELECT dti2.id_disch_dest_inst
                      FROM disch_transf_inst dti2
                     WHERE dti2.id_discharge = d.id_discharge)
            UNION ALL
            ---------------------------- Outra
            SELECT -1 id_disch_dest_inst,
                   g_no is_suggested,
                   pk_message.get_message(i_lang, 'DISCHARGE_T073') institution_name,
                   NULL work_phone
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dest_inst);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_INST_REMAINING_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Function to return the list of destination institutions of a Discharge
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    23/02/2010
    ********************************************************************************************/
    FUNCTION get_disch_transf_inst_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_transf_inst       OUT pk_types.cursor_type,
        o_discharge         OUT discharge.id_discharge%TYPE,
        o_flg_inst_transfer OUT discharge_detail.flg_inst_transfer%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_discharge discharge.id_discharge%TYPE;
    
        CURSOR c_epis_disch IS
            SELECT d.id_discharge,
                   decode(d.flg_status,
                          pk_discharge.g_disch_flg_active,
                          g_no,
                          decode(dd.flg_inst_transfer,
                                 NULL,
                                 g_no,
                                 decode(dd.flg_inst_transfer_status,
                                        g_transf_status_concluded,
                                        g_no,
                                        dd.flg_inst_transfer)))
              FROM discharge d, discharge_detail dd
             WHERE d.id_episode = i_episode
               AND d.flg_status IN (pk_discharge.g_disch_flg_active, pk_discharge.g_disch_flg_pend)
               AND d.id_discharge = dd.id_discharge(+)
               AND rownum = 1
             ORDER BY decode(d.flg_status, pk_discharge.g_disch_flg_active, 1, pk_discharge.g_disch_flg_pend, 2);
    
    BEGIN
        -- get the active discharge
        g_error := 'OPEN CURSOR C_EPIS_DISCH';
        OPEN c_epis_disch;
        FETCH c_epis_disch
            INTO l_id_discharge, o_flg_inst_transfer;
        g_found := c_epis_disch%FOUND;
        CLOSE c_epis_disch;
    
        IF g_found
           AND l_id_discharge IS NOT NULL
        THEN
            o_discharge := l_id_discharge;
            -- get list of transfer institutions for that discharge
            g_error := 'OPEN O_TRANSF_INST';
            OPEN o_transf_inst FOR
                SELECT dti.id_disch_transf_inst,
                       decode(dti.id_disch_dest_inst, -1, dti.free_text_inst, ie.institution_name) institution_name,
                       ie.work_phone,
                       dti.notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(dti.id_prof_update, dti.id_prof_create)) prof_responsible,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        nvl(dti.dt_update, dti.dt_create),
                                                        i_prof.institution,
                                                        i_prof.software) hour_last_change,
                       pk_date_utils.dt_chr_tsz(i_lang,
                                                nvl(dti.dt_update, dti.dt_create),
                                                i_prof.institution,
                                                i_prof.software) date_last_change,
                       dti.rank,
                       pk_utils.get_status_string_immediate(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_display_type_icon,
                                                            dti.flg_status,
                                                            NULL,
                                                            NULL,
                                                            g_domain_dti_flg_status,
                                                            NULL,
                                                            decode(pk_sysdomain.get_img(i_lang,
                                                                                        g_domain_dti_flg_status,
                                                                                        dti.flg_status),
                                                                   g_transf_pending_icon,
                                                                   pk_alert_constant.g_color_red,
                                                                   pk_alert_constant.g_color_null)) status,
                       dti.flg_status,
                       decode(dti.notes, NULL, NULL, pk_message.get_message(i_lang, 'COMMON_M097')) with_notes,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        nvl(dti.id_prof_update, dti.id_prof_create),
                                                        nvl(dti.dt_update, dti.dt_create),
                                                        NULL) prof_spec_sign,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(dti.dt_update, dti.dt_create), i_prof) dt,
                       pk_date_utils.date_send_tsz(i_lang, nvl(dti.dt_update, dti.dt_create), i_prof) dt_send
                  FROM disch_transf_inst dti, disch_dest_inst ddi, institution_ext ie
                 WHERE dti.id_discharge = l_id_discharge
                   AND dti.id_disch_dest_inst = ddi.id_disch_dest_inst(+) -- needs to be outher join because of
                   AND ddi.id_institution_ext = ie.id_institution_ext(+) -- free text institutions
                 ORDER BY decode(dti.flg_status,
                                 g_transf_status_pending,
                                 1,
                                 g_transf_status_concluded,
                                 2,
                                 g_transf_status_suggested,
                                 3,
                                 g_transf_status_not_available,
                                 3,
                                 g_transf_status_refused,
                                 4,
                                 g_transf_status_canceled,
                                 5),
                          dti.rank;
            RETURN TRUE;
        ELSE
            -- no discharge found for the selected episode but the function works fine
            o_flg_inst_transfer := g_no;
            pk_types.open_my_cursor(o_transf_inst);
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transf_inst);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_DISCH_TRANSF_INST_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns the last transference state (for doctor transf grid)
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION get_disch_transf_inst_active
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_transf_inst OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_discharge discharge.id_discharge%TYPE;
    
        CURSOR c_epis_disch IS
            SELECT d.id_discharge
              FROM discharge d
             WHERE d.id_episode = i_episode
               AND d.flg_status IN (pk_discharge.g_disch_flg_active, pk_discharge.g_disch_flg_pend)
               AND rownum = 1
             ORDER BY decode(d.flg_status, pk_discharge.g_disch_flg_active, 1, pk_discharge.g_disch_flg_pend, 2);
    
    BEGIN
        -- get the active discharge
        g_error := 'OPEN c_epis_disch';
        OPEN c_epis_disch;
        FETCH c_epis_disch
            INTO l_id_discharge;
        g_found := c_epis_disch%FOUND;
        CLOSE c_epis_disch;
    
        IF g_found
           AND l_id_discharge IS NOT NULL
        THEN
            -- get list of transfer institutions for that discharge
            g_error := 'OPEN O_TRANSF_INST';
            OPEN o_transf_inst FOR
                SELECT dti.id_disch_transf_inst,
                       ie.institution_name,
                       ie.work_phone,
                       dti.notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(dti.id_prof_update, dti.id_prof_create)) prof_responsible,
                       pk_date_utils.date_send_tsz(i_lang, nvl(dti.dt_update, dti.dt_create), i_prof) dt_last_change,
                       dti.flg_status icon_name
                  FROM disch_transf_inst dti, disch_dest_inst ddi, institution_ext ie
                 WHERE dti.id_discharge = l_id_discharge
                   AND dti.id_disch_dest_inst = ddi.id_disch_dest_inst
                   AND ddi.id_institution_ext = ie.id_institution_ext
                   AND rownum = 1
                 ORDER BY decode(dti.flg_status,
                                 g_transf_status_pending,
                                 1,
                                 g_transf_status_concluded,
                                 2,
                                 g_transf_status_not_available,
                                 3,
                                 g_transf_status_refused,
                                 4,
                                 g_transf_status_canceled,
                                 5),
                          dti.rank;
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transf_inst);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_DISCH_TRANSF_INST_ACTIVE',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function updates the institution transfer state 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION update_disch_transf_inst
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_discharge              IN disch_transf_inst.id_discharge%TYPE,
        i_disch_transf_inst      IN disch_transf_inst.id_disch_transf_inst%TYPE,
        i_admitted               IN VARCHAR2, -- Y - Yes; N - No
        i_id_refused_reason      IN disch_transf_inst.id_refused_reason%TYPE,
        i_notes                  IN disch_transf_inst.notes%TYPE,
        i_granted_transportation IN VARCHAR2, -- Y - Yes; N - No
        o_is_last_record         OUT VARCHAR2, -- Y - Yes; N - No 
        o_prof_has_permission    OUT VARCHAR2, -- Y - Yes; N - No
        o_show_alert_message     OUT VARCHAR2, -- Y - show Error
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids                 table_varchar;
        l_rowids_2               table_varchar;
        l_last_disch_transf_inst disch_transf_inst.id_disch_transf_inst%TYPE;
        l_dti_professional       disch_transf_inst.id_prof_create%TYPE;
    
        CURSOR c_last_not_aval_transf IS
            SELECT dt1.id_disch_transf_inst
              FROM disch_transf_inst dt1
             WHERE dt1.id_discharge = i_discharge
               AND dt1.flg_status = g_transf_status_not_available
               AND dt1.rank = (SELECT MIN(dt2.rank)
                                 FROM disch_transf_inst dt2
                                WHERE dt2.id_discharge = dt1.id_discharge
                                  AND dt2.flg_status = dt1.flg_status)
               AND rownum = 1;
    
        CURSOR c_disch_professional IS
            SELECT d.id_prof_med
              FROM discharge d
             WHERE d.id_discharge = i_discharge;
    
        l_dti_flg_status disch_transf_inst.flg_status%TYPE;
        CURSOR c_dti IS
            SELECT dti.flg_status
              FROM disch_transf_inst dti
             WHERE dti.id_disch_transf_inst = i_disch_transf_inst;
    
    BEGIN
        g_sysdate_tstz        := current_timestamp;
        o_is_last_record      := g_no;
        o_prof_has_permission := g_no;
        o_show_alert_message  := g_no;
    
        -------------------------------------------------
        -- verify if the record being changed is in the following states: concluded, refused, canceled
        g_error := 'OPEN c_last_not_aval_transf';
        OPEN c_dti;
        FETCH c_dti
            INTO l_dti_flg_status;
        g_found := c_dti%FOUND;
        CLOSE c_dti;
    
        -- if so, it cannot be changed and an alert message must be shown
        IF g_found
           AND l_dti_flg_status IN (g_transf_status_concluded, g_transf_status_refused, g_transf_status_canceled)
        THEN
            o_show_alert_message := g_yes;
            RETURN TRUE; -- althought a alert message is to be shown the function returns TRUE
        END IF;
    
        -------------------------------------------------
        -- verify if any professional has permissions to create or suggest transfer list
        IF prof_has_permissions(i_lang, i_prof)
        THEN
            o_prof_has_permission := g_yes;
        ELSE
            o_prof_has_permission := g_no;
        END IF;
    
        IF i_disch_transf_inst IS NULL
           OR (i_admitted = g_no AND i_id_refused_reason IS NULL)
        THEN
            RETURN FALSE;
        ELSE
            IF i_admitted = g_no
            THEN
                -- update disch_transf_inst status to "refused"
                g_error := 'TS_DISCH_TRANSF_INST.UPD';
                ts_disch_transf_inst.upd(id_disch_transf_inst_in  => i_disch_transf_inst,
                                         flg_status_in            => g_transf_status_refused,
                                         id_prof_update_in        => i_prof.id,
                                         dt_update_in             => g_sysdate_tstz,
                                         id_refused_reason_in     => i_id_refused_reason,
                                         notes_in                 => i_notes,
                                         flg_granted_transport_in => i_granted_transportation,
                                         rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DISCH_TRANSF_INST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                -- update last "not_available" transference to "pending"
                g_error := 'OPEN c_last_not_aval_transf';
                OPEN c_last_not_aval_transf;
                FETCH c_last_not_aval_transf
                    INTO l_last_disch_transf_inst;
                g_found := c_last_not_aval_transf%FOUND;
                CLOSE c_last_not_aval_transf;
            
                IF g_found
                   AND l_last_disch_transf_inst IS NOT NULL
                THEN
                    g_error := 'TS_DISCH_TRANSF_INST.UPD';
                    ts_disch_transf_inst.upd(id_disch_transf_inst_in => l_last_disch_transf_inst,
                                             flg_status_in           => g_transf_status_pending,
                                             rows_out                => l_rowids_2);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'DISCH_TRANSF_INST',
                                                  i_rowids     => l_rowids_2,
                                                  o_error      => o_error);
                ELSE
                    -- identify it's the last record
                    o_is_last_record := g_yes;
                
                    -- verify if any professional has permissions to create or suggest transfer list
                    IF prof_has_permissions(i_lang, i_prof)
                    THEN
                        o_prof_has_permission := g_yes;
                    ELSE
                        o_prof_has_permission := g_no;
                    END IF;
                
                    -- if last record then delete transf request alert
                    IF NOT delete_generic_alert(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_discharge => i_discharge,
                                                i_sys_alert => g_disch_transf_inst_alert, -- 85
                                                o_error     => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    -- if last record then update_disch_transf_status to Refused
                    IF NOT update_disch_transf_status(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_discharge  => i_discharge,
                                                      i_flg_status => g_transf_status_refused,
                                                      o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            ELSE
                g_error := 'TS_DISCH_TRANSF_INST.UPD';
                -- update disch_transf_inst status to "concluded" (institution accepted the transference)
                ts_disch_transf_inst.upd(id_disch_transf_inst_in  => i_disch_transf_inst,
                                         flg_status_in            => g_transf_status_concluded,
                                         id_prof_update_in        => i_prof.id,
                                         dt_update_in             => g_sysdate_tstz,
                                         notes_in                 => i_notes,
                                         flg_granted_transport_in => i_granted_transportation,
                                         rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DISCH_TRANSF_INST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                -- if accepted then delete transf request alert
                g_error := 'DELETE_GENERIC_ALERT ' || to_char(g_disch_transf_inst_alert);
                IF NOT delete_generic_alert(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_discharge => i_discharge,
                                            i_sys_alert => g_disch_transf_inst_alert, -- 85
                                            o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                -- if accepted then update update_disch_transf_status to Concluded
                IF NOT update_disch_transf_status(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_discharge  => i_discharge,
                                                  i_flg_status => g_transf_status_concluded,
                                                  o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                -- determine the professional that requested the transfer
                g_error := 'OPEN c_dti_professional';
                OPEN c_disch_professional;
                FETCH c_disch_professional
                    INTO l_dti_professional;
                g_found := c_disch_professional%FOUND;
                CLOSE c_disch_professional;
            
                IF g_found
                   AND l_dti_professional IS NOT NULL
                THEN
                    -- create new alert for the physician indicating that the transfer request was accepted
                    g_error := 'CREATE_GENERIC_ALERT ' || to_char(g_concluded_transf_alert);
                    IF NOT create_generic_alert(i_lang,
                                                i_prof,
                                                i_discharge,
                                                g_concluded_transf_alert, -- 86
                                                l_dti_professional,
                                                o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'UPDATE_DISCH_TRANSF_INST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Function to return the institution list creation options, when no more institutions exists in the list:
    * Criar nova lista / Sugerir nova lista / Pedir nova lista
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_transf_inst_options  options list
    * @return                            TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    23/02/2010
    ********************************************************************************************/
    FUNCTION get_transf_inst_options
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_transf_inst_options OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_can_create_list  VARCHAR2(1 CHAR) := g_no;
        l_can_suggest_list VARCHAR2(1 CHAR) := g_no;
    
    BEGIN
        IF prof_can_create_list(i_lang, i_prof)
        THEN
            l_can_create_list := g_yes;
        END IF;
    
        IF prof_can_suggest_list(i_lang, i_prof)
        THEN
            l_can_suggest_list := g_yes;
        END IF;
    
        g_error := 'OPEN o_transf_inst_options';
        OPEN o_transf_inst_options FOR
            SELECT 1 rank,
                   pk_message.get_message(i_lang, g_transf_option_create) option_desc,
                   g_transf_create_flg option_flg
              FROM dual
             WHERE l_can_create_list = g_yes
            UNION ALL
            SELECT 2 rank,
                   pk_message.get_message(i_lang, g_transf_option_sugest) option_desc,
                   g_transf_sugest_flg option_flg
              FROM dual
             WHERE l_can_suggest_list = g_yes
            UNION ALL
            SELECT 3 rank,
                   pk_message.get_message(i_lang, g_transf_option_request) option_desc,
                   g_transf_request_flg option_flg
              FROM dual;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transf_inst_options);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_TRANSF_INST_OPTIONS',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns de DTI detail. Grupos: Dados da instituição, Dados da alta, Dados da transferência
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_disch_dest_inst DTI ID
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION get_disch_transf_inst_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_disch_transf_inst IN disch_transf_inst.id_disch_transf_inst%TYPE,
        o_dti_det           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dti_flg_type disch_transf_inst.flg_type%TYPE;
    
        CURSOR c_dti_type IS
            SELECT dti.flg_type
              FROM disch_transf_inst dti
             WHERE dti.id_disch_transf_inst = i_disch_transf_inst;
    
    BEGIN
    
        g_error := 'OPEN c_dti_type';
        OPEN c_dti_type;
        FETCH c_dti_type
            INTO l_dti_flg_type;
        g_found := c_dti_type%FOUND;
        CLOSE c_dti_type;
    
        IF i_disch_transf_inst IS NOT NULL
           AND g_found
        THEN
            IF l_dti_flg_type = g_transf_type_insitutional
            THEN
                -- external institution
                g_error := 'OPEN O_DTI_DET';
                OPEN o_dti_det FOR
                    SELECT dti.flg_type,
                           ie.institution_name,
                           ie.work_phone,
                           ie.address,
                           ie.location,
                           ie.district,
                           ie.zip_code,
                           pk_translation.get_translation(i_lang, c.code_country) country,
                           -------------------------
                           pk_discharge.get_patient_condition(i_lang,
                                                              i_prof,
                                                              dis.id_discharge,
                                                              dei.id_discharge_reason,
                                                              dd.flg_pat_condition) pat_state,
                           pk_translation.get_translation(i_lang, te.code_transp_entity) transport_needs,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => pk_alert_constant.g_yes) transfer_reasons,
                           dd.notes notes,
                           pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') || ' ' ||
                           pk_date_utils.date_char_tsz(i_lang, dis.dt_med_tstz, i_prof.institution, i_prof.software) || '; ' ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, dis.id_prof_med) reg_data,
                           -------------------------
                           decode(dti.flg_status,
                                  g_transf_status_refused,
                                  g_no,
                                  g_transf_status_concluded,
                                  g_yes,
                                  g_transf_status_canceled,
                                  g_no,
                                  NULL) admitted_flg,
                           decode(dti.flg_status,
                                  g_transf_status_refused,
                                  pk_message.get_message(i_lang, 'COMMON_M023'),
                                  g_transf_status_concluded,
                                  pk_message.get_message(i_lang, 'COMMON_M022'),
                                  g_transf_status_canceled,
                                  pk_message.get_message(i_lang, 'COMMON_M023'),
                                  NULL) admitted_desc,
                           decode(dti.flg_status,
                                  g_transf_status_refused,
                                  pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dti.id_refused_reason),
                                  NULL) refused_reason,
                           dti.notes dti_notes,
                           decode(dti.flg_granted_transport,
                                  g_no,
                                  pk_message.get_message(i_lang, 'COMMON_M023'),
                                  g_yes,
                                  pk_message.get_message(i_lang, 'COMMON_M022')) flg_granted_transport,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') || ' ' ||
                                  pk_date_utils.date_char_tsz(i_lang, dti.dt_update, i_prof.institution, i_prof.software) || '; ' ||
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, dti.id_prof_update)) tranf_data,
                           dd.dti_notes transf_inst_notes,
                           pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') label_reg_data,
                           pk_date_utils.date_char_tsz(i_lang, dis.dt_med_tstz, i_prof.institution, i_prof.software) dt_reg_data,
                           pk_date_utils.date_send_tsz(i_lang, dis.dt_med_tstz, i_prof) dt_send_reg_data,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, dis.id_prof_med) prof_name_reg_data,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, dis.id_prof_med, dis.dt_med_tstz, NULL) prof_spec_reg_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004')) label_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_date_utils.date_char_tsz(i_lang, dti.dt_update, i_prof.institution, i_prof.software)) dt_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_date_utils.date_send_tsz(i_lang, dti.dt_update, i_prof)) dt_send_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, dti.id_prof_update)) prof_name_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   dti.id_prof_update,
                                                                   dti.dt_update,
                                                                   NULL)) prof_spec_tranf_data
                      FROM disch_transf_inst dti,
                           disch_dest_inst   ddi,
                           institution_ext   ie,
                           country           c,
                           -------------------------
                           discharge                 dis,
                           discharge_detail          dd,
                           disch_rea_transp_ent_inst dei,
                           transp_ent_inst           tei,
                           transp_entity             te,
                           -------------------------
                           diagnosis      d,
                           epis_diagnosis ed
                     WHERE dti.id_disch_transf_inst = i_disch_transf_inst
                       AND dti.id_disch_dest_inst = ddi.id_disch_dest_inst
                       AND ddi.id_institution_ext = ie.id_institution_ext
                       AND ie.id_country = c.id_country(+)
                          -------------------------
                       AND dis.id_discharge = dti.id_discharge
                       AND dd.id_discharge = dti.id_discharge
                       AND dd.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
                       AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
                       AND tei.id_transp_entity = te.id_transp_entity(+)
                          -------------------------
                       AND dd.id_transfer_diagnosis = d.id_diagnosis(+)
                       AND dd.id_epis_diagnosis = ed.id_epis_diagnosis(+);
            ELSIF l_dti_flg_type = g_transf_type_free_text
            THEN
                -- free text institution
                g_error := 'OPEN O_DTI_DET';
                OPEN o_dti_det FOR
                    SELECT dti.flg_type,
                           dti.free_text_inst,
                           -------------------------
                           pk_discharge.get_patient_condition(i_lang,
                                                              i_prof,
                                                              dis.id_discharge,
                                                              dei.id_discharge_reason,
                                                              dd.flg_pat_condition) pat_state,
                           pk_translation.get_translation(i_lang, te.code_transp_entity) transport_needs,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => pk_alert_constant.g_yes) transfer_reasons,
                           dd.notes notes,
                           pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') || ' ' ||
                           pk_date_utils.date_char_tsz(i_lang, dis.dt_med_tstz, i_prof.institution, i_prof.software) || '; ' ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, dis.id_prof_med) reg_data,
                           -------------------------
                           decode(dti.flg_status,
                                  g_transf_status_refused,
                                  g_no,
                                  g_transf_status_concluded,
                                  g_yes,
                                  g_transf_status_canceled,
                                  g_no,
                                  NULL) admitted_flg,
                           decode(dti.flg_status,
                                  g_transf_status_refused,
                                  pk_message.get_message(i_lang, 'COMMON_M023'),
                                  g_transf_status_concluded,
                                  pk_message.get_message(i_lang, 'COMMON_M022'),
                                  g_transf_status_canceled,
                                  pk_message.get_message(i_lang, 'COMMON_M023'),
                                  NULL) admitted_desc,
                           decode(dti.flg_status,
                                  g_transf_status_refused,
                                  pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dti.id_refused_reason),
                                  NULL) refused_reason,
                           dti.notes dti_notes,
                           decode(dti.flg_granted_transport,
                                  g_no,
                                  pk_message.get_message(i_lang, 'COMMON_M023'),
                                  g_yes,
                                  pk_message.get_message(i_lang, 'COMMON_M022')) flg_granted_transport,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') || ' ' ||
                                  pk_date_utils.date_char_tsz(i_lang, dti.dt_update, i_prof.institution, i_prof.software) || '; ' ||
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, dti.id_prof_update)) tranf_data,
                           dd.dti_notes transf_inst_notes,
                           
                           pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') label_reg_data,
                           pk_date_utils.date_char_tsz(i_lang, dis.dt_med_tstz, i_prof.institution, i_prof.software) dt_reg_data,
                           pk_date_utils.date_send_tsz(i_lang, dis.dt_med_tstz, i_prof) dt_send_reg_data,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, dis.id_prof_med) prof_name_reg_data,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, dis.id_prof_med, dis.dt_med_tstz, NULL) prof_spec_reg_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004')) label_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_date_utils.date_char_tsz(i_lang, dti.dt_update, i_prof.institution, i_prof.software)) dt_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_date_utils.date_send_tsz(i_lang, dti.dt_update, i_prof)) dt_send_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, dti.id_prof_update)) prof_name_tranf_data,
                           decode(dti.id_prof_update,
                                  NULL,
                                  NULL,
                                  pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   dti.id_prof_update,
                                                                   dti.dt_update,
                                                                   NULL)) prof_spec_tranf_data
                      FROM disch_transf_inst dti,
                           -------------------------
                           discharge                 dis,
                           discharge_detail          dd,
                           disch_rea_transp_ent_inst dei,
                           transp_ent_inst           tei,
                           transp_entity             te,
                           -------------------------
                           diagnosis      d,
                           epis_diagnosis ed
                     WHERE dti.id_disch_transf_inst = i_disch_transf_inst
                          -------------------------
                       AND dis.id_discharge = dti.id_discharge
                       AND dd.id_discharge = dti.id_discharge
                       AND dd.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
                       AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
                       AND tei.id_transp_entity = te.id_transp_entity(+)
                          -------------------------
                       AND dd.id_transfer_diagnosis = d.id_diagnosis(+)
                       AND dd.id_epis_diagnosis = ed.id_epis_diagnosis(+);
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dti_det);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_DISCH_TRANSF_INST_DETAIL',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function returns de DTI detail: Dados da instituição / Motivo da transferência / Dados da transferência
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_disch_dest_inst DTI ID
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION get_inst_admission_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_disch_transf_inst IN disch_transf_inst.id_disch_transf_inst%TYPE,
        o_dti_det           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dti_flg_type disch_transf_inst.flg_type%TYPE;
    
        CURSOR c_dti_type IS
            SELECT dti.flg_type
              FROM disch_transf_inst dti
             WHERE dti.id_disch_transf_inst = i_disch_transf_inst;
    
    BEGIN
    
        g_error := 'OPEN c_dti_type';
        OPEN c_dti_type;
        FETCH c_dti_type
            INTO l_dti_flg_type;
        g_found := c_dti_type%FOUND;
        CLOSE c_dti_type;
    
        IF i_disch_transf_inst IS NOT NULL
           AND g_found
        THEN
            IF l_dti_flg_type = g_transf_type_insitutional
            THEN
                -- external institution
                g_error := 'OPEN O_DTI_DET';
                OPEN o_dti_det FOR
                    SELECT dti.flg_type,
                           ie.institution_name,
                           ie.work_phone,
                           ie.address,
                           ie.location,
                           ie.district,
                           ie.zip_code,
                           pk_translation.get_translation(i_lang, c.code_country) country,
                           -------------------------
                           pk_discharge.get_patient_condition(i_lang,
                                                              i_prof,
                                                              dis.id_discharge,
                                                              dei.id_discharge_reason,
                                                              dd.flg_pat_condition) pat_state,
                           pk_translation.get_translation(i_lang, te.code_transp_entity) transport_needs,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => pk_alert_constant.g_yes) transfer_reasons,
                           dd.notes notes,
                           pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') || ' ' ||
                           pk_date_utils.date_char_tsz(i_lang, dis.dt_med_tstz, i_prof.institution, i_prof.software) || '; ' ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, dis.id_prof_med) reg_data,
                           decode(te.code_transp_entity,
                                  NULL,
                                  'N',
                                  decode(pk_translation.get_translation(i_lang, te.code_transp_entity),
                                         pk_message.get_message(i_lang, 'COMMON_M023'),
                                         'N',
                                         'Y')) need_transport,
                           dd.dti_notes transf_inst_notes
                      FROM disch_transf_inst dti,
                           disch_dest_inst   ddi,
                           institution_ext   ie,
                           country           c,
                           -------------------------
                           discharge                 dis,
                           discharge_detail          dd,
                           disch_rea_transp_ent_inst dei,
                           transp_ent_inst           tei,
                           transp_entity             te,
                           -------------------------
                           diagnosis      d,
                           epis_diagnosis ed
                     WHERE dti.id_disch_transf_inst = i_disch_transf_inst
                       AND dti.id_disch_dest_inst = ddi.id_disch_dest_inst
                       AND ddi.id_institution_ext = ie.id_institution_ext
                       AND ie.id_country = c.id_country(+)
                          -------------------------
                       AND dis.id_discharge = dti.id_discharge
                       AND dd.id_discharge = dti.id_discharge
                       AND dd.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
                       AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
                       AND tei.id_transp_entity = te.id_transp_entity(+)
                          -------------------------
                       AND dd.id_transfer_diagnosis = d.id_diagnosis(+)
                       AND dd.id_epis_diagnosis = ed.id_epis_diagnosis(+);
            ELSIF l_dti_flg_type = g_transf_type_free_text
            THEN
                -- free text institution
                g_error := 'OPEN O_DTI_DET';
                OPEN o_dti_det FOR
                    SELECT dti.flg_type,
                           dti.free_text_inst,
                           -------------------------
                           pk_discharge.get_patient_condition(i_lang,
                                                              i_prof,
                                                              dis.id_discharge,
                                                              dei.id_discharge_reason,
                                                              dd.flg_pat_condition) pat_state,
                           pk_translation.get_translation(i_lang, te.code_transp_entity) transport_needs,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => NULL,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => (SELECT desc_epis_diagnosis
                                                                                  FROM epis_diagnosis
                                                                                 WHERE dis.id_episode = id_episode
                                                                                   AND d.id_diagnosis = id_diagnosis
                                                                                   AND flg_type = 'D' -- final
                                                                                   AND rownum = 1),
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => pk_alert_constant.g_yes) transfer_reasons,
                           dd.notes notes,
                           pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M004') || ' ' ||
                           pk_date_utils.date_char_tsz(i_lang, dis.dt_med_tstz, i_prof.institution, i_prof.software) || '; ' ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, dis.id_prof_med) reg_data,
                           decode(te.code_transp_entity,
                                  NULL,
                                  'N',
                                  decode(pk_translation.get_translation(i_lang, te.code_transp_entity),
                                         pk_message.get_message(i_lang, 'COMMON_M023'),
                                         'N',
                                         'Y')) need_transport,
                           dd.dti_notes transf_inst_notes
                      FROM disch_transf_inst dti,
                           -------------------------
                           discharge_detail          dd,
                           disch_rea_transp_ent_inst dei,
                           transp_ent_inst           tei,
                           transp_entity             te,
                           -------------------------
                           diagnosis d,
                           discharge dis
                     WHERE dti.id_disch_transf_inst = i_disch_transf_inst
                          -------------------------
                       AND dis.id_discharge = dti.id_discharge
                       AND dd.id_discharge = dti.id_discharge
                       AND dd.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
                       AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
                       AND tei.id_transp_entity = te.id_transp_entity(+)
                          -------------------------
                       AND dd.id_transfer_diagnosis = d.id_diagnosis(+);
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dti_det);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'GET_INST_ADMISSION_DETAIL',
                                                     o_error);
    END;

    /********************************************************************************************
    *  Create discharge transference alert
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Episode ID
    * @param IN   i_sys_alert       Alert ID
    * @param IN   i_prof_id         Professional to whom this alert is targeted
    *
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    24/02/2010
    ********************************************************************************************/
    FUNCTION create_generic_alert
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_prof_id   IN professional.id_professional%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_id_episode      episode.id_episode%TYPE;
        l_dt_discharge    discharge.dt_med_tstz%TYPE;
        l_id_visit        visit.id_visit%TYPE;
    
        CURSOR c_epis_disch IS
            SELECT d.id_episode, nvl(d.dt_med_tstz, current_timestamp), e.id_visit
              FROM discharge d, episode e
             WHERE d.id_discharge = i_discharge
               AND d.id_episode = e.id_episode
               AND d.flg_status IN (pk_discharge.g_disch_flg_active, pk_discharge.g_disch_flg_pend)
               AND rownum = 1
             ORDER BY decode(d.flg_status, pk_discharge.g_disch_flg_active, 1, pk_discharge.g_disch_flg_pend, 2);
    
    BEGIN
        -- get the active discharge
        g_error := 'OPEN CURSOR C_EPIS_DISCH';
        OPEN c_epis_disch;
        FETCH c_epis_disch
            INTO l_id_episode, l_dt_discharge, l_id_visit;
        g_found := c_epis_disch%FOUND;
        CLOSE c_epis_disch;
    
        IF l_id_episode IS NOT NULL
           AND g_found
        THEN
            --new alert event - generic attributes:
            l_alert_event_row.id_professional := nvl(i_prof_id, i_prof.id);
            l_alert_event_row.id_software     := i_prof.software;
            l_alert_event_row.id_institution  := i_prof.institution;
            l_alert_event_row.id_episode      := l_id_episode;
            l_alert_event_row.id_patient      := pk_episode.get_id_patient(l_id_episode);
            l_alert_event_row.id_record       := i_discharge;
            --l_alert_event_row.dt_record       := l_dt_discharge;
            l_alert_event_row.dt_record    := current_timestamp;
            l_alert_event_row.id_sys_alert := i_sys_alert;
            l_alert_event_row.id_visit     := l_id_visit;
        
            g_error := 'PK_ALERTS.INSERT_SYS_ALERT_EVENT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'CREATE_GENERIC_ALERT',
                                                     o_error);
    END;

    /********************************************************************************************
    *  Delete discharge transference alert
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Episode ID
    * @param IN   i_sys_alert       Alert ID
    *
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    24/02/2010
    ********************************************************************************************/
    FUNCTION delete_generic_alert
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_id_episode      episode.id_episode%TYPE;
    
        CURSOR c_episode IS
            SELECT d.id_episode
              FROM discharge d
             WHERE d.id_discharge = i_discharge;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_id_episode;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
    
        IF l_id_episode IS NOT NULL
           AND g_found
        THEN
            l_alert_event_row.id_episode   := l_id_episode;
            l_alert_event_row.id_record    := i_discharge;
            l_alert_event_row.id_sys_alert := i_sys_alert;
        
            g_error := 'PK_ALERTS.DELETE_SYS_ALERT_EVENT';
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'DELETE_GENERIC_ALERT',
                                                     o_error);
    END;

    /********************************************************************************************
    *  verifies is a certain event exists
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Episode ID
    * @param IN   i_sys_alert       Alert ID
    *
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    24/02/2010
    ********************************************************************************************/
    FUNCTION exists_generic_alert
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE
    ) RETURN BOOLEAN IS
    
        l_error           t_error_out;
        l_sys_alert_event sys_alert_event.id_sys_alert_event%TYPE;
    
        CURSOR c_sys_alert IS
            SELECT sae.id_sys_alert_event
              FROM sys_alert_event sae
             WHERE sae.id_record = i_discharge
               AND sae.id_sys_alert = i_sys_alert;
    
    BEGIN
        g_error := 'OPEN CURSOR C_SYS_ALERT';
        OPEN c_sys_alert;
        FETCH c_sys_alert
            INTO l_sys_alert_event;
        g_found := c_sys_alert%FOUND;
        CLOSE c_sys_alert;
    
        IF l_sys_alert_event IS NOT NULL
           AND g_found
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'EXISTS_GENERIC_ALERT',
                                                     l_error);
    END;

    /********************************************************************************************
    *  Determines if the professional has permission to create a transference list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    10/03/2010
    ********************************************************************************************/
    FUNCTION prof_can_create_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
    
        l_error          t_error_out;
        l_id_category    category.id_category%TYPE;
        g_dti_permission sys_config.id_sys_config%TYPE;
    
    BEGIN
        g_error       := 'PK_PROF_UTILS.GET_ID_CATEGORY';
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        -- select sys_config type
        IF l_id_category = g_prof_cat_social_worker
        THEN
            g_dti_permission := g_dti_create_social_worker; -- Assistente Social
        ELSIF l_id_category = g_prof_cat_nurse
        THEN
            g_dti_permission := g_dti_create_nurse; -- Enfermeiro
        ELSIF l_id_category = g_prof_cat_registrar
        THEN
            g_dti_permission := g_dti_create_registrar; -- Administrativo
        ELSE
            g_dti_permission := NULL;
        END IF;
    
        RETURN TRUE; -- para remover
    
        -- get sys_config value
        g_error := 'PK_SYSCONFIG.GET_CONFIG';
        IF pk_sysconfig.get_config(g_dti_permission, i_prof) = g_yes
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'PROF_CAN_CREATE_LIST',
                                                     l_error);
    END;

    /********************************************************************************************
    *  Determines if the professional has permission to suggest a transference list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    10/03/2010
    ********************************************************************************************/
    FUNCTION prof_can_suggest_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
    
        l_error          t_error_out;
        l_id_category    category.id_category%TYPE;
        g_dti_permission sys_config.id_sys_config%TYPE;
    
    BEGIN
        g_error       := 'PK_PROF_UTILS.GET_ID_CATEGORY';
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        -- select sys_config type
        IF l_id_category = g_prof_cat_social_worker
        THEN
            g_dti_permission := g_dti_suggest_social_worker; -- Assistente Social
        ELSIF l_id_category = g_prof_cat_nurse
        THEN
            g_dti_permission := g_dti_suggest_nurse; -- Enfermeiro
        ELSIF l_id_category = g_prof_cat_registrar
        THEN
            g_dti_permission := g_dti_suggest_registrar; -- Administrativo
        ELSE
            g_dti_permission := NULL;
        END IF;
    
        RETURN TRUE; -- para remover
    
        -- get sys_config value
        g_error := 'PK_SYSCONFIG.GET_CONFIG';
        IF pk_sysconfig.get_config(g_dti_permission, i_prof) = g_yes
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'PROF_CAN_SUGGEST_LIST',
                                                     l_error);
    END;

    /********************************************************************************************
    *  Determines if any professional has permissions to create or suggest transfer list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    12/03/2010
    ********************************************************************************************/
    FUNCTION prof_has_permissions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
    
        l_error                      t_error_out;
        l_dti_sys_config_permissions table_varchar := table_varchar(g_dti_create_registrar,
                                                                    g_dti_create_nurse,
                                                                    g_dti_create_social_worker,
                                                                    g_dti_suggest_registrar,
                                                                    g_dti_suggest_nurse,
                                                                    g_dti_suggest_social_worker);
    
    BEGIN
    
        FOR i IN l_dti_sys_config_permissions.first .. l_dti_sys_config_permissions.last
        LOOP
            g_error := 'PK_SYSCONFIG.GET_CONFIG #' || to_char(i);
            IF pk_sysconfig.get_config(l_dti_sys_config_permissions(i), i_prof) = g_yes
            THEN
                RETURN TRUE;
            END IF;
        END LOOP;
    
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'PROF_HAS_PERMISSIONS',
                                                     l_error);
    END;

    /********************************************************************************************
    *  Determines if any professional has permissions to create a transfer list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    12/03/2010
    ********************************************************************************************/
    FUNCTION prof_has_create_permissions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
    
        l_error                      t_error_out;
        l_dti_sys_config_permissions table_varchar := table_varchar(g_dti_create_registrar,
                                                                    g_dti_create_nurse,
                                                                    g_dti_create_social_worker);
    
    BEGIN
    
        FOR i IN l_dti_sys_config_permissions.first .. l_dti_sys_config_permissions.last
        LOOP
            g_error := 'PK_SYSCONFIG.GET_CONFIG #' || to_char(i);
            IF pk_sysconfig.get_config(l_dti_sys_config_permissions(i), i_prof) = g_yes
            THEN
                RETURN TRUE;
            END IF;
        END LOOP;
    
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'prof_has_create_permissions',
                                                     l_error);
    END;

    /********************************************************************************************
    * Function insert into DISCH_TRANSF_INST a fixed institution resulted from a discharge without institution validation
    * this function is called:
    *      - when a physician makes a discharge without institution validation 
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_inst_name          institution name
    *
    * @return                       TRUE if destination institution inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    29/04/2010
    ********************************************************************************************/
    FUNCTION set_dti_stated_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_inst_name      IN disch_transf_inst.free_text_inst%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT set_dti_stated_inst(i_lang      => i_lang,
                                   i_prof      => i_prof,
                                   i_discharge => i_discharge,
                                   i_inst_name => i_inst_name,
                                   o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- update id_epis_diagnosis associated with the discharge
        IF NOT set_dti_epis_diagnosis(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_discharge      => i_discharge,
                                      i_epis_diagnosis => i_epis_diagnosis,
                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_STATED_INST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Function insert into DISCH_TRANSF_INST a fixed institution resulted from a discharge without institution validation
    * this function is called:
    *      - when a physician makes a discharge without institution validation 
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_inst_name          institution name
    *
    * @return                       TRUE if destination institution inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    29/04/2010
    ********************************************************************************************/
    FUNCTION set_dti_stated_inst
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
    
    BEGIN
        IF i_discharge IS NOT NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        
            -- set disch_transf_status to concluded
            IF NOT update_disch_transf_status(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_discharge  => i_discharge,
                                              i_flg_status => g_transf_status_concluded,
                                              o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- save discharge institution name
            IF i_inst_name IS NOT NULL
            THEN
                g_error := 'TS_DISCH_TRANSF_INST.INS';
                ts_disch_transf_inst.ins(id_disch_transf_inst_in => ts_disch_transf_inst.next_key,
                                         id_discharge_in         => i_discharge,
                                         id_disch_dest_inst_in   => -1, -- although the institution may be selected from the list, is always recorded as free text
                                         rank_in                 => 1,
                                         flg_status_in           => g_transf_status_concluded,
                                         id_prof_create_in       => i_prof.id,
                                         dt_create_in            => g_sysdate_tstz,
                                         flg_type_in             => g_transf_type_free_text,
                                         free_text_inst_in       => i_inst_name,
                                         rows_out                => l_rowids);
            
                g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT DISCH_TRANSF_INST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DISCH_TRANSF_INST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_STATED_INST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Function insert updates discharhe_detail with the id_epis_diagnosis 
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_epis_diagnosis     Epis diagnosis ID
    *
    * @return                       TRUE if destination institution inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    29/07/2010
    ********************************************************************************************/
    FUNCTION set_dti_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_epis_diagnosis IS NOT NULL
        THEN
            UPDATE discharge_detail dd
               SET dd.id_epis_diagnosis = i_epis_diagnosis
             WHERE dd.id_discharge = i_discharge;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_EPIS_DIAGNOSIS',
                                                     o_error);
    END;

    /********************************************************************************************
    * Function insert into DISCH_TRANSF_INST listed destination institutions
    * this function is called:
    *      - when a physician creates a institution list
    *      - after requestin for a social worker to create a list (request_other_prof_create_list)
    *              the social worker analyses the request and creates a list
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_disch_dest_inst    table with destination institutions ID's
    * @param IN   i_disch_rank         rank of destination institutions ID's
    * @param IN   i_other_inst_name    institution name when "other" is selected
    * @param OUT  o_show_alert_message if the list was already created then show alert message
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    22/02/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_discharge          IN discharge.id_discharge%TYPE,
        i_disch_dest_inst    IN table_number,
        i_disch_rank         IN table_number,
        i_other_inst_name    IN disch_transf_inst.free_text_inst%TYPE,
        i_epis_diagnosis     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_dti_notes          IN discharge_detail.dti_notes%TYPE,
        o_show_alert_message OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_has_inserted      BOOLEAN := FALSE;
        l_rowids            table_varchar;
        l_transf_type       disch_transf_inst.flg_type%TYPE;
        l_return            BOOLEAN;
        l_disch_transf_inst disch_transf_inst.id_disch_transf_inst%TYPE;
    
        CURSOR c_dti IS
            SELECT dti.id_disch_transf_inst
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge
               AND rownum = 1;
    
    BEGIN
        -------------------------------------------------
        -- verify if a list is already defined
        g_error := 'OPEN C_DTI';
        OPEN c_dti;
        FETCH c_dti
            INTO l_disch_transf_inst;
        g_found := c_dti%FOUND;
        CLOSE c_dti;
    
        -- if so, an alert message must be shown
        IF g_found
           OR l_disch_transf_inst IS NOT NULL
        THEN
            o_show_alert_message := g_yes;
            RETURN TRUE; -- althought a alert message is to be shown the function returns TRUE
        END IF;
    
        IF i_disch_dest_inst.count = 0
           AND i_disch_rank.count = 0
           AND i_other_inst_name IS NULL
        THEN
            RETURN TRUE;
        END IF;
        -------------------------------------------------
        -- insert / update the institutions list
        IF set_dti_list(i_lang            => i_lang,
                        i_prof            => i_prof,
                        i_discharge       => i_discharge,
                        i_disch_dest_inst => i_disch_dest_inst,
                        i_disch_rank      => i_disch_rank,
                        i_other_inst_name => i_other_inst_name,
                        i_flg_status      => g_transf_status_not_available,
                        i_dti_notes       => i_dti_notes,
                        o_error           => o_error)
        THEN
            o_show_alert_message := g_no;
        
            IF exists_generic_alert(i_lang, i_prof, i_discharge, g_other_prof_transf_list_alert) -- 89
            THEN
                -- alert 89 exists meaning the physician requested social work to create a list
                -- necessary to delete the alert since the function set_dti_list created the list
                g_error := 'DELETE_GENERIC_ALERT ' || to_char(g_other_prof_transf_list_alert);
                IF NOT delete_generic_alert(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_discharge => i_discharge,
                                            i_sys_alert => g_other_prof_transf_list_alert, -- 89
                                            o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                -- alert 89 does not exists so the request was made by the physician
                -- create alert 85 for the social work to be notified of the new request
                g_error := 'CREATE_GENERIC_ALERT ' || to_char(g_disch_transf_inst_alert);
                IF NOT create_generic_alert(i_lang,
                                            i_prof,
                                            i_discharge,
                                            g_disch_transf_inst_alert, -- 85
                                            NULL,
                                            o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- update_disch_transf_status to Pending
            IF NOT update_disch_transf_status(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_discharge  => i_discharge,
                                              i_flg_status => g_transf_status_pending,
                                              o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- update id_epis_diagnosis associated with the discharge
            IF NOT set_dti_epis_diagnosis(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_discharge      => i_discharge,
                                          i_epis_diagnosis => i_epis_diagnosis,
                                          o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_NEW_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Social Worker (or other professional with creation permission) suggests a new institution list
    * for physician approval
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list_suggested
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dti_professional disch_transf_inst.id_prof_create%TYPE;
    
        CURSOR c_disch_professional IS
            SELECT d.id_prof_med
              FROM discharge d
             WHERE d.id_discharge = i_discharge;
    
    BEGIN
    
        -------------------------------------------------------------------------
        -- insert / update the institutions list
        IF set_dti_list(i_lang            => i_lang,
                        i_prof            => i_prof,
                        i_discharge       => i_discharge,
                        i_disch_dest_inst => i_disch_dest_inst,
                        i_disch_rank      => i_disch_rank,
                        i_other_inst_name => i_other_inst_name,
                        i_flg_status      => g_transf_status_suggested,
                        i_dti_notes       => i_dti_notes,
                        o_error           => o_error)
        THEN
            -- if accepted then update update_disch_transf_status to suggested
            IF NOT update_disch_transf_status(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_discharge  => i_discharge,
                                              i_flg_status => g_transf_status_suggested,
                                              o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- determine the professional responsible for the discharge
            g_error := 'OPEN c_dti_professional';
            OPEN c_disch_professional;
            FETCH c_disch_professional
                INTO l_dti_professional;
            g_found := c_disch_professional%FOUND;
            CLOSE c_disch_professional;
        
            -- create new alert for the physician responsible for the discharge indicating a new list was suggested
            g_error := 'CREATE_GENERIC_ALERT ' || to_char(g_suggested_transf_alert);
            IF NOT create_generic_alert(i_lang,
                                        i_prof,
                                        i_discharge,
                                        g_suggested_transf_alert, -- 87
                                        l_dti_professional,
                                        o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_NEW_LIST_SUGGESTED',
                                                     o_error);
    END;

    /********************************************************************************************
    * Social Worker (or other professional with creation permission) creates a new institutions list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list_created
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -------------------------------------------------------------------------
        -- insert / update the institutions list
        IF NOT set_dti_list(i_lang            => i_lang,
                            i_prof            => i_prof,
                            i_discharge       => i_discharge,
                            i_disch_dest_inst => i_disch_dest_inst,
                            i_disch_rank      => i_disch_rank,
                            i_other_inst_name => i_other_inst_name,
                            i_flg_status      => g_transf_status_not_available,
                            i_dti_notes       => i_dti_notes,
                            o_error           => o_error)
        THEN
            RETURN FALSE;
        ELSE
            -- update_disch_transf_status to Pending
            IF NOT update_disch_transf_status(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_discharge  => i_discharge,
                                              i_flg_status => g_transf_status_pending,
                                              o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_NEW_LIST_CREATED',
                                                     o_error);
    END;

    /********************************************************************************************
    * After a request from the social worker the physician creates a new list
    * -- This is a physician function!
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list_requested
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_alert_list table_number;
        l_rowids          table_varchar;
    
        CURSOR c_alert_identification IS
            SELECT sae.id_sys_alert
              FROM sys_alert_event sae
             WHERE sae.id_record = i_discharge
               AND sae.id_sys_alert IN (g_concluded_transf_alert, g_suggested_transf_alert, g_requested_transf_alert)
               AND sae.id_professional = i_prof.id
               AND sae.flg_visible = g_yes;
    
        CURSOR c_dti_suggested IS
            SELECT dti.id_disch_transf_inst
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge
               AND dti.flg_status = g_transf_status_suggested;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        -- necessário detectar que tipo de alerta gerou a posterior chamada à função
        -- se foi um pedido de lista ou sugestão de nova lista
        -- a função chamada é a mesma (esta) como resultado dos dois alertas
    
        -- cleans all alerts related to discharge transference for this discharge and professional 
        g_error := 'OPEN C_ALERT_IDENTIFICATION';
        OPEN c_alert_identification;
        FETCH c_alert_identification BULK COLLECT
            INTO l_prof_alert_list;
        CLOSE c_alert_identification;
    
        IF l_prof_alert_list IS NOT NULL
           AND l_prof_alert_list.count != 0
        THEN
            FOR i IN l_prof_alert_list.first .. l_prof_alert_list.last
            LOOP
                IF NOT delete_generic_alert(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_discharge => i_discharge,
                                            i_sys_alert => l_prof_alert_list(i),
                                            o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
        -------------------------------------------------------------------------
        -- calls main list creation
        IF NOT set_dti_list(i_lang            => i_lang,
                            i_prof            => i_prof,
                            i_discharge       => i_discharge,
                            i_disch_dest_inst => i_disch_dest_inst,
                            i_disch_rank      => i_disch_rank,
                            i_other_inst_name => i_other_inst_name,
                            i_flg_status      => g_transf_status_not_available,
                            i_dti_notes       => i_dti_notes,
                            o_error           => o_error)
        THEN
            RETURN FALSE;
        ELSE
            -- if list succesfully created/updated, then update (to canceled) those records still with suggested state
            g_error := 'LOOP SUGGESTED DTI';
            FOR r_dti_suggested IN c_dti_suggested
            LOOP
                ts_disch_transf_inst.upd(id_disch_transf_inst_in => r_dti_suggested.id_disch_transf_inst,
                                         flg_status_in           => g_transf_status_canceled,
                                         id_prof_update_in       => i_prof.id,
                                         dt_update_in            => g_sysdate_tstz,
                                         rows_out                => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DISCH_TRANSF_INST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END LOOP;
        
            -- update_disch_transf_status to Pending
            IF NOT update_disch_transf_status(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_discharge  => i_discharge,
                                              i_flg_status => g_transf_status_pending,
                                              o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- create alert 85 for the social work to be notified of the new request
            g_error := 'CREATE_GENERIC_ALERT ' || to_char(g_disch_transf_inst_alert);
            IF NOT create_generic_alert(i_lang,
                                        i_prof,
                                        i_discharge,
                                        g_disch_transf_inst_alert, -- 85
                                        NULL,
                                        o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_NEW_LIST_REQUESTED',
                                                     o_error);
    END;

    /********************************************************************************************
    * Generic function to insert discharge institutions (called by the other functions)
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    * @param IN   i_flg_status      status of the inserted records (of the discharge institutions)
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_flg_status      IN disch_transf_inst.flg_status%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_has_inserted BOOLEAN := FALSE;
        l_has_updated  BOOLEAN := FALSE;
        l_rowids       table_varchar;
        l_rowids_upd   table_varchar;
        l_transf_type  disch_transf_inst.flg_type%TYPE;
        l_return       BOOLEAN;
        l_pending_dti  disch_transf_inst.id_disch_transf_inst%TYPE;
        l_max_rank     disch_transf_inst.rank%TYPE;
        l_update_dti   NUMBER := 0;
    
        CURSOR c_has_pending_dti IS
            SELECT dti.id_disch_transf_inst
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge
               AND dti.flg_status IN (g_transf_status_pending, g_transf_status_not_available)
               AND rownum = 1;
    
        CURSOR c_mac_rank IS
            SELECT MAX(dti.rank)
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge;
    
        l_id_dti             disch_transf_inst.id_disch_transf_inst%TYPE;
        l_id_disch_dest_inst disch_dest_inst.id_disch_dest_inst%TYPE;
    
        CURSOR c_suggested_dti(id_ddi IN disch_dest_inst.id_disch_dest_inst%TYPE) IS
            SELECT dti.id_disch_transf_inst
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge
               AND dti.flg_status = g_transf_status_suggested
               AND dti.id_disch_dest_inst = id_ddi
               AND rownum = 1;
    
        CURSOR c_free_t_suggested_dti(id_dti IN disch_transf_inst.id_disch_transf_inst%TYPE) IS
            SELECT dti.id_disch_transf_inst
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge
               AND dti.flg_status = g_transf_status_suggested
               AND dti.id_disch_transf_inst = id_dti * -1
               AND rownum = 1;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_disch_dest_inst.count = 0
           OR i_disch_rank.count = 0
           OR i_discharge IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        -------------------------------------------------------------------------
        -- determine if there's still records with "g_transf_status_pending" or "g_transf_status_not_available" status
        g_error := 'OPEN c_dti_professional';
        OPEN c_has_pending_dti;
        FETCH c_has_pending_dti
            INTO l_pending_dti;
        g_found := c_has_pending_dti%FOUND;
        CLOSE c_has_pending_dti;
    
        IF g_found
        THEN
            RETURN FALSE;
        END IF;
    
        -------------------------------------------------------------------------
        -- determine the maximum rank num associated with the list
        g_error := 'OPEN c_dti_professional';
        OPEN c_mac_rank;
        FETCH c_mac_rank
            INTO l_max_rank;
        g_found := c_mac_rank%FOUND;
        CLOSE c_mac_rank;
    
        IF NOT g_found
           OR l_max_rank IS NULL
        THEN
            l_max_rank := 0;
        END IF;
    
        -------------------------------------------------------------------------
        -- update dti_notes in the discharge_detail record (either dti_notes is null or not)
        UPDATE discharge_detail dd
           SET dd.dti_notes = i_dti_notes
         WHERE dd.id_discharge = i_discharge;
    
        -------------------------------------------------------------------------
        -- insert into DISCH_TRANSF_INST listed destination institutions
        FOR i IN i_disch_dest_inst.first .. i_disch_dest_inst.last
        LOOP
            IF i_disch_dest_inst.exists(i)
               AND i_disch_rank.exists(i)
            THEN
                --IF i_disch_dest_inst(i) = -1 -- -1: free text institution
                IF i_disch_dest_inst(i) < 0 -- negative: free text institution
                THEN
                    l_transf_type        := g_transf_type_free_text;
                    l_id_disch_dest_inst := -1;
                ELSE
                    l_transf_type        := g_transf_type_insitutional;
                    l_id_disch_dest_inst := i_disch_dest_inst(i);
                END IF;
            
                -- verify if there's a suggested discharge_transf_inst for the current i_disch_dest_inst(i)
                g_error := 'OPEN C_SUGGESTED_DTI';
                OPEN c_suggested_dti(l_id_disch_dest_inst);
                FETCH c_suggested_dti
                    INTO l_id_dti;
                g_found := c_suggested_dti%FOUND;
                CLOSE c_suggested_dti;
            
                IF g_found
                   AND l_id_dti IS NOT NULL
                THEN
                    -- if found a suggested ddi then update the discharge_transf_inst
                    g_error := 'TS_DISCH_TRANSF_INST.UPD';
                    ts_disch_transf_inst.upd(id_disch_transf_inst_in => l_id_dti,
                                             flg_status_in           => i_flg_status,
                                             rows_out                => l_rowids_upd);
                
                    l_update_dti  := l_update_dti + 1;
                    l_has_updated := TRUE;
                ELSE
                    -- else insert a new one
                    g_error := 'TS_DISCH_TRANSF_INST.INS #' || i;
                    ts_disch_transf_inst.ins(id_disch_transf_inst_in => ts_disch_transf_inst.next_key,
                                             id_discharge_in         => i_discharge,
                                             id_disch_dest_inst_in   => l_id_disch_dest_inst, --i_disch_dest_inst(i),
                                             rank_in                 => i_disch_rank(i) - l_update_dti + l_max_rank,
                                             flg_status_in           => i_flg_status,
                                             id_prof_create_in       => i_prof.id,
                                             dt_create_in            => g_sysdate_tstz,
                                             flg_type_in             => l_transf_type,
                                             free_text_inst_in       => i_other_inst_name,
                                             rows_out                => l_rowids);
                
                    l_has_inserted := TRUE;
                END IF;
            ELSE
                RETURN FALSE;
            END IF;
        END LOOP;
    
        -------------------------------------------------------------------------
        -- if records where inserted take some actions
        IF l_has_inserted
           OR l_has_updated
        THEN
            -- update data_gov table
            IF l_has_inserted
            THEN
                g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT DISCH_TRANSF_INST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DISCH_TRANSF_INST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
            -- update data_gov table
            IF l_has_updated
            THEN
                g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE DISCH_TRANSF_INST';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DISCH_TRANSF_INST',
                                              i_rowids     => l_rowids_upd,
                                              o_error      => o_error);
            END IF;
        
            -------------------------------------------------------------------------
            -- if suggested then don't update the list
            IF i_flg_status != g_transf_status_suggested
            THEN
                -- set first record of disch_transf_inst with the "pending" state
                g_error := 'UPDATE DISCH_TRANSF_INST';
                UPDATE disch_transf_inst dti
                   SET dti.flg_status = g_transf_status_pending
                 WHERE dti.id_disch_transf_inst = (SELECT dt1.id_disch_transf_inst
                                                     FROM disch_transf_inst dt1
                                                    WHERE dt1.id_discharge = i_discharge
                                                      AND dt1.flg_status = g_transf_status_not_available
                                                      AND dt1.rank = (SELECT MIN(dt2.rank)
                                                                        FROM disch_transf_inst dt2
                                                                       WHERE dt2.id_discharge = dt1.id_discharge
                                                                         AND dt2.flg_status = dt1.flg_status)
                                                      AND rownum = 1);
            END IF;
        ELSE
            l_return := FALSE;
        END IF;
    
        l_return := TRUE;
    
        IF l_return = FALSE
        THEN
            ROLLBACK;
        END IF;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'SET_DTI_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Social worker function
    * Function to call when a social worker requests a new list to the physician
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION request_new_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dti_professional disch_transf_inst.id_prof_create%TYPE;
    
        CURSOR c_disch_professional IS
            SELECT d.id_prof_med
              FROM discharge d
             WHERE d.id_discharge = i_discharge;
    
    BEGIN
        -- determine the professional responsible for the discharge
        g_error := 'OPEN c_dti_professional';
        OPEN c_disch_professional;
        FETCH c_disch_professional
            INTO l_dti_professional;
        g_found := c_disch_professional%FOUND;
        CLOSE c_disch_professional;
    
        -- create new alert for the physician responsible for the discharge requesting a new list
        g_error := 'CREATE_GENERIC_ALERT ' || to_char(g_requested_transf_alert);
        IF NOT create_generic_alert(i_lang,
                                    i_prof,
                                    i_discharge,
                                    g_requested_transf_alert, -- 88
                                    l_dti_professional,
                                    o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'REQUEST_NEW_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Physician function
    * Function to call when the physician requests other professional to create transference list
    * this function only needs to handle the alert creation
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION request_other_prof_create_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT request_other_prof_create_list(i_lang, i_prof, i_discharge, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- update id_epis_diagnosis associated with the discharge
        IF NOT set_dti_epis_diagnosis(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_discharge      => i_discharge,
                                      i_epis_diagnosis => i_epis_diagnosis,
                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'REQUEST_OTHER_PROF_CREATE_LIST',
                                                     o_error);
    END;

    FUNCTION request_other_prof_create_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- create new alert for the physician indicating that the transfer request was accepted
        g_error := 'CREATE_GENERIC_ALERT ' || to_char(g_other_prof_transf_list_alert);
        IF NOT create_generic_alert(i_lang,
                                    i_prof,
                                    i_discharge,
                                    g_other_prof_transf_list_alert, -- 89
                                    NULL,
                                    o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'REQUEST_OTHER_PROF_CREATE_LIST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Apdates discharge transfer status (flg_inst_transfer_status)
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_flg_status      Discharge transfer status
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    17/03/2010
    ********************************************************************************************/
    FUNCTION update_disch_transf_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        i_flg_status IN discharge_detail.flg_inst_transfer_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        UPDATE discharge_detail dd
           SET dd.flg_inst_transfer_status = i_flg_status
         WHERE dd.id_discharge = i_discharge;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'UPDATE_DISCH_TRANSF_STATUS',
                                                     o_error);
    END;

    /********************************************************************************************
    * Cancels all data related with the discharge: alerts and transf_inst
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    17/03/2010
    ********************************************************************************************/
    FUNCTION cancel_transf_discharge
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
    
        CURSOR c_alert_identification IS
            SELECT sae.id_sys_alert
              FROM sys_alert_event sae
             WHERE sae.id_record = i_discharge
               AND sae.id_sys_alert IN (g_disch_transf_inst_alert,
                                        g_other_prof_transf_list_alert,
                                        g_concluded_transf_alert,
                                        g_suggested_transf_alert,
                                        g_requested_transf_alert)
               AND sae.flg_visible = g_yes;
    
        CURSOR c_dti IS
            SELECT dti.id_disch_transf_inst
              FROM disch_transf_inst dti
             WHERE dti.id_discharge = i_discharge;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- deletes all alerts either for the physician or the social worker
        FOR r_sys_alert IN c_alert_identification
        LOOP
            IF NOT delete_generic_alert(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_discharge => i_discharge,
                                        i_sys_alert => r_sys_alert.id_sys_alert,
                                        o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
        -- cancels all the transference institution records
        g_error := 'LOOP TRANSF INSTITUTIONS';
        FOR r_dti IN c_dti
        LOOP
            ts_disch_transf_inst.upd(id_disch_transf_inst_in => r_dti.id_disch_transf_inst,
                                     flg_status_in           => g_transf_status_canceled,
                                     id_prof_update_in       => i_prof.id,
                                     dt_update_in            => g_sysdate_tstz,
                                     rows_out                => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DISCH_TRANSF_INST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END LOOP;
    
        -- update_disch_transf_status to NULL (no icon)
        IF NOT update_disch_transf_status(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_discharge  => i_discharge,
                                          i_flg_status => NULL,
                                          o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_DISCHARGE_INST',
                                                     'UPDATE_DISCH_TRANSF_STATUS',
                                                     o_error);
    END;

END pk_discharge_inst;
/
