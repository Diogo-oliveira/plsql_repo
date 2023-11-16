CREATE OR REPLACE TYPE t_rec_rehab_episodes FORCE IS OBJECT(id_episode NUMBER(24), id_schedule NUMBER(24), origin VARCHAR(1000 CHAR), pat_name VARCHAR(1000 CHAR), 
       pat_name_sort VARCHAR(1000 CHAR), pat_age VARCHAR2(50), pat_gender VARCHAR2(1 CHAR), photo VARCHAR(1000 CHAR), 
       num_clin_record VARCHAR2(100), name_prof VARCHAR2(800), desc_session_type VARCHAR(1000 CHAR), desc_schedule_type VARCHAR(1000 CHAR), 
       servico VARCHAR(1000 CHAR), desc_room VARCHAR(1000 CHAR), bed_name VARCHAR(1000 CHAR), dt_target VARCHAR2(4000), dt_target_tstz  VARCHAR2(4000));
/
