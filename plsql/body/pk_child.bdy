/*-- Last Change Revision: $Rev: 2026869 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:15 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_child IS
    /***
    * get ped_area_soft_inst.rank rank
    *
    * @param i_lang                   Language ID 
    * @param i_prof                   Professional info           
    * @param i_id_ped_area_add        ped area add identifier
    * @param i_market                 market identifier
    *
    * @return  ped_area_soft_inst.rank
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION get_pasi_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ped_area_add IN ped_area_add.id_ped_area_add%TYPE,
        i_market          IN market.id_market%TYPE
    ) RETURN NUMBER IS
        l_return ped_area_soft_inst.rank%TYPE;
    BEGIN
        g_error := 'pk_child.get_pasi_rank';
        BEGIN
            SELECT rank
              INTO l_return
              FROM (SELECT pasi.flg_available flg_available,
                           pasi.rank rank,
                           row_number() over(ORDER BY decode(pasi.id_market, i_market, 1, 2), decode(pasi.id_institution, i_prof.institution, 1, 2), decode(pasi.id_software, i_prof.software, 1, 2)) line_number
                      FROM ped_area_soft_inst pasi
                     WHERE pasi.id_ped_area_add = i_id_ped_area_add
                       AND pasi.id_institution IN (0, i_prof.institution)
                       AND pasi.id_software IN (0, i_prof.software)
                       AND pasi.id_market IN (0, i_market))
             WHERE line_number = 1
               AND flg_available = g_available;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := NULL;
        END;
    
        RETURN l_return;
    END get_pasi_rank;
    /***
    * Checks if a ped_area_add is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_ped_area_add        ped area add identifier
    * @param i_market                 market identifier
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION is_pasi_available
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ped_area_add IN ped_area_add.id_ped_area_add%TYPE,
        i_market          IN market.id_market%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        g_error := 'pk_child.is_pasi_available';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_return
              FROM (SELECT pasi.flg_available flg_available,
                           row_number() over(ORDER BY decode(pasi.id_market, i_market, 1, 2), decode(pasi.id_institution, i_prof.institution, 1, 2), decode(pasi.id_software, i_prof.software, 1, 2)) line_number
                      FROM ped_area_soft_inst pasi
                     WHERE pasi.id_ped_area_add = i_id_ped_area_add
                       AND pasi.id_institution IN (0, i_prof.institution)
                       AND pasi.id_software IN (0, i_prof.software)
                       AND pasi.id_market IN (0, i_market))
             WHERE line_number = 1
               AND flg_available = g_available;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := pk_alert_constant.g_no;
        END;
    
        RETURN l_return;
    END is_pasi_available;
    /***
    * get child_feed_dev_inst_soft.rank rank
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_child_feed_dev      child feed dev identifier
    * @param i_market                 market identifier
    *
    * @return  child_feed_dev_inst_soft.rank
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION get_cfd_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_child_feed_dev IN child_feed_dev.id_child_feed_dev%TYPE,
        i_market            IN market.id_market%TYPE
    ) RETURN NUMBER IS
        l_return child_feed_dev_inst_soft.rank%TYPE;
    BEGIN
        g_error := 'pk_child.get_cfd_rank';
        BEGIN
            SELECT rank
              INTO l_return
              FROM (SELECT cfdis.flg_available flg_available,
                           cfdis.rank rank,
                           row_number() over(ORDER BY decode(cfdis.id_market, i_market, 1, 2), decode(cfdis.id_institution, i_prof.institution, 1, 2), decode(cfdis.id_software, i_prof.software, 1, 2)) line_number
                      FROM child_feed_dev_inst_soft cfdis
                     WHERE cfdis.id_child_feed_dev = i_id_child_feed_dev
                       AND cfdis.id_institution IN (0, i_prof.institution)
                       AND cfdis.id_software IN (0, i_prof.software)
                       AND cfdis.id_market IN (0, i_market))
             WHERE line_number = 1
               AND flg_available = g_available;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := NULL;
        END;
    
        RETURN l_return;
    END get_cfd_rank;
    /***
    * Checks if a child_feed_dev is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_child_feed_dev      child feed dev identifier
    * @param i_market                 market identifier
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION is_cfd_available
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_child_feed_dev IN child_feed_dev.id_child_feed_dev%TYPE,
        i_market            IN market.id_market%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        g_error := 'pk_child.is_cfd_available';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_return
              FROM (SELECT cfdis.flg_available flg_available,
                           row_number() over(ORDER BY decode(cfdis.id_market, i_market, 1, 2), decode(cfdis.id_institution, i_prof.institution, 1, 2), decode(cfdis.id_software, i_prof.software, 1, 2)) line_number
                      FROM child_feed_dev_inst_soft cfdis
                     WHERE cfdis.id_child_feed_dev = i_id_child_feed_dev
                       AND cfdis.id_institution IN (0, i_prof.institution)
                       AND cfdis.id_software IN (0, i_prof.software)
                       AND cfdis.id_market IN (0, i_market))
             WHERE line_number = 1
               AND flg_available = g_available;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := pk_alert_constant.g_no;
        END;
    
        RETURN l_return;
    END is_cfd_available;

    /**************************************************************************
    * Obtains the patient age 
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             patient identifier
    * @param o_gender                 patient gender
    * @param o_year_age               patient age in years
    * @param o_month_age              patient age in months   
    * @param o_week_age               patient age in weeks
    * @param o_day_age                patient age in days
    * @param o_error                  error out
    *           
    * @return                         true if succeed
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/27
    **************************************************************************/
    FUNCTION get_pat_age
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_gender     OUT patient.gender%TYPE,
        o_year_age   OUT NUMBER,
        o_month_age  OUT NUMBER,
        o_week_age   OUT NUMBER,
        o_day_age    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased patient.dt_deceased%TYPE;
        l_age         patient.age%TYPE;
        l_dt_max      patient.dt_birth%TYPE;
    BEGIN
        BEGIN
            g_error := 'SELECT o_gender, l_dt_birth, l_dt_deceased, l_age';
            SELECT p.gender, p.dt_birth, p.dt_deceased, p.age
              INTO o_gender, l_dt_birth, l_dt_deceased, l_age
              FROM patient p
             WHERE p.id_patient = i_id_patient;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        l_dt_max := nvl(to_date(to_char(l_dt_deceased, pk_alert_constant.g_dt_yyyymmddhh24miss),
                                pk_alert_constant.g_dt_yyyymmddhh24miss),
                        SYSDATE);
    
        o_year_age  := trunc(nvl(months_between(l_dt_max, l_dt_birth) / 12, l_age));
        o_month_age := trunc(nvl(months_between(l_dt_max, l_dt_birth), l_age * 12));
        o_week_age  := trunc(nvl((l_dt_max - l_dt_birth) / 7, l_age * 365 / 7));
        o_day_age   := trunc(nvl(l_dt_max - l_dt_birth, l_age * 365));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_AGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            o_gender    := NULL;
            o_year_age  := NULL;
            o_month_age := NULL;
            o_week_age  := NULL;
            o_day_age   := NULL;
            RETURN FALSE;
    END get_pat_age;

    /**********************************************************************************************
    * get_sys_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_button          sys_button.id_sys_button%TYPE,
    * @param i_id_sys_button_prop     sys_button_prop.id_sys_button_prop%TYPE   
    *
    * @return                         id_sys_shortcut
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/07/1
    **********************************************************************************************/
    FUNCTION get_sys_shortcut
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button      IN sys_button.id_sys_button%TYPE,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER IS
        l_id_sys_shortcut            sys_shortcut.id_sys_shortcut%TYPE;
        l_id_profile_template        profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
        l_id_profile_template_parent profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'get l_id_profile_template_parent';
        SELECT pt.id_parent
          INTO l_id_profile_template_parent
          FROM profile_template pt
         WHERE pt.id_profile_template = l_id_profile_template;
    
        g_error := 'pk_child.get_sys_shortcut';
        SELECT ss.id_sys_shortcut
          INTO l_id_sys_shortcut
          FROM sys_button_prop sbp
          JOIN sys_shortcut ss
            ON ss.id_sys_button_prop = sbp.id_sys_button_prop
           AND id_software IN (0, i_prof.software)
           AND ss.id_institution IN (0, i_prof.institution)
          JOIN profile_templ_access pta
            ON pta.id_sys_button_prop = sbp.id_sys_button_prop
           AND pta.id_shortcut_pk = ss.id_shortcut_pk
           AND pta.id_profile_template IN (l_id_profile_template, l_id_profile_template_parent)
         WHERE sbp.id_sys_button = i_id_sys_button
           AND sbp.id_btn_prp_parent IN
               (SELECT sbp2.id_btn_prp_parent
                  FROM sys_button_prop sbp2
                CONNECT BY PRIOR sbp2.id_sys_button_prop = sbp2.id_btn_prp_parent
                 START WITH sbp2.id_sys_button_prop = i_id_sys_button_prop)
           AND rownum = 1;
    
        RETURN l_id_sys_shortcut;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sys_shortcut;

    /**********************************************************************************************
    * Obter detalhe dos alimentos do primeiro ano de um paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_button_prop     sys_button_prop.id_sys_button_prop%TYPE   
    * @param o_areas                  ped areas
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_ped_areas
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_areas              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_child.get_ped_areas';
        OPEN o_areas FOR
            SELECT pa.id_ped_area id_ped_area,
                   pk_translation.get_translation(i_lang, pa.code_ped_area) desc_ped_area,
                   pa.id_summary_page id_summary_page,
                   pa.id_doc_area id_doc_area,
                   get_sys_shortcut(i_lang, i_prof, pa.id_sys_button, i_id_sys_button_prop) id_sys_shortcut
              FROM ped_area pa
             ORDER BY pa.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PED_AREAS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_areas);
            RETURN FALSE;
    END get_ped_areas;
    /**********************************************************************************************
    * Obter detalhe dos alimentos do primeiro ano de um paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_id_summary_page        summary page identifier
    * @param o_id_doc_template        default ud_doc_template
    * @param o_templates              add button templates
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_ped_areas_templates
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_summary_page IN ped_area.id_summary_page%TYPE,
        o_id_doc_template OUT ped_area_add.id_doc_template%TYPE,
        o_templates       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market          institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        l_gender          patient.gender%TYPE;
        l_year_age        NUMBER(12);
        l_month_age       NUMBER(12);
        l_week_age        NUMBER(12);
        l_day_age         NUMBER(12);
        l_tb_doc_template table_number := table_number();
    BEGIN
        g_error := 'call get_pat_age';
        IF NOT get_pat_age(i_lang       => i_lang,
                           i_prof       => i_prof,
                           i_id_patient => i_id_patient,
                           o_gender     => l_gender,
                           o_year_age   => l_year_age,
                           o_month_age  => l_month_age,
                           o_week_age   => l_week_age,
                           o_day_age    => l_day_age,
                           o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'get l_tb_doc_template';
        BEGIN
            SELECT paa.id_doc_template
              BULK COLLECT
              INTO l_tb_doc_template
              FROM ped_area_add paa
              JOIN ped_area pa
                ON pa.id_ped_area = paa.id_ped_area
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = paa.id_unit_measure
             WHERE pa.id_summary_page = i_id_summary_page
               AND is_pasi_available(i_lang, i_prof, paa.id_ped_area_add, l_market) = pk_alert_constant.g_yes
               AND nvl(paa.flg_gender, pk_schedule.g_gender_undefined) IN (pk_schedule.g_gender_undefined, l_gender)
               AND paa.id_doc_template IS NOT NULL
               AND CASE
                       WHEN um.internal_name = g_id_um_year THEN
                        l_year_age
                       WHEN um.internal_name IN (g_id_um_month, g_id_um_month2) THEN
                        l_month_age
                       WHEN um.internal_name IN (g_id_um_week, g_id_um_week2) THEN
                        l_week_age
                       WHEN um.internal_name IN (g_id_um_day, g_id_um_day2) THEN
                        l_day_age
                       ELSE
                        NULL
                   END BETWEEN paa.age_min AND paa.age_max
             ORDER BY nvl(get_pasi_rank(i_lang, i_prof, paa.id_ped_area_add, l_market), paa.rank);
        EXCEPTION
            WHEN OTHERS THEN
                l_tb_doc_template := table_number();
        END;
    
        IF l_tb_doc_template.count = 1
        THEN
            o_id_doc_template := l_tb_doc_template(1);
        END IF;
    
        g_error := 'GET o_templates';
        OPEN o_templates FOR
            SELECT decode(pk_translation.get_translation(i_lang, paa.code_ped_area_add),
                          NULL,
                          pk_translation.get_translation(i_lang, dt.code_doc_template),
                          pk_translation.get_translation(i_lang, paa.code_ped_area_add)) desc_ped_area,
                   paa.id_ped_area_add id_ped_area_add,
                   paa.id_parent id_parent,
                   paa.id_doc_template id_doc_template,
                   CASE
                        WHEN paa.id_parent IS NULL
                             AND um.internal_name = g_id_um_year
                             AND l_year_age BETWEEN paa.age_min AND paa.age_max THEN
                         pk_alert_constant.g_yes
                        WHEN paa.id_parent IS NULL
                             AND um.internal_name IN (g_id_um_month, g_id_um_month2)
                             AND l_month_age BETWEEN paa.age_min AND paa.age_max THEN
                         pk_alert_constant.g_yes
                        WHEN paa.id_parent IS NULL
                             AND um.internal_name IN (g_id_um_week, g_id_um_week2)
                             AND l_week_age BETWEEN paa.age_min AND paa.age_max THEN
                         pk_alert_constant.g_yes
                        WHEN paa.id_parent IS NULL
                             AND um.internal_name IN (g_id_um_day, g_id_um_day2)
                             AND l_day_age BETWEEN paa.age_min AND paa.age_max THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_selected
              FROM ped_area_add paa
              JOIN ped_area pa
                ON pa.id_ped_area = paa.id_ped_area
              LEFT JOIN doc_template dt
                ON dt.id_doc_template = paa.id_doc_template
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = paa.id_unit_measure
             WHERE pa.id_summary_page = i_id_summary_page
               AND is_pasi_available(i_lang, i_prof, paa.id_ped_area_add, l_market) = pk_alert_constant.g_yes
               AND is_template_available(i_lang, i_prof, i_id_patient, pa.id_doc_area, dt.id_doc_template) =
                   pk_alert_constant.g_yes
               AND nvl(paa.flg_gender, pk_schedule.g_gender_undefined) IN (pk_schedule.g_gender_undefined, l_gender)
             ORDER BY nvl(get_pasi_rank(i_lang, i_prof, paa.id_ped_area_add, l_market), paa.rank);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PED_AREAS_TEMPLATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_templates);
            RETURN FALSE;
    END get_ped_areas_templates;
    /**********************************************************************************************
    * pediatric assessment insert
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_info                   id_alimento/idade em que se verifica
    * @param i_id_episode             id_episode
    * @param i_sys_date               sysdate
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_child_info_nc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_id_episode IN episode.id_episode%TYPE,
        i_sys_date   IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids   table_varchar;
        l_count    NUMBER(12);
        l_where_in VARCHAR2(4000 CHAR);
    BEGIN
        g_error := 'loop data';
        FOR i IN i_info.first .. i_info.last
        LOOP
        
            SELECT COUNT(1)
              INTO l_count
              FROM pat_child_feed_dev pcfd
             WHERE pcfd.id_patient = i_id_patient
               AND pcfd.id_child_feed_dev = i_info(i) (1)
               AND pcfd.child_age = i_info(i) (2);
        
            IF l_count = 0
            THEN
                g_error := 'call ts_pat_child_feed_dev.ins';
                ts_pat_child_feed_dev.ins(id_pat_child_feed_dev_in => ts_pat_child_feed_dev.next_key,
                                          dt_pat_child_feed_dev_in => i_sys_date,
                                          id_patient_in            => i_id_patient,
                                          id_child_feed_dev_in     => i_info(i) (1),
                                          child_age_in             => i_info(i) (2),
                                          flg_status_in            => i_info(i) (3),
                                          id_professional_in       => i_prof.id,
                                          id_episode_in            => i_id_episode,
                                          rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_CHILD_FEED_DEV',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            ELSE
            
                l_where_in := ' ID_PATIENT = ' || i_id_patient || --
                              ' AND ID_CHILD_FEED_DEV = ' || i_info(i) (1) || --
                              ' AND CHILD_AGE = ' || i_info(i) (2);
            
                g_error := 'call ts_pat_child_feed_dev.upd';
                ts_pat_child_feed_dev.upd(dt_pat_child_feed_dev_in => i_sys_date,
                                          dt_cancel_in             => CASE
                                                                          WHEN i_info(i) (3) = g_cancelled THEN
                                                                           i_sys_date
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                          dt_cancel_nin            => FALSE,
                                          flg_status_in            => i_info(i) (3),
                                          id_professional_in       => i_prof.id,
                                          id_prof_cancel_in        => CASE
                                                                          WHEN i_info(i) (3) = g_cancelled THEN
                                                                           i_prof.id
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                          id_prof_cancel_nin       => FALSE,
                                          id_episode_in            => i_id_episode,
                                          where_in                 => l_where_in,
                                          rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_CHILD_FEED_DEV',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CHILD_INFO_NC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_child_info_nc;
    /**********************************************************************************************
    * pediatric assessment insert
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_info                   id_alimento/idade em que se verifica   
    * @param i_id_episode             id_episode
    * @param i_sys_date               sysdate
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_child_info_hist_nc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_id_episode IN episode.id_episode%TYPE,
        i_sys_date   IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
    
        FOR i IN i_info.first .. i_info.last
        LOOP
            g_error := 'call ts_pat_child_feed_dev_hist.ins';
            ts_pat_child_feed_dev_hist.ins(id_pat_child_feed_dev_hist_in => ts_pat_child_feed_dev_hist.next_key,
                                           dt_pat_child_feed_dev_in      => i_sys_date,
                                           id_patient_in                 => i_id_patient,
                                           id_child_feed_dev_in          => i_info(i) (1),
                                           child_age_in                  => i_info(i) (2),
                                           flg_status_in                 => i_info(i) (3),
                                           id_professional_in            => i_prof.id,
                                           id_episode_in                 => i_id_episode,
                                           rows_out                      => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CHILD_FEED_DEV_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CHILD_INFO_HIST_NC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_child_info_hist_nc;
    /**********************************************************************************************
    * pediatric assessment insert
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_info                   id_alimento/idade em que se verifica
    * @param i_flg_type                   type of content
    * @param i_id_episode                id_episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_child_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL VALIDATE_DATA';
        IF NOT validate_data(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => i_id_patient,
                             i_info       => i_info,
                             i_flg_type   => i_flg_type,
                             o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'CALL SET_CHILD_INFO_HIST_NC';
        IF NOT set_child_info_hist_nc(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_id_patient => i_id_patient,
                                      i_info       => i_info,
                                      i_id_episode => i_id_episode,
                                      i_sys_date   => g_sysdate_tstz,
                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL SET_CHILD_INFO_NC';
        IF NOT set_child_info_nc(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_id_patient => i_id_patient,
                                 i_info       => i_info,
                                 i_id_episode => i_id_episode,
                                 i_sys_date   => g_sysdate_tstz,
                                 o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CHILD_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_child_info;
    /**********************************************************************************************
    * concatenação das milestones
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_child_age              idade do paciente
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param i_flg_status             status
    * @param i_market                 market identifier
    * @param i_dt                     record date
    *
    * @return                         Varchar2
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION concat_content
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_child_feed_dev.id_patient%TYPE,
        i_child_age  IN pat_child_feed_dev.child_age%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_flg_status IN pat_child_feed_dev.flg_status%TYPE,
        i_market     IN market.id_market%TYPE,
        i_dt         IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE
    ) RETURN VARCHAR2 IS
        l_aux table_varchar;
    BEGIN
        g_error := 'pk_child.concat_content';
        SELECT pk_translation.get_translation(i_lang, cfd.code_child_feed_dev)
          BULK COLLECT
          INTO l_aux
          FROM pat_child_feed_dev pcfd
          JOIN child_feed_dev cfd
            ON cfd.id_child_feed_dev = pcfd.id_child_feed_dev
           AND cfd.flg_type = i_flg_type
         WHERE pcfd.id_patient = i_id_patient
           AND pcfd.child_age = i_child_age
           AND pcfd.flg_status = i_flg_status
           AND is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, i_market) = pk_alert_constant.g_yes
           AND pcfd.dt_pat_child_feed_dev = nvl(i_dt, pcfd.dt_pat_child_feed_dev)
         ORDER BY nvl(get_cfd_rank(i_lang, i_prof, cfd.id_child_feed_dev, i_market), cfd.rank);
    
        IF l_aux.count = 0
        THEN
            RETURN NULL;
        ELSE
            RETURN pk_utils.concat_table(l_aux, g_semicolon || g_space, 1, -1) || g_dot;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END concat_content;
    /**********************************************************************************************
    * concatenação das milestones
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_child_age              idade do paciente
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param i_flg_status             status
    * @param i_market                 market identifier
    * @param i_dt                     record date
    *
    * @return                         Varchar2
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION concat_content_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_child_feed_dev.id_patient%TYPE,
        i_child_age  IN pat_child_feed_dev.child_age%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_flg_status IN pat_child_feed_dev.flg_status%TYPE,
        i_market     IN market.id_market%TYPE,
        i_dt         IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE
    ) RETURN VARCHAR2 IS
        l_aux table_varchar;
    BEGIN
        g_error := 'pk_child.concat_content_hist';
        SELECT pk_translation.get_translation(i_lang, cfd.code_child_feed_dev)
          BULK COLLECT
          INTO l_aux
          FROM pat_child_feed_dev_hist pcfdh
          JOIN child_feed_dev cfd
            ON cfd.id_child_feed_dev = pcfdh.id_child_feed_dev
           AND cfd.flg_type = i_flg_type
         WHERE pcfdh.id_patient = i_id_patient
           AND pcfdh.child_age = i_child_age
           AND pcfdh.flg_status = i_flg_status
           AND pcfdh.dt_pat_child_feed_dev = i_dt
           AND is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, i_market) = pk_alert_constant.g_yes
         ORDER BY nvl(get_cfd_rank(i_lang, i_prof, cfd.id_child_feed_dev, i_market), cfd.rank);
    
        IF l_aux.count = 0
        THEN
            RETURN NULL;
        ELSE
            RETURN pk_utils.concat_table(l_aux, g_semicolon || g_space, 1, -1) || g_dot;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END concat_content_hist;
    /**********************************************************************************************
    * Obter detalhe 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)    
    * @param o_det                    Cursor com o detalhe para um paciente
    * @param o_hist                    Cursor com o detalhe para um paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5  
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_hist       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'call get_child_det_report';
        IF NOT get_child_det_report(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_patient => i_id_patient,
                                    i_flg_type   => i_flg_type,
                                    i_id_episode => NULL,
                                    i_report     => NULL,
                                    o_det        => o_det,
                                    o_hist       => o_hist,
                                    o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_CHILD_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_det);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_child_det;
    /**********************************************************************************************
    * Obter detalhe 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)    
    * @param i_id_episode             episode id    
    * @param o_det                    Cursor com o detalhe para um paciente
    * @param o_hist                    Cursor com o detalhe para um paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5  
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_report     IN VARCHAR2,
        o_det        OUT pk_types.cursor_type,
        o_hist       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market  institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        l_created sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T034');
        l_edited  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T038');
        l_episode table_number := table_number();
    BEGIN
        g_error   := 'call pk_patient.get_episode_list';
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_id_patient,
                                                 i_id_episode        => i_id_episode,
                                                 i_flg_visit_or_epis => i_report);
    
        g_error := 'call get_child_det_summary_aux';
        IF NOT get_child_det_summary_aux(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_patient => i_id_patient,
                                         i_flg_type   => i_flg_type,
                                         i_report     => i_report,
                                         i_episode    => l_episode,
                                         i_market     => l_market,
                                         o_det        => o_det,
                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET O_HIST';
        OPEN o_hist FOR
            SELECT CASE
                        WHEN line_nr = total THEN
                         l_created || g_colon
                        ELSE
                         l_edited || g_colon
                    END label,
                   pk_date_utils.date_char_tsz(i_lang, dt, i_prof.institution, i_prof.software) dt_sign,
                   pk_date_utils.date_send_tsz(i_lang, dt, i_prof) dt_sign_send,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof) name_sign,
                   decode(pk_prof_utils.get_spec_signature(i_lang, i_prof, prof, dt, epis),
                          NULL,
                          NULL,
                          g_open || pk_prof_utils.get_spec_signature(i_lang, i_prof, prof, dt, epis) || g_close) spec_sign,
                   pk_child.get_child_det_hist(i_lang,
                                               i_prof,
                                               i_id_patient,
                                               i_flg_type,
                                               l_market,
                                               dt,
                                               l_episode,
                                               i_report) hist
              FROM (SELECT dt, prof, epis, rownum line_nr, COUNT(1) over() total
                      FROM (SELECT pcfdh.id_professional prof, pcfdh.dt_pat_child_feed_dev dt, pcfdh.id_episode epis
                              FROM pat_child_feed_dev_hist pcfdh
                              JOIN child_feed_dev cfd
                                ON cfd.id_child_feed_dev = pcfdh.id_child_feed_dev
                               AND cfd.flg_type = i_flg_type
                             WHERE pcfdh.id_patient = i_id_patient
                               AND is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, l_market) =
                                   pk_alert_constant.g_yes
                               AND (nvl(i_report, g_report_p) = g_report_p OR
                                   pcfdh.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE t ROWS=0.00000000001)*/
                                                          t.column_value
                                                           FROM TABLE(l_episode) t))
                             GROUP BY pcfdh.dt_pat_child_feed_dev, pcfdh.id_professional, pcfdh.id_episode
                             ORDER BY pcfdh.dt_pat_child_feed_dev DESC));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHILD_DET_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_det);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_child_det_report;
    /**********************************************************************************************
    * Obter detalhe 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)    
    * @param o_det                    Cursor com o detalhe para um paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5  
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market  institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        l_episode table_number := table_number();
    BEGIN
        g_error   := 'call pk_patient.get_episode_list';
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_id_patient,
                                                 i_id_episode        => NULL,
                                                 i_flg_visit_or_epis => NULL);
    
        g_error := 'call get_child_det_summary_aux';
        IF NOT get_child_det_summary_aux(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_patient => i_id_patient,
                                         i_flg_type   => i_flg_type,
                                         i_report     => NULL,
                                         i_market     => l_market,
                                         i_episode    => l_episode,
                                         o_det        => o_det,
                                         o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_CHILD_DET_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_det);
            RETURN FALSE;
    END get_child_det_summary;

    /**********************************************************************************************
    * Obter detalhe 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)    
    * @param i_report                 report orientation flag
    * @param i_episode                episode list
    * @param i_market                 market id   
    * @param o_det                    Cursor com o detalhe para um paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5  
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_summary_aux
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_report     IN VARCHAR2,
        i_episode    IN table_number,
        i_market     IN market.id_market%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_achieved     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T028');
        l_not_achieved sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T029');
        l_month        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T037');
    BEGIN
        g_error := 'get o_det';
        OPEN o_det FOR
            SELECT l_month || g_space || child_age months,
                   decode(content_a,
                          NULL,
                          NULL,
                          decode(i_flg_type, g_dev, l_achieved || g_colon || g_space || content_a, content_a)) achieved,
                   decode(content_v, NULL, NULL, l_not_achieved || g_colon || g_space || content_v) not_achieved
              FROM (SELECT child_age,
                           pk_child.concat_content(i_lang,
                                                   i_prof,
                                                   id_patient,
                                                   child_age,
                                                   i_flg_type,
                                                   g_active,
                                                   i_market,
                                                   NULL) content_a,
                           pk_child.concat_content(i_lang,
                                                   i_prof,
                                                   id_patient,
                                                   child_age,
                                                   i_flg_type,
                                                   g_verified,
                                                   i_market,
                                                   NULL) content_v
                      FROM (SELECT pcfd.child_age child_age, pcfd.id_patient id_patient
                              FROM pat_child_feed_dev pcfd
                              JOIN child_feed_dev cfd
                                ON cfd.id_child_feed_dev = pcfd.id_child_feed_dev
                               AND cfd.flg_type = i_flg_type
                             WHERE pcfd.id_patient = i_id_patient
                               AND pcfd.flg_status IN (g_active, g_verified)
                               AND is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, i_market) =
                                   pk_alert_constant.g_yes
                               AND (nvl(i_report, g_report_p) = g_report_p OR
                                   pcfd.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE t ROWS=0.00000000001)*/
                                                         t.column_value
                                                          FROM TABLE(i_episode) t))
                             GROUP BY pcfd.child_age, pcfd.id_patient
                             ORDER BY pcfd.child_age ASC));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHILD_DET_SUMMARY_AUX',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_det);
            RETURN FALSE;
    END get_child_det_summary_aux;
    /**********************************************************************************************
    * get_child_det_hist
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param i_market                 market identifier
    * @param i_dt                     record date
    * @param i_id_episode             episode id    
    *
    * @return                         table_varchar
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_child_feed_dev.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_market     IN market.id_market%TYPE,
        i_dt         IN pat_child_feed_dev_hist.dt_pat_child_feed_dev%TYPE,
        i_id_episode IN table_number,
        i_report     IN VARCHAR2
    ) RETURN table_varchar IS
        l_return       table_varchar := table_varchar();
        l_achieved     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T028');
        l_not_achieved sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T029');
        l_removed      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T033');
        l_month        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CHILD_T037');
    
        CURSOR c_cursor IS
            SELECT l_month || g_space || child_age child_age_month,
                   decode(content_a,
                          NULL,
                          NULL,
                          decode(i_flg_type, g_dev, l_achieved || g_colon || g_space || content_a, content_a)) achieved,
                   decode(content_v, NULL, NULL, l_not_achieved || g_colon || g_space || content_v) verified,
                   decode(content_c, NULL, NULL, l_removed || g_colon || g_space || content_c) cancelled
              FROM (SELECT child_age,
                           pk_child.concat_content_hist(i_lang,
                                                        i_prof,
                                                        i_id_patient,
                                                        child_age,
                                                        i_flg_type,
                                                        g_active,
                                                        i_market,
                                                        dt_pat_child_feed_dev) content_a,
                           pk_child.concat_content_hist(i_lang,
                                                        i_prof,
                                                        i_id_patient,
                                                        child_age,
                                                        i_flg_type,
                                                        g_verified,
                                                        i_market,
                                                        dt_pat_child_feed_dev) content_v,
                           pk_child.concat_content_hist(i_lang,
                                                        i_prof,
                                                        i_id_patient,
                                                        child_age,
                                                        i_flg_type,
                                                        g_cancelled,
                                                        i_market,
                                                        dt_pat_child_feed_dev) content_c
                    
                      FROM (SELECT pcfdh.child_age child_age, pcfdh.dt_pat_child_feed_dev dt_pat_child_feed_dev
                              FROM pat_child_feed_dev_hist pcfdh
                              JOIN child_feed_dev cfd
                                ON cfd.id_child_feed_dev = pcfdh.id_child_feed_dev
                               AND cfd.flg_type = i_flg_type
                             WHERE pcfdh.id_patient = i_id_patient
                               AND pcfdh.dt_pat_child_feed_dev = i_dt
                               AND is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, i_market) =
                                   pk_alert_constant.g_yes
                               AND (nvl(i_report, g_report_p) = g_report_p OR
                                   pcfdh.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE t ROWS=0.00000000001)*/
                                                          t.column_value
                                                           FROM TABLE(i_id_episode) t))
                             GROUP BY child_age, dt_pat_child_feed_dev
                             ORDER BY child_age ASC));
    
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_record t_cursor_type;
    
    BEGIN
        g_error := 'pk_child.get_child_det_hist open c_cursor';
        OPEN c_cursor;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_record LIMIT 200;
            FOR i IN 1 .. l_record.count
            LOOP
                l_return.extend(2);
                l_return(l_return.count - 1) := g_tag_bold;
                l_return(l_return.count) := l_record(i).child_age_month;
            
                IF l_record(i).achieved IS NOT NULL
                THEN
                    l_return.extend(2);
                    l_return(l_return.count - 1) := g_tag_normal;
                    l_return(l_return.count) := l_record(i).achieved;
                END IF;
            
                IF l_record(i).verified IS NOT NULL
                THEN
                    l_return.extend(2);
                    l_return(l_return.count - 1) := g_tag_normal;
                    l_return(l_return.count) := l_record(i).verified;
                END IF;
            
                IF l_record(i).cancelled IS NOT NULL
                THEN
                    l_return.extend(2);
                    l_return(l_return.count - 1) := g_tag_cancel;
                    l_return(l_return.count) := l_record(i).cancelled;
                END IF;
            
            END LOOP;
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_child_det_hist;
    /**********************************************************************************************
    * grid function
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               pediatric assessment type 
    * @param o_content                content cursor
    * @param o_grid                   grid cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/27
    **********************************************************************************************/
    FUNCTION get_child_grid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_content    OUT pk_types.cursor_type,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'call get_child_grid_report';
        IF NOT get_child_grid_report(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_id_patient => i_id_patient,
                                     i_flg_type   => i_flg_type,
                                     i_id_episode => NULL,
                                     i_report     => NULL,
                                     o_content    => o_content,
                                     o_grid       => o_grid,
                                     o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_CHILD_GRID',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_content);
            RETURN FALSE;
    END get_child_grid;
    /**********************************************************************************************
    * grid function
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               pediatric assessment type 
    * @param i_id_episode             episode id
    * @param o_content                content cursor
    * @param o_grid                   grid cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/27
    **********************************************************************************************/
    FUNCTION get_child_grid_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_report     IN VARCHAR2,
        o_content    OUT pk_types.cursor_type,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market  institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        l_episode table_number := table_number();
    BEGIN
        g_error   := 'call pk_patient.get_episode_list';
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_id_patient,
                                                 i_id_episode        => i_id_episode,
                                                 i_flg_visit_or_epis => i_report);
    
        g_error := 'GET o_content';
        OPEN o_content FOR
            SELECT cfd.id_child_feed_dev id_child_feed_dev,
                   pk_translation.get_translation(i_lang, cfd.code_child_feed_dev) desc_child_feed_dev,
                   cfd.age_min age_min,
                   cfd.age_max age_max
              FROM child_feed_dev cfd
             WHERE cfd.flg_type = i_flg_type
               AND is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, l_market) = pk_alert_constant.g_yes
             ORDER BY nvl(get_cfd_rank(i_lang, i_prof, cfd.id_child_feed_dev, l_market), cfd.rank);
    
        g_error := 'GET o_grid';
        OPEN o_grid FOR
            SELECT cfd.id_child_feed_dev id_child_feed_dev,
                   pcfd.child_age        child_age,
                   pcfd.flg_status       flg_status,
                   pcfd.id_episode       id_episode
              FROM pat_child_feed_dev pcfd
              JOIN child_feed_dev cfd
                ON pcfd.id_child_feed_dev = cfd.id_child_feed_dev
               AND cfd.flg_type = i_flg_type
             WHERE pcfd.id_patient = i_id_patient
               AND pcfd.flg_status IN (g_active, g_verified)
               AND pk_child.is_cfd_available(i_lang, i_prof, cfd.id_child_feed_dev, l_market) = pk_alert_constant.g_yes
               AND (nvl(i_report, g_report_p) = g_report_p OR
                   pcfd.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                         d.column_value
                                          FROM TABLE(l_episode) d))
             ORDER BY nvl(get_cfd_rank(i_lang, i_prof, cfd.id_child_feed_dev, l_market), cfd.rank), child_age;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHILD_GRID_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_content);
            RETURN FALSE;
    END get_child_grid_report;

    /**************************************************************************
    * validate input data
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             id do patient
    * @param i_info                   data to validate
    * @param i_flg_type               pediatric assessment type 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/27
    **************************************************************************/
    FUNCTION validate_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER(12);
        l_tab   table_table_varchar;
        l_found BOOLEAN;
    BEGIN
        g_error := 'pk_child.validate_data';
        IF i_flg_type IS NULL
           OR i_flg_type NOT IN (g_food, g_dev)
        THEN
            g_error := 'flg_type cannot be null, it must be ''A'' or ''P''';
            RAISE g_exception;
        END IF;
    
        IF i_id_patient IS NULL
        THEN
            g_error := 'id_patient cannot be null';
            RAISE g_exception;
        END IF;
    
        SELECT table_varchar(pcfd.id_child_feed_dev, pcfd.child_age, pcfd.flg_status)
          BULK COLLECT
          INTO l_tab
          FROM pat_child_feed_dev pcfd
          JOIN child_feed_dev cfd
            ON cfd.id_child_feed_dev = pcfd.id_child_feed_dev
           AND cfd.flg_type = i_flg_type
         WHERE pcfd.id_patient = i_id_patient
         ORDER BY pcfd.id_child_feed_dev, pcfd.child_age;
    
        IF i_info IS NULL
        THEN
            g_error := 'table_table_varchar cannot be null';
            RAISE g_exception;
        END IF;
    
        FOR i IN i_info.first .. i_info.last
        LOOP
            IF i_info(i) (1) IS NULL
               OR i_info(i) (2) IS NULL
               OR i_info(i) (3) IS NULL
            THEN
                g_error := 'some elements in the table_table_varchar are null';
                RAISE g_exception;
            END IF;
        
            SELECT COUNT(1)
              INTO l_count
              FROM child_feed_dev cfd
             WHERE cfd.id_child_feed_dev = i_info(i) (1)
               AND cfd.flg_type = i_flg_type;
        
            IF l_count = 0
            THEN
                g_error := 'content does not exist';
                RAISE g_exception;
            END IF;
        
            IF i_flg_type = g_food
               AND i_info(i) (3) = g_verified
            THEN
                g_error := 'nutrition does not support verifed but not achieved status';
                RAISE g_exception;
            END IF;
        
            IF i_info(i) (3) NOT IN (g_active, g_verified, g_cancelled)
            THEN
                g_error := 'status not in scope';
                RAISE g_exception;
            END IF;
        
            IF i_info(i) (3) = g_cancelled
            THEN
                SELECT COUNT(1)
                  INTO l_count
                  FROM pat_child_feed_dev pcfd
                 WHERE pcfd.id_patient = i_id_patient
                   AND pcfd.id_child_feed_dev = i_info(i) (1)
                   AND pcfd.child_age = i_info(i) (2);
            END IF;
        
            IF l_count = 0
            THEN
                g_error := 'can only cancel existing records';
                RAISE g_exception;
            END IF;
        
            FOR j IN i + 1 .. i_info.last
            LOOP
                IF i_info(i) (1) = i_info(j) (1)
                   AND i_info(i) (2) = i_info(j) (2)
                   AND i_info(i) (3) = i_info(j) (3)
                THEN
                    g_error := 'duplicate information';
                    RAISE g_exception;
                END IF;
            
                IF i_flg_type = g_dev
                   AND i_info(i) (1) = i_info(j) (1)
                   AND i_info(i) (3) = g_active
                   AND i_info(j) (3) = g_active
                THEN
                    g_error := 'develpment milestones, cannot insert same milestone in a diferent months';
                    RAISE g_exception;
                END IF;
            
                IF i_flg_type = g_dev
                   AND i_info(i) (1) = i_info(j) (1)
                   AND i_info(i) (3) = g_active
                   AND i_info(j) (3) = g_verified
                   AND to_number(i_info(i) (2)) < to_number(i_info(j) (2))
                THEN
                    g_error := 'develpment milestones, cannot insert an not achieved after an achieved';
                    RAISE g_exception;
                END IF;
            END LOOP;
        
            l_found := FALSE;
            IF l_tab.count > 0
            THEN
                FOR j IN l_tab.first .. l_tab.last
                LOOP
                    IF i_info(i) (1) = l_tab(j) (1)
                       AND i_info(i) (2) = l_tab(j) (2)
                    THEN
                        IF l_tab(j) (3) = i_info(i) (3)
                        THEN
                            g_error := 'duplicate information';
                            RAISE g_exception;
                        END IF;
                        l_tab(j)(3) := i_info(i) (3);
                        l_found := TRUE;
                    END IF;
                END LOOP;
            END IF;
        
            IF NOT l_found
            THEN
                l_tab.extend;
                l_tab(l_tab.count) := i_info(i);
            END IF;
        END LOOP;
    
        IF i_flg_type = g_dev
           AND l_tab.count > 0
        THEN
            FOR i IN l_tab.first .. l_tab.last
            LOOP
                FOR j IN i + 1 .. l_tab.last
                LOOP
                    IF l_tab(i) (1) = l_tab(j) (1)
                       AND l_tab(i) (3) = g_active
                       AND l_tab(j) (3) = g_active
                    THEN
                        g_error := 'develpment milestones, cannot insert same milestone in a diferent month';
                        RAISE g_exception;
                    END IF;
                
                    IF l_tab(i) (1) = l_tab(j) (1)
                       AND l_tab(i) (3) = g_active
                       AND l_tab(j) (3) = g_verified
                       AND to_number(l_tab(i) (2)) < to_number(l_tab(j) (2))
                    THEN
                        g_error := 'develpment milestones, cannot insert an not achieved after an achieved';
                        RAISE g_exception;
                    END IF;
                END LOOP;
            END LOOP;
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
                                              'VALIDATE_DATA',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_data;

    /**
    * Returns a set of records done in a touch-option area based on scope criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor containing information about registers (professional, record date, status, etc.)
    * @param   o_doc_area_val       Cursor containing information about data values saved in registers
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_doc_template_order order by id_doc_template rank defined on ped_area_add
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message
    *
    * @return  True or False on success or error
    *
    * @author  Paulo Teixeira
    * @version 2.5.1.6
    * @since   2011/07/22
    */
    FUNCTION get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_doc_template_order OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'call pk_summary_page.get_doc_area_value';
        IF NOT pk_summary_page.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_current_episode,
                                                  i_scope              => i_scope,
                                                  i_scope_type         => i_scope_type,
                                                  i_paging             => i_paging,
                                                  i_start_record       => i_start_record,
                                                  i_num_records        => i_num_records,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => o_record_count,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'call get_doc_template_order';
        IF NOT get_doc_template_order(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_episode            => i_current_episode,
                                      i_doc_area           => i_doc_area,
                                      o_doc_template_order => o_doc_template_order,
                                      o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_DOC_AREA_VALUE',
                                              o_error);
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_doc_template_order);
            RETURN FALSE;
    END get_doc_area_value;
    /**********************************************************************************************
    * get_doc_template_order
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_doc_template_order                   grid cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo teixeira
    * @version                        2.5.1.5 
    * @since                          2011/07/22
    **********************************************************************************************/
    FUNCTION get_doc_template_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_template_order OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market     institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        l_id_patient patient.id_patient%TYPE;
        l_gender     patient.gender%TYPE;
        l_year_age   NUMBER(12);
        l_month_age  NUMBER(12);
        l_week_age   NUMBER(12);
        l_day_age    NUMBER(12);
    BEGIN
        g_error := 'get id_patient';
        BEGIN
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_patient := NULL;
        END;
    
        g_error := 'call get_pat_age';
        IF NOT get_pat_age(i_lang       => i_lang,
                           i_prof       => i_prof,
                           i_id_patient => l_id_patient,
                           o_gender     => l_gender,
                           o_year_age   => l_year_age,
                           o_month_age  => l_month_age,
                           o_week_age   => l_week_age,
                           o_day_age    => l_day_age,
                           o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET o_doc_template_order';
        OPEN o_doc_template_order FOR
            SELECT paa.id_doc_template id_doc_template,
                   pk_translation.get_translation(i_lang, paa.code_ped_area_add) desc_template
              FROM ped_area_add paa
              JOIN ped_area pa
                ON pa.id_ped_area = paa.id_ped_area
             WHERE pa.id_doc_area = i_doc_area
               AND is_pasi_available(i_lang, i_prof, paa.id_ped_area_add, l_market) = pk_alert_constant.g_yes
               AND nvl(paa.flg_gender, pk_schedule.g_gender_undefined) IN (pk_schedule.g_gender_undefined, l_gender)
               AND EXISTS (SELECT 1
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ed.id_doc_template = paa.id_doc_template
                       AND ed.id_doc_area = pa.id_doc_area
                       AND e.id_patient = l_id_patient
                       AND rownum = 1)
             ORDER BY nvl(get_pasi_rank(i_lang, i_prof, paa.id_ped_area_add, l_market), paa.rank);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_TEMPLATE_ORDER',
                                              o_error);
            pk_types.open_my_cursor(o_doc_template_order);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Get concated child development/nutrition description by id patientand flg_type
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id patient
    * @param i_flg_type               Flg type -'P' - development , 'A' - nutrition
    * @param o_desc                   CLOB with the detail about patient dev/nutr
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Anna Kurowska
    * @version                        2.6.3  
    * @since                          2013/01/29
    **********************************************************************************************/
    FUNCTION get_child_det_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_desc       OUT CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_det_desc    pk_types.cursor_type;
        l_months      VARCHAR(1000 CHAR);
        l_achived     CLOB;
        l_not_achived CLOB;
    BEGIN
    
        g_error := 'CALL pk_child.get_child_det_summary.';
        IF NOT pk_child.get_child_det_summary(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_patient => i_id_patient,
                                              i_flg_type   => i_flg_type,
                                              o_det        => l_det_desc,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_desc := '';
        LOOP
            g_error := 'fetch record from l_det_descs cursor';
        
            -- if this patient has child information fetch it
            IF l_det_desc IS NOT NULL
            THEN
                FETCH l_det_desc
                    INTO l_months, l_achived, l_not_achived;
                EXIT WHEN l_det_desc%NOTFOUND;
            ELSE
                pk_types.open_my_cursor(l_det_desc);
                EXIT;
            END IF;
        
            -- add new line to the string
            IF o_desc IS NOT NULL
            THEN
                o_desc := o_desc || g_new_line;
            END IF;
        
            IF l_months IS NOT NULL
            THEN
                o_desc := o_desc || l_months;
            
                IF l_achived IS NOT NULL
                THEN
                    o_desc := o_desc || g_new_line || g_space || l_achived;
                END IF;
            
                IF l_not_achived IS NOT NULL
                THEN
                    o_desc := o_desc || g_new_line || g_space || l_not_achived;
                END IF;
            
            END IF;
        
        END LOOP;
    
        CLOSE l_det_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHILD_DET_DESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_child_det_desc;

    FUNCTION is_template_available
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN VARCHAR2 IS
        l_gender patient.gender%TYPE;
        l_age    patient.age%TYPE;
    
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        g_error := 'CALLING GET_PAT_INFO_BY_PATIENT';
        IF NOT pk_patient.get_pat_info_by_patient(i_lang, i_id_patient, l_gender, l_age)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'pk_child.is_template_available';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_return
              FROM (SELECT COUNT(1) AS cnt
                      FROM doc_template_area_doc dtad
                     INNER JOIN documentation d
                        ON dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dcomp
                        ON dcomp.id_doc_component = d.id_doc_component
                     INNER JOIN doc_dimension dd
                        ON d.id_doc_dimension = dd.id_doc_dimension
                     WHERE dtad.id_doc_template = i_doc_template
                       AND dtad.id_doc_area = i_doc_area
                          -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
                       AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
                       AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
                       AND d.flg_available = pk_alert_constant.g_available
                       AND dcomp.flg_available = pk_alert_constant.g_available
                       AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR
                           l_gender = pk_touch_option.g_gender_i)
                       AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR
                           l_age IS NULL))
             WHERE cnt > 0;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := pk_alert_constant.g_no;
        END;
    
        pk_alertlog.log_error('i_doc_area: ' || i_doc_area);
        pk_alertlog.log_error('i_doc_template: ' || i_doc_template);
        pk_alertlog.log_error('l_return: ' || l_return);
    
        RETURN l_return;
    END is_template_available;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_child;
/
