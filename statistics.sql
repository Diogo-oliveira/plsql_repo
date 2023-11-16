-- CHANGED BY: Ana Matos
-- CHANGE DATE: 07/02/2012 15:44
-- CHANGE REASON: [ALERT-217627] 
BEGIN

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_AGP',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_ALIAS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_COLLECTION',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_COLLECTION_INT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_DEP_CLIN_SERV',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_DESC',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_GROUP',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_GROUP_ALIAS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_INSTIT_RECIPIENT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_INSTIT_SOFT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_PARAM',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_PARAMETER',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_PARAMETER_ALIAS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_PARAM_FUNCIONALITY',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_PARAM_INSTIT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_PARAM_INSTIT_SAMPLE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_QUESTIONNAIRE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_RES_CALCULATOR',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_RES_PAR_CALC',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_ROOM',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_SAMPLE_TYPE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'ANALYSIS_UNIT_MEASURE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'LAB_TESTS_UNI_MEA_CNV',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'LAB_TESTS_PAR_UNI_MEA',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'LAB_TESTS_COMPLAINT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_ALIAS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_BODY_STRUCTURE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_CAT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_CAT_DCS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_CODIFICATION',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_COMPLAINT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_DEP_CLIN_SERV',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_EGP',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_GROUP',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_QUESTIONNAIRE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_ROOM',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_SCHEDULE_DCS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'CODIFICATION',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'EXAM_BODY_STRUCTURE',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'BODY_STRUCTURE_REL',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'BODY_STRUCTURE_DCS',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');

    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'CODIFICATION_INSTIT_SOFT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly');
END;
/
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/02/2012 14:11
-- CHANGE REASON: [ALERT-218283] 
DECLARE
    res VARCHAR2(1000);

    l_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(l_exception, -20007);
BEGIN
    res := dbms_stats.create_extended_stats(USER, 'CODIFICATION_INSTIT_SOFT', '(id_institution,id_software)');
EXCEPTION
    WHEN l_exception THEN
        NULL;
END;
/

BEGIN
    dbms_stats.set_table_prefs(ownname => USER,
                               tabname => 'CODIFICATION_INSTIT_SOFT',
                               pname   => 'METHOD_OPT',
                               pvalue  => 'for all indexed columns size skewonly  for columns (id_institution,id_software) size skewonly');
END;
/
-- CHANGE END: Ana Matos