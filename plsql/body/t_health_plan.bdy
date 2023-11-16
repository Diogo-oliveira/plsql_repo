/*-- Last Change Revision: $Rev: 2028427 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY t_health_plan IS

    g_package VARCHAR2(30 CHAR);
    g_owner   VARCHAR2(30 CHAR);

    FUNCTION next_health_plan RETURN NUMBER IS
        l_next NUMBER;
    BEGIN
    
        SELECT MAX(id_health_plan) + 1
          INTO l_next
          FROM health_plan;
    
        RETURN l_next;
    
    END next_health_plan;

    FUNCTION next_health_plan_instit RETURN NUMBER IS
        l_next NUMBER;
    BEGIN
    
        SELECT MAX(id_health_plan_instit) + 1
          INTO l_next
          FROM health_plan_instit;
    
        RETURN l_next;
    
    END next_health_plan_instit;

    FUNCTION ins_health_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        desc_health_plan     IN VARCHAR2,
        i_insurance_class    IN health_plan.insurance_class%TYPE,
        i_flg_client         IN health_plan.flg_client%TYPE,
        i_health_plan_entity IN health_plan.id_health_plan_entity%TYPE,
        o_id_health_plan     OUT health_plan.id_health_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_type institution.flg_type%TYPE;
    
    BEGIN
    
        SELECT flg_type
          INTO l_type
          FROM institution
         WHERE id_institution = i_institution;
    
        o_id_health_plan := next_health_plan;
    
        INSERT INTO health_plan
            (id_health_plan,
             code_health_plan,
             flg_available,
             rank,
             adw_last_update,
             flg_instit_type,
             insurance_class,
             flg_client,
             id_health_plan_entity)
        VALUES
            (o_id_health_plan,
             'HEALTH_PLAN.CODE_HEALTH_PLAN.' || o_id_health_plan,
             'Y',
             0,
             SYSDATE,
             l_type,
             i_insurance_class,
             i_flg_client,
             i_health_plan_entity);
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || o_id_health_plan,
                                               i_desc_trans => desc_health_plan);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_owner,
                                              g_package,
                                              'INS_HEALTH_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_health_plan;

    FUNCTION ins_health_plan_instit
    (
        i_lang           IN language.id_language%TYPE,
        i_id_health_plan IN health_plan.id_health_plan%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_hpi health_plan_instit.id_health_plan%TYPE;
    
    BEGIN
    
        l_id_hpi := next_health_plan_instit;
    
        INSERT INTO health_plan_instit
            (id_health_plan_instit, id_institution, id_health_plan)
        VALUES
            (l_id_hpi, i_institution, i_id_health_plan);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_owner,
                                              g_package,
                                              'INS_HEALTH_PLAN_INSTIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_health_plan_instit;

BEGIN
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END t_health_plan;
/
