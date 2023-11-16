BEGIN
    UPDATE epis_hidrics_det_ftxt hftxt
       SET hftxt.id_patient =
           (SELECT e.id_patient
              FROM epis_hidrics eh
              JOIN episode e
                ON e.id_episode = eh.id_episode
             WHERE eh.id_epis_hidrics = hftxt.id_epis_hidrics);
             
             
     UPDATE epis_hd_ftxt_hist hftxt
       SET hftxt.id_patient =
           (SELECT e.id_patient
              FROM epis_hidrics eh
              JOIN episode e
                ON e.id_episode = eh.id_episode
             WHERE eh.id_epis_hidrics = hftxt.id_epis_hidrics);
END;
/
