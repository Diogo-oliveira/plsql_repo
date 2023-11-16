-- Past Medical
UPDATE pat_past_hist_free_text pphft
  SET pphft.id_doc_area = 45
WHERE pphft.id_doc_area IS NULL
  AND pphft.flg_type = 'M';
  
-- Past Surgical
UPDATE pat_past_hist_free_text pphft
  SET pphft.id_doc_area = 46
 WHERE pphft.id_doc_area IS NULL
   AND pphft.flg_type = 'S';

-- Congenital anomalies
UPDATE pat_past_hist_free_text pphft
  SET pphft.id_doc_area = 52
 WHERE pphft.id_doc_area IS NULL
   AND pphft.flg_type = 'A';
