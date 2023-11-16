-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 18/03/2015 11:44
-- CHANGE REASON: [ALERT-309049] [STABLE] EDIS patient grids changes
--                
DECLARE
    CURSOR c_episode_opinion IS
        SELECT DISTINCT e.id_episode,
                        pk_problems.get_institution(i_epis => e.id_episode, i_patient => NULL) institution,
                        ei.id_software,
                        pk_problems.get_language(i_epis => e.id_episode, i_patient => NULL) lang,
                        o.id_prof_questions
          FROM episode e
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          JOIN opinion o
            ON o.id_episode = e.id_episode
           AND o.id_opinion_type IS NULL
           AND ei.id_software = 8;
    l_result BOOLEAN;
    o_data   t_rec_epis_last_opinion;
    o_error  t_error_out;
BEGIN
    FOR i IN c_episode_opinion
    LOOP
        l_result := pk_opinion.get_epis_last_opinion(i_lang       => i.lang,
                                                     i_prof       => profissional(0, i.institution, i.id_software),
                                                     i_id_episode => i.id_episode,
                                                     o_data       => o_data,
                                                     o_error      => o_error);
        IF l_result
        THEN
            UPDATE grid_task gt
               SET gt.opinion_state = o_data.status_string
             WHERE gt.id_episode = i.id_episode;
        ELSE
            dbms_output.put_line('AVISO EPISODIO NAO MIGRADO:' || i.id_episode);
        END IF;
    END LOOP;
END;
/
-- CHANGE END: Elisabete Bugalho