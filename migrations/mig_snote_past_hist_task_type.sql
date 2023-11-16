-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 01/03/2012
-- CHANGE REASON: [ALERT-166586] Current Visit
BEGIN
    UPDATE epis_pn_det_task_hist e
       SET e.id_task =
           (SELECT ph.id_pat_ph_ft
              FROM pat_past_hist_ft_hist ph
             WHERE ph.id_pat_ph_ft_hist = e.id_task)
     WHERE e.id_task_type = 42;

    UPDATE epis_pn_det_task_work e
       SET e.id_task =
           (SELECT ph.id_pat_ph_ft
              FROM pat_past_hist_ft_hist ph
             WHERE ph.id_pat_ph_ft_hist = e.id_task)
     WHERE e.id_task_type = 42;

    UPDATE epis_pn_det_task e
       SET e.id_task =
           (SELECT ph.id_pat_ph_ft
              FROM pat_past_hist_ft_hist ph
             WHERE ph.id_pat_ph_ft_hist = e.id_task)
     WHERE e.id_task_type = 42;
END;
/
-- CHANGED END: Sofia Mendes
