-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 09/06/2015 09:17
-- CHANGE REASON: [ALERT-312396] ALERT-312396 Issue Replication: [BSUH] Outpatient Appointment report and Outpatient GP Letter generation and sending 2 reports in discharge
BEGIN
    FOR disch IN (SELECT id_discharge, flg_crm_status, id_episode, id_report
                    FROM (SELECT d.id_discharge,
                                 d.flg_crm_status,
                                 d.id_episode,
                                 pk_sysconfig.get_config(i_code_cf   => 'DISCHARGE_LETTER_ID_REPORT',
                                                         i_prof_inst => e.id_institution,
                                                         i_prof_soft => ei.id_software) id_report
                            FROM discharge d
                            JOIN episode e
                              ON d.id_episode = e.id_episode
                            JOIN epis_info ei
                              ON e.id_episode = ei.id_episode
                           WHERE d.flg_crm_status IS NOT NULL
                             AND NOT EXISTS (SELECT 1
                                    FROM alert.discharge_report dr
                                   WHERE dr.id_discharge = d.id_discharge))
                   WHERE id_report IS NOT NULL)
    LOOP
        INSERT INTO discharge_report
            (id_discharge_report, id_discharge, id_report, flg_status)
        VALUES
            (seq_discharge_report.nextval, disch.id_discharge, disch.id_report, disch.flg_crm_status);
    END LOOP;
END;
/
-- CHANGE END: Nuno Alves