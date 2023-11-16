/*-- Last Change Revision: $Rev: 2026892 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_complication IS

    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_error         VARCHAR2(1000 CHAR);
    g_exception EXCEPTION;

    PROCEDURE set_diag_complications_h
    (
        i_epis_diagnosis   IN NUMBER,
        i_epis_diagnosis_h IN NUMBER
    ) IS
        l_id_sk NUMBER(24);
        l_date  TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        l_id_sk := seq_diag_compl_h.nextval;
        l_date  := current_timestamp;
    
        INSERT INTO epis_diag_complications_h
            (id_sk,
             dt_creation,
             id_epis_diagnosis,
             id_complication,
             id_alert_complication,
             flg_status,
             id_prof_create,
             dt_create,
             id_prof_upd,
             dt_upd,
             rank,
             id_epis_diagnosis_h,
             desc_complication)
            SELECT l_id_sk,
                   l_date,
                   edc.id_epis_diagnosis,
                   edc.id_complication,
                   edc.id_alert_complication,
                   edc.flg_status,
                   edc.id_prof_create,
                   edc.dt_create,
                   edc.id_prof_upd,
                   edc.dt_upd,
                   edc.rank,
                   i_epis_diagnosis_h,
                   desc_complication
              FROM epis_diag_complications edc
             WHERE edc.id_epis_diagnosis = i_epis_diagnosis;
    
    END set_diag_complications_h;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION set_epis_diag_complications
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_epis_diagnosis         IN pk_edis_types.rec_in_epis_diagnosis,
        i_id_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_id_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE DEFAULT NULL,
        i_dt_record              IN epis_diag_complications.dt_create%TYPE DEFAULT NULL,
        io_params                IN OUT NOCOPY pk_edis_types.table_out_epis_diags,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_EPIS_DIAG_COMPLICATIONS';
    
        l_epis_diagnosis    pk_edis_types.rec_in_epis_diagnosis;
        l_rec_diagnosis     pk_edis_types.rec_in_diagnosis;
        l_tbl_complications pk_edis_types.table_in_complications;
    
        l_id_epis_diagnosis epis_diagnosis.id_epis_diagnosis%TYPE;
        l_id_episode        epis_diagnosis.id_episode%TYPE;
        l_flg_type          epis_diagnosis.flg_type%TYPE;
        l_dt_record CONSTANT TIMESTAMP WITH TIME ZONE := nvl(i_dt_record, current_timestamp);
        l_comp_description VARCHAR2(4000 CHAR);
        l_comp_code        VARCHAR2(200 CHAR);
    
        l_inactivated table_number := table_number();
        l_udated      table_number := table_number();
        --
        l_removed   table_number := table_number();
        l_inserted  table_number := table_number();
        l_flg_other VARCHAR2(1 CHAR);
    BEGIN
        l_epis_diagnosis    := i_epis_diagnosis;
        l_rec_diagnosis     := l_epis_diagnosis.tbl_diagnosis(1);
        l_tbl_complications := l_rec_diagnosis.tbl_complications;
        l_id_episode        := i_epis_diagnosis.id_episode;
        l_flg_type          := i_epis_diagnosis.flg_type;
    
        l_id_epis_diagnosis := nvl(l_epis_diagnosis.id_epis_diagnosis, i_id_epis_diagnosis);
    
        --------------------------------------------------------------------
        -- set epis_diagnosis complication
        IF l_id_epis_diagnosis IS NOT NULL
           AND l_tbl_complications.exists(1)
        THEN
        
            set_diag_complications_h(i_epis_diagnosis   => l_id_epis_diagnosis,
                                     i_epis_diagnosis_h => i_id_epis_diagnosis_hist);
        
            -- update all epis_diag complication to inactive
            UPDATE epis_diag_complications edc
               SET edc.flg_status = g_complication_inactive
             WHERE edc.id_epis_diagnosis = l_id_epis_diagnosis
               AND edc.flg_status = g_complication_active
            RETURNING edc.id_complication BULK COLLECT INTO l_inactivated;
        
            FOR i IN l_tbl_complications.first .. l_tbl_complications.last
            LOOP
                BEGIN
                    SELECT d.flg_other
                      INTO l_flg_other
                      FROM diagnosis d
                     WHERE d.id_diagnosis = l_tbl_complications(i).id_complication
                       AND d.flg_available = pk_alert_constant.g_yes;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_flg_other := pk_alert_constant.g_no;
                END;
            
                UPDATE epis_diag_complications edc
                   SET edc.flg_status        = g_complication_active,
                       edc.id_prof_upd       = i_prof.id,
                       edc.dt_upd            = l_dt_record,
                       edc.rank              = i,
                       edc.desc_complication = decode(l_flg_other,
                                                      pk_alert_constant.g_yes,
                                                      l_tbl_complications(i).desc_complication,
                                                      NULL)
                 WHERE edc.id_epis_diagnosis = l_id_epis_diagnosis
                   AND edc.id_complication = l_tbl_complications(i).id_complication -- item_value
                   AND edc.id_alert_complication = l_tbl_complications(i).id_alert_complication -- alt_value
                   AND ((l_flg_other = pk_alert_constant.get_no) OR
                       ((l_flg_other = pk_alert_constant.get_yes) AND (edc.rank = i)));
            
                -- if no records where updated, it's because they don't exist and it's necessary to create them
                IF SQL%ROWCOUNT = 0
                   AND l_id_epis_diagnosis IS NOT NULL
                   AND l_tbl_complications(i).id_complication IS NOT NULL
                   AND l_tbl_complications(i).id_alert_complication IS NOT NULL
                THEN
                    INSERT INTO epis_diag_complications
                        (id_epis_diagnosis,
                         id_complication,
                         id_alert_complication,
                         flg_status,
                         id_prof_create,
                         dt_create,
                         rank,
                         desc_complication)
                    VALUES
                        (l_id_epis_diagnosis,
                         l_tbl_complications(i).id_complication,
                         l_tbl_complications(i).id_alert_complication,
                         g_complication_active, -- active
                         i_prof.id,
                         l_dt_record,
                         i,
                         decode(l_flg_other, pk_alert_constant.g_yes, l_tbl_complications(i).desc_complication, NULL));
                    l_comp_description := pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_id_concept_term => l_tbl_complications(i)
                                                                                               .id_alert_complication,
                                                                          i_id_task_type    => pk_ts1_api.g_task_type_default);
                    l_comp_code        := pk_ts1_api.get_term_code(i_id_concept_term => l_tbl_complications(i)
                                                                                        .id_alert_complication);
                
                    pk_diagnosis_core.add_output_param(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_episode             => NULL,
                                                       i_epis_diagnosis      => l_id_epis_diagnosis,
                                                       i_epis_diagnosis_hist => NULL,
                                                       i_id_complication     => l_tbl_complications(i).id_complication,
                                                       i_comp_description    => l_comp_description,
                                                       i_comp_code           => l_comp_code,
                                                       i_comp_rank           => i,
                                                       i_dt_record           => l_dt_record,
                                                       io_params             => io_params);
                
                    l_inserted.extend;
                    l_inserted(l_inserted.last) := l_tbl_complications(i).id_complication;
                    /* always add other diagnosis in list and let it confirm in epis_diagnosis */
                ELSIF (l_flg_other = pk_alert_constant.g_yes)
                THEN
                    l_inserted.extend;
                    l_inserted(l_inserted.last) := l_tbl_complications(i).id_complication;
                    /* ignore other diagnosis and let it cofirm in epis_diagnosis */
                ELSIF (l_flg_other = pk_alert_constant.g_no)
                THEN
                    l_udated.extend;
                    l_udated(l_udated.last) := l_tbl_complications(i).id_complication;
                END IF;
            END LOOP;
        
            -- removed complications
            l_removed := l_inactivated MULTISET except l_udated;
        
            -- update flg_is_complication in diagnosis set as complication
            IF l_removed.exists(1)
               OR l_inserted.exists(1)
            THEN
                pk_diagnosis_core.manage_epis_diagnosis_is_compl(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_episode     => l_id_episode,
                                                                 i_flg_type       => l_flg_type,
                                                                 i_removed_compl  => l_removed,
                                                                 i_inserted_compl => l_inserted);
            END IF;
        END IF;
    
        --------------------------------------------------------------------
        IF l_id_epis_diagnosis IS NOT NULL
           AND l_id_episode IS NOT NULL
           AND l_flg_type IS NOT NULL
        THEN
            -- if passed epis_diagnosis is marked as complication in other diagnosis, then:
            -- > remove the complication from the other(s) diagnosis(ses)
            -- > mark the epis_diagnosis as flg_is_complication = N
            l_removed  := table_number();
            l_inserted := table_number();
        
            UPDATE epis_diag_complications edc
               SET edc.flg_status = pk_complication.g_complication_inactive
             WHERE edc.id_epis_diagnosis IN
                   (SELECT ed.id_epis_diagnosis
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = l_id_episode
                       AND ed.flg_type = l_flg_type
                       AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL))
               AND edc.id_complication IN
                   (SELECT ed.id_diagnosis
                      FROM epis_diagnosis ed
                     WHERE ed.id_epis_diagnosis = l_id_epis_diagnosis
                       AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL)
                       AND ((ed.desc_epis_diagnosis IS NULL) OR (ed.desc_epis_diagnosis = edc.desc_complication)))
               AND edc.flg_status = pk_complication.g_complication_active
            RETURNING edc.id_complication BULK COLLECT INTO l_removed;
        
            IF l_removed.exists(1)
               OR l_inserted.exists(1)
            THEN
                pk_diagnosis_core.manage_epis_diagnosis_is_compl(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_episode     => l_id_episode,
                                                                 i_flg_type       => l_flg_type,
                                                                 i_removed_compl  => l_removed,
                                                                 i_inserted_compl => l_inserted);
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
    END set_epis_diag_complications;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION get_epis_diag_complications
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_diagnosis   IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_id_epis_diagnosis_h IN NUMBER
    ) RETURN pk_edis_types.table_out_complications IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_DIAG_COMPLICATIONS';
    
        l_error                 t_error_out;
        l_tbl_out_complications pk_edis_types.table_out_complications := pk_edis_types.table_out_complications();
        l_rec_out_complication  pk_edis_types.rec_out_complication;
    
    BEGIN
    
        FOR edc_rec IN (SELECT xsql.*
                          FROM (SELECT edc.id_complication,
                                       edc.id_alert_complication,
                                       edc.rank,
                                       edc.desc_complication,
                                       d.flg_other
                                  FROM epis_diag_complications edc
                                  JOIN diagnosis d
                                    ON d.id_diagnosis = edc.id_complication
                                 WHERE edc.id_epis_diagnosis = i_id_epis_diagnosis
                                   AND edc.flg_status = g_complication_active
                                   AND i_id_epis_diagnosis_h IS NULL
                                UNION ALL
                                SELECT eh.id_complication,
                                       eh.id_alert_complication,
                                       eh.rank,
                                       eh.desc_complication,
                                       d.flg_other
                                  FROM epis_diag_complications_h eh
                                  JOIN diagnosis d
                                    ON d.id_diagnosis = eh.id_complication
                                 WHERE 0 = 0 --edc.id_epis_diagnosis = i_id_epis_diagnosis
                                   AND eh.flg_status = g_complication_active
                                   AND eh.id_epis_diagnosis_h = i_id_epis_diagnosis_h) xsql
                         ORDER BY xsql.rank)
        LOOP
        
            l_rec_out_complication.id_complication       := edc_rec.id_complication;
            l_rec_out_complication.id_alert_complication := edc_rec.id_alert_complication;
        
            l_rec_out_complication.complication_description := pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                                                               i_prof            => i_prof,
                                                                                               i_id_concept_term => edc_rec.id_alert_complication,
                                                                                               i_id_task_type    => pk_ts1_api.g_task_type_default,
                                                                                               i_flg_show_code   => CASE
                                                                                                                        WHEN edc_rec.flg_other = pk_alert_constant.g_yes THEN
                                                                                                                         pk_alert_constant.g_diag_flg_show_f
                                                                                                                        ELSE
                                                                                                                         pk_alert_constant.g_yes
                                                                                                                    END,
                                                                                               i_free_text_desc  => edc_rec.desc_complication);
            l_rec_out_complication.rank                     := edc_rec.rank;
        
            l_tbl_out_complications.extend();
            l_tbl_out_complications(l_tbl_out_complications.last) := l_rec_out_complication;
        END LOOP;
    
        RETURN l_tbl_out_complications;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_epis_diag_complications;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION get_complications_desc_serial
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_COMPLICATIONS_DESC_SERIAL';
    
        l_error t_error_out;
    
        l_lbracket     VARCHAR2(1 CHAR) := '[';
        l_rbracket     VARCHAR2(1 CHAR) := ']';
        l_lparenthesis VARCHAR2(1 CHAR) := '(';
        l_rparenthesis VARCHAR2(1 CHAR) := ')';
        l_spc          VARCHAR2(1 CHAR) := ' ';
        l_sc           VARCHAR2(1 CHAR) := ';';
        l_compl_desc   VARCHAR2(4000 CHAR) := '';
    
        l_term_description VARCHAR2(4000 CHAR);
        l_term_code        VARCHAR2(200 CHAR);
    
    BEGIN
    
        SELECT listagg(cnt.desc_rank, l_sc) within GROUP(ORDER BY cnt.rank) AS simulate_complic_desc_serial
          INTO l_compl_desc
          FROM (SELECT edc.rank,
                       l_lbracket || edc.rank || l_rbracket || l_spc ||
                       pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_concept_term => edc.id_alert_complication,
                                                       i_id_task_type    => pk_ts1_api.g_task_type_default,
                                                       i_flg_show_code   => decode(d.flg_other,
                                                                                   pk_alert_constant.g_yes,
                                                                                   pk_alert_constant.g_diag_flg_show_f,
                                                                                   pk_alert_constant.g_yes),
                                                       i_free_text_desc  => edc.desc_complication) AS desc_rank
                  FROM epis_diag_complications edc
                  JOIN diagnosis d
                    ON d.id_diagnosis = edc.id_complication
                 WHERE edc.id_epis_diagnosis = i_id_epis_diagnosis
                   AND edc.flg_status = g_complication_active) cnt;
    
        RETURN l_compl_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_complications_desc_serial;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_complication_and_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter   NUMBER := 0;
        l_id_diag   table_number := table_number();
        l_dt_create table_timestamp_tstz := table_timestamp_tstz();
    BEGIN
    
        ----------------------------------------------------    
        SELECT id_diagnosis, dt_create
          BULK COLLECT
          INTO l_id_diag, l_dt_create
          FROM (SELECT ed.id_alert_diagnosis id_diagnosis, nvl(ed.dt_initial_diag, ed.dt_epis_diagnosis_tstz) dt_create
                  FROM epis_diagnosis ed
                 WHERE ed.id_episode = i_id_episode
                   AND ed.flg_type = pk_diagnosis.g_diag_type_p
                   AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
                           AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL))
         ORDER BY dt_create DESC;
    
        ----------------------------------------------------
        OPEN o_complications FOR
            SELECT id_concept_term,
                   pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_concept_term => id_concept_term,
                                                   i_id_task_type    => pk_ts1_api.g_task_type_default,
                                                   i_flg_show_code   => decode(desc_complication,
                                                                               NULL,
                                                                               NULL,
                                                                               pk_alert_constant.g_diag_flg_show_f),
                                                   i_free_text_desc  => desc_complication) desc_diagnosis,
                   NULL code_icd,
                   dt_create
              FROM (SELECT t.id_concept_term,
                           rank() over(PARTITION BY t.id_concept_term ORDER BY dt.dt_create DESC) rn,
                           --t.code code_icd,
                           dt.dt_create,
                           NULL         desc_complication
                      FROM alert_core_data.v_ts1_terms_ea t
                      JOIN (SELECT /*+OPT_ESTIMATE(TABLE l ROWS=1)*/
                            column_value id_diagnosis, rownum rn
                             FROM TABLE(l_id_diag) l) d
                        ON d.id_diagnosis = t.id_concept_term
                      JOIN (SELECT /*+OPT_ESTIMATE(TABLE l ROWS=1)*/
                            column_value dt_create, rownum rn
                             FROM TABLE(l_dt_create) l) dt
                        ON dt.rn = d.rn
                     WHERE pk_ts1_api.set_ts_context(i_lang           => i_lang,
                                                     i_concept_type   => 'COMPLICATION',
                                                     i_id_task_type   => 63, -- complications are also diagnosis
                                                     i_id_institution => i_prof.institution,
                                                     i_id_software    => i_prof.software,
                                                     i_id_patient     => i_id_patient) = 1
                    UNION
                    SELECT edc.id_alert_complication id_concept_term, 1 rn, edc.dt_create, edc.desc_complication
                      FROM epis_diag_complications edc
                     WHERE edc.id_epis_diagnosis IN
                           (SELECT ed.id_epis_diagnosis
                              FROM epis_diagnosis ed
                             WHERE ed.id_episode = i_id_episode
                               AND ed.flg_type = pk_diagnosis.g_diag_type_p
                               AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
                               AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL))
                       AND edc.flg_status = pk_complication.g_complication_active)
            
             WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complications);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_COMPLICATION_AND_DIAG',
                                              o_error);
            RETURN FALSE;
    END get_complication_and_diag;

BEGIN
    -- Log startup
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_complication;
/
