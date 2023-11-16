-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/10/2013 
-- CHANGE REASON: [ALERT-262351 INP Nurse simplified profile
DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    /* Edit this function */
    PROCEDURE do_my_validation IS
        /* Declarations */
        /* example: */
        e_has_findings EXCEPTION;
        l_count_810 PLS_INTEGER;
        l_count_613 PLS_INTEGER;
        l_count_610 PLS_INTEGER;
        l_count_682 PLS_INTEGER;
        l_count_684 PLS_INTEGER;
        l_count_686 PLS_INTEGER;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        BEGIN
            SELECT COUNT(1)
              INTO l_count_810
              FROM prof_profile_template p1
              JOIN prof_profile_template pv
                ON pv.id_professional = p1.id_professional
               AND pv.id_software = p1.id_software
               AND pv.id_institution = p1.id_institution
             WHERE p1.id_profile_template IN (810)
               AND pv.id_profile_template = 289;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_810 := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count_810 := 0;
                END IF;
        END;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_count_613
              FROM prof_profile_template p1
              JOIN prof_profile_template pv
                ON pv.id_professional = p1.id_professional
               AND pv.id_software = p1.id_software
               AND pv.id_institution = p1.id_institution
             WHERE p1.id_profile_template IN (613)
               AND pv.id_profile_template = 277;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_613 := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count_613 := 0;
                END IF;
        END;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_count_610
              FROM prof_profile_template p1
              JOIN prof_profile_template pv
                ON pv.id_professional = p1.id_professional
               AND pv.id_software = p1.id_software
               AND pv.id_institution = p1.id_institution
             WHERE p1.id_profile_template IN (610)
               AND pv.id_profile_template = 217;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_610 := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count_610 := 0;
                END IF;
        END;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_count_682
              FROM prof_profile_template p1
              JOIN prof_profile_template pv
                ON pv.id_professional = p1.id_professional
               AND pv.id_software = p1.id_software
               AND pv.id_institution = p1.id_institution
             WHERE p1.id_profile_template IN (682)
               AND pv.id_profile_template = 195;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_682 := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count_682 := 0;
                END IF;
        END;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_count_682
              FROM prof_profile_template p1
              JOIN prof_profile_template pv
                ON pv.id_professional = p1.id_professional
               AND pv.id_software = p1.id_software
               AND pv.id_institution = p1.id_institution
             WHERE p1.id_profile_template IN (684)
               AND pv.id_profile_template = 196;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_682 := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count_682 := 0;
                END IF;
        END;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_count_682
              FROM prof_profile_template p1
              JOIN prof_profile_template pv
                ON pv.id_professional = p1.id_professional
               AND pv.id_software = p1.id_software
               AND pv.id_institution = p1.id_institution
             WHERE p1.id_profile_template IN (686)
               AND pv.id_profile_template = 196;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_682 := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count_682 := 0;
                END IF;
        END;
    
        IF (l_count_810 > 0 OR l_count_613 > 0 OR l_count_610 > 0 OR l_count_682 > 0 OR l_count_684 > 0 OR
           l_count_686 > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON mig inp nurse profile viewer. l_count_810: ' || l_count_810 || ', l_count_613: ' ||
                      l_count_613 || ', l_count_610: ' || l_count_610 || ', l_count_682: ' || l_count_682 ||
                      ', l_count_684: ' || l_count_684 || ', l_count_686: ' || l_count_686);
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/
