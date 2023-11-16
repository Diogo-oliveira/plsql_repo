CREATE OR REPLACE view v_stg_files AS 
SELECT id_stg_files,file_name, id_professional, file_upload_time
  FROM stg_files;