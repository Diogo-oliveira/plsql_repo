-- CHANGE BY: Telmo
-- CHANGE DATE: 03-04-2014
-- CHANGE REASON: ALERT-280787
CREATE OR REPLACE TYPE t_wl_prof IS OBJECT(
                                id_prof   number(24),
                                prof_name varchar2(800)
                                );
-- CHANGE END: Telmo