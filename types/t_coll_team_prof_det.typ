create or replace type t_rec_team_prof_det force as object (
id_professional number(24),
prof_name varchar2(400 char),
id_profile_template number(24),
cat VARCHAR2(200 char)
);


CREATE OR REPLACE TYPE t_coll_team_prof_det IS TABLE OF t_rec_team_prof_det;
