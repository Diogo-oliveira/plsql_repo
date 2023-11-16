-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 26/07/2011 16:49
-- CHANGE REASON: [ALERT-188174] 
begin
INSERT INTO pat_child_feed_dev_hist
    (id_pat_child_feed_dev_hist,
     dt_pat_child_feed_dev,
     id_patient,
     id_child_feed_dev,
     id_professional,
     child_age,
     flg_status,
     id_episode)
    (SELECT ts_pat_child_feed_dev_hist.next_key id_pat_child_feed_dev_hist,
            nvl(decode(p.flg_status, 'C', p.dt_cancel, p.dt_pat_child_feed_dev), p.dt_pat_child_feed_dev) dt_pat_child_feed_dev,
            p.id_patient,
            p.id_child_feed_dev,
            nvl(decode(p.flg_status, 'C', p.id_prof_cancel, p.id_professional), p.id_professional) id_professional,
            p.child_age,
            p.flg_status,
            p.id_episode
       FROM pat_child_feed_dev p
      WHERE (SELECT COUNT(1)
               FROM pat_child_feed_dev_hist ph
              WHERE ph.dt_pat_child_feed_dev =
                    nvl(decode(p.flg_status, 'C', p.dt_cancel, p.dt_pat_child_feed_dev), p.dt_pat_child_feed_dev)
                AND ph.id_patient = p.id_patient
                AND ph.id_child_feed_dev = p.id_child_feed_dev
                AND ph.id_professional =
                    nvl(decode(p.flg_status, 'C', p.id_prof_cancel, p.id_professional), p.id_professional)
                AND ph.child_age = p.child_age
                AND ph.flg_status = p.flg_status
                AND ph.id_episode = p.id_episode) = 0) UNION ALL
    (SELECT ts_pat_child_feed_dev_hist.next_key id_pat_child_feed_dev_hist,
            p.dt_pat_child_feed_dev,
            p.id_patient,
            p.id_child_feed_dev,
            p.id_professional,
            p.child_age,
            'A',
            p.id_episode
       FROM pat_child_feed_dev p
      WHERE p.flg_status = 'C'
        AND (SELECT COUNT(1)
               FROM pat_child_feed_dev_hist ph
              WHERE ph.dt_pat_child_feed_dev = p.dt_pat_child_feed_dev
                AND ph.id_patient = p.id_patient
                AND ph.id_child_feed_dev = p.id_child_feed_dev
                AND ph.id_professional = p.id_professional
                AND ph.child_age = p.child_age
                AND ph.flg_status = 'A'
                AND ph.id_episode = p.id_episode) = 0);
end;
/
-- CHANGE END: Paulo Teixeira