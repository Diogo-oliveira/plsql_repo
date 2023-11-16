-- CHANGE BY: Telmo
-- CHANGE DATE: 03-04-2014
-- CHANGE REASON: ALERT-280787
CREATE OR REPLACE TYPE t_search_prof IS OBJECT(
                                    id   NUMBER(24),
                                    name VARCHAR2(4000)
                                    );
--CHANGE END: Telmo
