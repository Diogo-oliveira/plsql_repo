-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 15/11/2012 15:30
-- CHANGE REASON: [ALERT-244766] cds content for medispan update
DECLARE
    l_owner CONSTANT VARCHAR2(30 CHAR) := 'ALERT';
    l_tables table_varchar := table_varchar('CDR_MESSAGE',
                                            'CDR_DEFINITION',
                                            'CDR_DEF_MKT',
                                            'CDR_DEF_SEVERITY',
                                            'CDR_DEF_COND',
                                            'CDR_PARAMETER',
                                            'CDR_PARAM_ACTION',
                                            'CDR_INSTANCE',
                                            'CDR_INST_PARAM',
                                            'CDR_INST_PAR_ACTION',
                                            'CDR_INST_PAR_VAL',
                                            'CDR_INST_PAR_ACT_VAL');
BEGIN
    -- do not process any table more than once
    l_tables := l_tables MULTISET UNION DISTINCT table_varchar();

    -- enable indexes and foreign keys
    pk_frmw.enable_index_bulk(i_table_name => l_tables, i_enable_fk => TRUE, i_owner => l_owner);
END;
/
-- CHANGE END: Pedro Carneiro

-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 20/11/2012 12:19
-- CHANGE REASON: [ALERT-244766] cds content for medispan update
DECLARE
    l_owner CONSTANT VARCHAR2(30 CHAR) := 'ALERT';
    l_tables table_varchar := table_varchar('CDR_MESSAGE',
                                            'CDR_DEFINITION',
                                            'CDR_DEF_MKT',
                                            'CDR_DEF_SEVERITY',
                                            'CDR_DEF_COND',
                                            'CDR_PARAMETER',
                                            'CDR_PARAM_ACTION',
                                            'CDR_INSTANCE',
                                            'CDR_INST_PARAM',
                                            'CDR_INST_PAR_ACTION',
                                            'CDR_INST_PAR_VAL',
                                            'CDR_INST_PAR_ACT_VAL');
BEGIN
    -- do not process any table more than once
    l_tables := l_tables MULTISET UNION DISTINCT table_varchar();

    EXECUTE IMMEDIATE 'alter trigger b_iu_cdr_inst_param enable';

    -- enable indexes and foreign keys
    pk_frmw.enable_index_bulk(i_table_name => l_tables, i_enable_fk => TRUE, i_owner => l_owner);
END;
/
-- CHANGE END: Pedro Carneiro


-- CHANGED BY: Bernardo Almeida
-- CHANGE DATE: 05/03/2013 10:10
-- CHANGE REASON: [ALERT-240800]
DECLARE
    l_owner CONSTANT VARCHAR2(30 CHAR) := 'ALERT';
    l_tables table_varchar := table_varchar('CDR_MESSAGE',
                                            'CDR_DEFINITION',
                                            'CDR_DEF_MKT',
                                            'CDR_DEF_SEVERITY',
                                            'CDR_DEF_COND',
                                            'CDR_PARAMETER',
                                            'CDR_PARAM_ACTION',
                                            'CDR_INSTANCE',
                                            'CDR_INST_PARAM',
                                            'CDR_INST_PAR_ACTION',
                                            'CDR_INST_PAR_VAL',
                                            'CDR_INST_PAR_ACT_VAL');
BEGIN
    -- do not process any table more than once
    l_tables := l_tables MULTISET UNION DISTINCT table_varchar();

    EXECUTE IMMEDIATE 'alter trigger b_iu_cdr_inst_param enable';

    -- enable indexes and foreign keys
    pk_frmw.enable_index_bulk(i_table_name => l_tables, i_enable_fk => TRUE, i_owner => l_owner);
END;
/

-- CHANGE END: Bernardo Almeida