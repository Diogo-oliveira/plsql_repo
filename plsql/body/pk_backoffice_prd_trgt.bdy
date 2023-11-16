/*-- Last Change Revision: $Rev: 2026794 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_prd_trgt IS

    -- Purpose : Production Target functionality

    /** @headcom
    * Public Function. Get Production target information
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param       o_production_target       Production target cursor
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_production_target
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        o_production_target OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_category prof_cat.id_category%TYPE;
        l_no_value         CONSTANT VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'ADMINISTRATOR_T432');
        l_total_percentage CONSTANT VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'ADMINISTRATOR_T457');
        l_get_dep_clin_serv table_number;
    
    BEGIN
    
        g_error := 'Input parameters: i_lang=' || i_lang || ', i_prof=profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')';
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            l_get_dep_clin_serv := get_dep_clin_serv(i_lang, i_prof);
        
            g_error := 'CALCULATE PROF_CAT';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET ' || g_error);
        
            SELECT pc.id_category
              INTO l_category
              FROM prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            /*If the professional is a physician (ID_category = 1) then the cursor o_production_target must return all 
            the goals for himself and all the objectives of all specialties to which it is allocated.*/
        
            g_error := 'PROF_CAT: CATEGORY=' || l_category;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET ' || g_error);
        
            IF l_category = g_physician_category
            THEN
            
                g_error := 'L_CATEGORY=1: OPEN O_PRODUCTION_TARGET';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET ' || g_error);
            
                OPEN o_production_target FOR
                    SELECT DISTINCT id_production_target,
                                    subject_id,
                                    subject,
                                    type_slot,
                                    start_date,
                                    end_date,
                                    flag_target,
                                    target,
                                    probability_target,
                                    flag_possible,
                                    possible,
                                    probability_possible,
                                    flag_probable,
                                    probable,
                                    probability_probable,
                                    flag_real,
                                    REAL,
                                    probability_real,
                                    flag_subject
                      FROM (SELECT DISTINCT pt.id_production_target,
                                            pt.id_professional_subject subject_id,
                                            (SELECT p.name ||
                                                    decode(p.title,
                                                           NULL,
                                                           NULL,
                                                           ', ' ||
                                                           pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang))
                                               FROM professional p
                                              WHERE p.id_professional = pt.id_professional_subject) subject,
                                            
                                            (get_sch_dep_type(i_lang, pt.id_sch_dep_type) || ', ' ||
                                            get_clinical_service(i_lang, pt.id_dcs_type_slot)
                                            
                                            || ', ' || get_sch_event(i_lang, pt.id_sch_event)) type_slot,
                                            
                                            pt.dt_start start_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_start,
                                                                     i_prof.institution,
                                                                     i_prof.software) start_date,
                                            pt.dt_end end_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_end,
                                                                     i_prof.institution,
                                                                     i_prof.software) end_date,
                                            
                                            decode(pt.target, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flag_target,
                                            decode(pt.target, NULL, l_no_value, pt.target) target,
                                            decode(pt.target, NULL, NULL, l_total_percentage) probability_target,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_possible(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_possible,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_probable(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_probable,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_real,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution)) REAL,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_real(i_lang,
                                                                    pt.id_professional_subject,
                                                                    pt.id_dcs_subject,
                                                                    pt.id_dcs_type_slot,
                                                                    pt.id_sch_event,
                                                                    pt.id_sch_dep_type,
                                                                    pt.dt_start,
                                                                    pt.dt_end,
                                                                    pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_real,
                                            g_professional flag_subject
                              FROM production_target pt
                             WHERE pt.id_professional_subject = i_prof.id
                               AND pt.id_institution = i_prof.institution
                               AND pt.id_software = i_prof.software
                               AND pt.id_dcs_subject IS NULL
                               AND pt.flg_available = pk_alert_constant.g_yes
                               AND pt.id_dcs_type_slot IN (SELECT *
                                                             FROM TABLE(l_get_dep_clin_serv))
                            
                            UNION ALL
                            SELECT DISTINCT pt.id_production_target,
                                            pt.id_dcs_subject subject_id,
                                            get_clinical_service(i_lang, pt.id_dcs_subject) subject,
                                            (get_sch_dep_type(i_lang, pt.id_sch_dep_type) || ', ' ||
                                            get_clinical_service(i_lang, pt.id_dcs_type_slot) || ', ' ||
                                            get_sch_event(i_lang, pt.id_sch_event)) type_slot,
                                            
                                            pt.dt_start start_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_start,
                                                                     i_prof.institution,
                                                                     i_prof.software) start_date,
                                            pt.dt_end end_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_end,
                                                                     i_prof.institution,
                                                                     i_prof.software) end_date,
                                            
                                            decode(pt.target, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flag_target,
                                            decode(pt.target, NULL, l_no_value, pt.target) target,
                                            decode(pt.target, NULL, NULL, l_total_percentage) probability_target,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_possible(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_possible,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_probable(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_probable,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_real,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution)) REAL,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_real(i_lang,
                                                                    pt.id_professional_subject,
                                                                    pt.id_dcs_subject,
                                                                    pt.id_dcs_type_slot,
                                                                    pt.id_sch_event,
                                                                    pt.id_sch_dep_type,
                                                                    pt.dt_start,
                                                                    pt.dt_end,
                                                                    pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_real,
                                            g_speciality flag_subject
                              FROM production_target pt
                             WHERE pt.id_dcs_subject IN (SELECT *
                                                           FROM TABLE(l_get_dep_clin_serv))
                                  
                               AND pt.id_dcs_type_slot IN (SELECT *
                                                             FROM TABLE(l_get_dep_clin_serv))
                                  
                               AND pt.id_institution = i_prof.institution
                               AND pt.id_software = i_prof.software
                               AND pt.id_professional_subject IS NULL
                               AND pt.flg_available = pk_alert_constant.g_yes)
                    
                     ORDER BY flag_subject, subject, type_slot;
            
                /*If the professional is an administrative (ID_category = 4) then the cursor o_production_target should return  
                all objectives for all professionals who belong to the institution and software Outpatient and are 
                allocated to the same specialty as the administrative. In addition, The cursor must also list all the objectives of 
                all specialties to which it is allocated.*/
            
            ELSIF l_category = g_administrative_category
            THEN
            
                g_error := 'L_CATEGORY=4: OPEN O_PRODUCTION_TARGET';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET ' || g_error);
            
                OPEN o_production_target FOR
                    SELECT DISTINCT id_production_target,
                                    subject_id,
                                    subject,
                                    type_slot,
                                    start_date,
                                    end_date,
                                    flag_target,
                                    target,
                                    probability_target,
                                    flag_possible,
                                    possible,
                                    probability_possible,
                                    flag_probable,
                                    probable,
                                    probability_probable,
                                    flag_real,
                                    REAL,
                                    probability_real,
                                    flag_subject
                      FROM (SELECT DISTINCT pt.id_production_target,
                                            pt.id_professional_subject subject_id,
                                            (SELECT p.name ||
                                                    decode(p.title,
                                                           NULL,
                                                           NULL,
                                                           ', ' ||
                                                           pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang))
                                               FROM professional p
                                              WHERE p.id_professional = pt.id_professional_subject) subject,
                                            (get_sch_dep_type(i_lang, pt.id_sch_dep_type) || ', ' ||
                                            get_clinical_service(i_lang, pt.id_dcs_type_slot) || ', ' ||
                                            get_sch_event(i_lang, pt.id_sch_event)) type_slot,
                                            
                                            pt.dt_start start_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_start,
                                                                     i_prof.institution,
                                                                     i_prof.software) start_date,
                                            pt.dt_end end_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_end,
                                                                     i_prof.institution,
                                                                     i_prof.software) end_date,
                                            
                                            decode(pt.target, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flag_target,
                                            decode(pt.target, NULL, l_no_value, pt.target) target,
                                            decode(pt.target, NULL, NULL, l_total_percentage) probability_target,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_possible(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_possible,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_probable(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_probable,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_real,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution)) REAL,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_real(i_lang,
                                                                    pt.id_professional_subject,
                                                                    pt.id_dcs_subject,
                                                                    pt.id_dcs_type_slot,
                                                                    pt.id_sch_event,
                                                                    pt.id_sch_dep_type,
                                                                    pt.dt_start,
                                                                    pt.dt_end,
                                                                    pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_real,
                                            g_professional flag_subject
                              FROM production_target pt
                             WHERE pt.id_professional_subject IN
                                   (SELECT psi.id_professional
                                      FROM prof_soft_inst psi, prof_dep_clin_serv pdcs
                                     WHERE psi.id_institution = i_prof.institution
                                       AND psi.id_software = i_prof.software
                                       AND psi.id_professional = pdcs.id_professional
                                       AND pdcs.id_dep_clin_serv IN
                                           (SELECT *
                                              FROM TABLE(l_get_dep_clin_serv))
                                          
                                       AND pdcs.flg_status = pk_alert_constant.g_status_selected)
                                  
                               AND pt.id_institution = i_prof.institution
                               AND pt.id_software = i_prof.software
                               AND pt.id_dcs_subject IS NULL
                               AND pt.flg_available = pk_alert_constant.g_yes
                               AND pt.id_dcs_type_slot IN (SELECT *
                                                             FROM TABLE(l_get_dep_clin_serv))
                            
                            UNION ALL
                            SELECT DISTINCT pt.id_production_target,
                                            pt.id_dcs_subject subject_id,
                                            get_clinical_service(i_lang, pt.id_dcs_subject) subject,
                                            (get_sch_dep_type(i_lang, pt.id_sch_dep_type) || ', ' ||
                                            get_clinical_service(i_lang, pt.id_dcs_type_slot) || ', ' ||
                                            get_sch_event(i_lang, pt.id_sch_event)) type_slot,
                                            
                                            pt.dt_start start_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_start,
                                                                     i_prof.institution,
                                                                     i_prof.software) start_date,
                                            pt.dt_end end_date_db,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pt.dt_end,
                                                                     i_prof.institution,
                                                                     i_prof.software) end_date,
                                            
                                            decode(pt.target, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flag_target,
                                            decode(pt.target, NULL, l_no_value, pt.target) target,
                                            decode(pt.target, NULL, NULL, l_total_percentage) probability_target,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) possible,
                                            decode(get_possible(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_possible(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_possible,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution)) probable,
                                            decode(get_probable(i_lang,
                                                                pt.id_professional_subject,
                                                                pt.id_dcs_subject,
                                                                pt.id_dcs_type_slot,
                                                                pt.id_sch_event,
                                                                pt.id_sch_dep_type,
                                                                pt.dt_start,
                                                                pt.dt_end,
                                                                pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_probable(i_lang,
                                                                        pt.id_professional_subject,
                                                                        pt.id_dcs_subject,
                                                                        pt.id_dcs_type_slot,
                                                                        pt.id_sch_event,
                                                                        pt.id_sch_dep_type,
                                                                        pt.dt_start,
                                                                        pt.dt_end,
                                                                        pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_probable,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   pk_alert_constant.g_no,
                                                   pk_alert_constant.g_yes) flag_real,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   l_no_value,
                                                   get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution)) REAL,
                                            decode(get_real(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution),
                                                   NULL,
                                                   NULL,
                                                   round(((get_real(i_lang,
                                                                    pt.id_professional_subject,
                                                                    pt.id_dcs_subject,
                                                                    pt.id_dcs_type_slot,
                                                                    pt.id_sch_event,
                                                                    pt.id_sch_dep_type,
                                                                    pt.dt_start,
                                                                    pt.dt_end,
                                                                    pt.id_institution) / pt.target) * 100),
                                                         2) || '%') probability_real,
                                            g_speciality flag_subject
                              FROM production_target pt
                             WHERE pt.id_dcs_subject IN (SELECT *
                                                           FROM TABLE(l_get_dep_clin_serv))
                                  
                               AND pt.id_dcs_type_slot IN (SELECT *
                                                             FROM TABLE(l_get_dep_clin_serv))
                                  
                               AND pt.id_institution = i_prof.institution
                               AND pt.id_software = i_prof.software
                               AND pt.id_professional_subject IS NULL
                               AND pt.flg_available = pk_alert_constant.g_yes)
                     ORDER BY flag_subject, subject, type_slot;
            ELSE
            
                g_error := 'L_CATEGORY NOT IN (1,4): OPEN O_PRODUCTION_TARGET';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET ' || g_error);
            
                OPEN o_production_target FOR
                    SELECT NULL id_production_target,
                           NULL subject_id,
                           NULL subject,
                           NULL type_slot,
                           NULL start_date,
                           NULL end_date,
                           NULL flag_target,
                           NULL target,
                           NULL probability_target,
                           NULL flag_possible,
                           NULL possible,
                           NULL probability_possible,
                           NULL flag_probable,
                           NULL probable,
                           NULL probability_probable,
                           NULL flag_real,
                           NULL REAL,
                           NULL probability_real,
                           NULL flag_subject
                      FROM dual;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_production_target);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_PRODUCTION_TARGET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_production_target;

    /** @headcom
    * Public Function. Create/Edit Production target
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_production_target        Production Target identification
    * @param      i_subject                  Subject identification
    * @param      i_flag_subject             Flag Subject: D-Professional, S-Speciality
    * @param      i_type_schedule            Schedule Type identification
    * @param      i_dep_clin_serv            Service/speciality identification
    * @param      i_type_event               Event Type identification
    * @param      i_start_date               Target start date
    * @param      i_end_date                 Target end date
    * @param      i_target                   Target value
    * @param      i_notes                    Notes
    * @param      o_id_production_target     Production target record id
    * @param      o_id_production_target_hist     Production target history record id
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION set_production_target
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        i_production_target         IN production_target.id_production_target%TYPE,
        i_subject                   IN NUMBER,
        i_flag_subject              IN VARCHAR2,
        i_type_schedule             IN NUMBER,
        i_dep_clin_serv             IN NUMBER,
        i_type_event                IN NUMBER,
        i_start_date                IN VARCHAR2,
        i_end_date                  IN VARCHAR2,
        i_target                    IN NUMBER,
        i_notes                     IN VARCHAR2,
        o_id_production_target      OUT NUMBER,
        o_id_production_target_hist OUT NUMBER,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_production_target      production_target.id_production_target%TYPE;
        l_id_production_target_hist production_target_hist.id_production_target_hist%TYPE;
        l_rows_out                  table_varchar;
        l_error                     t_error_out;
        l_count_records             PLS_INTEGER;
        l_error_message             VARCHAR2(200);
        my_exception_msg EXCEPTION;
        l_start_date              production_target.dt_start%TYPE;
        l_end_date                production_target.dt_end%TYPE;
        l_id_pt_inactive          production_target.id_production_target%TYPE;
        l_count_records_inactive  PLS_INTEGER := 0;
        l_id_pt                   production_target.id_production_target%TYPE;
        l_number_inactive_default PLS_INTEGER := 1;
        l_current_timestamp       TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS: i_lang=' || i_lang || ', i_prof=PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), i_production_target=' || i_production_target ||
                   ', i_subject=' || i_subject || ', i_flag_subject=' || i_flag_subject || ', i_type_schedule=' ||
                   i_type_schedule || ', i_dep_clin_serv=' || i_dep_clin_serv || ', i_type_event=' || i_type_event ||
                   ', i_start_date=' || i_start_date || ', i_end_date=' || i_end_date || ', i_target=' || i_target ||
                   ', i_notes=' || i_notes;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
    
        IF i_flag_subject IS NOT NULL
        THEN
        
            l_count_records := 0;
        
            g_error := 'CALCULATE L_START_DATE AND L_END_DATE:';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
        
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_start_date,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_end_date,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'START_DATE=' || l_start_date || ', END_DATE=' || l_end_date;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
        
            /*Counting the number of record active that are equal to the production target inputs*/
        
            IF i_flag_subject = g_doctor
            THEN
            
                g_error := 'IF I_FLAG_SUBJECT = L_DOCTOR/L_COUNT_RECORDS';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                BEGIN
                    SELECT COUNT(*)
                      INTO l_count_records
                      FROM production_target pt
                     WHERE pt.id_professional_subject = i_subject
                       AND pt.id_dcs_type_slot = i_dep_clin_serv
                       AND pt.id_sch_event = i_type_event
                       AND pt.id_sch_dep_type = i_type_schedule
                       AND pt.id_institution = i_prof.institution
                       AND pt.id_software = i_prof.software
                       AND pt.dt_start = l_start_date
                       AND pt.dt_end = l_end_date
                       AND pt.flg_available = pk_alert_constant.g_yes;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count_records := 0;
                END;
            
            ELSE
                g_error := 'I_FLAG_SUBJECT != L_DOCTOR/L_COUNT_RECORDS';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                BEGIN
                    SELECT COUNT(*)
                      INTO l_count_records
                      FROM production_target pt
                     WHERE pt.id_dcs_subject = i_subject
                       AND pt.id_dcs_type_slot = i_dep_clin_serv
                       AND pt.id_sch_event = i_type_event
                       AND pt.id_sch_dep_type = i_type_schedule
                       AND pt.id_institution = i_prof.institution
                       AND pt.id_software = i_prof.software
                       AND pt.dt_start = l_start_date
                       AND pt.dt_end = l_end_date
                       AND pt.flg_available = pk_alert_constant.g_yes;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count_records := 0;
                END;
            
            END IF;
        
            g_error := 'L_COUNT_RECORDS=' || l_count_records;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
        
            /*If some active record are found then, an error should appear, otherwise, the production target can be a new record or
            can be an inactive record*/
        
            IF l_count_records > 0
               AND i_production_target IS NULL
            THEN
                g_error := 'IF L_COUNT_RECORDS>0 AND i_production_target IS NULL';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                RAISE my_exception_msg;
            ELSE
            
                SELECT current_timestamp
                  INTO l_current_timestamp
                  FROM dual;
            
                g_error := 'IF L_COUNT_RECORDS<=0| l_current_timestamp=|' || l_current_timestamp ||
                           ', CALCULATE seq_production_target.NEXTVAL';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                SELECT seq_production_target.NEXTVAL
                  INTO l_id_production_target
                  FROM dual;
            
                g_error := 'L_ID_PRODUCTION_TARGET=' || l_id_production_target ||
                           ' CALCULATE  L_ID_PRODUCTION_TARGET_HIST:';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                SELECT seq_production_target_hist.NEXTVAL
                  INTO l_id_production_target_hist
                  FROM dual;
            
                g_error := 'L_ID_PRODUCTION_TARGET_HIST=' || l_id_production_target_hist;
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                /*Counting the number of record inactive that are equal to the production target inputs*/
            
                IF i_flag_subject = g_doctor
                THEN
                
                    g_error := 'i_flag_subject = l_doctor| CALCULATE L_COUNT_RECORDS_INACTIVE:';
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET INACTIVE' || g_error);
                
                    BEGIN
                        SELECT COUNT(*)
                          INTO l_count_records_inactive
                          FROM production_target pt
                         WHERE pt.id_professional_subject = i_subject
                           AND pt.id_dcs_type_slot = i_dep_clin_serv
                           AND pt.id_sch_event = i_type_event
                           AND pt.id_sch_dep_type = i_type_schedule
                           AND pt.id_institution = i_prof.institution
                           AND pt.id_software = i_prof.software
                           AND pt.dt_start = l_start_date
                           AND pt.dt_end = l_end_date
                           AND pt.flg_available = pk_alert_constant.g_no;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_count_records_inactive := 0;
                    END;
                
                ELSE
                    g_error := 'I_FLAG_SUBJECT != L_DOCTOR|CALCULATE L_COUNT_RECORDS_INACTIVE:';
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET' || g_error);
                
                    BEGIN
                        SELECT COUNT(*)
                          INTO l_count_records_inactive
                          FROM production_target pt
                         WHERE pt.id_dcs_subject = i_subject
                           AND pt.id_dcs_type_slot = i_dep_clin_serv
                           AND pt.id_sch_event = i_type_event
                           AND pt.id_sch_dep_type = i_type_schedule
                           AND pt.id_institution = i_prof.institution
                           AND pt.id_software = i_prof.software
                           AND pt.dt_start = l_start_date
                           AND pt.dt_end = l_end_date
                           AND pt.flg_available = pk_alert_constant.g_no;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_count_records_inactive := 0;
                    END;
                
                END IF;
            
                g_error := 'L_COUNT_RECORDS_INACTIVE' || l_count_records_inactive;
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET' || g_error);
            
                /*If the production target already exists in the database in an inactive record then this record will be updated for active */
            
                IF l_count_records_inactive = l_number_inactive_default
                THEN
                
                    /*Checking the inactive record identification*/
                
                    IF i_flag_subject = g_doctor
                    THEN
                    
                        g_error := ' IF l_count_records_inactive = 1/IF i_flag_subject = l_doctor/CALCULATE l_id_pt_inactive';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        BEGIN
                            SELECT pt.id_production_target
                              INTO l_id_pt_inactive
                              FROM production_target pt
                             WHERE pt.id_professional_subject = i_subject
                               AND pt.id_dcs_type_slot = i_dep_clin_serv
                               AND pt.id_sch_event = i_type_event
                               AND pt.id_sch_dep_type = i_type_schedule
                               AND pt.id_institution = i_prof.institution
                               AND pt.id_software = i_prof.software
                               AND pt.dt_start = l_start_date
                               AND pt.dt_end = l_end_date
                               AND pt.flg_available = pk_alert_constant.g_no;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_pt_inactive := NULL;
                        END;
                    
                    ELSE
                        g_error := 'IF l_count_records_inactive = 1/CALCULATE l_id_pt_inactive';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        BEGIN
                            SELECT pt.id_production_target
                              INTO l_id_pt_inactive
                              FROM production_target pt
                             WHERE pt.id_dcs_subject = i_subject
                               AND pt.id_dcs_type_slot = i_dep_clin_serv
                               AND pt.id_sch_event = i_type_event
                               AND pt.id_sch_dep_type = i_type_schedule
                               AND pt.id_institution = i_prof.institution
                               AND pt.id_software = i_prof.software
                               AND pt.dt_start = l_start_date
                               AND pt.dt_end = l_end_date
                               AND pt.flg_available = pk_alert_constant.g_no;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_pt_inactive := NULL;
                        END;
                    
                    END IF;
                
                END IF;
            
                g_error := 'L_ID_PT_INACTIVE=' || l_id_pt_inactive;
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
            
                /*If the production target is a new record and don´t exists in a inactive record in the database then
                the information will be inserted*/
                IF (i_production_target IS NULL AND l_count_records_inactive = 0)
                THEN
                    g_error := 'IF I_PRODUCTION_TARGET IS NULL AND l_count_records_inactive = 0';
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                
                    /*If the production target subject is a physiscian then the id_professional_subject sould be written, otherwise, 
                    the id_dcs_subject sould be written*/
                    IF i_flag_subject = g_doctor
                    THEN
                        g_error := 'IF I_FLAG_SUBJECT=L_DOCTOR/ PRODUCTION_TARGET INSERT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target.ins(id_production_target_in    => l_id_production_target,
                                                 id_professional_subject_in => i_subject,
                                                 id_dcs_type_slot_in        => i_dep_clin_serv,
                                                 id_sch_event_in            => i_type_event,
                                                 id_sch_dep_type_in         => i_type_schedule,
                                                 id_institution_in          => i_prof.institution,
                                                 id_software_in             => i_prof.software,
                                                 dt_start_in                => l_start_date,
                                                 dt_end_in                  => l_end_date,
                                                 target_in                  => i_target,
                                                 notes_in                   => i_notes,
                                                 flg_available_in           => pk_alert_constant.g_yes,
                                                 dt_create_in               => l_current_timestamp,
                                                 prof_create_in             => i_prof.id,
                                                 rows_out                   => l_rows_out);
                    
                        g_error := 'PROCESS_INSERT PRODUCTION_TARGET';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'PRODUCTION_TARGET_HIST INSERT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target_hist.ins(id_production_target_hist_in => l_id_production_target_hist,
                                                      id_production_target_in      => l_id_production_target,
                                                      id_professional_subject_in   => i_subject,
                                                      id_dcs_type_slot_in          => i_dep_clin_serv,
                                                      id_sch_event_in              => i_type_event,
                                                      id_sch_dep_type_in           => i_type_schedule,
                                                      id_institution_in            => i_prof.institution,
                                                      id_software_in               => i_prof.software,
                                                      dt_start_in                  => l_start_date,
                                                      dt_end_in                    => l_end_date,
                                                      target_in                    => i_target,
                                                      notes_in                     => i_notes,
                                                      flg_available_in             => pk_alert_constant.g_yes,
                                                      dt_create_in                 => l_current_timestamp,
                                                      prof_create_in               => i_prof.id,
                                                      rows_out                     => l_rows_out);
                    
                        g_error := 'PROCESS_INSERT PRODUCTION_TARGET_HIST';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET_HIST',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'CALCULATE o_id_production_target/o_id_production_target_hist';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        o_id_production_target      := l_id_production_target;
                        o_id_production_target_hist := l_id_production_target_hist;
                    
                    ELSE
                    
                        g_error := 'IF I_FLAG_SUBJECT!=L_DOCTOR/ PRODUCTION_TARGET INSERT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target.ins(id_production_target_in => l_id_production_target,
                                                 id_dcs_subject_in       => i_subject,
                                                 id_dcs_type_slot_in     => i_dep_clin_serv,
                                                 id_sch_event_in         => i_type_event,
                                                 id_sch_dep_type_in      => i_type_schedule,
                                                 id_institution_in       => i_prof.institution,
                                                 id_software_in          => i_prof.software,
                                                 dt_start_in             => l_start_date,
                                                 dt_end_in               => l_end_date,
                                                 target_in               => i_target,
                                                 notes_in                => i_notes,
                                                 flg_available_in        => pk_alert_constant.g_yes,
                                                 dt_create_in            => l_current_timestamp,
                                                 prof_create_in          => i_prof.id,
                                                 rows_out                => l_rows_out);
                    
                        g_error := 'PROCESS_INSERT PRODUCTION_TARGET';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'PRODUCTION_TARGET_HIST INSERT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target_hist.ins(id_production_target_hist_in => l_id_production_target_hist,
                                                      id_production_target_in      => l_id_production_target,
                                                      id_dcs_subject_in            => i_subject,
                                                      id_dcs_type_slot_in          => i_dep_clin_serv,
                                                      id_sch_event_in              => i_type_event,
                                                      id_sch_dep_type_in           => i_type_schedule,
                                                      id_institution_in            => i_prof.institution,
                                                      id_software_in               => i_prof.software,
                                                      dt_start_in                  => l_start_date,
                                                      dt_end_in                    => l_end_date,
                                                      target_in                    => i_target,
                                                      notes_in                     => i_notes,
                                                      flg_available_in             => pk_alert_constant.g_yes,
                                                      dt_create_in                 => l_current_timestamp,
                                                      prof_create_in               => i_prof.id,
                                                      rows_out                     => l_rows_out);
                    
                        g_error := 'PROCESS_INSERT PRODUCTION_TARGET_HIST';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET_HIST',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'o_id_production_target/o_id_production_target_hist';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        o_id_production_target      := l_id_production_target;
                        o_id_production_target_hist := l_id_production_target_hist;
                    
                    END IF;
                
                    g_error := 'o_id_production_target=' || o_id_production_target || ', o_id_production_target_hist=' ||
                               o_id_production_target_hist;
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                
                ELSE
                
                    g_error := 'ELSE: IF (i_production_target IS NULL AND l_count_records_inactive = 0)';
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                
                    /*If the production target is an inactive record in the database then
                    the production target identification will be the identication of the inactive record*/
                
                    IF l_count_records_inactive = l_number_inactive_default
                    THEN
                        l_id_pt := l_id_pt_inactive;
                    ELSE
                        l_id_pt := i_production_target;
                    END IF;
                
                    g_error := 'L_ID_PT=' || l_id_pt;
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                
                    /*If the production target subject is a physiscian then the information about id_professional_subject should be written in input,
                    otherwise, the id_dcs_subject should be sent in the input.*/
                    IF i_flag_subject = g_doctor
                    THEN
                        g_error := 'IF I_FLAG_SUBJECT=L_DOCTOR/ PRODUCTION_TARGET UPDATE';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target.upd(id_professional_subject_in  => i_subject,
                                                 id_professional_subject_nin => FALSE,
                                                 id_dcs_subject_in           => NULL,
                                                 id_dcs_subject_nin          => FALSE,
                                                 id_dcs_type_slot_in         => i_dep_clin_serv,
                                                 id_dcs_type_slot_nin        => FALSE,
                                                 id_sch_event_in             => i_type_event,
                                                 id_sch_event_nin            => FALSE,
                                                 id_sch_dep_type_in          => i_type_schedule,
                                                 id_sch_dep_type_nin         => FALSE,
                                                 id_institution_in           => i_prof.institution,
                                                 id_institution_nin          => FALSE,
                                                 id_software_in              => i_prof.software,
                                                 id_software_nin             => FALSE,
                                                 dt_start_in                 => l_start_date,
                                                 dt_start_nin                => FALSE,
                                                 dt_end_in                   => l_end_date,
                                                 dt_end_nin                  => FALSE,
                                                 target_in                   => i_target,
                                                 target_nin                  => FALSE,
                                                 notes_in                    => i_notes,
                                                 notes_nin                   => FALSE,
                                                 flg_available_in            => pk_alert_constant.g_yes,
                                                 flg_available_nin           => FALSE,
                                                 dt_create_in                => l_current_timestamp,
                                                 dt_create_nin               => FALSE,
                                                 prof_create_in              => i_prof.id,
                                                 prof_create_nin             => FALSE,
                                                 where_in                    => 'id_production_target=' || l_id_pt,
                                                 rows_out                    => l_rows_out);
                        g_error := 'PROCESS_UPDATE PRODUCTION_TARGET';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'PRODUCTION_TARGET_HIST INSERT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target_hist.ins(id_production_target_hist_in => l_id_production_target_hist,
                                                      id_production_target_in      => l_id_pt,
                                                      id_professional_subject_in   => i_subject,
                                                      id_dcs_type_slot_in          => i_dep_clin_serv,
                                                      id_sch_event_in              => i_type_event,
                                                      id_sch_dep_type_in           => i_type_schedule,
                                                      id_institution_in            => i_prof.institution,
                                                      id_software_in               => i_prof.software,
                                                      dt_start_in                  => l_start_date,
                                                      dt_end_in                    => l_end_date,
                                                      target_in                    => i_target,
                                                      notes_in                     => i_notes,
                                                      flg_available_in             => pk_alert_constant.g_yes,
                                                      dt_create_in                 => l_current_timestamp,
                                                      prof_create_in               => i_prof.id,
                                                      rows_out                     => l_rows_out);
                    
                        g_error := 'PROCESS_INSERT PRODUCTION_TARGET_HIST';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET_HIST',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'o_id_production_target_hist';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        o_id_production_target_hist := l_id_production_target_hist;
                    
                    ELSE
                        g_error := 'IF I_FLAG_SUBJECT!=L_DOCTOR/PRODUCTION_TARGET UPDATE';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target.upd(id_dcs_subject_in           => i_subject,
                                                 id_dcs_subject_nin          => FALSE,
                                                 id_professional_subject_in  => NULL,
                                                 id_professional_subject_nin => FALSE,
                                                 id_dcs_type_slot_in         => i_dep_clin_serv,
                                                 id_dcs_type_slot_nin        => FALSE,
                                                 id_sch_event_in             => i_type_event,
                                                 id_sch_event_nin            => FALSE,
                                                 id_sch_dep_type_in          => i_type_schedule,
                                                 id_sch_dep_type_nin         => FALSE,
                                                 id_institution_in           => i_prof.institution,
                                                 id_institution_nin          => FALSE,
                                                 id_software_in              => i_prof.software,
                                                 id_software_nin             => FALSE,
                                                 dt_start_in                 => l_start_date,
                                                 dt_start_nin                => FALSE,
                                                 dt_end_in                   => l_end_date,
                                                 dt_end_nin                  => FALSE,
                                                 target_in                   => i_target,
                                                 target_nin                  => FALSE,
                                                 notes_in                    => i_notes,
                                                 notes_nin                   => FALSE,
                                                 flg_available_in            => pk_alert_constant.g_yes,
                                                 flg_available_nin           => FALSE,
                                                 dt_create_in                => l_current_timestamp,
                                                 dt_create_nin               => FALSE,
                                                 prof_create_in              => i_prof.id,
                                                 prof_create_nin             => FALSE,
                                                 where_in                    => 'id_production_target=' || l_id_pt,
                                                 rows_out                    => l_rows_out);
                    
                        g_error := 'PROCESS_UPDATE PRODUCTION_TARGET';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'PRODUCTION_TARGET_HIST INSERT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        ts_production_target_hist.ins(id_production_target_hist_in => l_id_production_target_hist,
                                                      id_production_target_in      => l_id_pt,
                                                      id_dcs_subject_in            => i_subject,
                                                      id_dcs_type_slot_in          => i_dep_clin_serv,
                                                      id_sch_event_in              => i_type_event,
                                                      id_sch_dep_type_in           => i_type_schedule,
                                                      id_institution_in            => i_prof.institution,
                                                      id_software_in               => i_prof.software,
                                                      dt_start_in                  => l_start_date,
                                                      dt_end_in                    => l_end_date,
                                                      target_in                    => i_target,
                                                      notes_in                     => i_notes,
                                                      flg_available_in             => pk_alert_constant.g_yes,
                                                      dt_create_in                 => l_current_timestamp,
                                                      prof_create_in               => i_prof.id,
                                                      rows_out                     => l_rows_out);
                    
                        g_error := 'PROCESS_INSERT PRODUCTION_TARGET_HIST';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PRODUCTION_TARGET_HIST',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        g_error := 'o_id_production_target_hist';
                        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                    
                        o_id_production_target_hist := l_id_production_target_hist;
                    
                    END IF;
                
                    g_error := 'o_id_production_target_hist=' || o_id_production_target_hist;
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_PRODUCTION_TARGET ' || g_error);
                
                END IF;
            
            END IF;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception_msg THEN
            DECLARE
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ADMINISTRATOR_T470');
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  'PTT_UK',
                                                  l_error_message,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_BACKOFFICE_PRD_TRGT',
                                                  'SET_PRODUCTION_TARGET',
                                                  'U',
                                                  o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'SET_PRODUCTION_TARGET',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_production_target;

    /** @headcom
    * Public Function. Get subject search
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_search_subject           Subject search
    * @param      o_subject                  Cursor - subject
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_subject_search
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_search_subject IN VARCHAR2,
        o_subject        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_category          prof_cat.id_category%TYPE;
        l_get_dep_clin_serv table_number;
    BEGIN
    
        g_error := 'INPUT PARAMETERS: I_LANG=' || i_lang || ', I_PROF=PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), i_search_subject=' || i_search_subject;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_SEARCH ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            l_get_dep_clin_serv := get_dep_clin_serv(i_lang, i_prof);
        
            g_error := 'IF I_LANG/I_PROF ARE NOT NULL -- CALCULATE L_CATEGORY:';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_SEARCH ' || g_error);
        
            SELECT pc.id_category
              INTO l_category
              FROM prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            g_error := 'L_CATEGORY=' || l_category;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_SEARCH ' || g_error);
        
            /*If the user is a physician then the search can list the professional name and the all speciality name that   
            to which it is allocated.*/
        
            IF l_category = g_physician_category
            THEN
                g_error := 'L_CATEGORY=1/OPEN O_SUBJECT:';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_SEARCH' || g_error);
            
                OPEN o_subject FOR
                    SELECT DISTINCT subject_service, subject_desc, subject_id, subject_type
                      FROM (SELECT NULL subject_service,
                                   p.name ||
                                   decode(p.title,
                                          NULL,
                                          NULL,
                                          ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc,
                                   p.id_professional subject_id,
                                   g_doctor subject_type
                              FROM professional p
                             WHERE p.id_professional = i_prof.id
                            UNION ALL
                            
                            SELECT DISTINCT get_department(i_lang, dcs.id_department) subject_service,
                                            get_clinical_service(i_lang, dcs.id_dep_clin_serv) subject_desc,
                                            dcs.id_dep_clin_serv subject_id,
                                            g_speciality subject_type
                              FROM dep_clin_serv dcs
                             WHERE get_clinical_service(i_lang, dcs.id_dep_clin_serv) IS NOT NULL
                               AND dcs.id_dep_clin_serv IN (SELECT *
                                                              FROM TABLE(l_get_dep_clin_serv)))
                     WHERE subject_desc IS NOT NULL
                       AND translate(upper(subject_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(i_search_subject), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY subject_type, subject_desc, subject_id;
            
                /*If the user is a administrative then the search can list all professionals names who belong to the institution 
                and software Outpatient and are allocated to the same specialty as the administrative and the all speciality name 
                that to which it is allocated.*/
            
            ELSIF l_category = g_administrative_category
            THEN
                g_error := 'L_CATEGORY=4/OPEN O_SUBJECT:';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_SEARCH' || g_error);
            
                OPEN o_subject FOR
                    SELECT DISTINCT subject_service, subject_desc, subject_id, subject_type
                      FROM (SELECT DISTINCT NULL subject_service,
                                            p.name ||
                                            decode(p.title,
                                                   NULL,
                                                   NULL,
                                                   ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc,
                                            pdcs.id_professional subject_id,
                                            g_doctor subject_type
                              FROM prof_soft_inst psi, prof_dep_clin_serv pdcs, professional p
                             WHERE psi.id_institution = i_prof.institution
                               AND psi.id_software = i_prof.software
                               AND psi.id_professional = pdcs.id_professional
                               AND pdcs.id_dep_clin_serv IN (SELECT *
                                                               FROM TABLE(l_get_dep_clin_serv))
                                  
                               AND pdcs.flg_status = pk_alert_constant.g_status_selected
                               AND pdcs.id_professional = p.id_professional
                            UNION ALL
                            SELECT DISTINCT get_department(i_lang, dcs.id_department) subject_service,
                                            get_clinical_service(i_lang, dcs.id_dep_clin_serv) subject_desc,
                                            dcs.id_dep_clin_serv subject_id,
                                            g_speciality subject_type
                              FROM dep_clin_serv dcs
                             WHERE get_clinical_service(i_lang, dcs.id_dep_clin_serv) IS NOT NULL
                               AND dcs.id_dep_clin_serv IN (SELECT *
                                                              FROM TABLE(l_get_dep_clin_serv)))
                     WHERE subject_desc IS NOT NULL
                       AND translate(upper(subject_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(i_search_subject), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                    
                     ORDER BY subject_type, subject_desc, subject_id;
            
            ELSE
                g_error := 'L_CATEGORY not in (1,4)';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_SEARCH' || g_error);
            
                OPEN o_subject FOR
                    SELECT NULL subject_service, NULL subject_desc, NULL subject_id, NULL subject_type
                      FROM dual;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_subject);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_PRODUCTION_TARGET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_subject_search;

    /** @headcom
    * Public Function. Get subject search
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_flag_category            Flag Subject search
    * @param      o_subject                  Cursor - subject
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_subject
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_flag_category IN VARCHAR2,
        o_subject       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_category          prof_cat.id_category%TYPE;
        l_get_dep_clin_serv table_number;
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS: i_lang=' || i_lang || ', i_prof=PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || 'i_flag_category=' || i_flag_category;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
            l_get_dep_clin_serv := get_dep_clin_serv(i_lang, i_prof);
        ELSE
            l_get_dep_clin_serv := table_number();
        END IF;
    
        /*If the user wants to define a physician target then ....*/
        IF i_flag_category = g_doctor
        THEN
        
            g_error := 'IF I_FLAG_CATEGORY=L_DOCTOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
        
            IF i_lang IS NOT NULL
               AND i_prof.id IS NOT NULL
               AND i_prof.institution IS NOT NULL
               AND i_prof.software IS NOT NULL
            THEN
            
                g_error := 'IF I_LANG/I_PROF ARE NOT NULL -- CALCULATE L_CATEGORY:';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
            
                SELECT pc.id_category
                  INTO l_category
                  FROM prof_cat pc
                 WHERE pc.id_professional = i_prof.id
                   AND pc.id_institution = i_prof.institution;
            
                g_error := 'L_CATEGORY=' || l_category;
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
            
                /*If the user category is a physician then he only can define targets for himself*/
                IF l_category = g_physician_category
                THEN
                
                    g_error := 'IF L_CATEGORY=1/OPEN O_SUBJECT';
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
                
                    OPEN o_subject FOR
                        SELECT DISTINCT p.name ||
                                        decode(p.title,
                                               NULL,
                                               NULL,
                                               ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc,
                                        p.id_professional subject_id,
                                        g_doctor subject_type
                          FROM professional p
                         WHERE p.id_professional = i_prof.id
                           AND p.name IS NOT NULL
                         ORDER BY 3, 1, 2;
                
                    /*If the user category is a administrative then he can define targets for all professionals who belong 
                    to the institution and software Outpatient and are allocated to the same specialty as the administrative*/
                
                ELSIF l_category = g_administrative_category
                THEN
                    g_error := 'IF L_CATEGORY=4/OPEN O_SUBJECT';
                    pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
                
                    OPEN o_subject FOR
                        SELECT DISTINCT p.name ||
                                        decode(p.title,
                                               NULL,
                                               NULL,
                                               ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc,
                                        pdcs.id_professional subject_id,
                                        g_doctor subject_type
                          FROM prof_soft_inst psi, prof_dep_clin_serv pdcs, professional p
                         WHERE psi.id_institution = i_prof.institution
                           AND psi.id_software = i_prof.software
                           AND psi.id_professional = pdcs.id_professional
                           AND pdcs.id_dep_clin_serv IN (SELECT *
                                                           FROM TABLE(l_get_dep_clin_serv))
                           AND pdcs.flg_status = pk_alert_constant.g_status_selected
                           AND pdcs.id_professional = p.id_professional
                           AND p.name IS NOT NULL
                         ORDER BY 3, 1, 2;
                
                END IF;
            
            END IF;
            /*If the user wants to define a speciality target then we can define a target for  
            all specialties to which it is allocated.*/
        
        ELSE
            g_error := 'IF I_FLAG_CATEGORY!=L_DOCTOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
        
            IF i_lang IS NOT NULL
               AND i_prof.id IS NOT NULL
               AND i_prof.institution IS NOT NULL
               AND i_prof.software IS NOT NULL
            THEN
                g_error := 'IF I_LANG/I_PROF ARE NOT NULL -- OPEN O_SUBJECT';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT ' || g_error);
            
                OPEN o_subject FOR
                    SELECT DISTINCT get_department(i_lang, dcs.id_department) subject_service,
                                    get_clinical_service(i_lang, dcs.id_dep_clin_serv) subject_desc,
                                    dcs.id_dep_clin_serv subject_id,
                                    g_speciality subject_type
                      FROM dep_clin_serv dcs
                     WHERE get_clinical_service(i_lang, dcs.id_dep_clin_serv) IS NOT NULL
                       AND dcs.id_dep_clin_serv IN (SELECT *
                                                      FROM TABLE(l_get_dep_clin_serv))
                     ORDER BY 4, 1, 2, 3;
            
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_subject);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_PRODUCTION_TARGET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_subject;

    /** @headcom
    * Public Function. Cancel production target
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_id_production_target      Production target identification
    * @param      o_id_production_target_hist   Production target history record identification
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION set_cancel_production_target
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_production_target      IN production_target.id_production_target%TYPE,
        o_id_production_target_hist OUT production_target_hist.id_production_target_hist%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar;
        l_error    t_error_out;
    
        l_id_production_target_hist production_target_hist.id_production_target_hist%TYPE;
    
        l_id_professional_subject production_target.id_professional_subject%TYPE;
        l_id_dcs_subject          production_target.id_dcs_subject%TYPE;
        l_id_dcs_type_slot        production_target.id_dcs_type_slot%TYPE;
        l_id_sch_event            production_target.id_sch_event%TYPE;
        l_id_sch_dep_type         production_target.id_sch_dep_type%TYPE;
        l_id_institution          production_target.id_institution%TYPE;
        l_id_software             production_target.id_software%TYPE;
        l_start_date              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_end_date                TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_target                  production_target.target%TYPE;
        l_notes                   VARCHAR2(200);
    
        CURSOR c_production_target(l_id_prod_target NUMBER) IS
            SELECT pt.id_professional_subject,
                   pt.id_dcs_subject,
                   pt.id_dcs_type_slot,
                   pt.id_sch_event,
                   pt.id_sch_dep_type,
                   pt.id_institution,
                   pt.id_software,
                   pt.dt_start,
                   pt.dt_end,
                   pt.target,
                   pt.notes
              FROM production_target pt
             WHERE pt.id_production_target = i_id_production_target;
    
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS: i_lang=' || i_lang || ', i_prof=PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), i_id_production_target=' ||
                   i_id_production_target;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_id_production_target IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            g_error := 'CALCULATE L_CURRENT_TIMESTAMP';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            SELECT current_timestamp
              INTO l_current_timestamp
              FROM dual;
        
            g_error := 'L_CURRENT_TIMESTAMP=' || l_current_timestamp || ' PRODUCTION_TARGET UPDATE';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            ts_production_target.upd(flg_available_in  => pk_alert_constant.g_no,
                                     flg_available_nin => FALSE,
                                     where_in          => 'id_production_target=' || i_id_production_target,
                                     rows_out          => l_rows_out);
        
            g_error := 'PROCESS_UPDATE PRODUCTION_TARGET';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PRODUCTION_TARGET',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            g_error := 'OPEN C_PRODUCTION_TARGET';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            OPEN c_production_target(i_id_production_target);
            FETCH c_production_target
                INTO l_id_professional_subject, l_id_dcs_subject, l_id_dcs_type_slot, l_id_sch_event, l_id_sch_dep_type, l_id_institution, l_id_software, l_start_date, l_end_date, l_target, l_notes;
        
            CLOSE c_production_target;
        
            /*When some production target are cancel always are created a history record with the change*/
        
            g_error := 'C_PRODUCTION_TARGET PARAMETERS: l_id_professional_subject=' || l_id_professional_subject ||
                       ', l_id_professional_subject=' || l_id_professional_subject || ', l_id_dcs_subject=' ||
                       l_id_dcs_subject || 'l_id_dcs_type_slot=' || l_id_dcs_type_slot || ', l_id_sch_event=' ||
                       l_id_sch_event || 'l_id_sch_dep_type=' || l_id_sch_dep_type || ', l_id_institution=' ||
                       l_id_institution || 'l_id_software=' || l_id_software || ', l_start_date=' || l_start_date ||
                       ', l_end_date=' || l_end_date || ', l_target=' || l_target || ', l_notes=' || l_notes ||
                       'CALCULATE l_id_production_target_hist';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            SELECT seq_production_target_hist.NEXTVAL
              INTO l_id_production_target_hist
              FROM dual;
        
            g_error := 'l_id_production_target_hist=' || l_id_production_target_hist ||
                       ' PRODUCTION_TARGET_HIST INSERT';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            ts_production_target_hist.ins(id_production_target_hist_in => l_id_production_target_hist,
                                          id_production_target_in      => i_id_production_target,
                                          id_professional_subject_in   => l_id_professional_subject,
                                          id_dcs_subject_in            => l_id_dcs_subject,
                                          id_dcs_type_slot_in          => l_id_dcs_type_slot,
                                          id_sch_event_in              => l_id_sch_event,
                                          id_sch_dep_type_in           => l_id_sch_dep_type,
                                          id_institution_in            => l_id_institution,
                                          id_software_in               => l_id_software,
                                          dt_start_in                  => l_start_date,
                                          dt_end_in                    => l_end_date,
                                          target_in                    => l_target,
                                          notes_in                     => l_notes,
                                          flg_available_in             => pk_alert_constant.g_no,
                                          dt_create_in                 => l_current_timestamp,
                                          prof_create_in               => i_prof.id,
                                          rows_out                     => l_rows_out);
        
            g_error := 'PROCESS_INSERT PRODUCTION_TARGET_HIST';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.SET_CANCEL_PRODUCTION_TARGET ' || g_error);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PRODUCTION_TARGET_HIST',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            o_id_production_target_hist := l_id_production_target_hist;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'set_cancel_production_target',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_cancel_production_target;

    /** @headcom
    * Public Function. Get schedule type
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_dcs_subject               Service/speciality identification
    * @param      o_schedule_type             Cursor schedule type
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_schedule_type
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_dcs_subject   IN production_target.id_dcs_subject%TYPE,
        o_schedule_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof= profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')' || ', i_dcs_subject=' || i_dcs_subject;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCHEDULE_TYPE ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
            g_error := 'IF I_LANG/I_PROF IS NOT NULL ---- IF I_DCS_SUBJECT';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCHEDULE_TYPE ' || g_error);
        
            IF i_dcs_subject IS NULL
            THEN
                g_error := 'IF I_DCS_SUBJECT IS NULL/OPEN O_SCHEDULE_TYPE';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCHEDULE_TYPE ' || g_error);
            
                OPEN o_schedule_type FOR
                    SELECT DISTINCT sdt.id_sch_dep_type,
                                    sdt.dep_type,
                                    pk_translation.get_translation(i_lang, sdt.code_dep_type) desc_type
                      FROM sch_dep_type sdt, sch_department sd, department d
                     WHERE sdt.flg_available = pk_alert_constant.g_yes
                       AND pk_translation.get_translation(i_lang, sdt.code_dep_type) IS NOT NULL
                       AND sdt.dep_type IN ('A', 'C', 'X', 'E', 'PM', 'N', 'U')
                       AND sd.id_department = d.id_department
                       AND sd.flg_dep_type = sdt.dep_type
                       AND d.id_institution = i_prof.institution
                       AND d.flg_available = pk_alert_constant.g_yes
                     ORDER BY desc_type;
            ELSE
                g_error := 'IF I_DCS_SUBJECT IS NOT NULL/OPEN O_SCHEDULE_TYPE';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCHEDULE_TYPE ' || g_error);
            
                OPEN o_schedule_type FOR
                    SELECT DISTINCT sdt.id_sch_dep_type,
                                    sdt.dep_type,
                                    pk_translation.get_translation(i_lang, sdt.code_dep_type) desc_type
                      FROM sch_dep_type sdt, sch_department sd, department d, dep_clin_serv dcs
                     WHERE sdt.flg_available = pk_alert_constant.g_yes
                       AND pk_translation.get_translation(i_lang, sdt.code_dep_type) IS NOT NULL
                       AND sd.id_department = d.id_department
                       AND dcs.id_department = d.id_department
                       AND sd.flg_dep_type = sdt.dep_type
                       AND dcs.id_dep_clin_serv = i_dcs_subject
                       AND sdt.dep_type IN ('A', 'C', 'X', 'E', 'PM', 'N', 'U')
                     ORDER BY desc_type;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedule_type);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_SCHEDULE_TYPE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedule_type;

    /** @headcom
    * Public Function. Get production target data
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_id_prod_target            Production target identification
    * @param      o_prod_target_data          Cursor with data about production target
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */
    FUNCTION get_production_target_data
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prod_target   IN production_target.id_production_target%TYPE,
        o_prod_target_data OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof= profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')' || ', i_id_prod_target=' || i_id_prod_target;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET_DATA ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_id_prod_target IS NOT NULL
        THEN
        
            g_error := 'IF I_LANG/I_PROF/I_ID_PROD_TARGET IS NOT NULL/o_prod_target_data';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PRODUCTION_TARGET_DATA ' || g_error);
        
            OPEN o_prod_target_data FOR
                SELECT pt.id_production_target,
                       decode(pt.id_professional_subject, NULL, pt.id_dcs_subject, pt.id_professional_subject) id_subject,
                       decode(pt.id_professional_subject,
                              NULL,
                              
                              get_clinical_service(i_lang, pt.id_dcs_subject),
                              (SELECT p.name ||
                                      decode(p.title,
                                             NULL,
                                             NULL,
                                             ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc
                                 FROM professional p
                                WHERE p.id_professional = pt.id_professional_subject)) desc_subject,
                       decode(pt.id_professional_subject, NULL, g_speciality, g_doctor) flag_subject,
                       (pt.id_sch_dep_type || ',' ||
                       (SELECT dcs.id_dep_clin_serv
                           FROM dep_clin_serv dcs
                          WHERE dcs.id_dep_clin_serv = pt.id_dcs_type_slot)
                       
                       || ',' || pt.id_sch_event) ids_type_slot,
                       (get_sch_dep_type(i_lang, pt.id_sch_dep_type) || ', ' ||
                       get_clinical_service(i_lang, pt.id_dcs_type_slot) || ', ' ||
                       get_sch_event(i_lang, pt.id_sch_event)) type_slot,
                       
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, pt.dt_start, NULL) start_date_s,
                       pk_date_utils.dt_chr_tsz(i_lang, pt.dt_start, i_prof.institution, i_prof.software) start_date,
                       
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, pt.dt_end, NULL) end_date_s,
                       pk_date_utils.dt_chr_tsz(i_lang, pt.dt_end, i_prof.institution, i_prof.software) end_date,
                       
                       pt.target,
                       (get_possible(i_lang,
                                     pt.id_professional_subject,
                                     pt.id_dcs_subject,
                                     pt.id_dcs_type_slot,
                                     pt.id_sch_event,
                                     pt.id_sch_dep_type,
                                     pt.dt_start,
                                     pt.dt_end,
                                     pt.id_institution) ||
                       decode(get_possible(i_lang,
                                            pt.id_professional_subject,
                                            pt.id_dcs_subject,
                                            pt.id_dcs_type_slot,
                                            pt.id_sch_event,
                                            pt.id_sch_dep_type,
                                            pt.dt_start,
                                            pt.dt_end,
                                            pt.id_institution),
                               NULL,
                               NULL,
                               ' (' || round(((get_possible(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution) / pt.target) * 100),
                                             2) || '%)')) possible,
                       (get_probable(i_lang,
                                     pt.id_professional_subject,
                                     pt.id_dcs_subject,
                                     pt.id_dcs_type_slot,
                                     pt.id_sch_event,
                                     pt.id_sch_dep_type,
                                     pt.dt_start,
                                     pt.dt_end,
                                     pt.id_institution) ||
                       decode(get_probable(i_lang,
                                            pt.id_professional_subject,
                                            pt.id_dcs_subject,
                                            pt.id_dcs_type_slot,
                                            pt.id_sch_event,
                                            pt.id_sch_dep_type,
                                            pt.dt_start,
                                            pt.dt_end,
                                            pt.id_institution),
                               NULL,
                               NULL,
                               ' (' || round(((get_probable(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution) / pt.target) * 100),
                                             2) || '%)')) probable,
                       (get_real(i_lang,
                                 pt.id_professional_subject,
                                 pt.id_dcs_subject,
                                 pt.id_dcs_type_slot,
                                 pt.id_sch_event,
                                 pt.id_sch_dep_type,
                                 pt.dt_start,
                                 pt.dt_end,
                                 pt.id_institution) ||
                       decode(get_real(i_lang,
                                        pt.id_professional_subject,
                                        pt.id_dcs_subject,
                                        pt.id_dcs_type_slot,
                                        pt.id_sch_event,
                                        pt.id_sch_dep_type,
                                        pt.dt_start,
                                        pt.dt_end,
                                        pt.id_institution),
                               NULL,
                               NULL,
                               ' (' || round(((get_real(i_lang,
                                                        pt.id_professional_subject,
                                                        pt.id_dcs_subject,
                                                        pt.id_dcs_type_slot,
                                                        pt.id_sch_event,
                                                        pt.id_sch_dep_type,
                                                        pt.dt_start,
                                                        pt.dt_end,
                                                        pt.id_institution) / pt.target) * 100),
                                             2) || '%)')) REAL,
                       pt.notes
                  FROM production_target pt
                 WHERE pt.id_production_target = i_id_prod_target;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prod_target_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_PRODUCTION_TARGET_DATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_production_target_data;

    /** @headcom
    * Public Function. Get appointment type
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_dep_clin_serv            Service/speciality identification
    * @param      i_flag_sch_type            Flag scheduling type
    * @param      o_appointment_type          Cursor with data about appointment type
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_appointment_type
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flag_sch_type    IN sch_dep_type.dep_type%TYPE,
        o_appointment_type OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_get_dep_clin_serv table_number;
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof= profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')' || ', i_dep_clin_serv=' || i_dep_clin_serv ||
                   ', i_flag_sch_type=' || i_flag_sch_type;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_APPOINTMENT_TYPE ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            g_error := 'I_LANG/I_PROF IS NOT NULL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_APPOINTMENT_TYPE ' || g_error);
        
            l_get_dep_clin_serv := get_dep_clin_serv(i_lang, i_prof);
        
            IF i_dep_clin_serv IS NULL
            THEN
            
                g_error := 'I_DEP_CLIN_SERV IS NULL/ o_appointment_type';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_APPOINTMENT_TYPE ' || g_error);
            
                OPEN o_appointment_type FOR
                    SELECT DISTINCT dcs.id_dep_clin_serv,
                                    dcs.id_clinical_service,
                                    dcs.id_department,
                                    get_department(i_lang, dcs.id_department) desc_service,
                                    get_clinical_service(i_lang, dcs.id_dep_clin_serv) desc_clinical_service
                      FROM sch_department sd, dep_clin_serv dcs
                     WHERE get_clinical_service(i_lang, dcs.id_dep_clin_serv) IS NOT NULL
                       AND dcs.id_department = sd.id_department
                       AND sd.flg_dep_type = i_flag_sch_type
                       AND dcs.id_dep_clin_serv IN (SELECT *
                                                      FROM TABLE(l_get_dep_clin_serv))
                     ORDER BY 4, 5;
            ELSE
            
                g_error := 'I_DEP_CLIN_SERV IS NOT NULL/o_appointment_type';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_APPOINTMENT_TYPE ' || g_error);
            
                OPEN o_appointment_type FOR
                    SELECT DISTINCT dcs.id_dep_clin_serv,
                                    dcs.id_clinical_service,
                                    dcs.id_department,
                                    get_department(i_lang, dcs.id_department) desc_service,
                                    get_clinical_service(i_lang, dcs.id_dep_clin_serv) desc_clinical_service
                      FROM sch_department sd, dep_clin_serv dcs
                     WHERE get_clinical_service(i_lang, dcs.id_dep_clin_serv) IS NOT NULL
                       AND dcs.id_department = sd.id_department
                       AND sd.flg_dep_type = i_flag_sch_type
                       AND dcs.id_dep_clin_serv = i_dep_clin_serv
                     ORDER BY 4, 5;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_appointment_type);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_APPOINTMENT_TYPE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_appointment_type;

    /** @headcom
    * Public Function. Get event
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_flag                      Flag scheduling type
    * @param      i_dep_clin_serv            Service/speciality identification
    * @param      o_event                    Cursor with data about event type
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_event
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_flag          IN sch_dep_type.dep_type%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_event         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof= profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')' || ', i_dep_clin_serv=' || i_dep_clin_serv ||
                   ', i_flag=' || i_flag;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_EVENT ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
            g_error := 'IF I_LANG/I_PROF IS NOT NULL/O_EVENT';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_EVENT ' || g_error);
        
            OPEN o_event FOR
                SELECT DISTINCT id_sch_event, desc_sch_event
                  FROM (SELECT se.id_sch_event, 
                               pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_sch_event
                          FROM sch_event se, sch_event_dcs sed
                         WHERE se.flg_available = pk_alert_constant.g_yes
                           AND se.dep_type = i_flag
                           AND se.id_sch_event = sed.id_sch_event
                           AND sed.id_dep_clin_serv = i_dep_clin_serv
                           AND se.dep_type IN ('A', 'C', 'X', 'E', 'PM', 'N', 'U', 'AS')
                           AND sed.flg_available = pk_alert_constant.g_yes
                           AND pk_schedule_common.get_sch_event_avail(se.id_sch_event,
                                                                      i_prof.institution,
                                                                      i_prof.software) = pk_alert_constant.g_yes)
                 WHERE desc_sch_event IS NOT NULL;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_event);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_EVENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_event;

    /** @headcom
    * Public Function. Get detail
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_id_production_target      Production target identification
    * @param      o_detail                    Cursor with data about the target
    * @param      o_detail_hist               Cursor with data about the target  history
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_detail
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_production_target IN production_target.id_production_target%TYPE,
        o_detail               OUT pk_types.cursor_type,
        o_detail_hist          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof= profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')' || ', i_id_production_target=' ||
                   i_id_production_target;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DETAIL ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_id_production_target IS NOT NULL
        THEN
        
            g_error := 'IF I_LANG/I_PROF/I_ID_PRODUCTION_TARGET IS NOT NULL/ O_DETAIL CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DETAIL ' || g_error);
        
            OPEN o_detail FOR
                SELECT pt.id_production_target,
                       decode(pt.id_professional_subject, NULL, pt.id_dcs_subject, pt.id_professional_subject) id_subject,
                       decode(pt.id_professional_subject,
                              NULL,
                              get_clinical_service(i_lang, pt.id_dcs_subject),
                              (SELECT p.name ||
                                      decode(p.title,
                                             NULL,
                                             NULL,
                                             ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc
                                 FROM professional p
                                WHERE p.id_professional = pt.id_professional_subject)) desc_subject,
                       (pt.id_sch_dep_type || ',' ||
                       (SELECT dcs.id_dep_clin_serv
                           FROM dep_clin_serv dcs
                          WHERE dcs.id_dep_clin_serv = pt.id_dcs_type_slot) || ',' || pt.id_sch_event) ids_type_slot,
                       (get_sch_dep_type(i_lang, pt.id_sch_dep_type) || ', ' ||
                       get_clinical_service(i_lang, pt.id_dcs_type_slot) || ', ' ||
                       (select pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event)
                        from sch_event se
                        where se.id_sch_event = pt.id_sch_event)) type_slot,
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, pt.dt_start, NULL) start_date_s,
                       pk_date_utils.dt_chr_tsz(i_lang, pt.dt_start, i_prof.institution, i_prof.software) start_date,
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, pt.dt_end, NULL) end_date_s,
                       pk_date_utils.dt_chr_tsz(i_lang, pt.dt_end, i_prof.institution, i_prof.software) end_date,
                       
                       pt.target,
                       (get_possible(i_lang,
                                     pt.id_professional_subject,
                                     pt.id_dcs_subject,
                                     pt.id_dcs_type_slot,
                                     pt.id_sch_event,
                                     pt.id_sch_dep_type,
                                     pt.dt_start,
                                     pt.dt_end,
                                     pt.id_institution) ||
                       decode(get_possible(i_lang,
                                            pt.id_professional_subject,
                                            pt.id_dcs_subject,
                                            pt.id_dcs_type_slot,
                                            pt.id_sch_event,
                                            pt.id_sch_dep_type,
                                            pt.dt_start,
                                            pt.dt_end,
                                            pt.id_institution),
                               NULL,
                               NULL,
                               ' (' || round(((get_possible(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution) / pt.target) * 100),
                                             2) || '%)')) possible,
                       (get_probable(i_lang,
                                     pt.id_professional_subject,
                                     pt.id_dcs_subject,
                                     pt.id_dcs_type_slot,
                                     pt.id_sch_event,
                                     pt.id_sch_dep_type,
                                     pt.dt_start,
                                     pt.dt_end,
                                     pt.id_institution) ||
                       decode(get_probable(i_lang,
                                            pt.id_professional_subject,
                                            pt.id_dcs_subject,
                                            pt.id_dcs_type_slot,
                                            pt.id_sch_event,
                                            pt.id_sch_dep_type,
                                            pt.dt_start,
                                            pt.dt_end,
                                            pt.id_institution),
                               NULL,
                               NULL,
                               ' (' || round(((get_probable(i_lang,
                                                            pt.id_professional_subject,
                                                            pt.id_dcs_subject,
                                                            pt.id_dcs_type_slot,
                                                            pt.id_sch_event,
                                                            pt.id_sch_dep_type,
                                                            pt.dt_start,
                                                            pt.dt_end,
                                                            pt.id_institution) / pt.target) * 100),
                                             2) || '%)')) probable,
                       (get_real(i_lang,
                                 pt.id_professional_subject,
                                 pt.id_dcs_subject,
                                 pt.id_dcs_type_slot,
                                 pt.id_sch_event,
                                 pt.id_sch_dep_type,
                                 pt.dt_start,
                                 pt.dt_end,
                                 pt.id_institution) ||
                       decode(get_real(i_lang,
                                        pt.id_professional_subject,
                                        pt.id_dcs_subject,
                                        pt.id_dcs_type_slot,
                                        pt.id_sch_event,
                                        pt.id_sch_dep_type,
                                        pt.dt_start,
                                        pt.dt_end,
                                        pt.id_institution),
                               NULL,
                               NULL,
                               ' (' || round(((get_real(i_lang,
                                                        pt.id_professional_subject,
                                                        pt.id_dcs_subject,
                                                        pt.id_dcs_type_slot,
                                                        pt.id_sch_event,
                                                        pt.id_sch_dep_type,
                                                        pt.dt_start,
                                                        pt.dt_end,
                                                        pt.id_institution) / pt.target) * 100),
                                             2) || '%)')) REAL,
                       pt.notes
                  FROM production_target pt
                 WHERE pt.id_production_target = i_id_production_target;
        
            g_error := 'O_DETAIL_HIST CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DETAIL ' || g_error);
        
            OPEN o_detail_hist FOR
                SELECT pth.id_production_target,
                       decode(pth.id_professional_subject, NULL, pth.id_dcs_subject, pth.id_professional_subject) id_subject,
                       decode(pth.id_professional_subject,
                              NULL,
                              get_clinical_service(i_lang, pth.id_dcs_subject),
                              (SELECT p.name ||
                                      decode(p.title,
                                             NULL,
                                             NULL,
                                             ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)) subject_desc
                                 FROM professional p
                                WHERE p.id_professional = pth.id_professional_subject)) desc_subject,
                       (pth.id_sch_dep_type || ',' ||
                       (SELECT dcs.id_dep_clin_serv
                           FROM dep_clin_serv dcs
                          WHERE dcs.id_dep_clin_serv = pth.id_dcs_type_slot) || ',' || pth.id_sch_event) ids_type_slot,
                       (get_sch_dep_type(i_lang, pth.id_sch_dep_type) || ', ' ||
                       get_clinical_service(i_lang, pth.id_dcs_type_slot) || ', ' ||
                       get_sch_event(i_lang, pth.id_sch_event)) type_slot,
                       
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, pth.dt_start, NULL) start_date_s,
                       pk_date_utils.dt_chr_tsz(i_lang, pth.dt_start, i_prof.institution, i_prof.software) start_date,
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, pth.dt_end, NULL) end_date_s,
                       pk_date_utils.dt_chr_tsz(i_lang, pth.dt_end, i_prof.institution, i_prof.software) end_date,
                       
                       pth.notes,
                       pth.target,
                       decode(pth.dt_create,
                              (SELECT MAX(pth.dt_create)
                                 FROM production_target_hist pth
                                WHERE pth.id_production_target = i_id_production_target),
                              'A',
                              'I') flg_status,
                       pk_date_utils.date_hour_chr_extend_tsz(i_lang,
                                                              pth.dt_create,
                                                              profissional(pth.prof_create, i_prof.institution, 0)) desc_adw_last_update,
                       (SELECT p.name ||
                               decode(p.title,
                                      NULL,
                                      NULL,
                                      ', ' || pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang))
                          FROM professional p
                         WHERE p.id_professional = pth.prof_create) prof_name
                
                  FROM production_target_hist pth
                 WHERE pth.id_production_target = i_id_production_target
                 ORDER BY pth.dt_create DESC;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_detail_hist);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_detail;

    /** @headcom
    * Public Function. Get subject appointment
    *
    * @param      I_LANG                      Language identification
    * @param      i_flag_subject              Professional identification
    * @param      id_subject                  Subject identification
    * @param      id_dcs                      Service/speciality identification
    * @param      o_flag                      Output Cursor
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_subject_appointment
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_flag_subject IN VARCHAR2,
        id_subject     IN NUMBER,
        id_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flag         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_true  VARCHAR2(200) := 'TRUE';
        l_false VARCHAR2(200) := 'FALSE';
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_flag_subject= ' || i_flag_subject || ', id_subject=' ||
                   id_subject || ', id_dcs=' || id_dcs;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_APPOINTMENT ' || g_error);
    
        IF i_flag_subject = g_doctor
        THEN
            g_error := 'I_FLAG_SUBJECT=L_DOCTOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_APPOINTMENT ' || g_error);
        
            o_flag := l_true;
        ELSE
            IF id_subject = id_dcs
            THEN
                g_error := 'I_FLAG_SUBJECT != L_DOCTOR AND I_FLAG_SUBJECT=DEP_CLIN_SERV TRUE';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_APPOINTMENT ' || g_error);
                o_flag := l_true;
            ELSE
                g_error := 'ELSE FALSE';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SUBJECT_APPOINTMENT ' || g_error);
                o_flag := l_false;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_SUBJECT_APPOINTMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_subject_appointment;

    /** @headcom
    * Public Function. Calculate the possible values:  Number of vacancy available for target
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_possible
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_dt_start                IN production_target.dt_start%TYPE,
        i_dt_end                  IN production_target.dt_end%TYPE,
        i_id_institution          IN production_target.id_institution%TYPE
    ) RETURN NUMBER IS
        l_count_possible PLS_INTEGER := 0;
        l_error          t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id_professional_subject= ' || i_id_professional_subject ||
                   ', i_id_dcs_subject=' || i_id_dcs_subject || ', i_id_dcs_type_slot=' || i_id_dcs_type_slot ||
                   ', i_id_sch_event=' || i_id_sch_event || ', i_id_sch_dep_type=' || i_id_sch_dep_type ||
                   ', i_dt_start=' || i_dt_start || ', i_dt_end=' || i_dt_end || ', i_id_institution' ||
                   i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_POSSIBLE ' || g_error);
    
        /*If the subject target is a professional then ....*/
        IF i_id_dcs_subject IS NULL
        THEN
            g_error := 'I_ID_DCS_SUBJECT IS NULL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_POSSIBLE ' || g_error);
        
            SELECT COUNT(*)
              INTO l_count_possible
              FROM sch_consult_vacancy scv
             WHERE scv.id_prof = i_id_professional_subject
               AND scv.id_sch_event = i_id_sch_event
               AND scv.max_vacancies - scv.used_vacancies > 0
               AND scv.dt_begin_tstz >= i_dt_start
               AND scv.dt_begin_tstz <= i_dt_end
               AND scv.id_institution = i_id_institution
               AND scv.id_dep_clin_serv = i_id_dcs_type_slot;
        
            g_error := 'L_COUNT_POSSIBLE=' || l_count_possible;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_POSSIBLE ' || g_error);
            /*If the subject target is a speciality then ....*/
        ELSE
            g_error := 'I_ID_DCS_SUBJECT IS NOT NULL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_POSSIBLE ' || g_error);
        
            SELECT COUNT(*)
              INTO l_count_possible
              FROM sch_consult_vacancy scv
             WHERE scv.id_sch_event = i_id_sch_event
               AND scv.max_vacancies - scv.used_vacancies > 0
               AND scv.dt_begin_tstz >= i_dt_start
               AND scv.dt_begin_tstz <= i_dt_end
               AND scv.id_institution = i_id_institution
               AND scv.id_dep_clin_serv = i_id_dcs_subject;
        
            g_error := 'L_COUNT_POSSIBLE=' || l_count_possible;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_POSSIBLE ' || g_error);
        
        END IF;
    
        RETURN l_count_possible;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_POSSIBLE',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
        
    END get_possible;

    /** @headcom
    * Public Function. Calculate the probable values:  Number of scheduler apointments
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_probable
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_dt_start                IN production_target.dt_start%TYPE,
        i_dt_end                  IN production_target.dt_end%TYPE,
        i_id_institution          IN production_target.id_institution%TYPE
    ) RETURN NUMBER IS
        l_count_probable PLS_INTEGER := 0;
        l_error          t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id_professional_subject= ' || i_id_professional_subject ||
                   ', i_id_dcs_subject=' || i_id_dcs_subject || ', i_id_dcs_type_slot=' || i_id_dcs_type_slot ||
                   ', i_id_sch_event=' || i_id_sch_event || ', i_id_sch_dep_type=' || i_id_sch_dep_type ||
                   ', i_dt_start=' || i_dt_start || ', i_dt_end=' || i_dt_end || ', i_id_institution' ||
                   i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PROBABLE ' || g_error);
    
        /*If the subject target is a professional then ....*/
        IF i_id_dcs_subject IS NULL
        THEN
            g_error := 'i_id_dcs_subject IS NULL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PROBABLE ' || g_error);
        
            SELECT COUNT(*)
              INTO l_count_probable
              FROM sch_resource sr, schedule s
             WHERE sr.id_institution = i_id_institution
               AND sr.id_professional = i_id_professional_subject
               AND sr.id_schedule = s.id_schedule
               AND s.id_instit_requested = i_id_institution
               AND s.id_dcs_requested = i_id_dcs_type_slot
               AND s.flg_status = pk_alert_constant.g_active
               AND s.id_sch_event = i_id_sch_event
               AND s.flg_sch_type IN (SELECT sdt.dep_type
                                        FROM sch_dep_type sdt
                                       WHERE sdt.id_sch_dep_type = i_id_sch_dep_type)
               AND s.dt_begin_tstz >= i_dt_start
               AND s.dt_begin_tstz <= i_dt_end;
        
            g_error := 'L_COUNT_PROBABLE' || l_count_probable;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PROBABLE ' || g_error);
        
            /*If the subject target is a speciality then ....*/
        
        ELSE
            g_error := 'i_id_dcs_subject IS NOT NULL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PROBABLE ' || g_error);
        
            SELECT COUNT(*)
              INTO l_count_probable
              FROM sch_resource sr, schedule s
             WHERE sr.id_institution = i_id_institution
               AND sr.id_schedule = s.id_schedule
               AND s.id_instit_requested = i_id_institution
               AND s.id_dcs_requested = i_id_dcs_subject
               AND s.flg_status = pk_alert_constant.g_active
               AND s.id_sch_event = i_id_sch_event
               AND s.flg_sch_type IN (SELECT sdt.dep_type
                                        FROM sch_dep_type sdt
                                       WHERE sdt.id_sch_dep_type = i_id_sch_dep_type)
               AND s.dt_begin_tstz >= i_dt_start
               AND s.dt_begin_tstz <= i_dt_end;
        
            g_error := 'L_COUNT_PROBABLE' || l_count_probable;
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_PROBABLE ' || g_error);
        
        END IF;
    
        RETURN l_count_probable;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_PROBABLE',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
        
    END get_probable;

    /** @headcom
    * Public Function. Calculate the real values:  Number of  apointments
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_real
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_dt_start                IN production_target.dt_start%TYPE,
        i_dt_end                  IN production_target.dt_end%TYPE,
        i_id_institution          IN production_target.id_institution%TYPE
    ) RETURN NUMBER IS
        l_count_real PLS_INTEGER := 0;
        l_error      t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id_professional_subject= ' || i_id_professional_subject ||
                   ', i_id_dcs_subject=' || i_id_dcs_subject || ', i_id_dcs_type_slot=' || i_id_dcs_type_slot ||
                   ', i_id_sch_event=' || i_id_sch_event || ', i_id_sch_dep_type=' || i_id_sch_dep_type ||
                   ', i_dt_start=' || i_dt_start || ', i_dt_end=' || i_dt_end || ', i_id_institution' ||
                   i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_REAL ' || g_error);
    
        /*If the subject target is a professional then ....*/
        IF i_id_dcs_subject IS NULL
        THEN
        
            g_error := 'IF I_ID_DCS_SUBJECT IS NULL/L_COUNT_REAL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_REAL ' || g_error);
        
            SELECT COUNT(*)
              INTO l_count_real
              FROM epis_info ei, schedule s, sch_resource sr
             WHERE ei.id_schedule = s.id_schedule
               AND s.id_schedule = sr.id_schedule
               AND ei.id_professional = i_id_professional_subject
               AND s.id_instit_requested = i_id_institution
               AND s.id_dcs_requested = i_id_dcs_type_slot
               AND sr.id_professional = i_id_professional_subject
               AND sr.id_institution = i_id_institution
               AND s.id_sch_event = i_id_sch_event
               AND s.flg_sch_type IN (SELECT sdt.dep_type
                                        FROM sch_dep_type sdt
                                       WHERE sdt.id_sch_dep_type = i_id_sch_dep_type)
               AND s.flg_status = pk_alert_constant.g_active
               AND s.dt_begin_tstz >= i_dt_start
               AND s.dt_begin_tstz <= i_dt_end
               AND ei.id_dcs_requested = i_id_dcs_type_slot
               AND ei.id_instit_requested = i_id_institution
               AND ei.dt_last_interaction_tstz >= i_dt_start
               AND ei.dt_last_interaction_tstz <= i_dt_end;
        
            /*If the subject target is a speciality then ....*/
        ELSE
        
            g_error := 'IF I_ID_DCS_SUBJECT IS NOT NULL/L_COUNT_REAL';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_REAL ' || g_error);
        
            SELECT COUNT(*)
              INTO l_count_real
              FROM sch_resource sr, schedule s, epis_info ei
             WHERE sr.id_institution = i_id_institution
               AND sr.id_schedule = s.id_schedule
               AND s.id_instit_requested = i_id_institution
               AND s.id_dcs_requested = i_id_dcs_subject
               AND s.flg_status = pk_alert_constant.g_active
               AND s.id_sch_event = i_id_sch_event
               AND s.flg_sch_type IN (SELECT sdt.dep_type
                                        FROM sch_dep_type sdt
                                       WHERE sdt.id_sch_dep_type = i_id_sch_dep_type)
               AND s.dt_begin_tstz >= i_dt_start
               AND s.dt_begin_tstz <= i_dt_end
               AND ei.id_schedule = s.id_schedule
               AND ei.id_dcs_requested = i_id_dcs_type_slot
               AND ei.id_instit_requested = i_id_institution
               AND ei.dt_last_interaction_tstz >= i_dt_start
               AND ei.dt_last_interaction_tstz <= i_dt_end;
        END IF;
    
        RETURN l_count_real;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_REAL',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
        
    END get_real;

    /** @headcom
    * Public Function. Calculate the possible, probable, real, probability possible, probability real, probability real values
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    * @param      i_target_value              Target values
    * @param      o_statistical_information   Cursor with statistical information
    * @param      o_error            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/06/16
    */

    FUNCTION get_statistical_information
    
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_start_date              IN VARCHAR2,
        i_end_date                IN VARCHAR2,
        i_id_institution          IN production_target.id_institution%TYPE,
        i_target_value            IN production_target.target%TYPE,
        o_statistical_information OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date production_target.dt_start%TYPE;
        l_end_date   production_target.dt_end%TYPE;
        l_no_value CONSTANT VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                     i_code_mess => 'ADMINISTRATOR_T432');
    
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof=profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), i_id_professional_subject= ' ||
                   i_id_professional_subject || ', i_id_dcs_subject=' || i_id_dcs_subject || ', i_id_dcs_type_slot=' ||
                   i_id_dcs_type_slot || ', i_id_sch_event=' || i_id_sch_event || ', i_id_sch_dep_type=' ||
                   i_id_sch_dep_type || ', i_dt_start=' || i_start_date || ', i_dt_end=' || i_end_date ||
                   ', i_id_institution' || i_id_institution || ', i_target_value=' || i_target_value;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_STATISTICAL_INFORMATION ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            IF ((i_id_professional_subject IS NOT NULL AND i_id_dcs_subject IS NULL) OR
               (i_id_professional_subject IS NULL AND i_id_dcs_subject IS NOT NULL))
               AND i_id_dcs_type_slot IS NOT NULL
               AND i_id_sch_event IS NOT NULL
               AND i_id_sch_dep_type IS NOT NULL
               AND i_start_date IS NOT NULL
               AND i_end_date IS NOT NULL
               AND i_id_institution IS NOT NULL
               AND i_target_value IS NOT NULL
            THEN
            
                g_error := 'L_START_DATE/L_END_DATE';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_STATISTICAL_INFORMATION ' || g_error);
            
                l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_start_date,
                                                              i_timezone  => NULL);
                l_end_date   := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_end_date,
                                                              i_timezone  => NULL);
            
                g_error := 'OPEN o_statistical_information';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_STATISTICAL_INFORMATION ' || g_error);
            
                OPEN o_statistical_information FOR
                
                    SELECT decode(get_possible(i_lang,
                                               i_id_professional_subject,
                                               i_id_dcs_subject,
                                               i_id_dcs_type_slot,
                                               i_id_sch_event,
                                               i_id_sch_dep_type,
                                               l_start_date,
                                               l_end_date,
                                               i_id_institution),
                                  NULL,
                                  l_no_value,
                                  get_possible(i_lang,
                                               i_id_professional_subject,
                                               i_id_dcs_subject,
                                               i_id_dcs_type_slot,
                                               i_id_sch_event,
                                               i_id_sch_dep_type,
                                               l_start_date,
                                               l_end_date,
                                               i_id_institution)) possible,
                           decode(get_possible(i_lang,
                                               i_id_professional_subject,
                                               i_id_dcs_subject,
                                               i_id_dcs_type_slot,
                                               i_id_sch_event,
                                               i_id_sch_dep_type,
                                               l_start_date,
                                               l_end_date,
                                               i_id_institution),
                                  NULL,
                                  NULL,
                                  round(((get_possible(i_lang,
                                                       i_id_professional_subject,
                                                       i_id_dcs_subject,
                                                       i_id_dcs_type_slot,
                                                       i_id_sch_event,
                                                       i_id_sch_dep_type,
                                                       l_start_date,
                                                       l_end_date,
                                                       i_id_institution) / i_target_value) * 100),
                                        2) || '%') probability_possible,
                           
                           decode(get_probable(i_lang,
                                               i_id_professional_subject,
                                               i_id_dcs_subject,
                                               i_id_dcs_type_slot,
                                               i_id_sch_event,
                                               i_id_sch_dep_type,
                                               l_start_date,
                                               l_end_date,
                                               i_id_institution),
                                  NULL,
                                  l_no_value,
                                  get_probable(i_lang,
                                               i_id_professional_subject,
                                               i_id_dcs_subject,
                                               i_id_dcs_type_slot,
                                               i_id_sch_event,
                                               i_id_sch_dep_type,
                                               l_start_date,
                                               l_end_date,
                                               i_id_institution)) probable,
                           decode(get_probable(i_lang,
                                               i_id_professional_subject,
                                               i_id_dcs_subject,
                                               i_id_dcs_type_slot,
                                               i_id_sch_event,
                                               i_id_sch_dep_type,
                                               l_start_date,
                                               l_end_date,
                                               i_id_institution),
                                  NULL,
                                  NULL,
                                  round(((get_probable(i_lang,
                                                       i_id_professional_subject,
                                                       i_id_dcs_subject,
                                                       i_id_dcs_type_slot,
                                                       i_id_sch_event,
                                                       i_id_sch_dep_type,
                                                       l_start_date,
                                                       l_end_date,
                                                       i_id_institution) / i_target_value) * 100),
                                        2) || '%') probability_probable,
                           
                           decode(get_real(i_lang,
                                           i_id_professional_subject,
                                           i_id_dcs_subject,
                                           i_id_dcs_type_slot,
                                           i_id_sch_event,
                                           i_id_sch_dep_type,
                                           l_start_date,
                                           l_end_date,
                                           i_id_institution),
                                  NULL,
                                  l_no_value,
                                  get_real(i_lang,
                                           i_id_professional_subject,
                                           i_id_dcs_subject,
                                           i_id_dcs_type_slot,
                                           i_id_sch_event,
                                           i_id_sch_dep_type,
                                           l_start_date,
                                           l_end_date,
                                           i_id_institution)) REAL,
                           decode(get_real(i_lang,
                                           i_id_professional_subject,
                                           i_id_dcs_subject,
                                           i_id_dcs_type_slot,
                                           i_id_sch_event,
                                           i_id_sch_dep_type,
                                           l_start_date,
                                           l_end_date,
                                           i_id_institution),
                                  NULL,
                                  NULL,
                                  round(((get_real(i_lang,
                                                   i_id_professional_subject,
                                                   i_id_dcs_subject,
                                                   i_id_dcs_type_slot,
                                                   i_id_sch_event,
                                                   i_id_sch_dep_type,
                                                   l_start_date,
                                                   l_end_date,
                                                   i_id_institution) / i_target_value) * 100),
                                        2) || '%') probability_real
                    
                      FROM dual;
            
            ELSE
            
                g_error := 'OPEN o_statistical_information';
                pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_STATISTICAL_INFORMATION ' || g_error);
            
                OPEN o_statistical_information FOR
                    SELECT l_no_value possible,
                           NULL       probability_possible,
                           l_no_value probable,
                           NULL       probability_probable,
                           l_no_value REAL,
                           NULL       probability_real
                      FROM dual;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_STATISTICAL_INFORMATION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_statistical_information;

    /** @headcom
    * Public Function. Get dep_clin_Serv identification
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/28
    */

    FUNCTION get_dep_clin_serv
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
    
        l_o_dcs pk_types.cursor_type;
        o_dcs   table_number;
        l_error t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_prof=profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || ')';
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DEP_CLIN_SERV ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            g_error := 'OPEN L_O_DCS';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DEP_CLIN_SERV ' || g_error);
        
            OPEN l_o_dcs FOR
            
                SELECT DISTINCT pdcs.id_dep_clin_serv
                  FROM prof_dep_clin_serv pdcs,
                       dep_clin_serv      dcs,
                       department         d,
                       dept               dt,
                       software_dept      sd,
                       prof_soft_inst     psi
                 WHERE pdcs.id_professional = i_prof.id
                   AND pdcs.flg_status = pk_alert_constant.g_status_selected
                   AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND dcs.id_department = d.id_department
                   AND d.id_dept = dt.id_dept
                   AND sd.id_dept = dt.id_dept
                   AND sd.id_software = i_prof.software
                   AND dt.id_institution = i_prof.institution
                   AND d.id_institution = i_prof.institution
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND dt.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND psi.id_professional = pdcs.id_professional
                   AND psi.id_software = i_prof.software
                   AND psi.id_institution = i_prof.institution;
        
            g_error := 'OPEN O_DCS';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DEP_CLIN_SERV ' || g_error);
        
            LOOP
                FETCH l_o_dcs BULK COLLECT
                    INTO o_dcs;
                EXIT WHEN l_o_dcs%NOTFOUND;
            
            END LOOP;
        
            CLOSE l_o_dcs;
        
        END IF;
    
        RETURN o_dcs;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_DEP_CLIN_SERV',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
            o_dcs := table_number();
        
            RETURN o_dcs;
        
    END get_dep_clin_serv;

    /** @headcom
    * Public Function. Get schedule type identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_sch_dep_type
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN sch_dep_type.id_sch_dep_type%TYPE
    ) RETURN VARCHAR2 IS
        l_sch_dep_type VARCHAR2(4000);
        l_error        t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id=' || i_id;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCH_DEP_TYPE ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_id IS NOT NULL
        THEN
        
            g_error := 'calculate l_sch_dep_type';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCH_DEP_TYPE' || g_error);
        
            SELECT pk_translation.get_translation(i_lang, sdt.code_dep_type)
              INTO l_sch_dep_type
              FROM sch_dep_type sdt
             WHERE sdt.id_sch_dep_type = i_id;
        
            RETURN l_sch_dep_type;
        
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_SCH_DEP_TYPE',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN NULL;
        
    END get_sch_dep_type;

    /** @headcom
    * Public Function. Get clinical service identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_clinical_service
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
        l_cs    VARCHAR2(4000);
        l_error t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id=' || i_id;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_CLINICAL_SERVICE ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_id IS NOT NULL
        THEN
        
            g_error := 'CALCULATE L_CS';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_CLINICAL_SERVICE ' || g_error);
        
            SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
              INTO l_cs
              FROM clinical_service cs, dep_clin_serv dcs
             WHERE dcs.id_clinical_service = cs.id_clinical_service
               AND dcs.id_dep_clin_serv = i_id;
        
            RETURN l_cs;
        
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_CLINICAL_SERVICE',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN NULL;
        
    END get_clinical_service;

    /** @headcom
    * Public Function. Get event identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_sch_event
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN sch_event.id_sch_event%TYPE
    ) RETURN VARCHAR2 IS
        l_cs    VARCHAR2(4000);
        l_error t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id=' || i_id;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCH_EVENT ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_id IS NOT NULL
        THEN
        
            g_error := 'CALCULATE L_CS';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_SCH_EVENT ' || g_error);
        
            
            SELECT pk_schedule_common.get_translation_alias(i_lang, profissional(0,0,0), se.id_sch_event, se.code_sch_event)
              INTO l_cs
              FROM sch_event se
             WHERE se.id_sch_event = i_id;
        
            RETURN l_cs;
        
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_SCH_EVENT',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN NULL;
        
    END get_sch_event;

    /** @headcom
    * Public Function. Get department identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_department
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN department.id_department%TYPE
    ) RETURN VARCHAR2 IS
        l_cs    VARCHAR2(4000);
        l_error t_error_out;
    BEGIN
    
        g_error := 'INPUT PARAMETERS i_lang=' || i_lang || ', i_id=' || i_id;
        pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DEPARTMENT ' || g_error);
    
        IF i_lang IS NOT NULL
           AND i_id IS NOT NULL
        THEN
        
            g_error := 'CALCULATE L_CS';
            pk_alertlog.log_debug('PK_BACKOFFICE_PRD_TRGT.GET_DEPARTMENT ' || g_error);
        
            SELECT pk_translation.get_translation(i_lang, d.code_department)
              INTO l_cs
              FROM department d
             WHERE d.id_department = i_id;
        
            RETURN l_cs;
        
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_PRD_TRGT',
                                              i_function => 'GET_DEPARTMENT',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN NULL;
        
    END get_department;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_prd_trgt;
/
