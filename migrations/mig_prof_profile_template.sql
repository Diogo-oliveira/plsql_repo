-- CHANGED BY: José Silva
-- CHANGE DATE: 17/11/2011 19:58
-- CHANGE REASON: [ALERT-205444] Associate UK profiles with the CL market
DECLARE
    
    l_new_prof_templ profile_template.id_profile_template%TYPE;

    CURSOR c_prof_profile_template IS
       SELECT p.id_prof_profile_template,
              p.id_profile_template,
              pt.intern_name_templ,
              pt.id_software,
              pt.flg_type
         FROM prof_profile_template p
         JOIN profile_template pt ON pt.id_profile_template = p.id_profile_template
         JOIN institution i ON i.id_institution = p.id_institution
        WHERE i.id_market = 12
          AND EXISTS (SELECT 0 FROM profile_template_market pm WHERE pm.id_profile_template = pt.id_profile_template AND pm.id_market = 0)
          AND pt.id_software in (1, 2, 8, 11, 43)
          AND pt.flg_type in ('U', 'D', 'N', 'A')
       ORDER BY id_software;
BEGIN
 
   FOR r_prof_profile IN c_prof_profile_template
   LOOP
   
     l_new_prof_templ := NULL;  
   
     IF r_prof_profile.id_software = 1 AND r_prof_profile.flg_type = 'A'
     THEN
        l_new_prof_templ := 63;
     ELSIF r_prof_profile.id_software = 1 AND r_prof_profile.flg_type = 'D'
     THEN
        l_new_prof_templ := 926;
     ELSIF r_prof_profile.id_software = 1 AND r_prof_profile.flg_type = 'N'
     THEN
        l_new_prof_templ := 922;
     ELSIF r_prof_profile.id_software = 2 AND r_prof_profile.flg_type = 'D'
     THEN
        l_new_prof_templ := 111;
     ELSIF r_prof_profile.id_software = 2 AND r_prof_profile.flg_type = 'N'
     THEN
        l_new_prof_templ := 114;
     ELSIF r_prof_profile.id_software = 8 AND r_prof_profile.flg_type = 'D'
     THEN
        l_new_prof_templ := 476;
     ELSIF r_prof_profile.id_software = 8 AND r_prof_profile.flg_type = 'N'
     THEN
        l_new_prof_templ := 472;
     ELSIF r_prof_profile.id_software = 11 AND r_prof_profile.flg_type = 'D'
     THEN
        l_new_prof_templ := 816;
     ELSIF r_prof_profile.id_software = 11 AND r_prof_profile.flg_type = 'N'
     THEN
        l_new_prof_templ := 812;
     ELSIF r_prof_profile.id_software = 43 AND r_prof_profile.flg_type = 'U'
     THEN
        l_new_prof_templ := 84;
     END IF;
   
     IF l_new_prof_templ IS NOT NULL
     THEN
       UPDATE prof_profile_template p
          SET p.id_profile_template = l_new_prof_templ
        WHERE p.id_prof_profile_template = r_prof_profile.id_prof_profile_template;
     END IF;
   
   END LOOP;


END;
/
-- CHANGE END: José Silva
