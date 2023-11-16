-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE view v_pat_medication_list AS
        SELECT *
          FROM pat_medication_list;
-- CHANGE END: Pedro Teixeira