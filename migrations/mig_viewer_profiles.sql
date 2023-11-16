-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/10/2013 
-- CHANGE REASON: [ALERT-262351 INP Nurse simplified profile
UPDATE prof_profile_template ppt
   SET ppt.id_profile_template = 223
 WHERE ppt.id_prof_profile_template IN (SELECT pv.id_prof_profile_template
                                          FROM prof_profile_template p1
                                          JOIN prof_profile_template pv
                                            ON pv.id_professional = p1.id_professional
                                           AND pv.id_software = p1.id_software
                                           AND pv.id_institution = p1.id_institution
                                         WHERE p1.id_profile_template IN (613)
                                           AND pv.id_profile_template = 277);

UPDATE prof_profile_template ppt
   SET ppt.id_profile_template = 223
 WHERE ppt.id_prof_profile_template IN (SELECT pv.id_prof_profile_template
                                          FROM prof_profile_template p1
                                          JOIN prof_profile_template pv
                                            ON pv.id_professional = p1.id_professional
                                           AND pv.id_software = p1.id_software
                                           AND pv.id_institution = p1.id_institution
                                         WHERE p1.id_profile_template IN (810)
                                           AND pv.id_profile_template = 289);
                                           
UPDATE prof_profile_template ppt
   SET ppt.id_profile_template = 274
 WHERE ppt.id_prof_profile_template IN (SELECT pv.id_prof_profile_template
                                          FROM prof_profile_template p1
                                          JOIN prof_profile_template pv
                                            ON pv.id_professional = p1.id_professional
                                           AND pv.id_software = p1.id_software
                                           AND pv.id_institution = p1.id_institution
                                         WHERE p1.id_profile_template IN (610)
                                           AND pv.id_profile_template = 217);
                                           
UPDATE prof_profile_template ppt
   SET ppt.id_profile_template = 274
 WHERE ppt.id_prof_profile_template IN (SELECT pv.id_prof_profile_template
                                          FROM prof_profile_template p1
                                          JOIN prof_profile_template pv
                                            ON pv.id_professional = p1.id_professional
                                           AND pv.id_software = p1.id_software
                                           AND pv.id_institution = p1.id_institution
                                         WHERE p1.id_profile_template IN (682)
                                           AND pv.id_profile_template = 195);
                                           
UPDATE prof_profile_template ppt
   SET ppt.id_profile_template = 274
 WHERE ppt.id_prof_profile_template IN (SELECT pv.id_prof_profile_template
                                          FROM prof_profile_template p1
                                          JOIN prof_profile_template pv
                                            ON pv.id_professional = p1.id_professional
                                           AND pv.id_software = p1.id_software
                                           AND pv.id_institution = p1.id_institution
                                         WHERE p1.id_profile_template IN (684)
                                           AND pv.id_profile_template = 196);
                                           
UPDATE prof_profile_template ppt
   SET ppt.id_profile_template = 274
 WHERE ppt.id_prof_profile_template IN (SELECT pv.id_prof_profile_template
                                          FROM prof_profile_template p1
                                          JOIN prof_profile_template pv
                                            ON pv.id_professional = p1.id_professional
                                           AND pv.id_software = p1.id_software
                                           AND pv.id_institution = p1.id_institution
                                         WHERE p1.id_profile_template IN (686)
                                           AND pv.id_profile_template = 196);
                                           
/*SELECT * FROM profile_template p
where p.id_profile_template = 684;*/
