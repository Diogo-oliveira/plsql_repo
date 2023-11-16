/*-- Last Change Revision: $Rev: 2029421 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE t_health_plan IS

    -- Author  : SUSANA
    -- Created : 27-05-2008 17:11:23
    -- Purpose : Functions for DML operations on health plans' tables.

    FUNCTION ins_health_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        desc_health_plan     IN VARCHAR2,
        i_insurance_class    IN health_plan.insurance_class%TYPE,
        i_flg_client         IN health_plan.flg_client%TYPE,
        i_health_plan_entity IN health_plan.id_health_plan_entity%TYPE,
        o_id_health_plan     OUT health_plan.id_health_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ins_health_plan_instit
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_id_health_plan IN health_plan.id_health_plan%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END t_health_plan;
/
