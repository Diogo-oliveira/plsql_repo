-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2011-APR-15
-- CHANGED REASON: ALERT-172741
DECLARE
    l_count PLS_INTEGER;
BEGIN

    SELECT COUNT(1)
      INTO l_count
      FROM all_objects o
     WHERE o.object_name LIKE 'PK_P1_CORE_INTERNAL'
       AND o.object_type LIKE 'PACKAGE%'
       AND o.owner = 'ALERT';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop package PK_P1_CORE_INTERNAL';
    END IF;
END;
/

DECLARE
    l_count PLS_INTEGER;
BEGIN

    SELECT COUNT(1)
      INTO l_count
      FROM all_objects o
     WHERE o.object_name LIKE 'PK_P1_EXR_DIAGNOSIS_TEMP'
       AND o.object_type LIKE 'PACKAGE%'
       AND o.owner = 'ALERT';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop package pk_p1_exr_diagnosis_temp';
    END IF;
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2011-APR-15
-- CHANGED REASON: ALERT-172741
DECLARE
    l_count PLS_INTEGER;
BEGIN

    -- spec
    SELECT COUNT(1)
      INTO l_count
      FROM all_objects o
     WHERE o.object_name LIKE 'PK_P1_CORE_INTERNAL'
       AND o.object_type = 'PACKAGE'
       AND o.owner = 'ALERT';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop package PK_P1_CORE_INTERNAL';
    END IF;

    -- body
    l_count := NULL;
    SELECT COUNT(1)
      INTO l_count
      FROM all_objects o
     WHERE o.object_name LIKE 'PK_P1_CORE_INTERNAL'
       AND o.object_type = 'PACKAGE BODY'
       AND o.owner = 'ALERT';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop package body PK_P1_CORE_INTERNAL';
    END IF;

    -- spec
    l_count := NULL;
    SELECT COUNT(1)
      INTO l_count
      FROM all_objects o
     WHERE o.object_name LIKE 'PK_P1_EXR_DIAGNOSIS_TEMP'
       AND o.object_type = 'PACKAGE'
       AND o.owner = 'ALERT';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop package pk_p1_exr_diagnosis_temp';
    END IF;

    -- body
    l_count := NULL;
    SELECT COUNT(1)
      INTO l_count
      FROM all_objects o
     WHERE o.object_name LIKE 'PK_P1_EXR_DIAGNOSIS_TEMP'
       AND o.object_type = 'PACKAGE BODY'
       AND o.owner = 'ALERT';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop package body pk_p1_exr_diagnosis_temp';
    END IF;
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 28/06/2013 17:48
-- CHANGE REASON: [ALERT_188926] Ability to perform triage based on EST (Échelle Suisse de Tri) - drop unused objects

DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE PK_EDIS_TRIAGE_AUX';
EXCEPTION
    WHEN e_already_dropped THEN
        NULL;
END;
/

-- CHANGE END: Alexandre Santos

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-09-04
-- CHANGE REASON: CODING-1567

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE PK_CODING_ACTIVITY';
    EXCEPTION
        WHEN e_object_exists THEN
            dbms_output.put_line('AVISO: Operacao ja executada anteriormente.');
    END;

END;
/

-- CHANGED END: Bruno Martins


-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2018-06-25
-- CHANGE REASON: EMR-4403

DROP PACKAGE pk_edis_discharge;
DROP PACKAGE pk_login_date_utils;
DROP PACKAGE pk_login_list;
DROP PACKAGE pk_login_message;
DROP PACKAGE pk_summary_page_dummy;
DROP PACKAGE pk_touch_option_dummy;
DROP PACKAGE rpe_experiencias;
DROP PACKAGE ts_epis_type_soft_inst;

-- CHANGED END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2018-06-26
-- CHANGE REASON: EMR-4403

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE pk_edis_discharge';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE pk_login_date_utils';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE pk_login_list';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE pk_login_message';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE pk_summary_page_dummy';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE pk_touch_option_dummy';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE rpe_experiencias';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04043);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE ts_epis_type_soft_inst';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;

END;
/

-- CHANGED END: Ana Matos

